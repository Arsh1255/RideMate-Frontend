import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/colors.dart';
import 'finding_matches_screen.dart';

class FindRideScreen extends StatefulWidget {
  const FindRideScreen({super.key});

  @override
  State<FindRideScreen> createState() => _FindRideScreenState();
}

class _FindRideScreenState extends State<FindRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  
  // Logic: Track which field is currently being edited
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropFocus = FocusNode();
  bool _isPickupActive = true; 

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedSeats = 1;

  @override
  void initState() {
    super.initState();
    // Listen for focus changes to target the "Locate Me" or "Map" inputs correctly
    _pickupFocus.addListener(() { if (_pickupFocus.hasFocus) setState(() => _isPickupActive = true); });
    _dropFocus.addListener(() { if (_dropFocus.hasFocus) setState(() => _isPickupActive = false); });
  }

  // LOGIC: Swap Pickup and Dropoff
  void _swapLocations() {
    setState(() {
      final String temp = _pickupController.text;
      _pickupController.text = _dropController.text;
      _dropController.text = temp;
    });
  }

  // LOGIC: Clear Both Fields
  void _clearBoth() {
    setState(() {
      _pickupController.clear();
      _dropController.clear();
    });
  }

  // LOGIC: Get Current GPS and fill the ACTIVE field
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}';
    
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'RideMate_App'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (_isPickupActive) {
            _pickupController.text = data['display_name'] ?? "Current Location";
          } else {
            _dropController.text = data['display_name'] ?? "Current Location";
          }
        });
      }
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Find your ride", 
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _clearBoth,
            child: const Text("Clear", 
              style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  
                  // INPUT SECTION (Pickup & Drop)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Row(
                          children: [
                            _buildRouteGraphic(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLocationInput("Pickup location", _pickupController, _pickupFocus),
                                  const Divider(height: 32, color: AppColors.border),
                                  _buildLocationInput("Drop location", _dropController, _dropFocus),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48), // Space for Swap Button
                          ],
                        ),
                        // THE SWAP BUTTON
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: _swapLocations,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                                color: Colors.white,
                              ),
                              child: const Icon(LucideIcons.arrowUpDown, size: 20, color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SELECTION ROWS
                  _buildRow(
                    icon: LucideIcons.calendar,
                    label: "Date",
                    value: DateFormat('EEEE, d MMM').format(_selectedDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2027),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                  _buildRow(
                    icon: LucideIcons.clock,
                    label: "Time",
                    value: _selectedTime.format(context),
                    onTap: _showSamsungTimePicker,
                  ),
                  _buildRow(
                    icon: LucideIcons.users,
                    label: "Seats Needed",
                    value: "$_selectedSeats Seat${_selectedSeats > 1 ? 's' : ''}",
                    onTap: _showSeatPicker,
                  ),
                ],
              ),
            ),
          ),

          // THE GRADIENT REQUEST BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryGreen]),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FindingMatchesScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Request Ride", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildRouteGraphic() {
    return Column(
      children: [
        const Icon(Icons.radio_button_checked, color: AppColors.primaryGreen, size: 22),
        Container(width: 2, height: 38, color: AppColors.primaryGreen.withOpacity(0.2)),
        const Icon(LucideIcons.mapPin, color: AppColors.error, size: 22),
      ],
    );
  }

  Widget _buildLocationInput(String label, TextEditingController controller, FocusNode focus) {
    return TextField(
      controller: controller,
      focusNode: focus,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: InputBorder.none,
        isDense: true,
        // The "Locate Me" icon logic
        suffixIcon: IconButton(
          icon: const Icon(LucideIcons.target, size: 18, color: AppColors.primaryBlue),
          onPressed: _getCurrentLocation,
        ),
      ),
    );
  }

  Widget _buildRow({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      leading: Icon(icon, color: AppColors.textSecondary, size: 24),
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  void _showSamsungTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Colors.white,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (dt) => setState(() => _selectedTime = TimeOfDay.fromDateTime(dt)),
        ),
      ),
    );
  }

  void _showSeatPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: 4, // Reasonable seats for a student carpool
          itemBuilder: (c, i) => ListTile(
            title: Text("${i + 1} Seat${i == 0 ? '' : 's'}", textAlign: TextAlign.center, 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () { setState(() => _selectedSeats = i + 1); Navigator.pop(ctx); },
          ),
        ),
      ),
    );
  }
}