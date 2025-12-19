/*
* Service pour gérer les notifications locales.
* Utilise le package flutter_local_notifications.
* Permet de programmer des rappels pour l'entretien des plantes.
*/

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz; 
import '../models/plant.dart';
import 'preferences_service.dart';
import 'package:flutter/material.dart';
import '../data/database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. On charge la base de données des fuseaux horaires
    tz.initializeTimeZones();
    
    // 2. ON FORCE LE FUSEAU HORAIRE (C'est la clé du problème)
    // Pour une appli perso, on peut mettre 'Europe/Paris' en dur.
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    } catch (e) {
      // Fallback par sécurité
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  // Méthode principale à appeler de partout
  Future<void> scheduleAllNotifications(Plant plant) async {
    await _scheduleWater(plant);
    await _scheduleFertilizer(plant);
    await _scheduleRepot(plant);
  }

  // 1. ARROSAGE
  Future<void> _scheduleWater(Plant plant) async {
    final prefs = PreferencesService();
    if (!await prefs.getBool(PreferencesService.keyNotifyWater)) return;

    final nextDate = plant.nextWateringDate;
    if (_isDateInPast(nextDate)) return;

    await _scheduleSpecific(
      plant: plant,
      typeKey: 'water', // Pour l'ID unique
      title: 'Rappel d\'arrosage 💧',
      body: '${plant.displayName} a besoin d\'eau.',
      date: nextDate,
    );
  }

  // 2. ENGRAIS
  Future<void> _scheduleFertilizer(Plant plant) async {
    // Si la plante n'a pas besoin d'engrais (freq = 0), on sort
    if (plant.fertilizerFreq <= 0) return;

    final prefs = PreferencesService();
    if (!await prefs.getBool(PreferencesService.keyNotifyFertilizer)) return;

    final nextDate = plant.nextFertilizingDate;
    if (_isDateInPast(nextDate)) return;

    await _scheduleSpecific(
      plant: plant,
      typeKey: 'fert',
      title: 'Rappel de fertilisation 🌱',
      body: 'C\'est l\'heure de l\'engrais pour ${plant.displayName}.',
      date: nextDate,
    );
  }

  // 3. REMPOTAGE
  Future<void> _scheduleRepot(Plant plant) async {
    if (plant.repottingFreq <= 0) return;

    final prefs = PreferencesService();
    if (!await prefs.getBool(PreferencesService.keyNotifyRepot)) return;

    final nextDate = plant.nextRepottingDate;
    if (_isDateInPast(nextDate)) return;

    await _scheduleSpecific(
      plant: plant,
      typeKey: 'repot',
      title: 'Rappel de rempotage 🪴',
      body: 'Pensez à rempoter ${plant.displayName} cette année.',
      date: nextDate,
    );
  }

  // Méthode générique pour programmer
  Future<void> _scheduleSpecific({
    required Plant plant,
    required String typeKey, // 'water', 'fert', 'repot'
    required String title,
    required String body,
    required DateTime date,
  }) async {
    
    // ASTUCE : On combine l'ID de la plante et le type pour avoir un ID unique par action
    // ex: "uuid-de-la-plante_water" -> HashCode 12345
    // ex: "uuid-de-la-plante_fert"  -> HashCode 67890
    final uniqueId = '${plant.id}_$typeKey'.hashCode;
    final time = await PreferencesService().getNotificationTime();


    // On fixe l'heure à 9h00 du matin
    var scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour, 
      time.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      uniqueId,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'care_channel', 
          'Soin des plantes',
          channelDescription: 'Notifications d\'entretien',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    debugPrint("PROGRAMMÉ ($typeKey) pour ${plant.displayName} le $scheduledDate");
  }

  // Annuler TOUTES les notifs d'une plante (quand on la supprime)
  Future<void> cancelAllNotifications(Plant plant) async {
    await flutterLocalNotificationsPlugin.cancel('${plant.id}_water'.hashCode);
    await flutterLocalNotificationsPlugin.cancel('${plant.id}_fert'.hashCode);
    await flutterLocalNotificationsPlugin.cancel('${plant.id}_repot'.hashCode);
  }

  bool _isDateInPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Reprogramme TOUTES les plantes (lourd mais nécessaire après un changement d'heure)
  Future<void> rescheduleAll() async {
    final plants = await DatabaseService().getPlants();
    
    // On annule tout d'abord pour être propre
    await flutterLocalNotificationsPlugin.cancelAll();

    for (var plant in plants) {
      await scheduleAllNotifications(plant);
    }
    debugPrint("Toutes les notifications ont été reprogrammées.");
  }
}