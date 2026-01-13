import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Splash screen with loading video animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoReady = false;

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
      _controller.play();
      
      setState(() {
        _isVideoReady = true;
      });
      
      // Video bitince login'e git
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToLogin();
        }
      });
      
      // Fallback: 3 saniye sonra git (video çok uzunsa veya hata varsa)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    } catch (e) {
      // Video yüklenemezse direkt git
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      context.go('/login');
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/onlybg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: _isVideoReady
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
