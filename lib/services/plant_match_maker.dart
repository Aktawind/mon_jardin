/*
* Service pour trouver des plantes correspondant à des critères donnés.
* Utilise les données de l'Encyclopédie.
* Permet de faire du "matching" entre les préférences utilisateur et les plantes disponibles.
*/

import '../models/enums.dart';
import '../models/plant_species_data.dart';
import 'encyclopedia_service.dart';

class PlantMatchCriteria {
  // Les critères peuvent être nuls (pas de préférence)
  PlantCategory? category; // Intérieur / Extérieur / Potager
  LightLevel? light;       // Luminosité dispo
  bool? lowMaintenance;    // Si vrai -> Cherche plantes faciles et peu d'eau
  bool? petSafe;           // Si vrai -> Cherche non toxique
  TemperatureTolerance? minTemp; // Pour l'extérieur (Rusticité)
  FoliageType? aesthetic;   // Fleur ou Vert
  PlantHeight? shape;       // Suspendu ou Sol
  LeafPersistence? leafPersistence; // Type de feuillage
  VegetableType? vegType;   // Type potager
  
  // Constructeur vide par défaut
  PlantMatchCriteria();
}

class PlantMatchMaker {
  
  List<PlantSpeciesData> findMatches(PlantMatchCriteria criteria) {
    // 1. On récupère toute la base
    // (Astuce : on peut ajouter une méthode getAll() dans EncyclopediaService 
    // ou utiliser search('') si getAll n'existe pas)
    List<PlantSpeciesData> allPlants = EncyclopediaService().getAll(); 

    return allPlants.where((p) => _matches(p, criteria)).toList();
  }

  bool _matches(PlantSpeciesData p, PlantMatchCriteria c) {
    // 1. Catégorie (Filtrage strict)
    if (c.category != null && p.category != c.category) return false;

    // 2. Lumière (Filtrage souple)
    // Si j'ai "Plein soleil", je peux accepter "Mi-ombre" ? Disons strict pour commencer.
    // Si l'utilisateur dit "Ombre" (low), on ne propose pas "Plein soleil" (direct).
    if (c.light != null) {
       // Logique simple : exact match
       if (p.light != c.light) return false;
       
       // Logique avancée possible : si j'ai "bright_ind", j'accepte "partial" ? 
       // À affiner selon tes retours.
    }

    // 3. Facilité / Arrosage (Low Maintenance)
    if (c.lowMaintenance == true) {
      // On veut : Facile ET (Arrosage faible OU moyen)
      if (p.difficulty == Difficulty.hard) return false;
      if (p.waterSummer < 7) return false; // Si faut arroser tous les 2 jours, c'est pas low maintenance (sauf potager)
    }

    // 4. Animaux (Pet Safe)
    if (c.petSafe == true) {
      if (p.toxicity == Toxicity.high) return false;
      // On accepte 'low' (irritant) ou 'none'. Si on veut strict -> p.toxicity != Toxicity.none return false;
    }

    // 5. Température (Pour l'extérieur)
    if (c.category == PlantCategory.outdoor && c.minTemp != null) {
      // Comparaison d'enum (ordre d'index : frost_tender < semi_hardy < hardy < very_hardy)
      // Si la plante est moins résistante que la température min de la région -> Rejet
      if (p.temperature.index < c.minTemp!.index) return false;
    }

    // 6. Esthétique (FoliageType)
    if (c.aesthetic != null && p.foliageType != c.aesthetic) return false;

    // 7. Forme (PlantHeight)
    if (c.shape != null && p.height != c.shape) return false;

    // 8. Feuillage (LeafPersistence)
    if (c.leafPersistence != null && p.leafPersistence != c.leafPersistence) return false;

    // 9. Type potager (VegetableType)
    if (c.vegType != null && p.vegetableType != c.vegType) return false;

    return true;
  }
}