/*
* Service pour gérer l'encyclopédie des plantes.
* Charge les données depuis un fichier JSON dans les assets.
*/

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/plant_species_data.dart';
import '../models/enums.dart';

class EncyclopediaService {
  // Singleton
  static final EncyclopediaService _instance = EncyclopediaService._internal();
  factory EncyclopediaService() => _instance;
  EncyclopediaService._internal();

  List<PlantSpeciesData> _plants = [];

  // Chargement au démarrage
  Future<void> load() async {
    try {
      final String response = await rootBundle.loadString('assets/plants.json');
      final List<dynamic> data = json.decode(response);
      _plants = data.map((json) => PlantSpeciesData.fromJson(json)).toList();
      print("Encyclopédie chargée : ${_plants.length} plantes.");
    } catch (e) {
      print("Erreur chargement encyclopédie : $e");
    }
  }

  // Recherche
  List<PlantSpeciesData> search(String query) {
  return _plants.where((p) => 
      p.species.toLowerCase().contains(query.toLowerCase()) || 
      p.synonyms.any((s) => s.toLowerCase().contains(query.toLowerCase()))
  ).toList();
  }

  // Récupération par catégorie (trié)
  List<PlantSpeciesData> getByCategory(PlantCategory category) {
    final list = _plants.where((p) => p.category == category).toList();
    list.sort((a, b) => a.species.compareTo(b.species));
    return list;
  }

  // Récupération unique
  PlantSpeciesData? getData(String speciesName) {
    try {
      return _plants.firstWhere((p) => p.species.toLowerCase() == speciesName.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}