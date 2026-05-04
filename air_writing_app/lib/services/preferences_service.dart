import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola preferensi aplikasi menggunakan SharedPreferences
/// Digunakan untuk menyimpan data seperti last login, user preferences, dll.
class PreferencesService {
  static late SharedPreferences _prefs;
  static bool _initialized = false;

  // Keys untuk SharedPreferences
  static const String _lastLoginUserKey = 'last_login_user';
  static const String _appThemeKey = 'app_theme';
  static const String _appLanguageKey = 'app_language';

  /// Initialize SharedPreferences instance
  /// Harus dipanggil sekali di main.dart
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Check if initialized
  static bool get isInitialized => _initialized;

  /// Save last login username
  static Future<bool> setLastLoginUser(String username) async {
    return await _prefs.setString(_lastLoginUserKey, username);
  }

  /// Get last login username, null if tidak ada
  static String? getLastLoginUser() {
    return _prefs.getString(_lastLoginUserKey);
  }

  /// Clear last login user
  static Future<bool> clearLastLoginUser() async {
    return await _prefs.remove(_lastLoginUserKey);
  }

  /// Save app theme preference (0 = light, 1 = dark, 2 = system)
  static Future<bool> setThemeMode(int themeMode) async {
    return await _prefs.setInt(_appThemeKey, themeMode);
  }

  /// Get app theme preference
  static int getThemeMode() {
    return _prefs.getInt(_appThemeKey) ?? 0; // Default: light theme
  }

  /// Save app language preference (id = Indonesian, en = English)
  static Future<bool> setLanguage(String languageCode) async {
    return await _prefs.setString(_appLanguageKey, languageCode);
  }

  /// Get app language preference
  static String getLanguage() {
    return _prefs.getString(_appLanguageKey) ?? 'id'; // Default: Indonesian
  }

  /// Clear all preferences
  static Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
