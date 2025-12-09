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
  factory PlantSpeciesData.fromJson(Map<String, dynamic> json) {
    final care = json['care'];
    final cal = json['calendar'];
    final info = json['info'];

    return PlantSpeciesData(
      species: json['species'],
      synonyms: List<String>.from(json['synonyms'] ?? []),
      // Conversion des Strings JSON en Enums Dart
      category: _parseEnum(PlantCategory.values, json['category']),
      cycle: _parseEnum(PlantCycle.values, json['cycle']),
      difficulty: _parseEnum(Difficulty.values, json['difficulty']),
      light: _parseEnum(LightLevel.values, json['light']),
      humidity: _parseEnum(HumidityNeed.values, json['humidity']),
      temperature: _parseEnum(TemperatureTolerance.values, json['temperature']),
      toxicity: _parseEnum(Toxicity.values, json['toxicity']),
      
      waterSummer: care['water_summer'],
      waterWinter: care['water_winter'],
      fertilizeFreq: care['fertilize_freq'],
      repotFreq: care['repot_freq'],
      
      sowingMonths: List<int>.from(cal['sowing'] ?? []),
      plantingMonths: List<int>.from(cal['planting'] ?? []),
      harvestMonths: List<int>.from(cal['harvest'] ?? []),
      pruningMonths: List<int>.from(cal['pruning'] ?? []),
      repottingMonths: List<int>.from(cal['repotting'] ?? []),
      winteringMonths: List<int>.from(cal['wintering'] ?? []),
      
      soilInfo: info['soil'] ?? '',
      pruningInfo: info['pruning'] ?? '',
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