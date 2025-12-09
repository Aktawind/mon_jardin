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
  factory PlantSpeciesData.fromMergedJson({
    required String id,
    required Map<String, dynamic> core,
    required Map<String, dynamic> care,
    required List<String> tags,
  }) {
    // Note : On n'a plus besoin de parser 'info' ou 'calendar' séparément
    // car tu as tout mis à plat dans 'care' (ce qui est très bien).

    return PlantSpeciesData(
      species: core['species'],
      // Gestion des synonymes (Liste de String)
      synonyms: (core['synonyms'] as List?)?.map((e) => e.toString()).toList() ?? [],
      
      // Enums (Core)
      category: _parseEnum(PlantCategory.values, core['category']),
      
      // Enums (Care)
      cycle: _parseEnum(PlantCycle.values, care['cycle']),
      difficulty: _parseEnum(Difficulty.values, care['difficulty']),
      light: _parseEnum(LightLevel.values, care['light']),
      humidity: _parseEnum(HumidityNeed.values, care['humidity']),
      // Attention à la casse ici (snake_case vs camelCase)
      temperature: _parseEnum(TemperatureTolerance.values, care['temperature']),
      toxicity: _parseEnum(Toxicity.values, care['toxicity']),
      
      // Valeurs numériques
      waterSummer: care['water_summer'] ?? 7,
      waterWinter: care['water_winter'] ?? 14,
      fertilizeFreq: care['fertilize_freq'] ?? 30,
      repotFreq: care['repot_freq'] ?? 24,
      
      // Listes d'entiers
      sowingMonths: List<int>.from(care['sowing_months'] ?? []),
      plantingMonths: List<int>.from(care['planting_months'] ?? []),
      harvestMonths: List<int>.from(care['harvest_months'] ?? []),
      pruningMonths: List<int>.from(care['pruning_months'] ?? []),
      repottingMonths: List<int>.from(care['repotting_months'] ?? [3, 4, 5]),
      winteringMonths: List<int>.from(care['wintering_months'] ?? [11, 12, 1, 2]),
      
      // Textes
      soilInfo: care['soil'] ?? '',
      pruningInfo: care['pruning'] ?? '',
      
      // Tags (Nouveau !)
      // Il faudra ajouter le champ 'final List<String> tags;' dans la classe si tu veux l'utiliser
    );
  }

  // Helper pour convertir "indoor" -> PlantCategory.indoor
  static T _parseEnum<T>(List<T> values, String str) {
    return values.firstWhere(
      (e) => e.toString().split('.').last == str,
      orElse: () => values.first, // Fallback si erreur
    );
  }
}