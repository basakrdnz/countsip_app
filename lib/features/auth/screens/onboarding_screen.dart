import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final int initialPage;
  const OnboardingScreen({super.key, this.initialPage = 0});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    
    // Float animation for icons
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.background, // #0A0E14 base
      body: Stack(
        children: [
          // Background Photo (blurred cocktail)
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Dark overlay: rgba(10,14,20,0.8) to rgba(10,14,20,0.95)
          // This matches #0A0E14 tone
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0E14).withOpacity(0.8),  // rgba(10,14,20,0.8)
                      const Color(0xFF0A0E14).withOpacity(0.95), // rgba(10,14,20,0.95)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Progress Dots
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isActive ? 32 : 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? null
                              : Colors.white.withOpacity(0.25),
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [AppColors.primary, const Color(0xFFEE5A6F)],
                                )
                              : null,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),

                // Slides
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
                    dragStartBehavior: DragStartBehavior.down,
                    children: [
                      _buildSlide(0),
                      _buildSlide(1),
                      _buildSlide(2),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                  child: _buildGradientButton(
                    _currentPage == _totalPages - 1 ? 'Başla' : 'İleri',
                    _nextPage,
                  ),
                ),
              ],
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
        'title': 'Arkadaşlarınla Yarış',
        'description': 'Haftalık liderlik tablosunda arkadaşlarınla rekabet et. Kim kazanacak? 🏆',
      },
      {
        'icon': 'assets/images/3d/lock3d.png',
        'title': 'Sadece Arkadaşlarına Görünür',
        'description': 'Veriler gizli kalır, sadece arkadaş listendekilere açık. Güvenle eğlen!',
      },
    ];

    final data = slideData[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating Icon with shadow
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatAnimation.value),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Image.asset(
              data['icon']!,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title with shadow for readability
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  offset: const Offset(0, 2),
                  blurRadius: 12,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description with shadow
          Text(
            data['description']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textTertiary,
              height: 1.6,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFFEE5A6F)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
