import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerTest extends StatefulWidget {
  const MapPickerTest({super.key});
  @override
  State<MapPickerTest> createState() => _MapPickerTestState();
}

class _MapPickerTestState extends State<MapPickerTest> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = LatLng(12.9416, 77.5651); // Default: BMSCE
  String _address = "Select a location";
  List<dynamic> _suggestions = [];

  // 1. Live Search Suggestions Logic
  Future<void> _getSuggestions(String query) async {
    if (query.length < 3) return; // Only search after 3 characters
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() => _suggestions = json.decode(response.body));
      }
    } catch (e) {
      print("Search Error: $e");
    }
  }

  // 2. Reverse Geocoding (Coordinates -> Name)
  Future<void> _getAddressFromLatLng(LatLng point) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() => _address = data['display_name'] ?? "Unknown Location");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RideMate Map Test")),
      body: Stack(
        children: [
          // THE MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() => _selectedLocation = point);
                _getAddressFromLatLng(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ridemate.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // SEARCH OVERLAY (The "As you type" UI)
          Positioned(
            top: 20, left: 15, right: 15,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Where do you wanna go?",
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: _getSuggestions,
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final place = _suggestions[index];
                        return ListTile(
                          title: Text(place['display_name']),
                          onTap: () {
                            final lat = double.parse(place['lat']);
                            final lon = double.parse(place['lon']);
                            final newPoint = LatLng(lat, lon);
                            setState(() {
                              _selectedLocation = newPoint;
                              _address = place['display_name'];
                              _suggestions = []; // Clear suggestions
                            });
                            _mapController.move(newPoint, 15);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // BOTTOM ADDRESS BOX
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Text("Selected: $_address", style: const TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }
}