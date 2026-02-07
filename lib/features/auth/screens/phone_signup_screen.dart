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
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header: Back Button + Centered Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBackButton(),
                        Text(
                          'CountSip',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 44), // Balanced with back button width
                      ],
                    ),
                    
                    const SizedBox(height: 100),
                    
                    // Header Text
                    Text(
                      _getStepTitle(),
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
                      _getStepTitleDescription(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Input Card
                    _buildInputCard(),
                    
                    // Error Text
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
                    
                    const SizedBox(height: 24),
                    
                    // Action Button
                    _buildStepButton(),
                    
                    const SizedBox(height: 24),
                    
                    // Social Sign Up
                    if (_currentStep == 0) _buildSocialSignUpSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Login Link
                    if (_currentStep == 0) _buildLoginLink(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Hesap Oluştur';
      case 1: return 'Kodu Doğrula';
      case 2: return 'Şifre Belirle';
      default: return 'Hesap Oluştur';
    }
  }

  String _getStepTitleDescription() {
    switch (_currentStep) {
      case 0: return 'CountSip ailesine katılmak için ilk adımı at';
      case 1: return 'Telefonuna gelen 6 haneli kodu gir';
      case 2: return 'Lütfen güvenli bir şifre belirle';
      default: return '';
    }
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
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
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

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indicator
          Row(
            children: List.generate(3, (index) {
              final isActive = _currentStep >= index;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: (index == 1) ? 6 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive ? AppColors.primary : Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          
          // Form Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(),
          ),
        ],
      ),
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
                  style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 13),
                )
              : TextButton(
                  onPressed: _resendCode,
                  child: Text(
                    'Kodu Tekrar Gönder',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
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
        _buildLabel('ŞİFRE'),
        const SizedBox(height: 12),
        _buildPasswordInput(
          controller: _passwordController,
          hintText: 'Şifren (min 6 karakter)',
          obscure: _obscurePassword,
          toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 20),
        _buildLabel('ŞİFREYİ ONAYLA'),
        const SizedBox(height: 12),
        _buildPasswordInput(
          controller: _confirmPasswordController,
          hintText: 'Şifren tekrar onayla',
          obscure: _obscureConfirmPassword,
          toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppColors.textTertiary.withOpacity(0.7),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252B35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          _buildCountryCodeDropdown(),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.08),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              AppIcons.phoneCall,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '5XX XXX XX XX',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textTertiary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCodeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
          style: GoogleFonts.inter(
            fontSize: 15,
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
    );
  }

  Widget _buildCodeInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252B35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 6,
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 12,
        ),
        decoration: InputDecoration(
          hintText: '••••••',
          hintStyle: GoogleFonts.inter(
            fontSize: 24,
            color: AppColors.textTertiary.withOpacity(0.3),
            letterSpacing: 12,
          ),
          counterText: '',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
        color: const Color(0xFF252B35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            AppIcons.lock,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: IconButton(
            onPressed: toggleObscure,
            icon: Icon(
              obscure ? AppIcons.eyeIcon : AppIcons.eyeCrossed,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
      text = 'Hesap Oluştur';
      action = _createAccount;
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
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : action,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
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

  Widget _buildSocialSignUpSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.apple,
                label: 'Apple',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                icon: Icons.g_mobiledata,
                label: 'Google',
                iconSize: 32,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
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
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF252B35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8EDF2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
