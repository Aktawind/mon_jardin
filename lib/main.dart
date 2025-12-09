import 'package:flutter/material.dart';
import 'data/database_service.dart';
import 'services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/encyclopedia_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/screens/my_plants_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr_FR', null);

  final db = DatabaseService();
  await db.database; 
  
  final notifService = NotificationService();
  await notifService.init();
  await notifService.requestPermissions();
  await EncyclopediaService().load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Enlève le bandeau "Debug"
      title: 'Sève',

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en', ''), // Anglais, souvent laissé par défaut
        Locale('fr', 'FR'), // 🇫🇷 Le Français !
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00b894), // Vert d'eau
          secondary: const Color(0xFFfab1a0), // Rose pâle
        ),
        useMaterial3: true,
        // On force un peu le style de l'AppBar pour qu'il soit joli
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MyPlantsScreen(), // On lance l'écran d'accueil
    );
  }
}