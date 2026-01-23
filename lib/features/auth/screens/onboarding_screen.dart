import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

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
    _pageController = PageController();
    
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
                              ? const Color(0xFF6A4A3C)
                              : const Color(0xFF6A4A3C).withOpacity(0.2),
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
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildSlide(1),
                      _buildSlide(2),
                      _buildSlide(3),
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
              width: 210,
              height: 210,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'CalSans',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A4A3C),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            data['description']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF6A4A3C).withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF6A4A3C).withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A4A3C).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
                  style: const TextStyle(
                    fontFamily: 'CalSans',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
