class PlantPhoto {
  final String id;        // UUID unique
  final String plantId;   // A qui appartient cette photo
  final String path;      // Le chemin du fichier sur le téléphone
  final DateTime date;    // Date de prise de vue
  final String? note;     // Petit commentaire optionnel (ex: "Première feuille !")

  PlantPhoto({
    required this.id,
    required this.plantId,
    required this.path,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plant_id': plantId,
      'path': path,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory PlantPhoto.fromMap(Map<String, dynamic> map) {
    return PlantPhoto(
      id: map['id'],
      plantId: map['plant_id'],
      path: map['path'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}