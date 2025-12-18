/*
* Service pour gérer l'encyclopédie des plantes.
* Charge les données depuis un fichier JSON dans les assets.
*/

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/plant_species_data.dart';
import '../models/enums.dart';
import 'package:flutter/material.dart';

class EncyclopediaService {
  static final EncyclopediaService _instance = EncyclopediaService._internal();
  factory EncyclopediaService() => _instance;
  EncyclopediaService._internal();

  List<PlantSpeciesData> _plants = [];

  Future<void> load() async {
    try {
      final String response = await rootBundle.loadString('assets/plants_data.json');
      final dynamic data = json.decode(response);

      _plants = [];
        data.forEach((key, value) {
          // Si l'ID n'est pas dans l'objet, on peut l'injecter si besoin, 
          // mais PlantSpeciesData n'a pas forcément de champ 'id', juste 'species'.
          _plants.add(PlantSpeciesData.fromJson(value));
        });

      debugPrint("Encyclopédie chargée : ${_plants.length} plantes.");
    } catch (e) {
      debugPrint("Erreur fatale chargement encyclopédie : $e");
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

  // Récupération complète
  List<PlantSpeciesData> getAll() {
    return _plants;
  }
}