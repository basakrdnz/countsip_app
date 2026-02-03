import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_icons.dart';
import '../providers/auth_controller.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  
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
    _passwordController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_selectedCountryCode${_phoneController.text.trim()}';

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _error = 'Geçerli bir telefon numarası gir');
      return;
    }
    
    if (password.isEmpty) {
      setState(() => _error = 'Şifre boş olamaz');
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
      
      // Check for errors in state
      final state = ref.read(authControllerProvider);
      if (state.hasError) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(state.error);
        });
        return;
      }
      
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = _getErrorMessage(e);
      });
    }
  }
  
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user-not-found') || errorStr.contains('wrong-password')) {
      return 'Telefon numarası veya şifre hatalı';
    }
    if (errorStr.contains('too-many-requests')) {
      return 'Çok fazla deneme. Lütfen bekleyin.';
    }
    if (errorStr.contains('invalid-credential')) {
      return 'Geçersiz giriş bilgileri';
    }
    return 'Giriş yapılamadı. Tekrar dene.';
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
                          // Header (Logo always at the top)
                          SizedBox(
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildGlassIconButton(
                                    AppIcons.angleLeft,
                                    () => context.go('/onboarding?page=2'),
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
                                        // Form Header
                                        Text(
                                          'Tekrar Hoş Geldin!',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppColors.textPrimary,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Kaldığın yerden devam etmek için giriş yap',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 40),
                                        
                                        // Form Content
                                        _buildLoginForm(),
                                        
                                        // Error
                                        if (_error != null) ...[
                                          const SizedBox(height: 20),
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                        
                                        // Signup Link (inside card)
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Hesabın yok mu? ',
                                              style: TextStyle(color: Colors.black.withOpacity(0.6)),
                                            ),
                                            TextButton(
                                              onPressed: () => context.go('/signup'),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text(
                                                'Hesap Oluştur',
                                                style: TextStyle(
                                                  color: AppColors.primary,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  Widget _buildLoginForm() {
    OutlineInputBorder roundedBorder(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 1),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputLabel('Telefon Numarası'),
        const SizedBox(height: 12),

        Row(
          children: [
            // Country Picker
            Container(
              height: 48,
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
            // Phone Field
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '5XX XXX XX XX',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontWeight: FontWeight.normal),
                  prefixIcon: Icon(AppIcons.phoneCall, color: AppColors.primary.withOpacity(0.6), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: roundedBorder(Colors.transparent),
                  enabledBorder: roundedBorder(Colors.black.withOpacity(0.08)),
                  focusedBorder: roundedBorder(AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildInputLabel('Şifre'),
        const SizedBox(height: 12),

        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Şifren',
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontWeight: FontWeight.normal),
            prefixIcon: Icon(AppIcons.lock, color: AppColors.primary.withOpacity(0.6), size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? AppIcons.eyeIcon : AppIcons.eyeCrossed,
                size: 20,
                color: AppColors.primary.withOpacity(0.5),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: roundedBorder(Colors.transparent),
            enabledBorder: roundedBorder(Colors.black.withOpacity(0.08)),
            focusedBorder: roundedBorder(AppColors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: const Text(
              'Şifremi Unuttum',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        _buildPrimaryButton('Giriş Yap', _login),
      ],
    );
  }

  // --- Helper UI Components ---

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    Widget? suffixIcon,
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
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontWeight: FontWeight.normal),
          prefixIcon: icon != null ? Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 20) : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
            AppColors.primary,
            AppColors.textPrimary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
}
