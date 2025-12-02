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