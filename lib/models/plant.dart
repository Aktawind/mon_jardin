class Plant {
  final String id; // UUID pour future synchro
  final String name; // Surnom (ex: "Pépette")
  final String species; // Espèce (ex: "Monstera")
  final String location; // "indoor" ou "outdoor"
  final String? photoPath; // Chemin vers la photo locale
  
  // Besoins (pour le futur algo de recommandation et soin)
  final int waterFrequencySummer; // en jours
  final int waterFrequencyWinter; // en jours
  final String? lightNeeds; // "low", "medium", "high"
  
  // État actuel
  final DateTime dateAdded;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.location,
    this.photoPath,
    this.waterFrequencySummer = 7, // Valeur par défaut
    this.waterFrequencyWinter = 14,
    this.lightNeeds,
    required this.dateAdded,
    this.lastWatered,
    this.lastFertilized,
  });

  // Conversion de la BDD vers l'objet Dart
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      location: map['location'],
      photoPath: map['photo_path'],
      waterFrequencySummer: map['water_freq_summer'],
      waterFrequencyWinter: map['water_freq_winter'],
      lightNeeds: map['light_needs'],
      dateAdded: DateTime.parse(map['date_added']),
      lastWatered: map['last_watered'] != null ? DateTime.parse(map['last_watered']) : null,
      lastFertilized: map['last_fertilized'] != null ? DateTime.parse(map['last_fertilized']) : null,
    );
  }

  // Conversion de l'objet Dart vers la BDD
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'location': location,
      'photo_path': photoPath,
      'water_freq_summer': waterFrequencySummer,
      'water_freq_winter': waterFrequencyWinter,
      'light_needs': lightNeeds,
      'date_added': dateAdded.toIso8601String(),
      'last_watered': lastWatered?.toIso8601String(),
      'last_fertilized': lastFertilized?.toIso8601String(),
    };
  }
}