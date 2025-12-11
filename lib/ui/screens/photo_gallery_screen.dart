/*
* Écran affichant la galerie photo pour une plante donnée.
* Permet d'ajouter, voir en grand et supprimer des photos.
* Utilise le widget ImageInput pour la sélection d'images.
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/plant.dart';
import '../../models/plant_photo.dart';
import '../../data/database_service.dart';
import '../common/image_input.dart'; // On réutilise notre sélecteur

class PhotoGalleryScreen extends StatefulWidget {
  final Plant plant;

  const PhotoGalleryScreen({super.key, required this.plant});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  // Pour l'instant, on n'a pas besoin d'état complexe car FutureBuilder gère le chargement
  
  // Fonction pour ajouter une photo
  Future<void> _addPhoto() async {
    // On ouvre un petit dialog ou bottom sheet pour prendre la photo
    // Comme notre widget ImageInput est conçu pour être intégré dans un formulaire,
    // on va ruser un peu et l'afficher dans une boite de dialogue simple.
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pour prendre toute la hauteur si besoin
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Nouvelle photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              ImageInput(
                onSelectImage: (path) async {
                  Navigator.pop(ctx); // Ferme le sélecteur
                  await _savePhotoToDb(path);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePhotoToDb(String path) async {
    final newPhoto = PlantPhoto(
      id: const Uuid().v4(),
      plantId: widget.plant.id,
      path: path,
      date: DateTime.now(),
      note: "", // On pourra ajouter une note plus tard
    );

    await DatabaseService().addPhoto(newPhoto);
    setState(() {}); // Rafraichir la galerie
  }

  Future<void> _deletePhoto(String photoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Cette photo sera effacée."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().deletePhoto(photoId);
      setState(() {});
    }
  }

  Future<void> _updatePhotoDate(PlantPhoto photo, DateTime newDate) async {
    // On crée une copie de la photo avec la nouvelle date
    final updatedPhoto = PlantPhoto(
      id: photo.id,
      plantId: photo.plantId,
      path: photo.path,
      date: newDate, // Nouvelle date
      note: photo.note,
    );

    await DatabaseService().updatePhoto(updatedPhoto);
    setState(() {}); // Rafraichir la galerie pour réordonner
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Album de ${widget.plant.displayName}"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: FutureBuilder<List<PlantPhoto>>(
        future: DatabaseService().getPhotosForPlant(widget.plant.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final photos = snapshot.data!;

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Aucune photo pour l'instant.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addPhoto,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text("Ajouter la première"),
                  )
                ],
              ),
            );
          }

          // Grille de photos
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 colonnes
              childAspectRatio: 0.8, // Un peu plus haut que large (format Polaroïd)
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () {
                   Navigator.push(
                     context, 
                     MaterialPageRoute(builder: (_) => _FullScreenViewer(
                       photo: photo, 
                       onDelete: () => _deletePhoto(photo.id),
                       onDateChange: (newDate) => _updatePhotoDate(photo, newDate),
                     ))
                   );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          DateFormat('d MMM yyyy', 'fr_FR').format(photo.date),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

// Petit widget pour voir en grand
class _FullScreenViewer extends StatefulWidget {
  final PlantPhoto photo;
  final VoidCallback onDelete;
  final Function(DateTime) onDateChange;

  const _FullScreenViewer({
    required this.photo, 
    required this.onDelete,
    required this.onDateChange,
  });

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.photo.date;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(DateFormat('d MMMM yyyy', 'fr_FR').format(_currentDate), style: const TextStyle(fontSize: 16)),
        actions: [
          // BOUTON CALENDRIER
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: "Changer la date",
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _currentDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                locale: const Locale("fr", "FR"),
              );
              if (picked != null) {
                widget.onDateChange(picked); // Sauvegarde en base (via parent)
                setState(() {
                  _currentDate = picked; // Mise à jour visuelle locale
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              widget.onDelete();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Center(
        child: Image.file(File(widget.photo.path)),
      ),
    );
  }
}