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
  LeafPersistence? persistence; // Type de feuillage
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

    if (p.species == "Rhododendron") {
  print("RHODO DEBUG:");
  print("- Cat: ${p.category} vs ${c.category}");
  print("- Light: ${p.light} vs ${c.light}");
  print("- Temp: ${p.temperature} vs ${c.minTemp}"); // C'est souvent lui le coupable !
  print("- Esthetic: ${p.foliage} vs ${c.aesthetic}"); // Attention à la confusion foliage/aesthetic
}
    // 1. Catégorie (Filtrage strict)
    if (c.category != null && p.category != c.category) return false;

    // 2. Lumière (Filtrage souple)
    // Si j'ai "Plein soleil", je peux accepter "Mi-ombre" ? Disons strict pour commencer.
    // Si l'utilisateur dit "Ombre" (low), on ne propose pas "Plein soleil" (direct).
    // Scénario A : Je veux du soleil.
       if (c.light == LightLevel.direct) {
          // On accepte direct OU brightInd (car brightInd c'est déjà très lumineux)
          if (p.light != LightLevel.direct && p.light != LightLevel.brightInd) return false;
       }
       
       // Scénario B : Je veux de l'ombre (Low).
       else if (c.light == LightLevel.low) {
          // On accepte low OU partial
          if (p.light != LightLevel.low && p.light != LightLevel.partial) return false;
       }
       
       // Scénario C : Cas exact pour les autres
       else {
          if (p.light != c.light) return false;
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
    if (c.aesthetic != null && p.foliage != c.aesthetic) return false;

    // 7. Forme (PlantHeight)
    if (c.shape != null && p.height != c.shape) return false;

    // 8. Feuillage (LeafPersistence)
    if (c.persistence != null && p.persistence != c.persistence) return false;

    // 9. Type potager (VegetableType)
    if (c.vegType != null && p.vegType != c.vegType) return false;

    return true;
  }
}