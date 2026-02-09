import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  String? _selectedVenueName;
  bool _isLoading = true;
  final List<Marker> _markers = [];
  final List<Map<String, dynamic>> _nearbyVenues = [];

  // Default position: Istanbul
  static const CameraPosition _kDefaultPosition = CameraPosition(
    target: LatLng(41.0082, 28.9784),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Konum servisleri kapalı.');
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Konum izni reddedildi.');
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Konum izni kalıcı olarak reddedildi.');
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentPosition = latLng;
          _selectedPosition = latLng;
          _isLoading = false;
        });
        _moveToPosition(latLng);
        _searchNearby(latLng);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Konum alınamadı: $e');
      }
    }
  }

  Future<void> _moveToPosition(LatLng position) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
    _updateMarker(position);
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    });
  }

  // Simplified nearby search (In a real app, use Google Places API)
  Future<void> _searchNearby(LatLng position) async {
    setState(() => _nearbyVenues.clear());
    
    // Mocking nearby bars for demonstration
    // In production, you would fetch these from an API
    final List<String> barNames = [
      'The Old Pub',
      'Irish Corner',
      'Cheers Bar',
      'Sunset Lounge',
      'Central Grill & Bar',
      'Blue Note Jazz Club'
    ];

    for (int i = 0; i < barNames.length; i++) {
        _nearbyVenues.add({
          'name': barNames[i],
          'address': 'Yakınlarda, 12$i. Sokak',
          'lat': position.latitude + (i * 0.001) - 0.003,
          'lng': position.longitude + (i * 0.0015) - 0.003,
        });
    }
    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: Stack(
        children: [
          // Map Background
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8902)))
            : GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _currentPosition != null 
                    ? CameraPosition(target: _currentPosition!, zoom: 16)
                    : _kDefaultPosition,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  // Apply dark mode if possible (needs a JSON style)
                },
                markers: Set<Marker>.of(_markers),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (latLng) {
                  _selectedPosition = latLng;
                  _updateMarker(latLng);
                  _searchNearby(latLng);
                },
              ),

          // Custom Header
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Mekan ara...',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet with Nearby Venues
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                color: Color(0xFF0A0E14),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yakındaki Mekanlar',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _determinePosition,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8902).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.my_location, color: Color(0xFFFF8902), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _nearbyVenues.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildVenueItem(
                            name: 'Şu anki konumum',
                            address: 'Bulunduğunuz tam nokta',
                            icon: Icons.person_pin_circle,
                            color: const Color(0xFF4ECDC4),
                            onTap: () {
                              context.pop('Şu anki konumum');
                            },
                          );
                        }
                        final venue = _nearbyVenues[index - 1];
                        return _buildVenueItem(
                          name: venue['name'],
                          address: venue['address'],
                          icon: Icons.local_bar,
                          color: const Color(0xFFFF8902),
                          onTap: () {
                            context.pop(venue['name']);
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 24, 
                      right: 24, 
                      bottom: MediaQuery.of(context).padding.bottom + 10,
                      top: 10
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop('Haritadan seçilen konum');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8902),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Bu Konumu Onayla',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueItem({
    required String name,
    required String address,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
