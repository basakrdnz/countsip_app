import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_icons.dart';

class PromilMeterWidget extends StatelessWidget {
  final double bac;
  final bool isPremium;
  final int drinkCount;

  const PromilMeterWidget({
    super.key,
    required this.bac,
    this.isPremium = false,
    required this.drinkCount,
  });

  @override
  Widget build(BuildContext context) {
    // Paywall trigger: TEMPORARILY DISABLED
    // Final logic was: final bool isLocked = !isPremium && drinkCount >= 2;
    final bool isLocked = false; 
    
    // Normalization for gauge: 0.0 to 1.5 (lethal-ish limit usually higher but 1.5 is very drunk for UI scaling)
    final double percentage = (bac / 1.5).clamp(0.0, 1.0);
    
    // Color gradient based on intensity
    Color progressColor;
    if (bac < 0.20) {
      progressColor = Colors.greenAccent;
    } else if (bac < 0.50) {
      progressColor = Colors.orangeAccent;
    } else {
      progressColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.glassCard(borderRadius: 24, borderWidth: 1.5).copyWith(
        border: Border.all(color: progressColor.withOpacity(0.3), width: 1.5),
      ),
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: progressColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(AppIcons.tachometerFast, color: progressColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Promil Metre',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (isLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, size: 10, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Meter Visualization
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background Track
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Active Progress
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.75 * percentage, 
                    // 0.75 is roughly (screen width - padding) / screen width factor
                    // Better to use LayoutBuilder but for simplicity:
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [progressColor.withOpacity(0.5), progressColor],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Value Display (Lockable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tahmini Alkol Seviyesi',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _buildPromilValue(isLocked, bac, progressColor),
                ],
              ),
              
              // Warning Text
              if (bac > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getWarningText(bac),
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          
          // Blur Overlay if Locked
          if (isLocked)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_person_rounded, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Detaylı Analiz İçin\nPremium\'a Geç',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPromilValue(bool isLocked, double bac, Color color) {
    if (isLocked) {
      return Text(
        '?.?? ‰',
        style: GoogleFonts.spaceMono(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: color.withOpacity(0.5),
        ),
      );
    }
    return Text(
      '${bac.toStringAsFixed(2)} ‰',
      style: GoogleFonts.spaceMono(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: color,
        shadows: [
          Shadow(color: color.withOpacity(0.5), blurRadius: 8),
        ],
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
