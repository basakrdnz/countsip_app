import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    // Keep a reasonable delay to show the animation
    await Future.delayed(const Duration(milliseconds: 2000));
    
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
            'assets/images/mainbg.png',
            fit: BoxFit.cover,
          ),
          
          Center(
            child: LoadingAnimationWidget.hexagonDots(
              color: AppColors.primary, 
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
