import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class StorageServicePrefs {
  static SharedPreferences get prefs => StorageService.prefs;
}
