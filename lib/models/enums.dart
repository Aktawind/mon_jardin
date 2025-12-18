/*
  * lib/models/enums.dart
  * Définitions des énumérations utilisées dans l'application
  * Permet de standardiser les valeurs pour les besoins des plantes
  * Chaque énumération est accompagnée d'extensions pour faciliter l'affichage dans l'interface utilisateur.
*/

// Niveau de difficulté (pour le filtre débutant)
enum Difficulty {
  easy,         // Débutant / Indestructible
  medium,       // Demande un peu d'attention
  hard          // Expert / Capricieuse
}

// Exposition / Lumière
enum LightLevel {
  low,          // Ombre / Pénombre
  partial,      // Mi-ombre / Tamisé
  brightInd,    // Lumière vive sans soleil direct
  direct        // Plein soleil
}

// Besoin en eau
enum WaterNeed {
  low,          // Cactus / Succulente (laisser sécher complètement)
  medium,       // Laisser sécher en surface
  high          // Garder humide
}

// Humidité de l'air (Hygrométrie)
enum HumidityNeed {
  low,          // Supporte l'air sec
  medium,       // Normal (40-60%)
  high          // Tropical / Salle de bain (>60%)
}

// Toxicité (Guide d'achat - Chats/Chiens/Bébés)
enum Toxicity {
  none,         // Comestible ou sans danger
  low,          // Irritant si ingéré
  high          // Toxique / Mortel
}

// Type de feuillage (Esthétique)
enum LeafPersistence {
  evergreen,    // Persistant (reste vert l'hiver)
  deciduous,    // Caduc (perd ses feuilles)
  semiEvergreen // Semi-persistant (perd partiellement ses feuilles)
}

// Type d'intérêt visuel (Esthétique)
enum FoliageType {
  foliage,   // Plante verte (intérêt feuilles)
  flowering, // Plante fleurie
  fruit      // Plante fruitière
}

// Type de port / Forme (Suspendu, Arbre...)
enum PlantHeight {
  hanging,   // Suspendue / Retombante
  ground,    // Couvre-sol / Basse
  shrub,     // Buisson / Plante moyenne (sur table/sol)
  tree,      // Arbre / Grand format
  climber    // Grimpante
}

// Température / Rusticité
enum TemperatureTolerance {
  frostTender,  // Gélive (Doit rentrer l'hiver : Tropicales, Tomates)
  semiHardy,    // Rustique jusqu'à -5°C (Laurier rose, Olivier)
  hardy,        // Rustique jusqu'à -15°C (Rosier, Pommier)
  veryHardy     // Très rustique (-20°C et plus)
}

// Type de cycle (utile pour le potager et l'extérieur)
enum PlantCycle {
  annual,       // Vit 1 an (Tomate, Basilic, Pétunia) -> Meurt en hiver
  biennial,     // Vit 2 ans (Persil, Carotte si on garde les graines)
  perennial     // Vivace (Repousse chaque année : Menthe, Rosier)
}

// Catégorie Globale (Pour le filtre initial)
enum PlantCategory {
  indoor,       // Plante verte / Intérieur
  vegetable,    // Potager / Fruitier
  outdoor,      // Ornemental Extérieur (Arbre, Arbuste, Fleur)
  herb          // Aromatique
}

// Sous-catégorie Potager (Type précis)
enum VegetableType {
  leaf,      // Légume feuille (Salade, Epinard)
  fruit,     // Légume fruit (Tomate, Courgette)
  root,      // Légume racine (Carotte, Radis)
  herb,      // Aromatique
  fruitTree  // Petit fruitier (Fraise, Framboise)
}

// --- EXTENSIONS POUR L'AFFICHAGE ---
extension LeafPersistenceExtension on LeafPersistence {
  String get label {
    switch (this) {
      case LeafPersistence.evergreen: return "Persistant";
      case LeafPersistence.deciduous: return "Caduc";
      case LeafPersistence.semiEvergreen: return "Semi-persistant";
    }
  }
}

extension VegetableTypeExtension on VegetableType {
  String get label {
    switch (this) {
      case VegetableType.leaf: return "Légume feuille";
      case VegetableType.fruit: return "Légume fruit";
      case VegetableType.root: return "Légume racine";
      case VegetableType.herb: return "Aromatique";
      case VegetableType.fruitTree: return "Petit fruitier";
    }
  }
}

extension PlantHeightExtension on PlantHeight {
  String get label {
    switch (this) {
      case PlantHeight.hanging: return "Suspendue / Retombante";
      case PlantHeight.ground: return "Basse / Couvre-sol";
      case PlantHeight.shrub: return "Buisson / En pot";
      case PlantHeight.tree: return "Arbre / Grand format";
      case PlantHeight.climber: return "Grimpante";
    }
  }
}

extension FoliageTypeExtension on FoliageType {
  String get label {
    switch (this) {
      case FoliageType.foliage: return "Plante verte";
      case FoliageType.flowering: return "Plante fleurie";
      case FoliageType.fruit: return "Plante fruitière";
    }
  }
}

extension LightLevelExtension on LightLevel {
  String get label {
    switch (this) {
      case LightLevel.low: return "Ombre / Pénombre";
      case LightLevel.partial: return "Mi-ombre / Tamisé";
      case LightLevel.brightInd: return "Lumière vive (sans soleil direct)";
      case LightLevel.direct: return "Plein soleil";
    }
  }
}

extension WaterNeedExtension on WaterNeed {
  String get label {
    switch (this) {
      case WaterNeed.low: return "Faible (Laisser sécher complètement)";
      case WaterNeed.medium: return "Modéré (Laisser sécher en surface)";
      case WaterNeed.high: return "Élevé (Garder humide)";
    }
  }
}

extension HumidityNeedExtension on HumidityNeed {
  String get label {
    switch (this) {
      case HumidityNeed.low: return "Air sec toléré";
      case HumidityNeed.medium: return "Normal";
      case HumidityNeed.high: return "Humide";
    }
  }
}

extension DifficultyExtension on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy: return "Facile";
      case Difficulty.medium: return "Intermédiaire";
      case Difficulty.hard: return "Exigeante";
    }
  }
}

extension ToxicityExtension on Toxicity {
  String get label {
    switch (this) {
      case Toxicity.none: return "Non toxique";
      case Toxicity.low: return "Légèrement irritant";
      case Toxicity.high: return "Toxique (Attention aux enfants/animaux)";
    }
  }
}

extension TemperatureExtension on TemperatureTolerance {
  String get label {
    switch (this) {
      case TemperatureTolerance.frostTender: return "Craint le gel";
      case TemperatureTolerance.semiHardy: return "Rustique jusqu'à -5°C";
      case TemperatureTolerance.hardy: return "Rustique jusqu'à -15°C";
      case TemperatureTolerance.veryHardy: return "Très rustique (-20°C+)";
    }
  }
}