import '../models/plant_species_data.dart';
import 'encyclopedia/indoor_plants.dart';
import 'encyclopedia/outdoor_plants.dart';
import 'encyclopedia/vegetable_plants.dart';

export '../models/plant_species_data.dart'; 

// La Grande Encyclopédie (pour la recherche inversée par nom si besoin)
final List<PlantSpeciesData> encyclopedia = [
  ...indoorPlants,
  ...outdoorPlants,
  ...vegetablePlants,
];

// Helper pour récupérer une plante par son nom (parcourt tout)
PlantSpeciesData? getSpeciesData(String name) {
  try {
    return encyclopedia.firstWhere(
      (e) => e.species.toLowerCase() == name.toLowerCase()
    );
  } catch (e) {
    return null;
  }
}

// --- ACCESSEURS TRIES PAR ORDRE ALPHABETIQUE ---

List<PlantSpeciesData> getIndoorSorted() {
  final list = List<PlantSpeciesData>.from(indoorPlants);
  list.sort((a, b) => a.species.compareTo(b.species));
  return list;
}

List<PlantSpeciesData> getOutdoorSorted() {
  final list = List<PlantSpeciesData>.from(outdoorPlants);
  list.sort((a, b) => a.species.compareTo(b.species));
  return list;
}

List<PlantSpeciesData> getVegetablesSorted() {
  final list = List<PlantSpeciesData>.from(vegetablePlants);
  list.sort((a, b) => a.species.compareTo(b.species));
  return list;
}