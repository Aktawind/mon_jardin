/*
* Modèle pour un événement lié à une plante (arrosage, fertilisation, rempotage, taille)
* Chaque événement est associé à une plante via son ID. 
* Le type d'événement est une chaîne de caractères ('water', 'fertilizer', 'repot', 'prune').
* La date de l'événement est stockée en DateTime.
* Une note optionnelle peut être ajoutée pour des détails supplémentaires.
* Utilisé pour l'historique des actions sur les plantes.
* Chaque événement peut être converti en Map pour stockage dans SQLite et reconverti en objet PlantEvent.
*/

class PlantEvent {
  final int? id; // Auto-incrementé par SQLite
  final String plantId;
  final String type; // 'water', 'fertilizer', 'repot', 'prune'
  final DateTime date;
  final String? note; // Pour plus tard (ex: "J'ai mis beaucoup d'eau")

  PlantEvent({
    this.id,
    required this.plantId,
    required this.type,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'type': type,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory PlantEvent.fromMap(Map<String, dynamic> map) {
    return PlantEvent(
      id: map['id'],
      plantId: map['plant_id'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}