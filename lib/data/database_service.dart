import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant.dart';

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
      version: 3, 
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
        light_level TEXT,       -- Faible, Indirecte, Vive
        temperature_info TEXT,  -- Texte libre (ex: 18-24°C, éviter courants d'air)
        humidity_pref TEXT,     -- Normal, Humide (SDB)
        soil_type TEXT,         -- Drainant, Riche, Terre de bruyère...
        fertilizer_freq INTEGER,-- En jours (ex: 30 pour 1 mois). 0 = jamais
        last_fertilized TEXT,   -- Date
        repotting_freq INTEGER, -- En mois (ex: 24 pour 2 ans)
        last_repotted TEXT,     -- Date (ou date d'achat par défaut)
        pruning_info TEXT,      -- Conseils de taille
        date_added TEXT,
        last_watered TEXT
      )
    ''');
  }

  // Gestion des futures mises à jour (ex: passer de V1 à V2)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print("Mise à jour de la BDD : Ajout de la colonne 'room'");
      await db.execute("ALTER TABLE plants ADD COLUMN room TEXT");
    }

    // Migration V2 -> V3 (La grosse mise à jour)
    if (oldVersion < 3) {
      print("Mise à jour V3 : Ajout des infos encyclopédiques");
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

  // Met à jour la date d'arrosage à "Maintenant"
  Future<void> updatePlantWatering(String id) async {
    final db = await database;
    await db.update(
      'plants',
      {
        'last_watered': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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
    
    print("Apprentissage : Plante ${plant.name} ajustée de $currentFreq à $newFreq jours (${isWinter ? 'Hiver' : 'Été'})");
  }
}