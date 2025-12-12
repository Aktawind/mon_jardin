import 'package:flutter/material.dart';
import '../../models/plant_species_data.dart';
import '../../models/enums.dart';

// Ta fonction (rendue globale)
  IconData getPlantIcon(PlantSpeciesData data) {
  // 1. Potager
  if (data.category == PlantCategory.vegetable) {
    if (data.vegType == VegetableType.fruit) return Icons.eco; 
    if (data.vegType == VegetableType.root) return Icons.eco; 
    if (data.vegType == VegetableType.herb) return Icons.grass; 
    return Icons.eco; // Défaut légume
  }

  // 2. Extérieur
  if (data.category == PlantCategory.outdoor) {
    if (data.height == PlantHeight.tree) return Icons.park; // Arbre
    if (data.foliage == FoliageType.flowering) return Icons.local_florist; // Fleur
    return Icons.forest; // Arbuste/Autre
  }

  // 3. Intérieur
  if (data.foliage == FoliageType.flowering) return Icons.local_florist; // Fleurie
  if (data.height == PlantHeight.hanging) return Icons.filter_vintage; // Suspendue (approximatif)
  
  return Icons.filter_vintage; // Défaut plante verte (Feuille)
}

// Tu peux aussi y mettre ton générateur de couleurs
Color getStringToColor(String str) {
  int hash = 0;
  for (int i = 0; i < str.length; i++) {
    hash = str.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final double hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1.0, hue, 0.6, 0.85).toColor(); 
}