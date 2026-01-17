import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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
          // Background - full screen
          Image.asset(
            'assets/images/bgwglass.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // White overlay
          Container(
            color: Colors.white.withOpacity(0.85),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Header
                  Column(
                    children: [
                      Icon(Icons.local_bar_rounded, size: 60, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        'CountSip',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Rosaline',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Phone Number
                  Text(
                    'Telefon Numarası',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            prefixIcon: const Icon(Icons.phone),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Şifrenizi girin',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Signup Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hesabın yok mu? ',
                        style: TextStyle(color: AppColors.textSecondary),
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
        ],
      ),
    );
  }
}
