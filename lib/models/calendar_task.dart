/*
  * Modèle représentant une tâche dans le calendrier (arrosage, fertilisation, etc.)
  * Chaque tâche est associée à une plante et à un type de tâche.
  * Le titre et le sous-titre sont utilisés pour l'affichage dans l'interface utilisateur.
  * La date spécifique est optionnelle et peut être nulle si la tâche est basée sur le mois uniquement.
*/

import 'plant.dart';

enum TaskType {
  water,      // Arrosage (Calculé)
  fertilizer, // Engrais (Calculé ou Saison)
  repot,      // Rempotage (Annuel)
  prune,      // Taille (Encyclopédie)
  sow,        // Semis (Encyclopédie)
  harvest,    // Récolte (Encyclopédie)
  planting,   // Mise en terre (Encyclopédie)
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