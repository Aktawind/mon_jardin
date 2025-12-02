import 'package:flutter/material.dart';
import 'data/database_service.dart';
import 'ui/screens/home_screen.dart'; // Importe le nouvel écran

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();
  await db.database; 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Enlève le bandeau "Debug"
      title: 'Mon Jardin',
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