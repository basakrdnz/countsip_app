import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences wrapper for app settings and user preferences
class PreferencesService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keyLocale = 'locale';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Remember Me
  Future<void> setRememberMe(bool value) async {
    await _prefs.setBool(_keyRememberMe, value);
  }

  bool getRememberMe() {
    return _prefs.getBool(_keyRememberMe) ?? false;
  }

  // Saved Email
  Future<void> setSavedEmail(String email) async {
    await _prefs.setString(_keySavedEmail, email);
  }

  String? getSavedEmail() {
    return _prefs.getString(_keySavedEmail);
  }

  Future<void> clearSavedEmail() async {
    await _prefs.remove(_keySavedEmail);
  }

  // Locale
  Future<void> setLocale(String locale) async {
    await _prefs.setString(_keyLocale, locale);
  }

  String? getLocale() {
    return _prefs.getString(_keyLocale);
  }

  // Onboarding
  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_keyOnboardingCompleted, value);
  }

  bool getOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Clear all preferences (for logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
