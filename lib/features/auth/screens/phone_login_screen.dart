import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_icons.dart';
import '../providers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  String _selectedCountryCode = '+90';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+90', 'country': '🇹🇷'},
    {'code': '+1', 'country': '🇺🇸'},
    {'code': '+44', 'country': '🇬🇧'},
    {'code': '+49', 'country': '🇩🇪'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedCountryCode${_phoneController.text.trim()}';

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _error = 'Lütfen tüm alanları doldur');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      await authController.signInWithPhone(
        phoneNumber: _fullPhoneNumber,
        password: password,
      );
      
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) return 'Bu numaraya kayıtlı hesap bulunamadı';
    if (error.contains('wrong-password')) return 'Hatalı şifre';
    if (error.contains('invalid-email')) return 'Geçersiz telefon numarası';
    if (error.contains('too-many-requests')) return 'Çok fazla deneme. Lütfen bekle.';
    return 'Giriş yapılamadı. Tekrar dene.';
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
                      'Tekrar Hoş Geldin!',
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
                      'Kaldığın yerden devam etmek için giriş yap',
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
                    
                    // Login Button
                    _buildGradientButton('Giriş Yap', _login),
                    
                    const SizedBox(height: 24),
                    
                    // Social Login
                    _buildSocialLoginSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Signup Link
                    _buildSignupLink(),
                    
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.go('/onboarding?page=2'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('TELEFON NUMARASI'),
          const SizedBox(height: 12),
          _buildPhoneInput(),
          const SizedBox(height: 20),
          _buildLabel('ŞİFRE'),
          const SizedBox(height: 12),
          _buildPasswordInput(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Şifremi Unuttum',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
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
          // Country Code
          _buildCountryCodeDropdown(),
          
          // Vertical Divider Line
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.08),
          ),
          
          // Phone Icon and Input
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
                hintText: AppLocalizations.of(context)?.phoneHint ?? '5XX XXX XX XX',
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

  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252B35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Şifren',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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

  Widget _buildSocialLoginSection() {
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

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabın yok mu? ',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/signup'),
          child: Text(
            'Hesap Oluştur',
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

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
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
          onTap: _isLoading ? null : onPressed,
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
