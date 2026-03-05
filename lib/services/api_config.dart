import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _kBaseUrlKey = 'api_base_url';

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kBaseUrlKey);
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrlKey, url.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBaseUrlKey);
  }
}
