import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/colors.dart'; //
import '../models/post_ride_model.dart'; //
import '../service/auth_service.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers & FocusNodes to prevent keyboard issues
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _pickupFocus = FocusNode();
  final FocusNode _dropoffFocus = FocusNode();

  // State
  LatLng? _sourceCoords;
  LatLng? _destCoords;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  int _selectedSeats = 1;
  String? _selectedMode;
  String? _selectedVehicle;
  bool _isSuggestionsLoading = false;
  bool _hasSearched = false;
  bool _showMapHint = false;
  bool _isLoading = false;

  // Search Logic
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  bool _isSearchingPickup = true;

  final Map<String, String> _modeMap = {
    'Ride Together': 'hasVehicle',
    'Public Transport': 'publicTransportation',
    'Walk Together': 'stride',
  };

  final Map<String, String> _vehicleMap = {
    'Car': 'car',
    'Bike': 'bike',
    'Metro': 'metro',
    'BMTC Bus': 'bmtcBus',
  };

  @override
  void initState() {
    super.initState();
    // Hint logic: Appears after 800ms, stays for 7 seconds for better visibility
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showMapHint = true);
    });
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) setState(() => _showMapHint = false);
    });
  }

  // ================= 1. HELPERS & LOGIC =================

  String _formatShortAddress(Map<String, dynamic> addressObj) {
    List<String> parts = [];
    if (addressObj.containsKey('road')) parts.add(addressObj['road']);
    if (addressObj.containsKey('suburb')) parts.add(addressObj['suburb']);
    if (addressObj.containsKey('city') || addressObj.containsKey('town')) {
      parts.add(addressObj['city'] ?? addressObj['town']);
    }
    return parts.isEmpty ? "Unknown Location" : parts.join(', ');
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      _nameController.clear(); _pickupController.clear(); _dropoffController.clear();
      _notesController.clear(); _priceController.clear();
      _sourceCoords = null; _destCoords = null; _selectedMode = null;
      _selectedVehicle = null; _suggestions = []; _hasSearched = false;
    });
  }

  void _swapLocations() {
    FocusScope.of(context).unfocus();
    setState(() {
      final tText = _pickupController.text; _pickupController.text = _dropoffController.text; _dropoffController.text = tText;
      final tCoords = _sourceCoords; _sourceCoords = _destCoords; _destCoords = tCoords;
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
        if (isPickup) { _pickupController.text = result.address; _sourceCoords = result.coords; }
        else { _dropoffController.text = result.address; _destCoords = result.coords; }
      });
    }
  }

  // ================= 2. UI BUILDERS =================

  @override
  Widget build(BuildContext context) {
    bool isWalk = _selectedMode == 'Walk Together';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background, //
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text("Post a ride", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [TextButton(onPressed: _clearAll, child: const Text("Clear", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)))],
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
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 120),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildRideNameInput(),
                const SizedBox(height: 16),
                _buildLocationCard(), // Matches visual from image_856bb3.png
                const SizedBox(height: 24),
                _buildSelectionList(),
                const SizedBox(height: 32),
                _buildSectionHeader("Ride Mode"), _buildModeSelector(),
                const SizedBox(height: 24),
                if (!isWalk) ...[_buildSectionHeader("Vehicle Type"), _buildVehicleSelector(), const SizedBox(height: 24)],
                _buildSectionHeader("Optional Details"),
                const SizedBox(height: 12),
                _buildTextInput(_notesController, null, "Notes (Optional)", Icons.notes),
                const SizedBox(height: 16),
                _buildTextInput(_priceController, null, isWalk ? "N/A for walking" : "Price per person", Icons.payments_outlined, isEnabled: !isWalk, isNumeric: true),
                const SizedBox(height: 120),
              ]),
            ),
              ),
            ),
            if (_hasSearched) _buildSuggestionsOverlay(),
            _buildBottomSubmitButton(),
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
                    // SWAPPED: display_name is now Title (greater size), shortAddr is Subtitle (less text size)
                    return ListTile(
                      title: Text(s['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: Text(shortAddr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      onTap: () {
                        setState(() {
                          if (_isSearchingPickup) { _pickupController.text = s['display_name']; _sourceCoords = LatLng(double.parse(s['lat']), double.parse(s['lon'])); }
                          else { _dropoffController.text = s['display_name']; _destCoords = LatLng(double.parse(s['lat']), double.parse(s['lon'])); }
                          _suggestions = []; _hasSearched = false; FocusScope.of(context).unfocus();
                        });
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRideNameInput() => Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: TextFormField(controller: _nameController, focusNode: _nameFocus, style: const TextStyle(fontSize: 15), decoration: const InputDecoration(hintText: "Ride Name (e.g. Office Run)", border: InputBorder.none, hintStyle: TextStyle(color: AppColors.textSecondary))));

  Widget _buildLocationCard() => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Row(children: [const SizedBox(width: 16), _buildRouteGraphic(), Expanded(child: Column(children: [_buildLocField(_pickupController, _pickupFocus, "Pickup location", true), const Divider(height: 1, color: AppColors.border), _buildLocField(_dropoffController, _dropoffFocus, "Drop location", false)])), IconButton(onPressed: _swapLocations, icon: const Icon(Icons.swap_vert, color: AppColors.primaryBlue)), const SizedBox(width: 8)]));

  Widget _buildLocField(TextEditingController ctrl, FocusNode node, String hint, bool isPickup) {
    return TextFormField(
      controller: ctrl, focusNode: node,
      onChanged: (v) { 
        if (_debounce?.isActive ?? false) _debounce!.cancel(); 
        _debounce = Timer(const Duration(milliseconds: 500), () => _fetchSuggestions(v, isPickup)); 
        setState(() {
          if (isPickup) { _sourceCoords = null; }
          else { _destCoords = null; }
        });
      },
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        suffixIcon: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(icon: const Icon(Icons.map_outlined, size: 20, color: AppColors.primaryBlue), onPressed: () => _openMapPicker(isPickup)),
            if (isPickup && _showMapHint)
              Positioned(
                top: -38, right: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.9), // Muted but highly visible
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Text("Click to find location", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteGraphic() => Column(children: [const Icon(Icons.radio_button_checked, color: AppColors.primaryGreen, size: 18), Container(width: 1, height: 35, color: AppColors.border), const Icon(Icons.location_on, color: AppColors.error, size: 18)]);

  Widget _buildSectionHeader(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary));

  Widget _buildSelectionList() => Column(children: [_selectionRow(Icons.calendar_today_outlined, "Date", DateFormat('EEEE, d MMMM').format(_selectedDateTime), _showDate), const Divider(height: 1, color: AppColors.border), _selectionRow(Icons.access_time, "Time", DateFormat('h:mm a').format(_selectedDateTime), _showTime), const Divider(height: 1, color: AppColors.border), _selectionRow(Icons.people_outline, "Seats Needed", "$_selectedSeats Seats", _showSeats)]);

  Widget _selectionRow(IconData icon, String label, String val, VoidCallback tap) => ListTile(onTap: tap, contentPadding: EdgeInsets.zero, leading: Icon(icon, color: AppColors.textSecondary, size: 22), title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(val, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 15)), const Icon(Icons.chevron_right, color: AppColors.textSecondary)]));

  Widget _buildModeSelector() => Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 10, children: _modeMap.keys.map((l) => _buildPillChip(l, _selectedMode == l, () { FocusScope.of(context).unfocus(); setState(() { _selectedMode = l; _selectedVehicle = null; if (l == 'Walk Together') { _priceController.clear(); if (_selectedSeats > 2) _selectedSeats = 2; } }); })).toList()));

  Widget _buildVehicleSelector() {
    List<String> opts = _selectedMode == 'Ride Together' ? ['Car', 'Bike'] : (_selectedMode == 'Public Transport' ? ['Metro', 'BMTC Bus'] : []);
    return Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 10, children: opts.map((l) => _buildPillChip(l, _selectedVehicle == l, () { FocusScope.of(context).unfocus(); setState(() => _selectedVehicle = l); })).toList()));
  }

  Widget _buildPillChip(String l, bool s, VoidCallback t) => GestureDetector(onTap: t, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: s ? AppColors.primaryGreen.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: s ? AppColors.primaryGreen : AppColors.border)), child: Text(l, style: TextStyle(color: s ? AppColors.primaryGreen : AppColors.textSecondary, fontWeight: s ? FontWeight.w600 : FontWeight.normal))));

  Widget _buildTextInput(TextEditingController ctrl, FocusNode? node, String hint, IconData icon, {bool isNumeric = false, bool isEnabled = true}) => Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: isEnabled ? Colors.white : Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: TextField(controller: ctrl, focusNode: node, enabled: isEnabled, keyboardType: isNumeric ? TextInputType.number : TextInputType.text, style: TextStyle(color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary), decoration: InputDecoration(icon: Icon(icon, color: AppColors.textSecondary, size: 20), hintText: hint, border: InputBorder.none)));

  Widget _buildBottomSubmitButton() => Align(alignment: Alignment.bottomCenter, child: Container(padding: const EdgeInsets.all(20), color: Colors.white, child: InkWell(onTap: _isLoading ? null : _submit, child: Container(height: 56, width: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: _isLoading ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!]) : const LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryGreen])), alignment: Alignment.center, child: _isLoading ? const CupertinoActivityIndicator(color: Colors.white) : const Text("Post Ride", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))))));

  void _showSeats() { FocusScope.of(context).unfocus(); setState(() => _hasSearched = false); bool isWalk = _selectedMode == 'Walk Together'; int maxSeats = isWalk ? 2 : 6; showCupertinoModalPopup(context: context, builder: (c) => Container(height: 250, color: Colors.white, child: CupertinoPicker(itemExtent: 40, onSelectedItemChanged: (v) => setState(() => _selectedSeats = v + 1), children: List.generate(maxSeats, (i) => Center(child: Text("${i + 1} Seats")))))); }
  void _showDate() { FocusScope.of(context).unfocus(); setState(() => _hasSearched = false); showCupertinoModalPopup(context: context, builder: (c) => Container(height: 250, color: Colors.white, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.date, initialDateTime: _selectedDateTime, onDateTimeChanged: (d) => setState(() => _selectedDateTime = DateTime(d.year, d.month, d.day, _selectedDateTime.hour, _selectedDateTime.minute))))); }
  void _showTime() { FocusScope.of(context).unfocus(); setState(() => _hasSearched = false); showCupertinoModalPopup(context: context, builder: (c) => Container(height: 250, color: Colors.white, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, initialDateTime: _selectedDateTime, onDateTimeChanged: (t) => setState(() => _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, t.hour, t.minute))))); }

  void _submit() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    void showValidationSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }

    final rideName = _nameController.text.trim();
    if (rideName.length < 3) {
      showValidationSnackBar("Ride name must be at least 3 characters long.");
      return;
    }

    if (_sourceCoords == null || _destCoords == null) {
      showValidationSnackBar("Please select valid pickup and drop locations.");
      return;
    }

    final distance = Geolocator.distanceBetween(
      _sourceCoords!.latitude, _sourceCoords!.longitude,
      _destCoords!.latitude, _destCoords!.longitude,
    );
    if (distance < 100) {
      showValidationSnackBar("Pickup and drop locations must be at least 100 meters apart.");
      return;
    }

    if (_selectedDateTime.isBefore(DateTime.now())) {
      showValidationSnackBar("Departure time cannot be in the past.");
      return;
    }

    if (_selectedMode == null) {
      showValidationSnackBar("Please select a ride mode.");
      return;
    }

    bool isWalk = _selectedMode == 'Walk Together';
    String vehicleType = "none";
    int price = 0;

    if (!isWalk) {
      if (_selectedVehicle == null) {
        showValidationSnackBar("Please select a vehicle type.");
        return;
      }
      vehicleType = _vehicleMap[_selectedVehicle] ?? 'none';
      price = int.tryParse(_priceController.text) ?? 0;
    }

    if (_formKey.currentState!.validate()) {
      final ride = PostRideModel(
        rideName: rideName,
        totalSeats: _selectedSeats,
        sourceName: _pickupController.text,
        sourceLat: _sourceCoords!.latitude,
        sourceLng: _sourceCoords!.longitude,
        destinationName: _dropoffController.text,
        destinationLat: _destCoords!.latitude,
        destinationLng: _destCoords!.longitude,
        departureTime: _selectedDateTime,
        mode: _modeMap[_selectedMode]!,
        vehicleType: vehicleType,
        notes: _notesController.text,
        pricePerPerson: price,
      );
      
      AuthService().createRide(ride.toJson()).then((response) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.white,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Stack(
                  children: [
                    CustomPaint(
                      painter: EcoBackgroundPainter(),
                      child: Container(),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryGreen]),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Ride Created",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Your ride is now visible to others",
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context); // Pop dialog
          Navigator.pop(context); // Pop screen
        });
      }).catchError((error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.white.withOpacity(0.9),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                        child: const Icon(Icons.close, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 24),
                      const Text("Failed to Create Ride", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text("Go Back", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
}

class EcoBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 80, paint);

    final leafPaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(50, 0, 50, 50);
    path.quadraticBezierTo(0, 50, 0, 0);

    canvas.save();
    canvas.translate(size.width * 0.3, size.height * 0.4);
    canvas.rotate(0.5);
    canvas.drawPath(path, leafPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.7, size.height * 0.3);
    canvas.rotate(-0.3);
    canvas.drawPath(path, leafPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= 3. MAP PICKER (ZOOM 18.49) =================

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
        _mapController.move(_pickedLoc, 18.49); // LOCKED ZOOM LEVEL 18.49
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
        setState(() => _address = parts.join(', '));
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