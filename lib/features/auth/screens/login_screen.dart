import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/email_validator.dart';
import '../../../ui/widgets/glass_container.dart';
import '../providers/auth_controller.dart';
import '../../../core/providers/preferences_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  void _loadSavedEmail() {
    final prefsService = ref.read(preferencesServiceProvider);
    final savedEmail = prefsService.getSavedEmail();
    final rememberMe = prefsService.getRememberMe();
    
    if (savedEmail != null && rememberMe) {
      _emailController.text = savedEmail;
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    
    // Check network connectivity
    final connectivityService = ref.read(connectivityServiceProvider);
    final hasConnection = await connectivityService.hasConnection();
    
    if (!hasConnection) {
      setState(() {
        _errorMessage = l10n.networkError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = EmailValidator.normalize(_emailController.text);
      
      await ref.read(authControllerProvider.notifier).signInWithEmail(
        email: email,
        password: _passwordController.text,
      );
      
      // Save email if remember me is checked
      final prefsService = ref.read(preferencesServiceProvider);
      await prefsService.setRememberMe(_rememberMe);
      if (_rememberMe) {
        await prefsService.setSavedEmail(email);
      } else {
        await prefsService.clearSavedEmail();
      }
      
      // Log analytics event
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logLogin('email');
      
      // Show success (navigation handled by router)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on AuthException catch (e) {
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logAuthError(e.code ?? 'unknown', e.message ?? 'Unknown error');
      
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthErrorToMessage(e.code ?? 'unknown', l10n);
          _isLoading = false;
        });
      }
    } catch (e) {
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logAuthError('unknown', e.toString());
      
      if (mounted) {
        setState(() {
          _errorMessage = l10n.unexpectedError;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Check network connectivity
    final connectivityService = ref.read(connectivityServiceProvider);
    final hasConnection = await connectivityService.hasConnection();
    
    if (!hasConnection) {
      setState(() {
        _errorMessage = l10n.networkError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      
      // Log analytics event
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logLogin('google');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on AuthException catch (e) {
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logAuthError(e.code ?? 'unknown', e.message ?? 'Unknown error');
      
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthErrorToMessage(e.code ?? 'unknown', l10n);
          _isLoading = false;
        });
      }
    } catch (e) {
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logAuthError('unknown', e.toString());
      
      if (mounted) {
        setState(() {
          _errorMessage = l10n.unexpectedError;
          _isLoading = false;
        });
      }
    }
  }

  String _mapAuthErrorToMessage(String code, AppLocalizations l10n) {
    switch (code) {
      case 'user-not-found':
        return l10n.userNotFound;
      case 'wrong-password':
        return l10n.wrongPassword;
      case 'invalid-credential':
        return l10n.invalidCredentials;
      case 'too-many-requests':
        return l10n.tooManyAttempts;
      default:
        return l10n.unexpectedError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgwglass.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GlassContainer(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Title
                    Text(
                      l10n.appName,
                      style: AppTextStyles.largeTitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.loginSubtitle,
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.footnote.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.emailRequired;
                        }
                        return null; // Add stronger validation if needed
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.passwordRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Remember Me & Forgot Password
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.rememberMe,
                          style: AppTextStyles.footnote,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {}, // TODO: Implement forgot password
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.forgotPassword,
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.login),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: AppTextStyles.body,
                        ),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          child: Text(
                            l10n.signUp,
                            style: AppTextStyles.body.copyWith(
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
    );
  }

}

