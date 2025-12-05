import '../data/plant_data.dart'; // Pour accéder à getSpeciesData

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

  final String lifecycleStage; // 'seed' (graine), 'seedling' (semis), 'planted' (en place)
  final bool trackWatering;    // true = on gère, false = on ignore (ex: arbre dehors)
  final bool trackRepotting;  // true = on gère
  final bool trackFertilizer;  // true = on gère

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
    this.lifecycleStage = 'planted', // Par défaut, c'est une plante en pot
    this.trackWatering = true,       // Par défaut, on veut des notifs
    this.trackRepotting = true,
    this.trackFertilizer = true,
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
  
  // --- CALCUL INTELLIGENT FERTILISATION ---
  DateTime get nextFertilizingDate {
    // 1. Si fréquence 0, jamais
    if (fertilizerFreq <= 0) return DateTime(2100);

    // 2. Date théorique (Dernière fois + fréquence)
    // Si jamais fait, on dit 2 semaines après l'ajout
    DateTime baseDate = lastFertilized != null 
        ? lastFertilized!.add(Duration(days: fertilizerFreq))
        : dateAdded.add(const Duration(days: 14));

    // 3. Correction selon l'Encyclopédie (Hivernage)
    final speciesData = getSpeciesData(species);
    
    // Si on a des infos sur l'hivernage
    if (speciesData != null && speciesData.winteringMonths.isNotEmpty) {
      // Tant que la date tombe pendant le repos, on repousse au mois suivant
      while (speciesData.winteringMonths.contains(baseDate.month)) {
        // On passe au 1er du mois suivant
        // ex: Si on est le 15 Décembre et que Décembre est repos -> 1er Janvier
        // Si Janvier est aussi repos -> 1er Février...
        baseDate = DateTime(baseDate.year, baseDate.month + 1, 1);
      }
    }
    
    return baseDate;
  }

  // --- CALCUL INTELLIGENT REMPOTAGE ---
  DateTime get nextRepottingDate {
    if (repottingFreq <= 0) return DateTime(2100);

    // 1. Date théorique (ex: Date d'achat + 24 mois)
    DateTime baseDate = (lastRepotted ?? dateAdded);
    DateTime targetDate = DateTime(baseDate.year, baseDate.month + repottingFreq, baseDate.day);

    // 2. Correction selon l'Encyclopédie (Période idéale)
    final speciesData = getSpeciesData(species);

    if (speciesData != null && speciesData.repottingMonths.isNotEmpty) {
      // Tant que le mois cible N'EST PAS dans la liste idéale, on avance
      // ex: Si théorique = Novembre, mais idéal = [Mars, Avril]
      // -> On avance jusqu'à Mars de l'année suivante.
      
      // Sécurité anti-boucle infinie : on s'arrête si on a fait plus de 12 mois de recherche
      int safetyCounter = 0;
      while (!speciesData.repottingMonths.contains(targetDate.month) && safetyCounter < 12) {
        targetDate = DateTime(targetDate.year, targetDate.month + 1, 1);
        safetyCounter++;
      }
    }

    return targetDate;
  }

  // Jours restants
  int get daysUntilWatering => nextWateringDate.difference(DateTime.now()).inDays;
  // Note: Pour fertilisation/rempotage, on peut avoir des logiques similaires

  // LOGIQUE D'AFFICHAGE DU NOM
  // Si le nom est différent de l'espèce (surnom) -> "Pépette (Monstera)"
  // Sinon -> "Monstera"
  String get displayName {
    if (name == species) {
      return species;
    } else {
      return '$name ($species)';
    }
  }

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
      // Mapping V4
      dateAdded: DateTime.parse(map['date_added']),
      lastWatered: map['last_watered'] != null ? DateTime.parse(map['last_watered']) : null,
      lastFertilized: map['last_fertilized'] != null ? DateTime.parse(map['last_fertilized']) : null,
      lastRepotted: map['last_repotted'] != null ? DateTime.parse(map['last_repotted']) : null,
      // Mapping V5
      lifecycleStage: map['lifecycle_stage'] ?? 'planted',
      trackWatering: map['track_watering'] == 0 ? false : true,
      trackFertilizer: map['track_fertilizer'] == 0 ? false : true,
      trackRepotting: map['track_repotting'] == 0 ? false : true,
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
      // Mapping V4
      'date_added': dateAdded.toIso8601String(),
      'last_watered': lastWatered?.toIso8601String(),
      'last_fertilized': lastFertilized?.toIso8601String(),
      'last_repotted': lastRepotted?.toIso8601String(),
      // Mapping V5
      'lifecycle_stage': lifecycleStage,
      'track_watering': trackWatering ? 1 : 0,
      'track_fertilizer': trackFertilizer ? 1 : 0,
      'track_repotting': trackRepotting ? 1 : 0,
    };
  }
}