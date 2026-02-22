// lib/features/hospital/screens/hospital_screen.dart
//
// Uses FREE OpenStreetMap data via Flask backend.
// No Google billing. No API key needed.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

// Backend base URL — same as api_service.dart
const String _backendBase = 'http://localhost:5000';
const int _searchRadiusMetres = 10000; // 10 km for better coverage in Pakistan

// ── Data model ────────────────────────────────────────────────────────────────
class _Hospital {
  final String placeId;
  final String name;
  final String address;
  final String phone;
  final LatLng position;
  final double distanceKm;

  const _Hospital({
    required this.placeId,
    required this.name,
    required this.address,
    required this.phone,
    required this.position,
    required this.distanceKm,
  });

  factory _Hospital.fromJson(Map<String, dynamic> json) {
    final geo = json['geometry']['location'];
    return _Hospital(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Hospital',
      address: json['vicinity'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      position: LatLng(
        (geo['lat'] as num).toDouble(),
        (geo['lng'] as num).toDouble(),
      ),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────
class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  bool _isLoading = false;
  bool _showResults = false;
  String? _errorMessage;

  LatLng? _userLocation;
  List<_Hospital> _hospitals = [];

  // FIX: Use a direct controller reference instead of a Completer.
  // The Completer pattern causes a race condition — it's awaited before
  // the GoogleMap widget has rendered, so onMapCreated never fires in time.
  GoogleMapController? _mapController;

  // FIX: A unique key forces GoogleMap to fully rebuild (and re-fire
  // onMapCreated) each time the user triggers a new search.
  Key _mapKey = UniqueKey();

  final Set<Marker> _markers = {};
  int? _selectedIndex;

  Future<void> _findHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pos = await _getLocation();
      _userLocation = LatLng(pos.latitude, pos.longitude);

      final hospitals = await _fetchHospitals(_userLocation!);
      _hospitals = hospitals; // already sorted by backend
      _buildMarkers();

      // FIX: Reset the map key so GoogleMap rebuilds and fires onMapCreated
      // with a fresh controller pointing at the real GPS position.
      setState(() {
        _isLoading = false;
        _showResults = true;
        _mapKey = UniqueKey(); // forces map widget rebuild
        _mapController = null; // clear stale controller
      });

      // The map will call _onMapCreated after the next frame.
      // Camera animation happens inside _onMapCreated once controller is ready.
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Called by GoogleMap's onMapCreated — controller is guaranteed ready here.
  void _onMapCreated(GoogleMapController ctrl) {
    _mapController = ctrl;
    // Fly to user's REAL GPS location now that the controller exists.
    if (_userLocation != null) {
      ctrl.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation!, zoom: 13),
      ));
    }
  }

