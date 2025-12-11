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
      // 1. Chargement parallèle
      final responses = await Future.wait([
        rootBundle.loadString('assets/plants_core.json'),
        rootBundle.loadString('assets/plants_care.json'),
        rootBundle.loadString('assets/plants_tags.json'),
      ]);

      final coreMap = json.decode(responses[0]) as Map<String, dynamic>;
      final careMap = json.decode(responses[1]) as Map<String, dynamic>;
      final tagsMap = json.decode(responses[2]) as Map<String, dynamic>;

      List<PlantSpeciesData> tempList = [];

      // 2. Fusion
      coreMap.forEach((id, coreData) {
        final careData = careMap[id] ?? {};
        final tagsData = tagsMap[id] ?? {};

        try {
          tempList.add(PlantSpeciesData.fromMergedJson(
            id: id, // On passe l'ID si on veut le stocker, sinon utile pour debug
            core: coreData,
            care: careData,
            tags: tagsData,
          ));
        } catch (e) {
          debugPrint("Erreur parsing plante $id (${coreData['species']}) : $e");
        }
      });

      _plants = tempList;
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