import 'dart:ui';
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Custom Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep--);
                        } else {
                          context.go('/login');
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Icon(
                          AppIcons.angleLeft,
                          color: AppColors.brandDark,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Header with Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 25,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/countsiplogo.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CountSip',
                        style: TextStyle(
                          fontFamily: 'Rosaline',
                          color: const Color(0xFF6A4A3C),
                          fontSize: 36,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Glass Form Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card Header
                            Text(
                              'Şifremi Unuttum',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                color: const Color(0xFF4B3126),
                                fontWeight: FontWeight.w600,
                                fontSize: 26,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getStepDescription(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF4B3126).withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
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
                  ),
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
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  items: _countryCodes.map((c) => DropdownMenuItem(
                    value: c['code'],
                    child: Text(
                      c['code']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCountryCode = v!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.black87),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '5XX XXX XX XX',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    prefixIcon: Icon(AppIcons.phoneCall, color: Colors.grey.shade600, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                  ),
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
            backgroundColor: const Color(0xFF6A4A3C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Kod Gönder', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '• • • • • •',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
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
            backgroundColor: const Color(0xFF6A4A3C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Doğrula', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Yeni Şifre (en az 6 karakter)',
              prefixIcon: Icon(AppIcons.lock, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Şifre Tekrar',
              prefixIcon: Icon(AppIcons.lock, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF6A4A3C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Şifreyi Güncelle', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }
}
