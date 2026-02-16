import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';
import '../../core/services/bac_service.dart';

class DurumMeterWidget extends StatefulWidget {
  final BacResult bacResult;
  final bool isPremium;
  final int drinkCount;

  const DurumMeterWidget({
    super.key,
    required this.bacResult,
    this.isPremium = false,
    required this.drinkCount,
  });

  @override
  State<DurumMeterWidget> createState() => _DurumMeterWidgetState();
}

class _DurumMeterWidgetState extends State<DurumMeterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bac = widget.bacResult.average;
    // Temporary Unlock: User requested to see detailed analysis
    final bool isLocked = false; // !widget.isPremium && widget.drinkCount >= 2; 
    
    final double percentage = (bac / 1.5).clamp(0.0, 1.0);
    
    Color progressColor;
    if (bac < 0.2) {
      progressColor = const Color(0xFF10B981); // Emerald
    } else if (bac < 0.5) {
      progressColor = const Color(0xFFF59E0B); // Amber
    } else if (bac < 0.8) {
      progressColor = const Color(0xFFF97316); // Orange
    } else {
      progressColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AppDecorations.glassCardWidget(
        padding: const EdgeInsets.all(16),
        blurSigma: 12,
        color: AppColors.surface.withOpacity(0.8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildTrendIndicator(widget.bacResult.trend, progressColor),
                        const SizedBox(width: 10),
                        Text(
                          'DURUM METRE',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    _buildPremiumBadge(isLocked),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Animated Gauge
                _buildAnimatedGauge(percentage, progressColor),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tahmini Aralık',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.bacResult.statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: progressColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.bacResult.statusDescription,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDurumRange(isLocked, widget.bacResult, progressColor),
                  ],
                ),
                
                if (!isLocked && widget.bacResult.dailyPeak != null && widget.bacResult.recoveryPercentage > 0.01) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  const SizedBox(height: 12),
                  _buildRecoveryStats(widget.bacResult, progressColor),
                ],
              ],
            ),
            
            if (isLocked) _buildLockOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryStats(BacResult res, Color color) {
    final recovery = (res.recoveryPercentage * 100).toInt();
    final peakText = '${res.dailyPeak!.min.toStringAsFixed(2)}-${res.dailyPeak!.max.toStringAsFixed(2)} ‰';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          label: 'GÜNLÜK ZİRVE',
          value: peakText,
          icon: Icons.high_quality_rounded, // or Icons.vertical_align_top
          color: color.withOpacity(0.6),
        ),
        _buildStatItem(
          label: 'TOPARLANMA',
          value: '%$recovery',
          icon: Icons.refresh_rounded, // Changed icon to better represent recovery
          color: Colors.blueAccent,
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceMono(
            fontSize: isHighlight ? 14 : 12,
            fontWeight: FontWeight.w700,
            color: isHighlight ? color : Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(BacTrend trend, Color color) {
    IconData icon;
    String label;
    switch (trend) {
      case BacTrend.rising:
        icon = Icons.trending_up_rounded;
        label = 'YÜKSELİYOR';
        break;
      case BacTrend.falling:
        icon = Icons.trending_down_rounded;
        label = 'DÜŞÜYOR';
        break;
      case BacTrend.stable:
        icon = Icons.trending_flat_rounded;
        label = 'STABİL';
        break;
    }

    return ScaleTransition(
      scale: trend == BacTrend.rising ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 9,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedGauge(double percentage, Color color) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              height: 10,
              width: constraints.maxWidth * percentage,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.4), color],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: -1,
                  ),
                ],
              ),
            );
          }
        ),
      ],
    );
  }

  Widget _buildDurumRange(bool isLocked, BacResult res, Color color) {
    if (isLocked) {
      return Text(
        '?.?? - ?.?? ‰',
        style: GoogleFonts.spaceMono(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.white.withOpacity(0.15),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${res.min.toStringAsFixed(2)} - ${res.max.toStringAsFixed(2)}',
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '‰',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          'GÜVEN ARALIĞI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: color.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBadge(bool isLocked) {
    if (!isLocked) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, size: 12, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            'PREMIUM',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 9,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    'Detaylı Analiz',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _getWarningText(double bac) {
    if (bac < 0.20) return 'Keyifler yerinde! 😌';
    if (bac < 0.50) return 'Çakırkeyif mod açıldı. 😉';
    if (bac < 1.00) return 'Dikkatli ol, denge şaşabilir. 🥴';
    return 'Eve taksiyle dönme vakti! 🚖';
  }
}
