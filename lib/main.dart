import 'package:flutter/material.dart';
import 'data/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Petit test pour initialiser la DB au démarrage
  final db = DatabaseService();
  await db.database; 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon Jardin',
      theme: ThemeData(
        // Ta palette de couleurs : Vert d'eau et Rose pâle
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00b894), // Vert d'eau approximatif
          secondary: const Color(0xFFfab1a0), // Rose pâle
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text("Initialisation terminée.\nBase de données prête."),
        ),
      ),
    );
  }
}