import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/email_validator.dart';
import '../../../ui/widgets/password_strength_indicator.dart';
import '../providers/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
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
      
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
        email: email,
        password: _passwordController.text,
      );
      
      // Log analytics event
      final analyticsService = ref.read(analyticsServiceProvider);
      await analyticsService.logSignUp('email');
      
      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signupSuccess),
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
      await analyticsService.logSignUp('google');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signupSuccess),
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
      case 'email-already-in-use':
        return l10n.emailAlreadyInUse;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgwglass.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Title
                  Text(
                    l10n.createAccount,
                    style: AppTextStyles.largeTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.createAccountSubtitle,
                    style: AppTextStyles.subheadline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        if (_errorMessage == l10n.networkError)
                          TextButton(
                            onPressed: _handleSignUp,
                            child: Text(l10n.tryAgain),
                          ),
                      ],
                    ),
                  ),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                 validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.emailRequired;
                    }
                    if (!EmailValidator.isValid(value)) {
                      return l10n.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}), // Rebuild for strength indicator
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
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
                    if (value.length < 6) {
                      return l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                // Password strength indicator
                PasswordStrengthIndicator(
                  password: _passwordController.text,
                  getStrengthLabel: (strength) {
                    switch (strength) {
                      case PasswordStrength.weak:
                        return l10n.passwordWeak;
                      case PasswordStrength.medium:
                        return l10n.passwordMedium;
                      case PasswordStrength.strong:
                        return l10n.passwordStrong;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _handleSignUp(),
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    hintText: l10n.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.confirmPasswordRequired;
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordsDontMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                // Sign up button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.signUp),
                ),
                const SizedBox(height: AppSpacing.md),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        l10n.or,
                        style: AppTextStyles.subheadline,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Google Sign In button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: Text(l10n.continueWithGoogle),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: AppTextStyles.body,
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.pop();
                            },
                      child: Text(
                        l10n.login,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
  );
  }
}

String _mapAuthErrorToMessage(String code, AppLocalizations l10n) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return l10n.invalidCredentials;
    case 'email-already-in-use':
      return l10n.emailAlreadyInUse;
    case 'weak-password':
      return l10n.passwordTooShort;
    case 'invalid-email':
      return l10n.emailInvalid;
    case 'network-request-failed':
      return l10n.networkError;
    case 'user-disabled':
      return l10n.unexpectedError;
    case 'too-many-requests':
      return l10n.tooManyAttempts;
    default:
      return l10n.unexpectedError;
  }
}
