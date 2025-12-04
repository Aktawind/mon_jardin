import '../models/plant_species_data.dart';
import 'encyclopedia/indoor_plants.dart';
import 'encyclopedia/outdoor_plants.dart';
import 'encyclopedia/vegetable_plants.dart';

// On exporte le modèle pour que les autres fichiers n'aient pas besoin de l'importer manuellement
export '../models/plant_species_data.dart'; 

// On combine tout dans une seule "Grande Encyclopédie" pour la recherche
final List<PlantSpeciesData> encyclopedia = [
  ...indoorPlants,
  ...outdoorPlants,
  ...vegetablePlants,
];

// Helper pour trouver les infos
PlantSpeciesData? getSpeciesData(String name) {
  try {
    return encyclopedia.firstWhere(
      (e) => e.species.toLowerCase() == name.toLowerCase()
    );
  } catch (e) {
    return null;
  }
}

// Helper optionnel : si plus tard on veut filtrer par catégorie
List<PlantSpeciesData> getIndoorOnly() => indoorPlants;
List<PlantSpeciesData> getOutdoorOnly() => outdoorPlants;
List<PlantSpeciesData> getVegetablesOnly() => vegetablePlants;