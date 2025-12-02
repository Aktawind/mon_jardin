import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyNotifyWater = 'notify_water';
  static const String keyNotifyFertilizer = 'notify_fertilizer';
  static const String keyNotifyRepot = 'notify_repot';

  // Sauvegarder
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Lire (par défaut true)
  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true; // Par défaut, tout est activé
  }
}