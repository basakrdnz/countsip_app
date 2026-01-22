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
      // Check if phone is already registered
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
      // Verify the code first (will be used in next step)
      // Move to password step
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
      
      // Create credential from verification
      final credential = authController.verifyCode(
        _verificationId!,
        _codeController.text.trim(),
      );
      
      // Create account
      await authController.signUpWithPhone(
        phoneNumber: _fullPhoneNumber,
        password: password,
        phoneCredential: credential,
      );
      
      if (mounted) {
        context.go('/profile-setup');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message ?? 'Hesap oluşturulamadı';
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

          // 3. Main Glass/Blur Overlay (Removed blur for maximum clarity)
          const Positioned.fill(
            child: SizedBox.shrink(),
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
                          // Header (Back + Logo aligned at the very top)
                          SizedBox(
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildGlassIconButton(
                                    AppIcons.angleLeft,
                                    () => context.go('/login'),
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/applogowname.png',
                                  height: 60,
                                ),
                              ],
                            ),
                          ),
                          
                          // Centered form (Removed Expanded to fix crash)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
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
                                        // Form Title
                                        Text(
                                          'Hesap Oluştur',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'CalSans',
                                            color: const Color(0xFF4B3126),
                                            fontSize: 28,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sadece birkaç adımda topluluğumuza katıl',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 32),
                                        
                                        // Premium Step Indicator
                                        _buildPremiumIndicator(),
                                        
                                        const SizedBox(height: 40),

                                        // Step Transitions
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 400),
                                          transitionBuilder: (Widget child, Animation<double> animation) {
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

                                        // Error feedback
                                        if (_error != null) ...[
                                          const SizedBox(height: 20),
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                        
                                        // Login Link (inside card)
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Zaten bir hesabın var mı? ',
                                              style: TextStyle(color: Colors.black.withOpacity(0.6)),
                                            ),
                                            TextButton(
                                              onPressed: () => context.go('/login'),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Giriş Yap',
                                                style: TextStyle(
                                                  color: Color(0xFF6A4A3C),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
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
              color: isActive 
                ? const Color(0xFF6A4A3C) 
                : const Color(0xFF6A4A3C).withOpacity(0.15),
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
            // Styled Country Picker
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
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
            // Premium Input field
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
        _buildPrimaryButton('Devam Et', _sendCode),
      ],
    );
  }

  Widget _buildCodeStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputLabel('Doğrulama Kodu'),
        const SizedBox(height: 8),
        Text(
          '$_selectedCountryCode ${_phoneController.text} adresine gönderilen kodu gir',
          style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 13),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _codeController,
          hintText: '• • • • • •',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
        ),
        const SizedBox(height: 16),
        Center(
          child: _resendCountdown > 0
              ? Text('Tekrar gönder: $_resendCountdown sn', style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13))
              : TextButton(
                  onPressed: _resendCode,
                  child: const Text('Kodu Tekrar Gönder', style: TextStyle(color: Color(0xFF6A4A3C), fontWeight: FontWeight.w600)),
                ),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton('Doğrula', _verifyCode),
        const SizedBox(height: 12),
        _buildSecondaryButton('Numarayı Değiştir', () => setState(() => _currentStep = 0)),
      ],
    );
  }

  Widget _buildPasswordStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputLabel('Şifre Belirle'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          hintText: 'Şifren (en az 6 karakter)',
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
        _buildPrimaryButton('Hesap Oluştur', _createAccount),
        const SizedBox(height: 12),
        _buildSecondaryButton('Geri Dön', () => setState(() => _currentStep = 1)),
      ],
    );
  }

  // --- Helper UI Components ---

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF4B3126)),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textAlign: textAlign,
        maxLength: maxLength,
        style: style ?? const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontWeight: FontWeight.normal),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6A4A3C).withOpacity(0.6), size: 20) : null,
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A4A3C),
            const Color(0xFF4B3126),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A4A3C).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
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
            : Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: _isLoading ? null : onPressed,
      child: Text(
        text,
        style: TextStyle(color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w600),
      ),
    );
  }
}
