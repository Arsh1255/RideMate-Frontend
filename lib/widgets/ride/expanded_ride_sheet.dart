import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/colors.dart';
import '../../service/auth_service.dart';
import 'status_pill.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/profile_screen.dart';
import '../../screens/ride_chat_screen.dart';
import '../gradient_button.dart';
import '../../service/socket_service.dart';

class ExpandedRideSheet extends StatefulWidget {
  final String rideId;
  final int? seatsRequested;
  final Map<String, dynamic>? pickupLocation;

  const ExpandedRideSheet({
    super.key,
    required this.rideId,
    this.seatsRequested,
    this.pickupLocation,
  });

  @override
  State<ExpandedRideSheet> createState() => _ExpandedRideSheetState();
}

class _ExpandedRideSheetState extends State<ExpandedRideSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _ride;
  String? _error;
  final AuthService _authService = AuthService();

  void _onRideUpdate(dynamic _) {
    if (mounted) _fetchRideDetails();
  }

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
    
    // Join ride room
    SocketService().joinRide(widget.rideId);
    
    // Listen for events
    SocketService().on('PARTICIPANT_JOINED', _onRideUpdate);
    SocketService().on('RIDE_STARTED', _onRideUpdate);
    SocketService().on('RIDE_COMPLETED', _onRideUpdate);
    SocketService().on('RIDE_CANCELLED', _onRideUpdate);
    SocketService().on('REQUEST_CREATED', _onRideUpdate);
  }

  @override
  void dispose() {
    SocketService().off('PARTICIPANT_JOINED', _onRideUpdate);
    SocketService().off('RIDE_STARTED', _onRideUpdate);
    SocketService().off('RIDE_COMPLETED', _onRideUpdate);
    SocketService().off('RIDE_CANCELLED', _onRideUpdate);
    SocketService().off('REQUEST_CREATED', _onRideUpdate);
    SocketService().leaveRide(widget.rideId);
    super.dispose();
  }

  Future<void> _fetchRideDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _authService.getRideDetails(widget.rideId);
      setState(() {
        _ride = response['ride'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createRequest() async {
    try {
      await _authService.createRequest({
        'rideId': widget.rideId,
        'seatsRequested': widget.seatsRequested ?? 1,
        'pickupLocation': widget.pickupLocation ?? {
          'address': 'Current Location',
          'coordinates': _ride!['source']
        }
      });
      _showSnackBar("Request sent successfully!", isError: false);
      await _fetchRideDetails(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to send request: $e", isError: true);
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _authService.acceptRequest(requestId);
      _showSnackBar("Request accepted!", isError: false);
      await _fetchRideDetails(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to accept: $e", isError: true);
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _authService.rejectRequest(requestId);
      _showSnackBar("Request rejected.", isError: false);
      await _fetchRideDetails(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to reject: $e", isError: true);
    }
  }

  Future<void> _removeParticipant(String participantId) async {
    try {
      await _authService.removeParticipant(widget.rideId, participantId);
      _showSnackBar("Participant removed.", isError: false);
      await _fetchRideDetails(); // Refresh
    } catch (e) {
      _showSnackBar("Failed to remove: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showParticipantActions(Map<String, dynamic> participant, bool isCreator) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = participant['uid'] == currentUserUid;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(participant['name'] ?? "User"),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: participant['uid'])));
            },
            child: const Text("View Profile"),
          ),
          if (isCreator && !isMe)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _removeParticipant(participant['_id']);
              },
              child: const Text("Remove Participant"),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 400,
        child: Center(child: Text("Error: $_error", style: const TextStyle(color: AppColors.error))),
      );
    }

    if (_ride == null) {
      return const SizedBox(
        height: 400,
        child: Center(child: Text("Ride not found")),
      );
    }

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final creator = _ride!['creatorId'];
    final isCreator = creator != null && creator['uid'] == currentUserUid;
    
    final participants = _ride!['participantIds'] as List<dynamic>;
    final isParticipant = participants.any((p) => p['uid'] == currentUserUid);
    
    final pendingRequests = _ride!['pendingRequests'] as List<dynamic>;
    final isPending = pendingRequests.any((r) => r['userId'] != null && r['userId']['uid'] == currentUserUid);
    
    final isStranger = !isCreator && !isParticipant && !isPending;

    final departureTime = DateTime.parse(_ride!['departureTime']);
    final timeStr = DateFormat('h:mm a').format(departureTime);
    final dateStr = DateFormat('EEEE, d MMMM').format(departureTime);

    String modeLabel = _ride!['mode'] ?? "N/A";
    if (modeLabel == 'publicTransportation') modeLabel = 'Public Transport';
    if (modeLabel == 'hasVehicle') modeLabel = 'Ride together';
    if (modeLabel == 'stride') modeLabel = 'Walk together';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Header: Creator & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  if (creator != null && creator['uid'] != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: creator['uid'])));
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: creator != null && creator['profilePic'] != null 
                        ? AssetImage("assets/avatars/${creator['profilePic']}") 
                        : const AssetImage("assets/avatars/earth.png") as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(creator != null ? creator['name'] ?? "Rider" : "Rider", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            if (creator != null && creator['ecoScore'] != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Eco ${creator['ecoScore']}",
                                  style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(modeLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              StatusPill(status: _ride!['status'] ?? 'created'),
            ],
          ),
          const SizedBox(height: 24),

          if (_ride!['status'] == 'started') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.mapPin, color: AppColors.primaryBlue, size: 20),
                  SizedBox(width: 12),
                  Text(
                    "Ride In Progress",
                    style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Route & Timing Group
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Image.asset('assets/icons/start.png', width: 20, height: 20),
                        Container(
                          width: 2,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        Image.asset('assets/icons/stop.png', width: 20, height: 20),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(_ride!['source']['name'] ?? _ride!['source']['address'] ?? "Unknown", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 22),
                          Text(_ride!['destination']['name'] ?? _ride!['destination']['address'] ?? "Unknown", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _detailItem(LucideIcons.calendar, dateStr),
                    _detailItem(LucideIcons.clock, timeStr),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pricing & Seats Group
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _detailItem(LucideIcons.armchair, "${_ride!['availableSeats']} seats available"),
                    _detailItem(LucideIcons.banknote, "₹${_ride!['pricePerPerson'] ?? 0} per person"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _detailItem(LucideIcons.tag, _ride!['vehicleType'] ?? "N/A"),
                    const SizedBox(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Creator Notes
          if (_ride!['notes'] != null && _ride!['notes'].isNotEmpty) ...[
            const Text("Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_ride!['notes'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
          ],

          // Participants
          const Text("Participants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (participants.isEmpty)
            const Text("No participants yet", style: TextStyle(color: AppColors.textSecondary))
          else
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  final isMe = p['uid'] == currentUserUid;
                  final isPricipalCreator = creator != null && p['uid'] == creator['uid'];
                  
                  String nameLabel = p['name'] ?? "User";
                  if (isMe) nameLabel += " (You)";

                  return GestureDetector(
                    onTap: () => _showParticipantActions(p, isCreator),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: p['profilePic'] != null 
                              ? AssetImage("assets/avatars/${p['profilePic']}") 
                              : const AssetImage("assets/avatars/earth.png") as ImageProvider,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nameLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              color: isPricipalCreator ? AppColors.primaryGreen : AppColors.textPrimary,
                            ),
                          ),
                          if (isPricipalCreator)
                            const Text("Creator", style: TextStyle(fontSize: 10, color: AppColors.primaryGreen)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // Request Match Button (for strangers)
          if (isStranger) ...[
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: "Request Match",
                onTap: _createRequest,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Chatroom Button
          if ((isCreator || isParticipant) && _ride!['status'] != 'completed' && _ride!['status'] != 'cancelled' && _ride!['membershipStatus'] != 'pending') ...[
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: "Open Chatroom",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideChatScreen(
                        rideId: widget.rideId,
                        rideName: _ride!['rideName'] ?? "Ride Chat",
                        rideStatus: _ride!['status'] ?? "created",
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Creator Section: Pending Requests
          if (isCreator) ...[
            const Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            if (pendingRequests.isEmpty)
              const Text("No pending requests", style: TextStyle(color: AppColors.textSecondary))
            else
              ...pendingRequests.map((req) {
                final requester = req['userId'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: requester != null && requester['profilePic'] != null 
                              ? AssetImage("assets/avatars/${requester['profilePic']}") 
                              : const AssetImage("assets/avatars/earth.png") as ImageProvider,
                          ),
                          const SizedBox(width: 8),
                          Text(requester != null ? requester['name'] ?? "User" : "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.check, color: AppColors.primaryGreen),
                            onPressed: () => _acceptRequest(req['_id']),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, color: AppColors.error),
                            onPressed: () => _rejectRequest(req['_id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }
}
