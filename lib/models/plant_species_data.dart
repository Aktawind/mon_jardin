/*
* Modèle pour les données spécifiques à une espèce de plante.
* Contient des informations encyclopédiques et de soin.
* Utilisé pour enrichir les données des plantes individuelles.
*/

import 'enums.dart';


class PlantSpeciesData {
  final String species;
  final List<String> synonyms;
  final PlantCategory category;
  final PlantCycle cycle;
  final Difficulty difficulty;
  final LightLevel light;
  final HumidityNeed humidity;
  final TemperatureTolerance temperature;
  final Toxicity toxicity;
  final VegetableType? vegType;
  final LeafPersistence? persistence;
  final FoliageType? foliage;
  final PlantHeight? height;
  
  final int waterSummer;
  final int waterWinter;
  final int fertilizeFreq;
  final int repotFreq;
  
  final List<int> sowingMonths;
  final List<int> plantingMonths;
  final List<int> harvestMonths;
  final List<int> pruningMonths;
  final List<int> repottingMonths;
  final List<int> winteringMonths;
  
  final String soilInfo;
  final String pruningInfo;

  const PlantSpeciesData({
    required this.species,
    this.synonyms = const [],
    required this.category,
    required this.cycle,
    required this.difficulty,
    required this.light,
    required this.humidity,
    required this.temperature,
    required this.toxicity,
    this.persistence,
    this.height,
    this.vegType,
    this.foliage,
    required this.waterSummer,
    required this.waterWinter,
    required this.fertilizeFreq,
    required this.repotFreq,
    this.sowingMonths = const [],
    this.plantingMonths = const [],
    this.harvestMonths = const [],
    this.pruningMonths = const [],
    this.repottingMonths = const [],
    this.winteringMonths = const [],
    required this.soilInfo,
    required this.pruningInfo,
  });

  // Factory pour créer depuis le JSON
factory PlantSpeciesData.fromJson(Map<String, dynamic> json) {
    return PlantSpeciesData(

      // Enums
      species: json['species'] ?? 'Inconnue',
      category: _parseEnum(PlantCategory.values, json['category']),
      cycle: _parseEnum(PlantCycle.values, json['cycle']),
      difficulty: _parseEnum(Difficulty.values, json['difficulty']),
      light: _parseEnum(LightLevel.values, json['light']),
      humidity: _parseEnum(HumidityNeed.values, json['humidity']),
      // Attention à la casse ici (snake_case vs camelCase)
      temperature: _parseEnum(TemperatureTolerance.values, json['temperature']),
      toxicity: _parseEnum(Toxicity.values, json['toxicity']),
      vegType: _parseEnumNullable(VegetableType.values, json['vegType']),
      persistence: _parseEnumNullable(LeafPersistence.values, json['foliage']),
      foliage: _parseEnumNullable(FoliageType.values, json['esthetic']),
      height: _parseEnumNullable(PlantHeight.values, json['height']),
      
      // Valeurs numériques
      waterSummer: json['water_summer'] ?? 7,
      waterWinter: json['water_winter'] ?? 14,
      fertilizeFreq: json['fertilize_freq'] ?? 30,
      repotFreq: json['repot_freq'] ?? 24,
      
      // Listes d'entiers
      sowingMonths: List<int>.from(json['sowing_months'] ?? []),
      plantingMonths: List<int>.from(json['planting_months'] ?? []),
      harvestMonths: List<int>.from(json['harvest_months'] ?? []),
      pruningMonths: List<int>.from(json['pruning_months'] ?? []),
      repottingMonths: List<int>.from(json['repotting_months'] ?? [3, 4, 5]),
      winteringMonths: List<int>.from(json['wintering_months'] ?? [11, 12, 1, 2]),
      
      // Textes
      soilInfo: json['soil'] ?? '',
      pruningInfo: json['pruning'] ?? '',
      

    );
  }

  // Helper pour convertir "indoor" -> PlantCategory.indoor
  static T _parseEnum<T>(List<T> values, String str) {
    return values.firstWhere(
      (e) => e.toString().split('.').last == str,
      orElse: () => values.first, // Fallback si erreur
    );
  }

  static T? _parseEnumNullable<T>(List<T> values, String? str) {
    if (str == null || str.isEmpty) return null; // Si vide, on renvoie null proprement
    
    final cleanStr = str.trim().toLowerCase();
    try {
      return values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == cleanStr,
      );
    } catch (e) {
      return null; // Si pas trouvé, on renvoie null au lieu de planter
    }
  }
}