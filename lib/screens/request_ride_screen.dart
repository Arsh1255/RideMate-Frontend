import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/colors.dart';
import 'finding_matches_screen.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({super.key});

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropFocus = FocusNode();
  bool _isPickupActive = true; 

  LatLng? _pickupCoords;
  LatLng? _destCoords;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedSeats = 1;
  String _selectedAccuracy = 'Moderate Match';
  bool _flexibleTime = false;
  String? _selectedMode = 'hasVehicle'; // Default to Ride together

  final List<String> _modes = ['publicTransportation', 'hasVehicle', 'stride'];
  final List<String> _accuracies = ['Exact Match', 'Moderate Match', 'Lenient Match'];

  // Suggestions Logic
  List<dynamic> _suggestions = [];
  bool _isSuggestionsLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  bool _isSearchingPickup = true;

  @override
  void initState() {
    super.initState();
    _pickupFocus.addListener(() { if (_pickupFocus.hasFocus) setState(() => _isPickupActive = true); });
    _dropFocus.addListener(() { if (_dropFocus.hasFocus) setState(() => _isPickupActive = false); });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _swapLocations() {
    FocusScope.of(context).unfocus();
    setState(() {
      final String temp = _pickupController.text;
      _pickupController.text = _dropController.text;
      _dropController.text = temp;
      
      final LatLng? tempCoords = _pickupCoords;
      _pickupCoords = _destCoords;
      _destCoords = tempCoords;
      _hasSearched = false;
    });
  }

  void _clearBoth() {
    setState(() {
      _pickupController.clear();
      _dropController.clear();
      _pickupCoords = null;
      _destCoords = null;
      _suggestions = [];
      _hasSearched = false;
    });
  }

  Future<void> _fetchSuggestions(String query, bool isPickup) async {
    if (query.length < 3) {
      setState(() { _suggestions = []; _hasSearched = false; });
      return;
    }
    setState(() { _isSuggestionsLoading = true; _hasSearched = true; });
    
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1&countrycodes=in';
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'com.ridemate.app'});
      if (response.statusCode == 200) {
        setState(() { _isSearchingPickup = isPickup; _suggestions = json.decode(response.body); });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isSuggestionsLoading = false);
    }
  }

  Future<void> _openMapPicker(bool isPickup) async {
    FocusScope.of(context).unfocus();
    setState(() => _hasSearched = false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerOverlay()),
    );

    if (result != null && result is MapResult) {
      setState(() {
        if (isPickup) {
          _pickupController.text = result.address;
          _pickupCoords = result.coords;
        } else {
          _dropController.text = result.address;
          _destCoords = result.coords;
        }
      });
    }
  }

  void _submit() {
    if (_pickupCoords == null || _destCoords == null) {
      _showErrorSnackBar("Please select valid locations using the map or suggestions.");
      return;
    }
    
    final distance = Geolocator.distanceBetween(
      _pickupCoords!.latitude, _pickupCoords!.longitude,
      _destCoords!.latitude, _destCoords!.longitude
    );
    
    if (distance < 100) {
      _showErrorSnackBar("Pickup and drop locations must be at least 100m apart.");
      return;
    }

    if (_selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      _showErrorSnackBar("Date cannot be in the past.");
      return;
    }

    if (_selectedMode == null) {
      _showErrorSnackBar("Please select a ride mode.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FindingMatchesScreen(
          searchParams: {
            'source': {'lat': _pickupCoords!.latitude, 'lng': _pickupCoords!.longitude},
            'destination': {'lat': _destCoords!.latitude, 'lng': _destCoords!.longitude},
            'date': _selectedDate.toIso8601String(),
            'time': _selectedTime.format(context),
            'flexibleTime': _flexibleTime,
            'seatsNeeded': _selectedSeats,
            'mode': _selectedMode,
            'matchAccuracy': _selectedAccuracy,
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatShortAddress(Map<String, dynamic> addressObj) {
    List<String> parts = [];
    if (addressObj.containsKey('road')) parts.add(addressObj['road']);
    if (addressObj.containsKey('suburb')) parts.add(addressObj['suburb']);
    if (addressObj.containsKey('city') || addressObj.containsKey('town')) parts.add(addressObj['city'] ?? addressObj['town']);
    return parts.isNotEmpty ? parts.join(', ') : "Selected Location";
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _hasSearched = false);
        },
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification) {
                  if (_hasSearched) {
                    setState(() => _hasSearched = false);
                  }
                }
                return false;
              },
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                          _buildLocationInput("Pickup location", _pickupController, _pickupFocus, true),
                                          const Divider(height: 32, color: AppColors.border),
                                          _buildLocationInput("Drop location", _dropController, _dropFocus, false),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 48), // Space for Swap Button
                                  ],
                                ),
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
                            subdued: _flexibleTime,
                          ),
                          _buildRow(
                            icon: LucideIcons.users,
                            label: "Seats Needed",
                            value: "$_selectedSeats Seat${_selectedSeats > 1 ? 's' : ''}",
                            onTap: _showSeatPicker,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // MATCH ACCURACY
                          const Text("Match Accuracy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          const Text("Controls how flexible RideMate is when matching nearby pickup and drop locations.", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            children: _accuracies.map((a) => _buildPillChip(a, _selectedAccuracy == a, () => setState(() => _selectedAccuracy = a))).toList(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // FLEXIBLE TIME
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Flexible Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                  Text("Ignore time matching on the same date", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              CupertinoSwitch(
                                value: _flexibleTime,
                                onChanged: (v) => setState(() => _flexibleTime = v),
                                activeColor: AppColors.primaryGreen,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // MODE SELECTOR
                          const Text("Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            children: _modes.map((m) => _buildPillChip(m, _selectedMode == m, () => setState(() => _selectedMode = m))).toList(),
                          ),
                          
                          const SizedBox(height: 120), // Space for bottom button
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
                        onPressed: _submit,
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
            ),
            if (_hasSearched) _buildSuggestionsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: _isSearchingPickup ? 120 : 180, left: 32, right: 32,
      child: Material(
        elevation: 8, borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: _isSuggestionsLoading 
            ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator()))
            : _suggestions.isEmpty 
              ? const Padding(padding: EdgeInsets.all(20), child: Text("No results found", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  shrinkWrap: true, itemCount: _suggestions.length,
                  itemBuilder: (c, i) {
                    final s = _suggestions[i];
                    final shortAddr = _formatShortAddress(s['address']);
                    return ListTile(
                      title: Text(s['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: Text(shortAddr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      onTap: () {
                        setState(() {
                          if (_isSearchingPickup) { 
                            _pickupController.text = s['display_name']; 
                            _pickupCoords = LatLng(double.parse(s['lat']), double.parse(s['lon'])); 
                          } else { 
                            _dropController.text = s['display_name']; 
                            _destCoords = LatLng(double.parse(s['lat']), double.parse(s['lon'])); 
                          }
                          _suggestions = []; 
                          _hasSearched = false; 
                          FocusScope.of(context).unfocus();
                        });
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRouteGraphic() {
    return Column(
      children: [
        const Icon(Icons.radio_button_checked, color: AppColors.primaryGreen, size: 22),
        Container(width: 2, height: 38, color: AppColors.primaryGreen.withOpacity(0.2)),
        const Icon(LucideIcons.mapPin, color: AppColors.error, size: 22),
      ],
    );
  }

  Widget _buildLocationInput(String label, TextEditingController controller, FocusNode focus, bool isPickup) {
    return TextField(
      controller: controller,
      focusNode: focus,
      onChanged: (v) { 
        setState(() {
          if (isPickup) _pickupCoords = null;
          else _destCoords = null;
        });
        if (_debounce?.isActive ?? false) _debounce!.cancel(); 
        _debounce = Timer(const Duration(milliseconds: 500), () => _fetchSuggestions(v, isPickup)); 
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: InputBorder.none,
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.map_outlined, size: 20, color: AppColors.primaryBlue),
          onPressed: () => _openMapPicker(isPickup),
        ),
      ),
    );
  }

  Widget _buildRow({required IconData icon, required String label, required String value, required VoidCallback onTap, bool subdued = false}) {
    return ListTile(
      onTap: subdued ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      leading: Icon(icon, color: subdued ? AppColors.textSecondary.withOpacity(0.5) : AppColors.textSecondary, size: 24),
      title: Text(label, style: TextStyle(color: subdued ? AppColors.textSecondary.withOpacity(0.5) : AppColors.textSecondary, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: subdued ? AppColors.primaryGreen.withOpacity(0.5) : AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
          Icon(Icons.chevron_right, color: subdued ? AppColors.textSecondary.withOpacity(0.5) : AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildPillChip(String l, bool s, VoidCallback t) {
    String displayLabel = l;
    if (l == 'publicTransportation') displayLabel = 'Public Transport';
    if (l == 'hasVehicle') displayLabel = 'Ride together';
    if (l == 'stride') displayLabel = 'Walk together';
    
    return GestureDetector(
      onTap: t,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: s ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: s ? AppColors.primaryGreen : AppColors.border),
        ),
        child: Text(displayLabel, style: TextStyle(color: s ? AppColors.primaryGreen : AppColors.textSecondary, fontWeight: s ? FontWeight.w600 : FontWeight.normal)),
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
          itemCount: 4,
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

// ================= MAP PICKER OVERLAY =================

class MapResult { final LatLng coords; final String address; MapResult(this.coords, this.address); }

class MapPickerOverlay extends StatefulWidget { const MapPickerOverlay({super.key}); @override State<MapPickerOverlay> createState() => _MapPickerOverlayState(); }

class _MapPickerOverlayState extends State<MapPickerOverlay> {
  LatLng _pickedLoc = const LatLng(20.5937, 78.9629); // India Center
  String _address = "Locating...";
  bool _isLoading = true;
  final MapController _mapController = MapController();

  @override
  void initState() { super.initState(); _initLoc(); }

  Future<void> _initLoc() async {
    if (await Permission.location.request().isGranted) {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _pickedLoc = LatLng(pos.latitude, pos.longitude);
        _mapController.move(_pickedLoc, 18.49);
      });
      _reverseGeocode();
    } else { setState(() { _address = "Permission Denied. Tap map to pick."; _isLoading = false; }); }
  }

  Future<void> _reverseGeocode() async {
    setState(() => _isLoading = true);
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${_pickedLoc.latitude}&lon=${_pickedLoc.longitude}&addressdetails=1';
    try {
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'com.ridemate.app'});
      if (res.statusCode == 200) {
        final d = json.decode(res.body);
        List<String> parts = [];
        if (d['address'].containsKey('road')) parts.add(d['address']['road']);
        if (d['address'].containsKey('suburb')) parts.add(d['address']['suburb']);
        if (d['address'].containsKey('city') || d['address'].containsKey('town')) parts.add(d['address']['city'] ?? d['address']['town']);
        setState(() => _address = parts.isNotEmpty ? parts.join(', ') : "Location Selected");
      }
    } catch (_) { setState(() => _address = "Location Selected"); } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _pickedLoc, initialZoom: 18.49, onTap: (_, l) { setState(() => _pickedLoc = l); _reverseGeocode(); }),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ridemate.app'),
            MarkerLayer(markers: [Marker(point: _pickedLoc, child: const Icon(Icons.location_on, color: AppColors.error, size: 40))]),
          ],
        ),
        Positioned(top: 50, left: 20, child: CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)))),
        Positioned(bottom: 30, left: 20, right: 20, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_address, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)), const SizedBox(height: 16), ElevatedButton(onPressed: _isLoading ? null : () => Navigator.pop(context, MapResult(_pickedLoc, _address)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 50)), child: _isLoading ? const CupertinoActivityIndicator() : const Text("Confirm Location", style: TextStyle(color: Colors.white)))]))),
      ]),
    );
  }
}
