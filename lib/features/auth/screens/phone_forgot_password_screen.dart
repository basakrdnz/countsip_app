import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../providers/auth_controller.dart';

class PhoneForgotPasswordScreen extends ConsumerStatefulWidget {
  const PhoneForgotPasswordScreen({super.key});

  @override
  ConsumerState<PhoneForgotPasswordScreen> createState() => _PhoneForgotPasswordScreenState();
}

class _PhoneForgotPasswordScreenState extends ConsumerState<PhoneForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _currentStep = 0; // 0: Phone, 1: Code, 2: New Password
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  
  String _selectedCountryCode = '+90';
  
  final List<Map<String, String>> _countryCodes = [
    {'code': '+90', 'country': '🇹🇷 Türkiye'},
    {'code': '+1', 'country': '🇺🇸 USA'},
    {'code': '+44', 'country': '🇬🇧 UK'},
    {'code': '+49', 'country': '🇩🇪 Germany'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedCountryCode${_phoneController.text.trim()}';

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _error = 'Geçerli bir telefon numarası gir');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      
      // Check if phone is registered
      final isRegistered = await authController.isPhoneRegistered(_fullPhoneNumber);
      if (!isRegistered) {
        setState(() {
          _isLoading = false;
          _error = 'Bu numara ile kayıtlı hesap bulunamadı';
        });
        return;
      }

      final result = await authController.sendVerificationCode(_fullPhoneNumber);
      
      if (result.error != null) {
        setState(() {
          _isLoading = false;
          _error = result.error;
        });
      } else {
        setState(() {
          _isLoading = false;
          _verificationId = result.verificationId;
          _resendToken = result.resendToken;
          _currentStep = 1;
          _startResendCountdown();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bir hata oluştu: $e';
      });
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 haneli kodu gir');
      return;
    }

    setState(() {
      _isLoading = false;
      _currentStep = 2;
      _error = null;
    });
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    if (password.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı');
      return;
    }
    
    if (password != confirmPassword) {
      setState(() => _error = 'Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      
      final credential = authController.verifyCode(
        _verificationId!,
        _codeController.text.trim(),
      );
      
      await authController.resetPasswordWithPhone(
        phoneNumber: _fullPhoneNumber,
        newPassword: password,
        phoneCredential: credential,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Şifren güncellendi! Giriş yapabilirsin.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message ?? 'Şifre sıfırlanamadı';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bir hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.angleLeft, color: Colors.white),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.pop();
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background - full screen
          // Lighter background
          Image.asset(
            'assets/images/onlybg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Light white overlay
          Container(
            color: Colors.white.withOpacity(0.2),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Column(
                    children: [
                      Icon(AppIcons.lock, size: 60, color: AppColors.brandDark),
                      const SizedBox(height: 8),
                      Text(
                        'Şifremi Unuttum',
                        style: AppTextStyles.largeTitle.copyWith(
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStepDescription(),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.brandDark.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Step Content
                  if (_currentStep == 0) _buildPhoneStep(),
                  if (_currentStep == 1) _buildCodeStep(),
                  if (_currentStep == 2) _buildPasswordStep(),
                  
                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(AppIcons.exclamation, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Hesabınla kayıtlı telefon numarasını gir';
      case 1:
        return 'Telefonuna gelen 6 haneli kodu gir';
      case 2:
        return 'Yeni şifreni belirle';
      default:
        return '';
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  items: _countryCodes.map((c) => DropdownMenuItem(
                    value: c['code'],
                    child: Text(
                      c['code']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCountryCode = v!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '5XX XXX XX XX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(AppIcons.phoneCall, color: AppColors.textSecondaryLight, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCode,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Kod Gönder', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '• • • • • •',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: _resendCountdown > 0
              ? Text('Tekrar gönder ($_resendCountdown sn)', style: TextStyle(color: Colors.grey.shade500))
              : TextButton(
                  onPressed: _sendCode,
                  child: const Text('Kodu Tekrar Gönder'),
                ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Doğrula', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Yeni Şifre (en az 6 karakter)',
            prefixIcon: Icon(AppIcons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Şifre Tekrar',
            prefixIcon: Icon(AppIcons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Şifreyi Güncelle', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
