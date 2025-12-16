/*
* Service pour gérer les préférences utilisateur.
* Utilise le package shared_preferences.
*/

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PreferencesService {
  static const String keyNotifyWater = 'notify_water';
  static const String keyNotifyFertilizer = 'notify_fertilizer';
  static const String keyNotifyRepot = 'notify_repot';
  static const String keyNotifHour = 'notif_hour';
  static const String keyNotifMinute = 'notif_minute';

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

  Future<TimeOfDay> getNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getInt(keyNotifHour) ?? 9;
    final m = prefs.getInt(keyNotifMinute) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyNotifHour, time.hour);
    await prefs.setInt(keyNotifMinute, time.minute);
  }
}