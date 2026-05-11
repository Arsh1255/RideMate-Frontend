import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/colors.dart';
import '../../service/socket_service.dart';
import '../../service/auth_service.dart';
import '../widgets/ride/status_pill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final String rideName;
  final String rideStatus;

  const RideChatScreen({
    super.key,
    required this.rideId,
    required this.rideName,
    required this.rideStatus,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoadingHistory = true;
  bool _isSending = false;
  Map<String, dynamic>? _ride;
  List<dynamic> _participants = [];
  String? _currentUserId;
  bool _isNearBottom = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchRideDetails();
    _fetchMessageHistory();
    
    // Join room
    SocketService().joinRide(widget.rideId);
    
    // Listen for messages
    SocketService().on('CHAT:MESSAGE', _onMessageReceived);
    
    // Listen for reconnect to safely re-fetch missed messages
    SocketService().onConnect(_onSocketReconnect);
    
    // Listen for scroll to detect if near bottom
    _scrollController.addListener(_onScroll);
  }

  void _onSocketReconnect(dynamic data) {
    if (mounted) {
      SocketService().joinRide(widget.rideId);
      _fetchMessageHistory();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    
    // Leave room and remove listener safely
    SocketService().leaveRide(widget.rideId);
    SocketService().off('CHAT:MESSAGE', _onMessageReceived);
    // Note: onConnect listener in socket_io_client isn't easily removable via our abstraction, but it's safe if it triggers.
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // If within 100 pixels of bottom
      _isNearBottom = (maxScroll - currentScroll) <= 100;
    }
  }

  Future<void> _fetchRideDetails() async {
    try {
      final data = await AuthService().fetchRideDetails(widget.rideId);
      setState(() {
        _ride = data['ride'];
        _participants = _ride!['participantIds'] ?? [];
        // Add creator to list at index 0
        if (_ride!['creatorId'] != null) {
          _participants.insert(0, _ride!['creatorId']);
        }
      });
    } catch (e) {
      print("Error fetching ride details: $e");
    }
  }

  Future<void> _fetchMessageHistory() async {
    try {
      final data = await AuthService().fetchMessages(widget.rideId);
      setState(() {
        _messages.clear();
        _messages.addAll(List<Map<String, dynamic>>.from(data['messages'] ?? []));
        _isLoadingHistory = false;
      });
      _scrollToBottom(force: true);
    } catch (e) {
      print("Error fetching message history: $e");
      setState(() => _isLoadingHistory = false);
    }
  }

  void _onMessageReceived(dynamic data) {
    if (data is Map && data['rideId'] == widget.rideId) {
      setState(() {
        _messages.add(Map<String, dynamic>.from(data));
      });
      
      if (_isNearBottom) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (force || _isNearBottom) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSending = true);
    
    try {
      SocketService().sendMessage(widget.rideId, text);
      _messageController.clear();
      setState(() => _isSending = false);
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message. Try again.")),
      );
      setState(() => _isSending = false);
    }
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return "";
    final date = DateTime.parse(isoString).toLocal();
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('h:mm a').format(date);
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return "Yesterday ${DateFormat('h:mm a').format(date)}";
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.rideStatus == 'completed' || widget.rideStatus == 'cancelled';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rideName,
              style: TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  "${_participants.length} members",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 8),
                StatusPill(status: widget.rideStatus),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: AppColors.white,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _participants.length,
              itemBuilder: (context, index) {
                final participant = _participants[index];
                final profilePic = participant['profilePic'];
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: profilePic != null
                        ? AssetImage("assets/avatars/$profilePic")
                        : const AssetImage("assets/avatars/earth.png") as ImageProvider,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (isLocked)
            Container(
              width: double.infinity,
              color: AppColors.warningBg,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, color: AppColors.warningText, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "This ride is ${widget.rideStatus} and chat is locked.",
                    style: TextStyle(color: AppColors.warningText, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.messageSquare, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              "No messages yet.\nStart coordinating your ride 👋",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final sender = message['sender'];
                          final isSelf = sender != null && sender['uid'] == _currentUserId;
                          
                          bool isSameSenderAsPrevious = false;
                          if (index > 0) {
                            final prevSender = _messages[index - 1]['sender'];
                            isSameSenderAsPrevious = prevSender != null && sender != null && prevSender['uid'] == sender['uid'];
                          }
                          
                          return _buildMessageBubble(message, isSelf, isSameSenderAsPrevious);
                        },
                      ),
          ),
          
          if (!isLocked)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.send, color: AppColors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isSelf, bool isSameSenderAsPrevious) {
    final sender = message['sender'];
    final senderName = sender != null ? sender['name'] : "Unknown";
    final profilePic = sender != null ? sender['profilePic'] : null;
    final text = message['text'] ?? "";
    final timeStr = _formatTimestamp(message['createdAt']);

    return Container(
      margin: EdgeInsets.only(top: isSameSenderAsPrevious ? 4 : 12),
      child: Row(
        mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSelf && !isSameSenderAsPrevious) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: profilePic != null
                  ? AssetImage("assets/avatars/$profilePic")
                  : const AssetImage("assets/avatars/earth.png") as ImageProvider,
            ),
            const SizedBox(width: 8),
          ] else if (!isSelf) ...[
            const SizedBox(width: 36), // Indent for missing avatar
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelf ? AppColors.primaryGreen : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(!isSelf && !isSameSenderAsPrevious ? 4 : 16),
                  bottomRight: Radius.circular(isSelf ? 4 : 16),
                ),
                border: isSelf ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSelf && !isSameSenderAsPrevious)
                    Text(
                      senderName,
                      style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  if (!isSelf && !isSameSenderAsPrevious) const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(color: isSelf ? AppColors.white : AppColors.black, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(color: isSelf ? Color(0xB3FFFFFF) : AppColors.textSecondary, fontSize: 10), // Colors.white70 is 0xB3FFFFFF
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
