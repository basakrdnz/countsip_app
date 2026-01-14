import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Splash screen - Video plays as the main loading animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/animations/loadingvid.mp4',
    );
    
    try {
      await _controller.initialize();
      _controller.setLooping(false);
      
      // Video yüklenince hemen oynat
      if (mounted) {
        setState(() {});
        _controller.play();
      }
      
      // Video bitince onboarding'e git
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration &&
            _controller.value.duration > Duration.zero) {
          _navigateToOnboarding();
        }
      });
      
      // Fallback: 4 saniye sonra git (video uzunsa veya hata varsa)
      Future.delayed(const Duration(seconds: 4), () {
        _navigateToOnboarding();
      });
    } catch (e) {
      // Video yüklenemezse direkt git
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}
