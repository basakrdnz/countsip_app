import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    // Keep a reasonable delay to show the animation
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted || _navigating) return;
    _navigating = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/onlybg.png',
            fit: BoxFit.cover,
          ),
          
          // Optional: Light overlay if needed for contrast, 
          // keeping it subtle or removing if "directly on bg" means raw image.
          // User said "direk bizim bg üstüne", sticking to clean BG or very subtle overlay.
          // I will omit the overlay to be "direct" as requested, or keep it very minimal if contrast is needed.
          // Let's go with raw BG first as implicit in "direk bg üstüne".
          
          Center(
            child: LoadingAnimationWidget.hexagonDots(
              color: AppColors.primaryLight, 
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
