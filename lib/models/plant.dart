class Plant {
  final String id;
  final String name; // Le surnom (ou l'espèce si pas de surnom)
  final String species;
  final String location; // "Intérieur" ou "Extérieur"
  final String? room; // NOUVEAU : Salon, Cuisine, Jardin Sud...
  final String? photoPath;
  
  final int waterFrequencySummer;
  final int waterFrequencyWinter;
  final String? lightNeeds;
  
  final DateTime dateAdded;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.location,
    this.room, // Peut être vide
    this.photoPath,
    this.waterFrequencySummer = 7,
    this.waterFrequencyWinter = 14,
    this.lightNeeds,
    required this.dateAdded,
    this.lastWatered,
    this.lastFertilized,
  });

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      location: map['location'],
      room: map['room'], // Mapping du nouveau champ
      photoPath: map['photo_path'],
      waterFrequencySummer: map['water_freq_summer'],
      waterFrequencyWinter: map['water_freq_winter'],
      lightNeeds: map['light_needs'],
      dateAdded: DateTime.parse(map['date_added']),
      lastWatered: map['last_watered'] != null ? DateTime.parse(map['last_watered']) : null,
      lastFertilized: map['last_fertilized'] != null ? DateTime.parse(map['last_fertilized']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'location': location,
      'room': room, // Ajout
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