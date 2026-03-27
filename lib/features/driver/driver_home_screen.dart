import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';


class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isTripStarted = false;
  int _currentStopIndex = 0;
  
  final List<String> _stops = [
    'KIIT University',
    'Patia Square',
    'Infocity',
    'Jayadev Vihar',
    'Master Canteen'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDarkTitle,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 24),
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildNextStopGuidance(),
            const Spacer(),
            if (_isTripStarted) _buildQuickActionTray(),
            const SizedBox(height: 24),
            _buildMainControl(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROUTE 1 • EXPRESS',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bus #402',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                Text(
                  'SYNCED',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('ETA NEXT', '4 min', AppColors.primary),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildStat('NETWORK SCHED', 'ON TIME', AppColors.accent),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildStat('PAX LOAD', 'Med', AppColors.textPrimary),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStopGuidance() {
    if (!_isTripStarted) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.departure_board, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Awaiting Dispatch',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'System AI suggests waiting 2 minutes to balance line load.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT STOP',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stops[_currentStopIndex],
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1.2 km away • Turn right ahead',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTray() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionBtn(Icons.record_voice_over, 'Announce'),
          const SizedBox(width: 16),
          _buildActionBtn(Icons.report_problem, 'Delay'),
          const SizedBox(width: 16),
          _buildActionBtn(Icons.groups, 'Load Full'),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () {
          if (!_isTripStarted) {
            setState(() => _isTripStarted = true);
          } else {
            if (_currentStopIndex < _stops.length - 1) {
              setState(() => _currentStopIndex++);
            } else {
              setState(() {
                _isTripStarted = false;
                _currentStopIndex = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip Completed successfully')),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: _isTripStarted ? AppColors.accent : AppColors.primary,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: (_isTripStarted ? AppColors.accent : AppColors.primary).withValues(alpha: 0.3),
                blurRadius: 32,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Center(
            child: Text(
              _isTripStarted 
                  ? (_currentStopIndex == _stops.length - 1 ? 'COMPLETE TRIP' : 'ARRIVED AT STOP')
                  : 'START TRIP',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
