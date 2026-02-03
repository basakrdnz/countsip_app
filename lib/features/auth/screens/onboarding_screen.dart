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
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    
    // Bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
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
      // Son sayfada login'e git
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // White overlay with blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ),

          // Slide İçerikleri (PageView)
          SafeArea(
            child: Column(
              children: [
                // Page Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: isActive ? 32 : 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isActive
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
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
                        // 4. sayfaya (boş sayfa) geçmeye çalışınca login'e git
                        context.go('/login');
                        return;
                      }
                      setState(() => _currentPage = index);
                    },
                    dragStartBehavior: DragStartBehavior.down,
                    children: [
                      _buildSlide(1),
                      _buildSlide(2),
                      _buildLastSlide(), // Use a special build for the last slide
                      // Swipe-to-Next için gizli sayfa
                      const SizedBox.shrink(),
                    ],
                  ),
                ),

                // Bottom Button (Sabit Konum)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                  child: _buildGlassButton(
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

  Widget _buildLastSlide() {
    return _buildSlide(3);
  }

  Widget _buildSlide(int slideNumber) {
    // 3D ikonlar ve içerikler
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

    final data = slideData[slideNumber - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D Icon with bounce animation
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_bounceAnimation.value),
                child: child,
              );
            },
            child: Image.asset(
              data['icon']!,
              width: 120, // Reduced from 140
              height: 120, // Reduced from 140
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            data['description']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
