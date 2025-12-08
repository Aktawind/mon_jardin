// Niveau de difficulté (pour le filtre débutant)
enum Difficulty {
  easy,   // Débutant / Indestructible
  medium, // Demande un peu d'attention
  hard    // Expert / Capricieuse
}

// Exposition / Lumière
enum LightLevel {
  low,        // Ombre / Pénombre (Nord)
  partial,    // Mi-ombre / Tamisé (Est/Ouest)
  bright_ind, // Lumière vive sans soleil direct (Sud voilé)
  direct      // Plein soleil (Sud direct)
}

// Besoin en eau (Fréquence théorique globale)
enum WaterNeed {
  low,    // Cactus / Succulente (laisser sécher complètement)
  medium, // Laisser sécher en surface
  high    // Garder humide (Terre de bruyère, potager)
}

// Humidité de l'air (Hygrométrie)
enum HumidityNeed {
  low,    // Supporte l'air sec
  medium, // Normal (40-60%)
  high    // Tropical / Salle de bain (>60%)
}

// Toxicité (Guide d'achat - Chats/Chiens/Bébés)
enum Toxicity {
  none,   // Comestible ou sans danger
  low,    // Irritant si ingéré
  high    // Toxique / Mortel
}

// Type de feuillage (Esthétique)
enum FoliageType {
  evergreen, // Persistant (reste vert l'hiver)
  deciduous, // Caduc (perd ses feuilles)
  flowering  // À fleurs
}

// Température / Rusticité (Zones USDA simplifiées)
enum TemperatureTolerance {
  frost_tender, // Gélive (Doit rentrer l'hiver : Tropicales, Tomates)
  semi_hardy,   // Rustique jusqu'à -5°C (Laurier rose, Olivier)
  hardy,        // Rustique jusqu'à -15°C (Rosier, Pommier)
  very_hardy    // Très rustique (-20°C et plus)
}

// Type de cycle (utile pour le potager et l'extérieur)
enum PlantCycle {
  annual,    // Vit 1 an (Tomate, Basilic, Pétunia) -> Meurt en hiver
  biennial,  // Vit 2 ans (Persil, Carotte si on garde les graines)
  perennial  // Vivace (Repousse chaque année : Menthe, Rosier)
}

// Catégorie Globale (Pour le filtre initial)
enum PlantCategory {
  indoor,     // Plante verte / Intérieur
  vegetable,  // Potager / Fruitier
  outdoor,    // Ornemental Extérieur (Arbre, Arbuste, Fleur)
  herb        // Aromatique
}

// --- EXTENSIONS POUR L'AFFICHAGE ---

extension LightLevelExtension on LightLevel {
  String get label {
    switch (this) {
      case LightLevel.low: return "Ombre / Pénombre ☁️";
      case LightLevel.partial: return "Mi-ombre / Tamisé ⛅";
      case LightLevel.bright_ind: return "Lumière vive (sans soleil direct) 💡";
      case LightLevel.direct: return "Plein soleil ☀️";
    }
  }
}

extension WaterNeedExtension on WaterNeed {
  String get label {
    switch (this) {
      case WaterNeed.low: return "Faible (Laisser sécher) 🌵";
      case WaterNeed.medium: return "Modéré (Sécher en surface) 💧";
      case WaterNeed.high: return "Élevé (Garder humide) 🌊";
    }
  }
}

extension HumidityNeedExtension on HumidityNeed {
  String get label {
    switch (this) {
      case HumidityNeed.low: return "Air sec toléré";
      case HumidityNeed.medium: return "Normal";
      case HumidityNeed.high: return "Humide (Vaporiser / SdB) 🚿";
    }
  }
}

extension DifficultyExtension on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy: return "Facile / Débutant 💚";
      case Difficulty.medium: return "Intermédiaire";
      case Difficulty.hard: return "Expert / Exigeante 🔥";
    }
  }
}

extension ToxicityExtension on Toxicity {
  String get label {
    switch (this) {
      case Toxicity.none: return "Non toxique (Safe) 🐶";
      case Toxicity.low: return "Légèrement irritant";
      case Toxicity.high: return "Toxique (Attention animaux/enfants) ⚠️";
    }
  }
}

extension TemperatureExtension on TemperatureTolerance {
  String get label {
    switch (this) {
      case TemperatureTolerance.frost_tender: return "Craint le gel (Intérieur/Serre) ❄️🚫";
      case TemperatureTolerance.semi_hardy: return "Rustique jusqu'à -5°C";
      case TemperatureTolerance.hardy: return "Rustique jusqu'à -15°C";
      case TemperatureTolerance.very_hardy: return "Très rustique (-20°C+) 🏔️";
    }
  }
}