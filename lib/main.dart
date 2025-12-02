import 'package:flutter/material.dart';
import 'data/database_service.dart';
import 'ui/screens/home_screen.dart';
import 'services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr_FR', null);

  final db = DatabaseService();
  await db.database; 
  
  final notifService = NotificationService();
  await notifService.init();
  await notifService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Enlève le bandeau "Debug"
      title: 'Sève',
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
      home: const HomeScreen(), // On lance l'écran d'accueil
    );
  }
}