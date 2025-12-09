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
      builder: (ctx) => Padding(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Album de ${widget.plant.name}"),
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
                   // Ouvrir en grand (Visionneuse simple)
                   Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenViewer(photo: photo, onDelete: () => _deletePhoto(photo.id))));
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
class _FullScreenViewer extends StatelessWidget {
  final PlantPhoto photo;
  final VoidCallback onDelete;

  const _FullScreenViewer({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete();
              Navigator.pop(context); // Fermer après suppression
            },
          )
        ],
      ),
      body: Center(
        child: Image.file(File(photo.path)),
      ),
    );
  }
}