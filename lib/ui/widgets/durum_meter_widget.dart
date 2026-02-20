
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';

import '../../core/services/bac_service.dart';

class DurumMeterWidget extends StatefulWidget {
  final BacResult bacResult;
  final bool isPremium;
  final int drinkCount;
  final bool isProfileComplete;
  final VoidCallback? onProfileTap;
  final VoidCallback? onTap;

  const DurumMeterWidget({
    super.key,
    required this.bacResult,
    this.isPremium = false,
    required this.drinkCount,
    this.isProfileComplete = true,
    this.onProfileTap,
    this.onTap,
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
    final bool isLocked = !widget.isProfileComplete;
    
    final double percentage = (bac / 1.5).clamp(0.0, 1.0);
    
    Color progressColor;
    switch (widget.bacResult.trend) {
      case BacTrend.rising:
        progressColor = const Color(0xFFEF4444); // Kırmızı — yükseliyor
        break;
      case BacTrend.falling:
        progressColor = const Color(0xFFF59E0B); // Sarı — düşüyor
        break;
      case BacTrend.stable:
        progressColor = AppColors.primary; // Turuncu (brand) — stabil
        break;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: AppDecorations.glassCardWidget(
        padding: const EdgeInsets.all(16),
        blurSigma: 12,
        color: AppColors.surface.withOpacity(0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — always visible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!isLocked) 
                      _buildTrendIndicator(widget.bacResult.trend, progressColor)
                    else 
                      Icon(Icons.speed_rounded, size: 14, color: Colors.white.withOpacity(0.4)),
                    
                    const SizedBox(width: 8),
                    Text(
                      'DURUM METRE',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: progressColor.withOpacity(0.9), // Trend rengi
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                if (!isLocked) _buildPremiumBadge(false),
              ],
            ),

            if (isLocked) ...[
              // Locked content
              const SizedBox(height: 14),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1), // Amber tint
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bilgiler Eksik',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Doğru tahmin yapabilmemiz için profil bilgilerinizi girmeniz gerek.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                      ),
                    ],
                  ),
                ),
              ),

            ] else ...[
              // Unlocked content
              const SizedBox(height: 16),
              _buildAnimatedGauge(percentage, progressColor),
              const SizedBox(height: 12),
              
              // Status & Range Row
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
                  _buildDurumRange(false, widget.bacResult, progressColor),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.05), height: 1),
              const SizedBox(height: 12),
              
              // Always show stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    label: 'AKTİF İÇKİ',
                    value: '${widget.drinkCount} ADET',
                    color: Colors.orangeAccent,
                  ),
                  if (widget.bacResult.trend == BacTrend.falling && widget.bacResult.recoveryPercentage > 0.01)
                     _buildStatItem(
                      label: 'TOPARLANMA',
                      value: '%${(widget.bacResult.recoveryPercentage * 100).toInt()}',
                      icon: Icons.refresh_rounded,
                      color: Colors.blueAccent,
                      isHighlight: true,
                    )
                  else
                     _buildStatItem(
                      label: 'GÜNLÜK ZİRVE',
                      value: widget.bacResult.dailyPeak != null 
                          ? '${widget.bacResult.dailyPeak!.max.toStringAsFixed(2)} ‰'
                          : '-.-- ‰',
                      icon: Icons.trending_up_rounded,
                      color: Colors.redAccent.withOpacity(0.7),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }




  Widget _buildStatItem({
    required String label,
    required String value,
    IconData? icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 4)],
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
    Color trendColor;
    switch (trend) {
      case BacTrend.rising:
        icon = Icons.trending_up_rounded;
        label = 'YÜKSELİYOR';
        trendColor = const Color(0xFFEF4444); // Kırmızı — artıyor
        break;
      case BacTrend.falling:
        icon = Icons.trending_down_rounded;
        label = 'DÜŞÜYOR';
        trendColor = const Color(0xFF10B981); // Yeşil — düşüyor
        break;
      case BacTrend.stable:
        icon = Icons.trending_flat_rounded;
        label = 'STABİL';
        trendColor = AppColors.primary; // Turuncu (brand) — stabil
        break;
    }

    return ScaleTransition(
      scale: trend == BacTrend.rising ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: trendColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: trendColor.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: trendColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 9,
                color: trendColor,
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


  

}
