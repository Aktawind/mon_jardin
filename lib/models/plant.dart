class Plant {
  final String id;
  final String name;
  final String species;
  final String location;
  final String? room;
  final String? photoPath;
  
  // Arrosage
  final int waterFrequencySummer;
  final int waterFrequencyWinter;
  
  // Nouveaux champs encyclopédiques
  final String? lightLevel;      // "Faible", "Indirecte", "Vive"
  final String? temperatureInfo; // "15-25°C, craint le gel"
  final String? humidityPref;    // "Normal", "Élevée"
  final String? soilType;        // "Terreau plante verte", "Spécial cactées"
  final String? pruningInfo;     // "Couper les fleurs fanées"
  
  // Fertilisation
  final int fertilizerFreq;      // Jours (ex: 15 ou 30). 0 si pas besoin.
  
  // Rempotage
  final int repottingFreq;       // Mois (ex: 12, 24).
  
  // Suivi temporel
  final DateTime dateAdded;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;
  final DateTime? lastRepotted;  // Date du dernier rempotage (ou achat)

  Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.location,
    this.room,
    this.photoPath,
    this.waterFrequencySummer = 7,
    this.waterFrequencyWinter = 14,
    this.lightLevel,
    this.temperatureInfo,
    this.humidityPref,
    this.soilType,
    this.pruningInfo,
    this.fertilizerFreq = 30, // Par défaut 1 mois
    this.repottingFreq = 24,  // Par défaut 2 ans
    required this.dateAdded,
    this.lastWatered,
    this.lastFertilized,
    this.lastRepotted,
  });

   bool get _isWinter {
    final month = DateTime.now().month;
    return month >= 10 || month <= 3;
  }

  int get currentFrequency => _isWinter ? waterFrequencyWinter : waterFrequencySummer;

  DateTime get nextWateringDate {
    if (lastWatered == null) return dateAdded;
    return lastWatered!.add(Duration(days: currentFrequency));
  }
  
  // Calcul Fertilisation (On ne fertilise généralement pas en hiver !)
  DateTime get nextFertilizingDate {
    if (fertilizerFreq == 0) return DateTime(2100); // Jamais
    // Si on est en hiver, on repousse au printemps (ex: 1er Avril)
    if (_isWinter) {
      final now = DateTime.now();
      // Année actuelle ou suivante selon le mois
      final year = now.month > 3 ? now.year + 1 : now.year;
      return DateTime(year, 4, 1); 
    }
    
    if (lastFertilized == null) return dateAdded.add(const Duration(days: 14)); // 2 semaines après achat
    return lastFertilized!.add(Duration(days: fertilizerFreq));
  }

  // Calcul Rempotage
  DateTime get nextRepottingDate {
    // Base : dernier rempotage ou date d'ajout
    final baseDate = lastRepotted ?? dateAdded;
    // On ajoute le nombre de mois
    final nextDate = DateTime(baseDate.year, baseDate.month + repottingFreq, baseDate.day);
    return nextDate;
  }

  // Jours restants
  int get daysUntilWatering => nextWateringDate.difference(DateTime.now()).inDays;
  // Note: Pour fertilisation/rempotage, on peut avoir des logiques similaires


  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      location: map['location'],
      room: map['room'],
      photoPath: map['photo_path'],
      waterFrequencySummer: map['water_freq_summer'] ?? 7,
      waterFrequencyWinter: map['water_freq_winter'] ?? 14,
      // Mapping V3
      lightLevel: map['light_level'],
      temperatureInfo: map['temperature_info'],
      humidityPref: map['humidity_pref'],
      soilType: map['soil_type'],
      pruningInfo: map['pruning_info'],
      fertilizerFreq: map['fertilizer_freq'] ?? 30,
      repottingFreq: map['repotting_freq'] ?? 24,
      
      dateAdded: DateTime.parse(map['date_added']),
      lastWatered: map['last_watered'] != null ? DateTime.parse(map['last_watered']) : null,
      lastFertilized: map['last_fertilized'] != null ? DateTime.parse(map['last_fertilized']) : null,
      lastRepotted: map['last_repotted'] != null ? DateTime.parse(map['last_repotted']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'location': location,
      'room': room,
      'photo_path': photoPath,
      'water_freq_summer': waterFrequencySummer,
      'water_freq_winter': waterFrequencyWinter,
      // Mapping V3
      'light_level': lightLevel,
      'temperature_info': temperatureInfo,
      'humidity_pref': humidityPref,
      'soil_type': soilType,
      'pruning_info': pruningInfo,
      'fertilizer_freq': fertilizerFreq,
      'repotting_freq': repottingFreq,
      
      'date_added': dateAdded.toIso8601String(),
      'last_watered': lastWatered?.toIso8601String(),
      'last_fertilized': lastFertilized?.toIso8601String(),
      'last_repotted': lastRepotted?.toIso8601String(),
    };
  }
}