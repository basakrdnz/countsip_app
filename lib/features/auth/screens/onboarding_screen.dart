import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'İçeceklerini\nTakip Et',
      description: 'Her yudumu kaydet, alkol tüketimini kontrol altında tut.',
      icon: AppIcons.onboardingGlass,
    ),
    OnboardingContent(
      title: 'Promilini\nGör',
      description: 'Vücudundaki tahmini alkol oranını anlık olarak takip et.',
      icon: AppIcons.onboardingGauge,
    ),
    OnboardingContent(
      title: 'Arkadaşlarınla\nKarşılaştır',
      description: 'Liderlik tablosunda yerini al, eğlenceyi paylaş.',
      icon: AppIcons.onboardingFollowers,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Listen for overscroll on last page to navigate to login
    _pageController.addListener(_handleOverscroll);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeController.forward();
  }

  void _handleOverscroll() {
    if (_currentPage == _contents.length - 1) {
      // Check if user is trying to swipe past the last page
      if (_pageController.position.pixels > _pageController.position.maxScrollExtent + 50) {
        HapticFeedback.mediumImpact();
        context.go('/login');
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _contents.length - 1) {
      HapticFeedback.lightImpact();
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutExpo,
      );
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbgdark.png',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Progress Indicators
                _buildProgressIndicators(),

                const SizedBox(height: 24),

                // Page Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _fadeController
                        ..reset()
                        ..forward();
                    },
                    itemCount: _contents.length,
                    itemBuilder: (context, index) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _fadeController,
                            curve: Curves.easeOutBack,
                          ),
                        ),
                        child: FadeTransition(
                          opacity: _fadeController,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: OnboardingPageContent(
                                content: _contents[index],
                                isActive: index == _currentPage,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
                  child: _buildBottomActions(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_contents.length, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 4,
            width: isActive ? 140 : 30, // Wider bars as requested
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive
                  ? const Color(0xFFD2C5BC)
                  : const Color(0xFFD2C5BC).withOpacity(0.3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomActions() {
    final isLastPage = _currentPage == _contents.length - 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLastPage
          ? _buildAuthButtons()
          : _buildNextButton(),
    );
  }

  Widget _buildNextButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A4A3C).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        key: const ValueKey('next'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6A4A3C),
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: _nextPage,
        child: const Text(
          'Hadi Başlayalım',
          style: TextStyle(
            fontFamily: 'CalSans',
            color: Color(0xFFF3EDE9),
            fontSize: 18,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      key: const ValueKey('auth'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A4A3C).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A4A3C),
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.go('/login');
            },
            child: const Text(
              'Giriş Yap',
              style: TextStyle(
                fontFamily: 'CalSans',
                color: Color(0xFFF3EDE9),
                fontSize: 18,
                fontWeight: FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('/signup');
          },
          child: const Text(
            'Hesap Oluştur',
            style: TextStyle(
              fontFamily: 'CalSans',
              color: Color(0xFFB9ADA5),
              fontSize: 16,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingPageContent extends StatefulWidget {
  final OnboardingContent content;
  final bool isActive;

  const OnboardingPageContent({
    super.key,
    required this.content,
    required this.isActive,
  });

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with Bounce Animation and Subtle Glow
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_bounceAnimation.value),
              child: child,
            );
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD2C5BC).withOpacity(0.08),
                  Colors.transparent,
                ],
                stops: const [0.4, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD2C5BC).withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                widget.content.icon,
                size: 110,
                color: Colors.white.withOpacity(0.9),
                shadows: [
                  Shadow(
                    color: const Color(0xFFD2C5BC).withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Title - Plain Color
        Text(
          widget.content.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'CalSans',
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 16),

        // Description - Plain Color
        Text(
          widget.content.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.white.withOpacity(0.75),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
