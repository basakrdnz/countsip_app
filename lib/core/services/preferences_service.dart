import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences wrapper for app settings and user preferences
class PreferencesService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keySavedEmail = 'saved_email';
  static const String _keyLocale = 'locale';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  final SharedPreferences _prefs;
  static late PreferencesService _instance;
  static PreferencesService get instance => _instance;

  PreferencesService(this._prefs);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = PreferencesService(prefs);
  }

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

  // Search History
  static const String _keySearchHistory = 'recent_searches';
  
  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    List<String> history = getSearchHistory();
    history.remove(query); // Avoid duplicates
    history.insert(0, query); // Add to top
    if (history.length > 5) history = history.sublist(0, 5); // Keep last 5
    await _prefs.setStringList(_keySearchHistory, history);
  }

  Future<void> removeFromSearchHistory(String query) async {
    List<String> history = getSearchHistory();
    history.remove(query);
    await _prefs.setStringList(_keySearchHistory, history);
  }

  List<String> getSearchHistory() {
    return _prefs.getStringList(_keySearchHistory) ?? [];
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keySearchHistory);
  }
  
  // Quick Add Customization
  static const String _keyQuickAddIds = 'quick_add_ids';
  static const String _keyQuickAddConfigs = 'quick_add_configs';
  
  Future<void> setQuickAddIds(List<String> ids) async {
    await _prefs.setStringList(_keyQuickAddIds, ids);
  }
  
  List<String> getQuickAddIds() {
    return _prefs.getStringList(_keyQuickAddIds) ?? ['beer', 'wine', 'whiskey', 'cocktail'];
  }

  Future<void> setQuickAddConfigs(List<Map<String, dynamic>> configs) async {
    final encoded = configs.map((c) => json.encode(c)).toList();
    await _prefs.setStringList(_keyQuickAddConfigs, encoded);
  }

  List<Map<String, dynamic>> getQuickAddConfigs() {
    final encoded = _prefs.getStringList(_keyQuickAddConfigs);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      return encoded.map((s) => json.decode(s) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear all preferences (for logout)
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
