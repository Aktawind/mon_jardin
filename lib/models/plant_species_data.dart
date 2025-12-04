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