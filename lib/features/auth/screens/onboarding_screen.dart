import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../widgets/auth_background.dart';
import '../../../ui/widgets/countsip_button.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  final int initialPage;
  const OnboardingScreen({super.key, this.initialPage = 0});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutExpo,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showOrbs: false,
      child: Column(
        children: [
          // 1. HEADER (Atla + Progress Indicators)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 16, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CountSipButton(
                  onPressed: () => context.go('/login'),
                  text: 'Atla',
                  variant: CountSipButtonVariant.ghost,
                  width: 60,
                  height: 32,
                  fontSize: 14,
                  textColor: Colors.white.withValues(alpha: 0.6),
                ),
                
                // PROGRESS INDICATORS (Moved here)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_totalPages, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isActive ? 24 : 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.accentPrimary],
                              )
                            : null,
                        color: isActive ? null : Colors.white.withValues(alpha: 0.2),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(width: 50), // Balanced with "Atla"
              ],
            ),
          ),

          // 2. SLIDES Content moves up as indicators are now in header
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                if (index == _totalPages) {
                  context.go('/login');
                  return;
                }
                setState(() => _currentPage = index);
              },
              children: [
                _buildSlide(0),
                _buildSlide(1),
                _buildSlide(2),
                const SizedBox.shrink(),
              ],
            ),
          ),

          // 5. BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: CountSipButton(
              onPressed: _nextPage,
              text: _currentPage == _totalPages - 1 ? 'Başla' : 'İleri',
              height: 56,
              borderRadius: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(int index) {
    final slideData = [
      {
        'icon': 'assets/images/3d/glass3d.png',
        'title': 'İçeceklerini Kaydet',
        'description': 'Tek dokunuşla ne içtiğini, nerede olduğunu kaydet. Basit, hızlı ve eğlenceli!',
      },
      {
        'icon': 'assets/images/3d/people3d.png',
        'title': 'Anlarını Paylaş',
        'description': 'Arkadaşlarınla ne içtiğini paylaş, kimin ne yaptığından haberdar ol. Sosyal kalmak bu kadar kolay!',
      },
      {
        'icon': 'assets/images/3d/lock3d.png',
        'title': 'Arkadaşlarına Özel',
        'description': 'Veriler gizli kalır, sadece arkadaş listendekilere açık. Güvenle eğlen!',
      },
    ];

    final data = slideData[index];

    return Column(
      children: [
        // Illustration
        Expanded(
          flex: 5,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(index),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.asset(
                        data['icon']!,
                        height: (index == 0 || index == 2) ? 340 : 280,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Text Content
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  data['title']!,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  data['description']!,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFCBD5E1),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
