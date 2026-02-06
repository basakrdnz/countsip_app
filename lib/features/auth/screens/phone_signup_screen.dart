import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icons.dart';
import '../providers/auth_controller.dart';

class PhoneSignupScreen extends ConsumerStatefulWidget {
  const PhoneSignupScreen({super.key});

  @override
  ConsumerState<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends ConsumerState<PhoneSignupScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  int _currentStep = 0; // 0: Phone, 1: Code, 2: Password
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
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
      final isRegistered = await authController.isPhoneRegistered(_fullPhoneNumber);
      
      if (isRegistered) {
        setState(() {
          _isLoading = false;
          _error = 'Bu numara zaten kayıtlı. Giriş yapmayı dene.';
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

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      final result = await authController.resendVerificationCode(
        _fullPhoneNumber,
        _resendToken,
      );
      
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
          _startResendCountdown();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kod tekrar gönderildi'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bir hata oluştu: $e';
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = '6 haneli kodu gir');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      setState(() {
        _isLoading = false;
        _currentStep = 2;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Geçersiz kod. Tekrar dene.';
      });
    }
  }

  Future<void> _createAccount() async {
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
      final code = _codeController.text.trim();
      
      // First verify the code to get credential
      final credential = authController.verifyCode(_verificationId!, code);
      
      // Then sign up with phone, password and credential
      await authController.signUpWithPhone(
        phoneNumber: _fullPhoneNumber,
        password: password,
        phoneCredential: credential,
      );
      
      if (mounted) {
        context.go('/profilesetup');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Hesap oluşturulamadı: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // #0A0E14 - direct navy
      body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button + Logo
                  SizedBox(
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildBackButton(),
                        ),
                        Image.asset(
                          'assets/images/applogowname.png',
                          height: 60,
                        ),
                      ],
                    ),
                  ),
                    
                    const SizedBox(height: 32),
                    
                    // Header (no card, direct on background)
                    Text(
                      'Hesap Oluştur',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sadece birkaç adımda topluluğumuza katıl',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Step Indicator
                    _buildStepIndicator(),
                    
                    const SizedBox(height: 32),
                    
                    // Current Step Content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildCurrentStep(),
                    ),
                    
                    // Error
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 28),
                    
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Zaten bir hesabın var mı? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Giriş Yap',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
            _error = null;
          });
        } else {
          context.go('/login');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            AppIcons.angleLeft,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = _currentStep >= index;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: 4,
            margin: EdgeInsets.symmetric(horizontal: index == 1 ? 6 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive ? null : AppColors.primary.withOpacity(0.15),
              gradient: isActive
                  ? LinearGradient(
                      colors: [AppColors.primary, Color(0xFFEE5A6F)],
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhoneStep(key: const ValueKey(0));
      case 1:
        return _buildCodeStep(key: const ValueKey(1));
      case 2:
        return _buildPasswordStep(key: const ValueKey(2));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('TELEFON NUMARASI'),
        const SizedBox(height: 10),
        _buildPhoneInput(),
        const SizedBox(height: 24),
        _buildGradientButton('Kod Gönder', _sendCode),
      ],
    );
  }

  Widget _buildCodeStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('DOĞRULAMA KODU'),
        const SizedBox(height: 10),
        _buildCodeInput(),
        const SizedBox(height: 16),
        
        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resendCountdown > 0 
                  ? 'Kod tekrar gönderilebilir: ${_resendCountdown}s'
                  : 'Kod gelmedi mi?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
            if (_resendCountdown == 0)
              TextButton(
                onPressed: _resendCode,
                child: Text(
                  'Tekrar Gönder',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        _buildGradientButton('Doğrula', _verifyCode),
      ],
    );
  }

  Widget _buildPasswordStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel('ŞİFRE'),
        const SizedBox(height: 10),
        _buildPasswordInput(
          controller: _passwordController,
          hintText: 'Şifren (min 6 karakter)',
          obscure: _obscurePassword,
          toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        
        const SizedBox(height: 16),
        
        _buildLabel('ŞİFRE TEKRAR'),
        const SizedBox(height: 10),
        _buildPasswordInput(
          controller: _confirmPasswordController,
          hintText: 'Şifren tekrar',
          obscure: _obscureConfirmPassword,
          toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        
        const SizedBox(height: 24),
        _buildGradientButton('Hesap Oluştur', _createAccount),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF252B35).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Color(0xFF252B35).withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountryCode,
                dropdownColor: AppColors.surface,
                icon: Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textTertiary),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                isDense: true,
                items: _countryCodes.map((c) => DropdownMenuItem(
                  value: c['code'],
                  child: Text(c['code']!),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCountryCode = v!),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '5XX XXX XX XX',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                prefixIcon: Icon(AppIcons.phoneCall, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF252B35).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 6,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 12,
        ),
        decoration: InputDecoration(
          hintText: '• • • • • •',
          hintStyle: GoogleFonts.inter(
            fontSize: 24,
            color: AppColors.textTertiary.withOpacity(0.3),
            letterSpacing: 8,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF252B35).withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          prefixIcon: Icon(AppIcons.lock, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            onPressed: toggleObscure,
            icon: Icon(
              obscure ? AppIcons.eyeIcon : AppIcons.eyeCrossed,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFEE5A6F)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
