import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;

class ImageInput extends StatefulWidget {
  final Function(String) onSelectImage;

  const ImageInput({super.key, required this.onSelectImage});

  @override
  State<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends State<ImageInput> {
  File? _storedImage;

  Future<void> _takePicture(ImageSource source) async {
    final picker = ImagePicker();
    // On ouvre la caméra ou la galerie
    final imageFile = await picker.pickImage(
      source: source,
      maxWidth: 600, // On limite la taille pour pas faire exploser la mémoire
    );

    if (imageFile == null) {
      return;
    }

    setState(() {
      _storedImage = File(imageFile.path);
    });

    // Sauvegarde de l'image dans le dossier de l'appli
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    final savedImage = await _storedImage!.copy('${appDir.path}/$fileName');

    // On renvoie le chemin au formulaire parent
    widget.onSelectImage(savedImage.path);
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: _storedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _storedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Center(
                  child: TextButton.icon(
                    onPressed: _showPickerOptions,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Ajouter une photo'),
                  ),
                ),
        ),
        if (_storedImage != null)
          TextButton.icon(
             onPressed: _showPickerOptions,
             icon: const Icon(Icons.refresh),
             label: const Text("Changer la photo"),
          )
      ],
    );
  }
}