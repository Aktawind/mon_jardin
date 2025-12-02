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
      version: 2, 
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
        light_needs TEXT,
        date_added TEXT,
        last_watered TEXT,
        last_fertilized TEXT
      )
    ''');
    print("Base de données créée avec la table Plants");
  }

  // Gestion des futures mises à jour (ex: passer de V1 à V2)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      print("Mise à jour de la BDD : Ajout de la colonne 'room'");
      await db.execute("ALTER TABLE plants ADD COLUMN room TEXT");
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
}