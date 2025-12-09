/* 
* Widget personnalisé pour la sélection d'images.
* Permet de prendre une photo ou de choisir dans la galerie.
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;

class ImageInput extends StatefulWidget {
  final Function(String) onSelectImage;
  final String? initialImage; 
  final String? heroTag;     

  const ImageInput({
    super.key, 
    required this.onSelectImage, 
    this.initialImage,
    this.heroTag,
  });

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  File? _storedImage;

  @override
  void initState() {
    super.initState();
    // Si on nous donne une image au démarrage (mode édition), on l'affiche
    if (widget.initialImage != null) {
      _storedImage = File(widget.initialImage!);
    }
  }

  Future<void> _takePicture(ImageSource source) async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: source,
      maxWidth: 600,
    );

    if (imageFile == null) return;

    setState(() {
      _storedImage = File(imageFile.path);
    });

    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    final savedImage = await _storedImage!.copy('${appDir.path}/$fileName');

    widget.onSelectImage(savedImage.path);
  }

void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _takePicture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.of(ctx).pop();
                _takePicture(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Le contenu de l'image (soit l'image, soit le bouton)
    Widget content;

    if (_storedImage != null) {
      // C'est ici qu'on met l'animation Hero
      // On vérifie si un Tag existe (pour éviter les erreurs en mode création)
      Widget imageWidget = Image.file(
        _storedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
      );

      if (widget.heroTag != null) {
        content = Hero(
          tag: widget.heroTag!, 
          child: imageWidget,
        );
      } else {
        content = imageWidget;
      }
    } else {
      content = Center(
        child: TextButton.icon(
          onPressed: _showPickerOptions,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Ajouter une photo'),
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _showPickerOptions, // Permet de changer la photo en cliquant dessus
          child: Container(
            height: 250, // Un peu plus grand pour être joli
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: content,
            ),
          ),
        ),
      ],
    );
  }
}