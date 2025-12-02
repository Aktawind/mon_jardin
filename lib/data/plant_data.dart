class PlantSpeciesData {
  final String species;
  final int waterSummer;
  final int waterWinter;
  final String light;
  final String temp;
  final String humidity;
  final String soil;
  final int fertilizeFreq; // jours
  final int repotFreq; // mois
  final String pruning;

  const PlantSpeciesData({
    required this.species,
    required this.waterSummer,
    required this.waterWinter,
    required this.light,
    required this.temp,
    required this.humidity,
    required this.soil,
    required this.fertilizeFreq,
    required this.repotFreq,
    required this.pruning,
  });
}

// Notre petite encyclopédie (Exemple avec 3 plantes, on pourra l'étendre)
final List<PlantSpeciesData> encyclopedia = [
  const PlantSpeciesData(
    species: 'Monstera Deliciosa',
    waterSummer: 7,
    waterWinter: 14,
    light: 'Lumière vive mais indirecte (pas de soleil direct)',
    temp: '18-25°C. Craint le froid sous 15°C',
    humidity: 'Aime l\'humidité. Vaporiser les feuilles ou nettoyer avec une éponge humide',
    soil: 'Drainant : Terreau plante verte + Perlites ou écorces',
    fertilizeFreq: 30, // 1 fois par mois
    repotFreq: 24, // Tous les 2 ans
    pruning: 'Couper les feuilles jaunies à la base. Nettoyer la poussière pour la photosynthèse.',
  ),
  const PlantSpeciesData(
    species: 'Cactus',
    waterSummer: 20,
    waterWinter: 45,
    light: 'Plein soleil ! Lumière directe nécessaire.',
    temp: 'Chaud en été, frais en hiver (10-15°C) pour favoriser la floraison',
    humidity: 'Air sec. Surtout pas de salle de bain.',
    soil: 'Très drainant : 1/3 terreau, 1/3 sable, 1/3 terre de jardin',
    fertilizeFreq: 30, // Seulement en été
    repotFreq: 36, // Tous les 3-4 ans
    pruning: 'Aucune taille nécessaire. Retirer les parties molles si pourriture.',
  ),
  const PlantSpeciesData(
    species: 'Calathea',
    waterSummer: 4,
    waterWinter: 7,
    light: 'Ombre ou mi-ombre. La lumière directe brûle les feuilles.',
    temp: 'Stable vers 20°C. Déteste les courants d\'air et radiateurs.',
    humidity: 'Très élevée ! Idéal salle de bain ou sur un lit de billes d\'argile humides.',
    soil: 'Riche et drainant (terre de bruyère + terreau)',
    fertilizeFreq: 15, // Gourmande
    repotFreq: 12, // Chaque année si possible
    pruning: 'Couper les feuilles sèches qui brunissent.',
  ),
  // ... On ajoutera les autres ici
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