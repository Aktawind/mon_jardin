import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz; // Important : pour charger la base de données des heures
import 'package:timezone/timezone.dart' as tz;   // Important : pour utiliser les types
import '../models/plant.dart';
import 'preferences_service.dart';

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
      print("Erreur fuseau : $e");
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

  Future<void> schedulePlantNotification(Plant plant) async {
    // 1. Vérification des préférences
    final prefs = PreferencesService();
    final canNotifyWater = await prefs.getBool(PreferencesService.keyNotifyWater);

    // Si l'utilisateur a désactivé les notifs d'arrosage, on arrête tout ici.
    if (!canNotifyWater) {
      print("Notif annulée par les paramètres (Arrosage OFF)");
      // Optionnel : on pourrait aussi annuler une notif existante ici
      await cancelNotification(plant);
      return;
    }

    final nextDate = plant.nextWateringDate;
    // On crée la date précise à 9h00 du matin
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nextDate.year,
      nextDate.month,
      nextDate.day,
      9, 
      0,
    );
    // Si 9h00 est déjà passé aujourd'hui, on pourrait vouloir programmer pour demain
    // Mais ici on garde simple.

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print("Date passée, pas de notif");
      return; 
    }

    final notificationId = plant.id.hashCode;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Soif ! 🌿',
      '${plant.name} a besoin d\'eau !',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_channel',
          'Arrosage',
          channelDescription: 'Rappels pour arroser les plantes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    print("PROGRAMMÉ pour : $scheduledDate (Heure locale)");
  }
  
  // Fonction pour annuler (utile plus tard)
  Future<void> cancelNotification(Plant plant) async {
    await flutterLocalNotificationsPlugin.cancel(plant.id.hashCode);
  }
}