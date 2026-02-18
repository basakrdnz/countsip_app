import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../providers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_background.dart';

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
          _currentStep = 1;
          _startResendCountdown();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bir hata oluştu. Lütfen tekrar deneyin.';
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
      
      if (_verificationId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Doğrulama oturumu bulunamadı. Lütfen kodu tekrar iste.';
        });
        return;
      }
      
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
        _error = e.code == 'invalid-verification-code'
            ? 'Geçersiz doğrulama kodu'
            : 'Şifre sıfırlanamadı. Lütfen tekrar deneyin.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Stack(
        children: [
          // Main Content - centered
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),

                  // Glassmorphic Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step Indicator
                            Row(
                              children: List.generate(3, (index) {
                                final isActive = _currentStep >= index;
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 4,
                                    margin: EdgeInsets.symmetric(horizontal: (index == 1) ? 6 : 0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                                      boxShadow: isActive ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                        )
                                      ] : [],
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 28),

                            Text(
                              _getStepTitle(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getStepTitleDescription(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Form Content
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildCurrentStep(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Error Message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 20, color: Colors.red[300]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.red[100],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Action Button
                  _buildStepButton(),

                  const SizedBox(height: 32),

                  // Back to Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Şifreni hatırladın mı? ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Giriş Yap',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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

          // Top bar: Back Button + Brand
          Positioned(
            top: 16,
            left: 24,
            right: 24,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  _buildBackButton(),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CountSip',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PREMIUM TRACKER',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary.withValues(alpha: 0.8),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Şifreni Sıfırla';
      case 1: return 'Kodu Doğrula';
      case 2: return 'Yeni Şifre';
      default: return 'Şifreni Sıfırla';
    }
  }

  String _getStepTitleDescription() {
    switch (_currentStep) {
      case 0: return 'Hesabına bağlı telefon numaranı gir';
      case 1: return 'Telefonuna gelen 6 haneli kodu gir';
      case 2: return 'Lütfen yeni ve güvenli bir şifre belirle';
      default: return '';
    }
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        } else {
          context.go('/login');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('TELEFON NUMARASI'),
        const SizedBox(height: 12),
        _buildPhoneInput(),
      ],
    );
  }

  Widget _buildCodeStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('DOĞRULAMA KODU'),
        const SizedBox(height: 12),
        _buildCodeInput(),
        const SizedBox(height: 16),
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Tekrar gönder: $_resendCountdown sn',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                )
              : TextButton(
                  onPressed: _sendCode,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'Kodu Tekrar Gönder',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('YENİ ŞİFRE'),
        const SizedBox(height: 12),
        _buildPasswordInput(_passwordController, 'Yeni Şifren'),
        const SizedBox(height: 24),
        _buildLabel('ŞİFREYİ ONAYLA'),
        const SizedBox(height: 12),
        _buildPasswordInput(_confirmPasswordController, 'Şifreni Onayla'),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          _buildCountryCodeDropdown(),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.phoneHint ?? '5XX XXX XX XX',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCodeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          dropdownColor: const Color(0xFF1A1F2E),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white.withValues(alpha: 0.3)),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          isDense: true,
          items: _countryCodes.map((c) => DropdownMenuItem(
            value: c['code'],
            child: Text(c['code']!),
          )).toList(),
          onChanged: (v) => setState(() => _selectedCountryCode = v!),
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 6,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 12,
        ),
        decoration: InputDecoration(
          hintText: '••••••',
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            color: Colors.white.withValues(alpha: 0.2),
            letterSpacing: 12,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildPasswordInput(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildStepButton() {
    String text = 'Kod Gönder';
    VoidCallback? action = _sendCode;
    
    if (_currentStep == 1) {
      text = 'Doğrula';
      action = _verifyCode;
    } else if (_currentStep == 2) {
      text = 'Şifreyi Güncelle';
      action = _resetPassword;
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accentPrimary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : action,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
