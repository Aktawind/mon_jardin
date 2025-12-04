import 'plant.dart';

enum TaskType {
  water,      // Arrosage (Calculé)
  fertilizer, // Engrais (Calculé ou Saison)
  repot,      // Rempotage (Annuel)
  prune,      // Taille (Encyclopédie)
  sow,        // Semis (Encyclopédie)
  harvest,    // Récolte (Encyclopédie)
  wintering,  // Hivernage (Encyclopédie)
}

class CalendarTask {
  final Plant plant;
  final TaskType type;
  final String title;
  final String subtitle;
  final DateTime? specificDate; // Null si c'est une tâche "du mois" sans date précise

  CalendarTask({
    required this.plant,
    required this.type,
    required this.title,
    required this.subtitle,
    this.specificDate,
  });
}