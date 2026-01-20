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
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeController.forward();
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
              'assets/images/bgwdark.png',
              fit: BoxFit.cover,
            ),
          ),

          // Smoky warm overlay (KEY PART)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF3A2E28).withOpacity(0.58),
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
                      return FadeTransition(
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
    return ElevatedButton(
      key: const ValueKey('next'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6A4A3C),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: _nextPage,
      child: const Text(
        'Hadi Başlayalım',
        style: TextStyle(
          color: Color(0xFFF3EDE9),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      key: const ValueKey('auth'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A4A3C),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('/login');
          },
          child: const Text(
            'Giriş Yap',
            style: TextStyle(
              color: Color(0xFFF3EDE9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            context.go('/signup');
          },
          child: const Text(
            'Hesap Oluştur',
            style: TextStyle(
              color: Color(0xFFB9ADA5),
              fontSize: 15,
              fontWeight: FontWeight.w500,
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

class OnboardingPageContent extends StatelessWidget {
  final OnboardingContent content;
  final bool isActive;

  const OnboardingPageContent({
    super.key,
    required this.content,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Section
        Icon(
          content.icon,
          size: 64,
          color: const Color(0xFFD2C5BC),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          content.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD2C5BC),
          ),
        ),

        const SizedBox(height: 12),

        // Description
        Text(
          content.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFFB9ADA5),
          ),
        ),
      ],
    );
  }
}
