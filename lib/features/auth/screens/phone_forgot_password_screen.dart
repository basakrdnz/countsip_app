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
          // 1. Base Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mainbgwemp.png',
              fit: BoxFit.cover,
            ),
          ),
          

          
          // 4. Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute top and center
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header (Top Aligned)
                          SizedBox(
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildGlassIconButton(
                                    AppIcons.angleLeft,
                                    () {
                                      if (_currentStep > 0) {
                                        setState(() => _currentStep--);
                                      } else {
                                        context.go('/login');
                                      }
                                    },
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/applogowname.png',
                                  height: 60,
                                ),
                              ],
                            ),
                          ),
                          

                          // Centered form
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 190),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.xl),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Title & Indicator
                                        Text(
                                          'Şifreni Sıfırla',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'CalSans',
                                            color: const Color(0xFF6A4A3C),
                                            fontSize: 28,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        _buildPremiumIndicator(),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Form Content
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: _buildCurrentStep(),
                                        ),
                                        
                                        // Error
                                        if (_error != null) ...[
                                          const SizedBox(height: 20),
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitleDescription() {
    switch (_currentStep) {
      case 0: return 'Şifreni sıfırlamak için telefonunu kullan';
      case 1: return 'Telefonuna gelen doğrulama kodunu gir';
      case 2: return 'Yeni ve güçlü bir şifre belirle';
      default: return '';
    }
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: const Color(0xFF6A4A3C), size: 22),
      ),
    );
  }

  Widget _buildPremiumIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = _currentStep >= index;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.symmetric(horizontal: (index == 1) ? 6 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive ? const Color(0xFF6A4A3C) : const Color(0xFF6A4A3C).withOpacity(0.15),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildPhoneStep(key: const ValueKey(0));
      case 1: return _buildCodeStep(key: const ValueKey(1));
      case 2: return _buildPasswordStep(key: const ValueKey(2));
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputLabel('Telefon Numarası'),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  items: _countryCodes.map((c) => DropdownMenuItem(
                    value: c['code'],
                    child: Text(c['code']!),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCountryCode = v!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                hintText: '5XX XXX XX XX',
                icon: AppIcons.phoneCall,
                keyboardType: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton('Kod Gönder', _sendCode),
      ],
    );
  }

  Widget _buildCodeStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputLabel('Doğrulama Kodu'),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _codeController,
          hintText: '• • • • • •',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        Center(
          child: _resendCountdown > 0
              ? Text('Tekrar gönder: $_resendCountdown sn', style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13))
              : TextButton(
                  onPressed: _sendCode,
                  child: const Text('Kodu Tekrar Gönder', style: TextStyle(color: Color(0xFF6A4A3C), fontWeight: FontWeight.w600)),
                ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton('Doğrula', _verifyCode),
      ],
    );
  }

  Widget _buildPasswordStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputLabel('Yeni Şifre'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          hintText: 'Yeni Şifren',
          icon: AppIcons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          hintText: 'Şifreni Onayla',
          icon: AppIcons.lock,
          obscureText: true,
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton('Şifreyi Güncelle', _resetPassword),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4B3126)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    TextAlign textAlign = TextAlign.start,
    TextStyle? style,
    int? maxLength,
  }) {
    OutlineInputBorder roundedBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 1),
      );
    }
    
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textAlign: textAlign,
      maxLength: maxLength,
      style: style ?? const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6A4A3C).withOpacity(0.6), size: 20) : null,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: roundedBorder(Colors.transparent),
        enabledBorder: roundedBorder(Colors.black.withOpacity(0.08)),
        focusedBorder: roundedBorder(const Color(0xFF6A4A3C)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [const Color(0xFF6A4A3C), const Color(0xFF4B3126)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A4A3C).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
