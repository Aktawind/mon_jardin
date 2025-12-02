import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/plant.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialisation (à lancer au démarrage de l'app)
  Future<void> init() async {
    // Initialisation des fuseaux horaires
    tz.initializeTimeZones();

    // Config Android (on utilise l'icône par défaut de l'app)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Config iOS (simple pour l'instant)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Demander la permission (surtout pour Android 13+)
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  // Programmer une notification
  Future<void> schedulePlantNotification(Plant plant) async {
    // Calcul de la date : Prochain arrosage à 9h00 du matin
    
    final nextDate = plant.nextWateringDate;
    var scheduledDate = tz.TZDateTime(
      tz.local,
      nextDate.year,
      nextDate.month,
      nextDate.day,
      9, // Heure : 9h00
      0,
    );

    // Si la date calculée est déjà passée (ex: retard), on ne programme pas
    // ou on pourrait programmer pour demain matin. Ici on ignore si c'est passé.
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return; 
    }

    // L'ID de notif doit être un entier (int). 
    // Comme nos plantes ont un ID String (UUID), on utilise hashCode pour générer un entier unique.
    final notificationId = plant.id.hashCode;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Soif ! 🌿',
      '${plant.name} a besoin d\'eau aujourd\'hui.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_channel', // Id du canal
          'Arrosage', // Nom du canal visible par l'user
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
    
    print("Notification programmée pour ${plant.name} le $scheduledDate (ID: $notificationId)");
  }

  // Annuler une notification (si on supprime la plante ou on arrose avant)
  Future<void> cancelNotification(Plant plant) async {
    await flutterLocalNotificationsPlugin.cancel(plant.id.hashCode);
  }
}