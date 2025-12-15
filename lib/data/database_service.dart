/*
  * Service de gestion de la base de données SQLite
  * Utilise le package sqflite
  * Gère la création, les mises à jour et les opérations CRUD sur les plantes, événements et photos de plantes. 
  * Implémente un singleton pour s'assurer qu'une seule instance de la base de données est ouverte.
*/

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant.dart';
import '../models/plant_event.dart';
import '../models/plant_photo.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  // Singleton : on s'assure qu'il n'y a qu'une seule instance de la BDD ouverte
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mon_jardin.db');

    // On ouvre la base. Si la version change, on appelle onUpgrade
    return await openDatabase(
      path,
      version: 6, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Création initiale des tables (Version 1)
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants(
        id TEXT PRIMARY KEY,
        name TEXT,
        species TEXT,
        location TEXT,
        room TEXT,
        photo_path TEXT,
        water_freq_summer INTEGER,
        water_freq_winter INTEGER,
        light_level TEXT,       
        temperature_info TEXT,  
        humidity_pref TEXT,    
        soil_type TEXT,        
        fertilizer_freq INTEGER,
        last_fertilized TEXT,   
        repotting_freq INTEGER, 
        last_repotted TEXT,     
        pruning_info TEXT,      
        date_added TEXT,        
        last_watered TEXT,    
        lifecycle_stage TEXT,
        track_watering INTEGER,
        track_repotting INTEGER,
        track_fertilizer INTEGER
      )
    ''');

    // Création table events
    await db.execute('''
      CREATE TABLE events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plant_id TEXT,
        type TEXT,
        date TEXT,
        note TEXT,
        FOREIGN KEY(plant_id) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');

    // Table Photos (Journal)
    await db.execute('''
      CREATE TABLE plant_photos(
        id TEXT PRIMARY KEY,
        plant_id TEXT,
        path TEXT,
        date TEXT,
        note TEXT,
        FOREIGN KEY(plant_id) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');
  }

  // Gestion des futures mises à jour (ex: passer de V1 à V2)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE plants ADD COLUMN room TEXT");
    }

    // Migration V2 -> V3 (La grosse mise à jour)
    if (oldVersion < 3) {
      // SQLite ne permet pas d'ajouter plusieurs colonnes en une seule ligne ALTER, il faut les faire une par une
      await db.execute("ALTER TABLE plants ADD COLUMN light_level TEXT");
      await db.execute("ALTER TABLE plants ADD COLUMN temperature_info TEXT");
      await db.execute("ALTER TABLE plants ADD COLUMN humidity_pref TEXT");
      await db.execute("ALTER TABLE plants ADD COLUMN soil_type TEXT");
      await db.execute("ALTER TABLE plants ADD COLUMN fertilizer_freq INTEGER DEFAULT 30"); // Par défaut 1 mois
      await db.execute("ALTER TABLE plants ADD COLUMN repotting_freq INTEGER DEFAULT 24");  // Par défaut 2 ans
      await db.execute("ALTER TABLE plants ADD COLUMN last_repotted TEXT");
      await db.execute("ALTER TABLE plants ADD COLUMN pruning_info TEXT");
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE events(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plant_id TEXT,
          type TEXT,
          date TEXT,
          note TEXT
        )
      ''');
    }

    if (oldVersion < 5) {
      // 1. Ajout des colonnes
      await db.execute("ALTER TABLE plants ADD COLUMN lifecycle_stage TEXT DEFAULT 'planted'");
      await db.execute("ALTER TABLE plants ADD COLUMN track_watering INTEGER DEFAULT 1");
      await db.execute("ALTER TABLE plants ADD COLUMN track_fertilizer INTEGER DEFAULT 1");
      
      // 2. Création table photos
      await db.execute('''
        CREATE TABLE plant_photos(
          id TEXT PRIMARY KEY,
          plant_id TEXT,
          path TEXT,
          date TEXT,
          note TEXT
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute("ALTER TABLE plants ADD COLUMN track_repotting INTEGER DEFAULT 1");
    }
  }

  // --- Méthodes CRUD de base (Create, Read) ---
  Future<void> insertPlant(Plant plant) async {
    final db = await database;
    await db.insert(
      'plants', 
      plant.toMap(), 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<List<Plant>> getPlants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('plants');
    return List.generate(maps.length, (i) => Plant.fromMap(maps[i]));
  }

  // Valider l'arrosage
  Future<void> updatePlantWatering(String id) async {
    final db = await database;
    final now = DateTime.now();

    // 1. Mise à jour de la plante
    await db.update(
      'plants',
      {'last_watered': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    // 2. AJOUT HISTORIQUE   
    await logEvent(PlantEvent(
      plantId: id,
      type: 'water',
      date: now,
    ));
  }

  // Valider la fertilisation
  Future<void> updatePlantFertilizing(String id) async {
    final db = await database;
    final now = DateTime.now();

    await db.update(
      'plants',
      {'last_fertilized': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    await logEvent(PlantEvent(
      plantId: id,
      type: 'fertilizer', 
      date: now,
    ));
  }

  // Valider le rempotage
  Future<void> updatePlantRepotting(String id) async {
    final db = await database;
    final now = DateTime.now();

    await db.update(
      'plants',
      {'last_repotted': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    await logEvent(PlantEvent(
      plantId: id,
      type: 'repot',
      date: now,
    ));
  }

  // Mettre à jour toutes les infos d'une plante
  Future<void> updatePlant(Plant plant) async {
    final db = await database;
    await db.update(
      'plants',
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  // Supprimer une plante
  Future<void> deletePlant(String id) async {
    final db = await database;
    await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Ajuste la fréquence d'une plante (Apprentissage)
  // daysAdjustment : +1 (ralentir) ou -1 (accélérer)
  Future<void> adjustPlantFrequency(Plant plant, int daysAdjustment) async {
    final db = await database;
    
    // On détermine si on touche à l'été ou l'hiver
    final isWinter = DateTime.now().month >= 10 || DateTime.now().month <= 3;
    
    // On calcule la nouvelle valeur
    int currentFreq = isWinter ? plant.waterFrequencyWinter : plant.waterFrequencySummer;
    int newFreq = currentFreq + daysAdjustment;
    
    // Sécurité : pas moins de 1 jour, pas plus de 60 jours (pour éviter les bugs)
    if (newFreq < 1) newFreq = 1;
    if (newFreq > 60) newFreq = 60;

    // On prépare la mise à jour
    Map<String, dynamic> updateData = {};
    if (isWinter) {
      updateData['water_freq_winter'] = newFreq;
    } else {
      updateData['water_freq_summer'] = newFreq;
    }

    await db.update(
      'plants',
      updateData,
      where: 'id = ?',
      whereArgs: [plant.id],
    );
    
    debugPrint("Apprentissage : Plante ${plant.name} ajustée de $currentFreq à $newFreq jours (${isWinter ? 'Hiver' : 'Été'})");
  }

  Future<void> logEvent(PlantEvent event) async {
    final db = await database;
    
    // 1. On insère le nouvel événement
    await db.insert('events', event.toMap());

    // 2. On définit la limite selon le type
    int limit = 10; // Par défaut (Arrosage)
    if (event.type == 'fertilizer') limit = 5;
    if (event.type == 'repot') limit = 2;
    if (event.type == 'prune') limit = 5;

    // 3. NETTOYAGE : On supprime les vieux enregistrements en trop
    await db.execute('''
      DELETE FROM events 
      WHERE plant_id = ? AND type = ? 
      AND id NOT IN (
        SELECT id FROM events 
        WHERE plant_id = ? AND type = ? 
        ORDER BY date DESC 
        LIMIT ?
      )
    ''', [event.plantId, event.type, event.plantId, event.type, limit]);
  }

  // Récupérer l'historique d'une plante
  Future<List<PlantEvent>> getEventsForPlant(String plantId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'date DESC', // Du plus récent au plus vieux
    );
    return List.generate(maps.length, (i) => PlantEvent.fromMap(maps[i]));
  }

  // Méthodes CRUD pour les photos
  // Ajouter une photo au journal
  Future<void> addPhoto(PlantPhoto photo) async {
    final db = await database;
    await db.insert('plant_photos', photo.toMap());
  }

  // Récupérer les photos d'une plante (du plus récent au plus vieux)
  Future<List<PlantPhoto>> getPhotosForPlant(String plantId) async {
    final db = await database;
    final maps = await db.query(
      'plant_photos',
      where: 'plant_id = ?',
      whereArgs: [plantId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => PlantPhoto.fromMap(maps[i]));
  }

  // Supprimer une photo
  Future<void> deletePhoto(String photoId) async {
    final db = await database;
    await db.delete('plant_photos', where: 'id = ?', whereArgs: [photoId]);
  }

  // Supprimer un événement historique
  Future<void> deleteEvent(int eventId) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
  }

  // Mettre à jour une photo (ex: changer la date)
  Future<void> updatePhoto(PlantPhoto photo) async {
    final db = await database;
    await db.update(
      'plant_photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null; // Important pour forcer la réouverture après
  }
}