import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics service wrapper for Firebase Analytics
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  // Auth Events
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  // Onboarding Events
  Future<void> logOnboardingStart() async {
    await _analytics.logEvent(name: 'onboarding_start');
  }

  Future<void> logOnboardingComplete() async {
    await _analytics.logEvent(name: 'onboarding_complete');
  }

  Future<void> logOnboardingSkip() async {
    await _analytics.logEvent(name: 'onboarding_skip');
  }

  // Error Events
  Future<void> logAuthError(String errorCode, String errorMessage) async {
    await _analytics.logEvent(
      name: 'auth_error',
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage,
      },
    );
  }

  Future<void> logNetworkError() async {
    await _analytics.logEvent(name: 'network_error');
  }

  // User Properties
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Screen Tracking
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}

/// Provider for FirebaseAnalytics instance
final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return AnalyticsService(analytics);
});
