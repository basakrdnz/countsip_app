import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

/// Welcome screen - First screen users see
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgwglass.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 1),
                          
                          // Branding Section
                          Column(
                            children: [
                              Icon(
                                Icons.local_bar_rounded,
                                size: 80,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'CountSip',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Rosaline',
                                  letterSpacing: -2,
                                  color: AppColors.primary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'İçeceklerini takip et, promilini gör,\narkadaşlarınla karşılaştır!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textPrimary.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          
                          const Spacer(flex: 3),
                          
                          // Action Buttons at Bottom
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text('Giriş Yap'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => context.go('/signup'),
                                  child: const Text('Hesap Oluştur'),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
