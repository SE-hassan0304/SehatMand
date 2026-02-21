import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

// Mock hospital data for Karachi
const _mockHospitals = [
  {
    'name': 'Aga Khan University Hospital',
    'address': 'Stadium Road, Karachi',
    'distance': '1.2 km',
    'phone': '021-34930051',
    'specialties': ['Emergency', 'Cardiology', 'Oncology'],
    'rating': 4.8,
    'open': true,
  },
  {
    'name': 'Liaquat National Hospital',
    'address': 'Stadium Road, Karachi',
    'distance': '2.1 km',
    'phone': '021-34412000',
    'specialties': ['Emergency', 'Orthopedics', 'Neurology'],
    'rating': 4.5,
    'open': true,
  },
  {
    'name': 'South City Hospital',
    'address': 'DHA Phase II, Karachi',
    'distance': '3.4 km',
    'phone': '021-35393000',
    'specialties': ['Cardiology', 'Gynecology', 'Pediatrics'],
    'rating': 4.3,
    'open': true,
  },
  {
    'name': 'Indus Hospital',
    'address': 'Korangi, Karachi',
    'distance': '5.7 km',
    'phone': '021-35112709',
    'specialties': ['Emergency', 'General Surgery', 'Cancer Care'],
    'rating': 4.6,
    'open': false,
  },
];

class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  // ignore: unused_field
  bool _locationGranted = false;
  bool _isLoading = false;
  bool _showResults = false;

  Future<void> _findHospitals() async {
    setState(() => _isLoading = true);
    // TODO: Integrate with google_maps_flutter and geolocator
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _locationGranted = true;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HospitalHeader(),
        Expanded(
          child: _showResults
              ? _ResultsView()
              : _RequestLocationView(
                  isLoading: _isLoading,
                  onFindHospitals: _findHospitals,
                ),
        ),
      ],
    );
  }
}

class _HospitalHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.sidebarBorder),
        ),
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
            child: const Icon(
              Icons.local_hospital,
              color: AppColors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.hospitalTitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              Text(
                'Karachi, Pakistan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestLocationView extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onFindHospitals;

  const _RequestLocationView({
    required this.isLoading,
    required this.onFindHospitals,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 28),
            Text(
              AppStrings.hospitalTitle,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.charcoal,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 10),
            Text(
              'We\'ll locate the nearest hospitals in Karachi and show them on the map with directions.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.greyText,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 36),
            SizedBox(
              width: 260,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onFindHospitals,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.my_location, size: 20),
                label: Text(
                  isLoading ? 'Getting location...' : AppStrings.findHospitals,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            Text(
              '📍 Currently available for Karachi only',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.greyText,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map placeholder
        _MapPlaceholder(),

        // Hospital list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'Nearest Hospitals',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
              ),
              ..._mockHospitals.asMap().entries.map(
                    (e) => _HospitalCard(
                      hospital: e.value,
                      rank: e.key + 1,
                    )
                        .animate(delay: Duration(milliseconds: e.key * 100))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.05, end: 0, duration: 300.ms),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greyMid),
      ),
      child: Stack(
        children: [
          // Fake map background
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Map grid lines (visual representation)
          CustomPaint(
            painter: _MapGridPainter(),
            child: Container(),
          ),
          // Center overlay
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Google Maps Integration\n(Coming Soon)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.charcoal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          // Hospital pins
          ..._buildPins(),
        ],
      ),
    );
  }

  List<Widget> _buildPins() {
    const positions = [
      Offset(0.3, 0.4),
      Offset(0.55, 0.35),
      Offset(0.7, 0.6),
      Offset(0.25, 0.65),
    ];

    return positions.asMap().entries.map((e) {
      return Positioned(
        left: e.value.dx * 300,
        top: e.value.dy * 200,
        child: const Icon(
          Icons.location_on,
          color: AppColors.coral,
          size: 28,
        ),
      );
    }).toList();
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HospitalCard extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final int rank;

  const _HospitalCard({required this.hospital, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isOpen = hospital['open'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                color: rank == 1 ? AppColors.primary : AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: rank == 1 ? AppColors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hospital['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.coral.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? AppColors.success : AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.greyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hospital['address'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.greyText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        hospital['distance'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Specialties chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (hospital['specialties'] as List<String>)
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),

                  // Actions
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.phone_outlined,
                        label: hospital['phone'] as String,
                        onTap: () {
                          // TODO: launch phone call
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.directions_outlined,
                        label: 'Directions',
                        onTap: () {
                          // TODO: launch maps
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
    );
  }
}

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
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