  Future<Position> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services disabled. Enable them in your browser settings.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception(
            'Location permission denied. Please allow it and try again.');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(
          'Location permanently denied. Enable it in browser settings.');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<_Hospital>> _fetchHospitals(LatLng origin) async {
    final uri = Uri.parse('$_backendBase/api/places/nearby').replace(
      queryParameters: {
        'lat': '${origin.latitude}',
        'lng': '${origin.longitude}',
        'radius': '$_searchRadiusMetres',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN';

    if (status == 'ZERO_RESULTS') return [];
    if (status != 'OK') throw Exception('Search error: $status');

    return (data['results'] as List)
        .map((r) => _Hospital.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  void _buildMarkers() {
    _markers.clear();

    // Blue = user
    if (_userLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('user'),
        position: _userLocation!,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Red = hospitals
    for (int i = 0; i < _hospitals.length; i++) {
      final h = _hospitals[i];
      _markers.add(Marker(
        markerId: MarkerId('h_$i'),
        position: h.position,
        infoWindow: InfoWindow(
          title: h.name,
          snippet: '${h.distanceKm.toStringAsFixed(1)} km away',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () => _onMarkerTap(i),
      ));
    }
  }

  Future<void> _onMarkerTap(int index) async {
    setState(() => _selectedIndex = index);
    await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _hospitals[index].position, zoom: 15.5),
    ));
  }

  Future<void> _flyToHospital(int index) async {
    setState(() => _selectedIndex = index);
    await _mapController?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _hospitals[index].position, zoom: 15.5),
    ));
    await _mapController?.showMarkerInfoWindow(MarkerId('h_$index'));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HospitalHeader(),
        Expanded(
          child: _showResults
              ? _ResultsView(
                  mapKey: _mapKey,
                  markers: _markers,
                  onMapCreated: _onMapCreated,
                  hospitals: _hospitals,
                  // FIX: Pass real GPS position as initial target.
                  // Previously the widget used a hardcoded Karachi fallback
                  // when the map first rendered because the Completer hadn't
                  // resolved yet. Now we pass _userLocation directly.
                  userLocation: _userLocation,
                  selectedIndex: _selectedIndex,
                  onCardTap: _flyToHospital,
                )
              : _RequestLocationView(
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  onFindHospitals: _findHospitals,
                ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HospitalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.local_hospital,
                color: AppColors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.hospitalTitle,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.charcoal)),
              Text('Live • Free via OpenStreetMap',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.greyText)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Request location ──────────────────────────────────────────────────────────
class _RequestLocationView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onFindHospitals;

  const _RequestLocationView({
    required this.isLoading,
    required this.errorMessage,
    required this.onFindHospitals,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined,
                    size: 52, color: AppColors.primary),
              ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              const SizedBox(height: 24),
              Text(AppStrings.hospitalTitle,
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal),
                      textAlign: TextAlign.center)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Find real hospitals near you — completely free using OpenStreetMap.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.greyText, height: 1.6),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              // Free badge
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 15),
                    const SizedBox(width: 6),
                    Text('100% Free • No billing required',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

              // Error
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(errorMessage!,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onFindHospitals,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.white))
                      : const Icon(Icons.my_location, size: 20),
                  label: Text(
                    isLoading ? 'Searching...' : AppStrings.findHospitals,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              Text('📡 Searches within 10 km of your location',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.greyText))
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────
class _ResultsView extends StatelessWidget {
  final Key mapKey;
  final Set<Marker> markers;
  // FIX: Accept onMapCreated callback instead of a Completer.
  final void Function(GoogleMapController) onMapCreated;
  final List<_Hospital> hospitals;
  final LatLng? userLocation;
  final int? selectedIndex;
  final void Function(int) onCardTap;

  const _ResultsView({
    required this.mapKey,
    required this.markers,
    required this.onMapCreated,
    required this.hospitals,
    required this.userLocation,
    required this.selectedIndex,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map
        SizedBox(
          height: 260,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                // FIX: Unique key ensures the widget fully rebuilds each search,
                // so onMapCreated is always called with a fresh controller.
                key: mapKey,
                initialCameraPosition: CameraPosition(
                  // FIX: Use real GPS position as initial target.
                  // onMapCreated will immediately animate to the same point,
                  // so even the brief initial render shows the correct area.
                  target: userLocation ?? const LatLng(24.8607, 67.0104),
                  zoom: 13,
                ),
                onMapCreated: onMapCreated,
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),
            ),
          ),
        ),

        // Count bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                '${hospitals.length} hospitals found near you',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.charcoal),
              ),
              const Spacer(),
              // OSM credit
              Text('© OpenStreetMap',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: AppColors.greyText)),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: hospitals.length,
            itemBuilder: (context, i) => _HospitalCard(
              hospital: hospitals[i],
              rank: i + 1,
              isSelected: selectedIndex == i,
              onTap: () => onCardTap(i),
            )
                .animate(delay: Duration(milliseconds: i * 60))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.04, end: 0, duration: 300.ms),
          ),
        ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────
class _HospitalCard extends StatelessWidget {
  final _Hospital hospital;
  final int rank;
  final bool isSelected;
  final VoidCallback onTap;

  const _HospitalCard({
    required this.hospital,
    required this.rank,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      rank == 1 ? AppColors.primary : AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$rank',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              rank == 1 ? AppColors.white : AppColors.primary)),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + distance
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(hospital.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.charcoal)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${hospital.distanceKm.toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Address
                    if (hospital.address.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.greyText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(hospital.address,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.greyText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),

                    // Phone
                    if (hospital.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: AppColors.greyText),
                          const SizedBox(width: 4),
                          Text(hospital.phone,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.greyText)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Buttons
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.map_outlined,
                          label: 'View on Map',
                          onTap: onTap,
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.directions_outlined,
                          label: 'Directions',
                          onTap: () {
                            final url = 'https://www.google.com/maps/dir/?api=1'
                                '&destination=${hospital.position.latitude}'
                                ',${hospital.position.longitude}';
                            debugPrint('Directions: $url');
                            // add url_launcher to open in browser
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
