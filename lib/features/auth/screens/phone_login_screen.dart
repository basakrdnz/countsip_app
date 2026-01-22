import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
                      onPressed: () => context.go('/onboarding'),
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
                              'Giriş Yap',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'CalSans',
                                color: const Color(0xFF4B3126),
                                fontWeight: FontWeight.w600,
                                fontSize: 26,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Phone Number
                            Text(
                              'Telefon Numarası',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B3126),
                              ),
                            ),
                            const SizedBox(height: 8),
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
                            
                            const SizedBox(height: 20),
                            
                            // Password
                            Text(
                              'Şifre',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B3126),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Şifrenizi girin',
                                  prefixIcon: Icon(AppIcons.lock, color: Colors.grey.shade600, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? AppIcons.eyeCrossed : AppIcons.eyeIcon, color: Colors.grey.shade600, size: 20),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
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
                            
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                child: Text(
                                  'Şifremi Unuttum',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ),
                            
                            // Error
                            if (_error != null) ...[
                              const SizedBox(height: 8),
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
                            
                            const SizedBox(height: 24),
                            
                            // Login Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF6A4A3C),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Giriş Yap', style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    )),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Signup Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hesabın yok mu? ',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Text(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
