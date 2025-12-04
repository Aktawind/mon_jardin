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

  // NOUVEAUX CHAMPS (Mois : 1=Janvier ... 12=Décembre)
  final List<int> sowingMonths;    // Semis
  final List<int> harvestMonths;   // Récolte
  final List<int> pruningMonths;   // Période de taille idéale
  final List<int> repottingMonths; // Période de rempotage idéale
  final List<int> winteringMonths; // Mois de repos (moins d'eau, pas d'engrais)

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

    // On met des valeurs par défaut pour ne pas casser l'encyclopédie actuelle
    this.sowingMonths = const [],
    this.harvestMonths = const [],
    this.pruningMonths = const [],
    
    // VALEURS PAR DÉFAUT STANDARD (Printemps / Hiver)
    this.repottingMonths = const [3, 4, 5],      // Mars, Avril, Mai
    this.winteringMonths = const [11, 12, 1, 2], // Nov, Déc, Jan, Fév
  });
}