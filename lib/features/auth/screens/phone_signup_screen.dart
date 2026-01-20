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
          // Lighter background
          Image.asset(
            'assets/images/onlybg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Light white overlay
          Container(
            color: const Color(0xFF3A2E28).withOpacity(0.58),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/countsiplogo.png',
                        width: 80,
                        height: 80,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CountSip',
                        style: AppTextStyles.largeTitle.copyWith(
                          fontFamily: 'Rosaline',
                          color: Colors.white, // Changed to White for contrast
                          fontSize: 42,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Card Container for Content
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDE9).withOpacity(0.92), // Light warm beige/white
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                          'Hesap Oluştur',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title1.copyWith(
                            color: const Color(0xFF4B3126),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Step Indicator
                        _buildStepIndicator(),
                        
                        const SizedBox(height: 32),
                        
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
                        
                        const SizedBox(height: 32),
                        
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Zaten hesabın var mı? ',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Giriş Yap',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'Telefon'),
        Expanded(child: Container(height: 2, color: _currentStep > 0 ? AppColors.primary : Colors.grey.shade300)),
        _buildStepDot(1, 'Doğrula'),
        Expanded(child: Container(height: 2, color: _currentStep > 1 ? AppColors.primary : Colors.grey.shade300)),
        _buildStepDot(2, 'Şifre'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            border: isCurrent ? Border.all(color: AppColors.primary, width: 3) : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? Icon(AppIcons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : Colors.grey.shade500,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Telefon Numarası',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Picker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
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
            // Phone Number
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
              : const Text(
                  'Devam Et', 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Doğrulama Kodu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_selectedCountryCode ${_phoneController.text} numarasına gönderilen 6 haneli kodu gir',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
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
        // Resend button
        Center(
          child: _resendCountdown > 0
              ? Text(
                  'Tekrar gönder ($_resendCountdown sn)',
                  style: TextStyle(color: Colors.grey.shade500),
                )
              : TextButton(
                  onPressed: _resendCode,
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
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text(
                  'Doğrula', 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _currentStep = 0),
          child: const Text('Geri'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Şifre Belirle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hesabın için güçlü bir şifre belirle',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Şifre (en az 6 karakter)',
              prefixIcon: Icon(AppIcons.lock, color: Colors.grey.shade600, size: 20),
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
            decoration: InputDecoration(
              hintText: 'Şifre Tekrar',
              prefixIcon: Icon(AppIcons.lock, color: Colors.grey.shade600, size: 20),
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
          onPressed: _isLoading ? null : _createAccount,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF6A4A3C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text(
                  'Hesap Oluştur', 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: const Text('Geri'),
        ),
      ],
    );
  }
}
