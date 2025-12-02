import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../data/plant_data.dart';
import '../../services/notification_service.dart';
import '../common/image_input.dart';
import 'dart:io';

class AddPlantScreen extends StatefulWidget {
  // Si cette variable est remplie, on est en mode "Édition", sinon "Création"
  final Plant? plantToEdit;

  const AddPlantScreen({super.key, this.plantToEdit});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  late TextEditingController _nameController;
  late TextEditingController _roomController;
  
  String _selectedSpecies = '';
  String? _selectedImage;
  String _location = 'Intérieur'; 
  int _waterFreqSummer = 7;
  
  // Pour savoir si on est en mode édition
  bool get _isEditing => widget.plantToEdit != null;

  @override
  void initState() {
    super.initState();
    // Initialisation des valeurs si on édite
    if (_isEditing) {
      final p = widget.plantToEdit!;
      _nameController = TextEditingController(text: p.name);
      _roomController = TextEditingController(text: p.room);
      _selectedSpecies = p.species;
      _selectedImage = p.photoPath;
      _location = p.location;
      _waterFreqSummer = p.waterFrequencySummer;
    } else {
      _nameController = TextEditingController();
      _roomController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _onSpeciesSelected(String species) {
    setState(() {
      _selectedSpecies = species;
      // On ne change la fréquence automatiquement que si on est en mode création
      // ou si l'utilisateur change d'espèce (pour ne pas écraser ses réglages perso)
      if (!_isEditing || _selectedSpecies != widget.plantToEdit?.species) {
         if (speciesWateringData.containsKey(species)) {
          _waterFreqSummer = speciesWateringData[species]!;
        }
      }
    });
  }

  void _selectImage(String pickedImage) {
    setState(() {
      _selectedImage = pickedImage;
    });
  }

  Future<void> _savePlant() async {
    if (_formKey.currentState!.validate()) {
      // 1. Définition du nom
      String finalName = _nameController.text.trim();
      if (finalName.isEmpty) {
        finalName = _selectedSpecies.isNotEmpty ? _selectedSpecies : 'Plante inconnue';
      }

      // 2. Création de l'objet (Nouvel ID ou Ancien ID)
      final plant = Plant(
        id: _isEditing ? widget.plantToEdit!.id : const Uuid().v4(),
        name: finalName,
        species: _selectedSpecies,
        location: _location,
        room: _roomController.text.trim(),
        photoPath: _selectedImage,
        dateAdded: _isEditing ? widget.plantToEdit!.dateAdded : DateTime.now(),
        lastWatered: _isEditing ? widget.plantToEdit!.lastWatered : null,
        // Si on édite, on garde l'historique, sinon null
        
        waterFrequencySummer: _waterFreqSummer,
        waterFrequencyWinter: _waterFreqSummer * 2, 
      );

      // 3. Sauvegarde (Update ou Insert)
      if (_isEditing) {
        await DatabaseService().updatePlant(plant);
        // Si on change les réglages, on reprogramme la notif
        await NotificationService().cancelNotification(plant);
        await NotificationService().schedulePlantNotification(plant);
      } else {
        await DatabaseService().insertPlant(plant);
        await NotificationService().schedulePlantNotification(plant);
      }

      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _deletePlant() async {
    // Fenêtre de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous vraiment supprimer ${widget.plantToEdit!.name} ?\nCette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Suppression BDD + Notif
      await DatabaseService().deletePlant(widget.plantToEdit!.id);
      await NotificationService().cancelNotification(widget.plantToEdit!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Modifier la plante" : "Nouvelle Plante"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        actions: [
          // Icône de suppression visible seulement en mode édition
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePlant,
              tooltip: "Supprimer la plante",
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo (avec un petit système pour charger l'image existante si besoin)
              // Note: ImageInput a été conçu pour créer, il faut peut-être l'adapter légèrement
              // pour afficher l'image existante au démarrage. 
              // Pour simplifier ici, on reconstruit ImageInput pour qu'il prenne une image initiale ?
              // Ou plus simple : on affiche l'image actuelle au dessus s'il y en a une.
              if (_selectedImage != null && !_selectedImage!.contains('cache')) 
                 Padding(
                   padding: const EdgeInsets.only(bottom: 16),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(12),
                     child: Image.file(
                       File(_selectedImage!), 
                       height: 200, 
                       fit: BoxFit.cover
                     ),
                   ),
                 ),
              
              // Widget de sélection (pour changer ou ajouter)
              ImageInput(onSelectImage: _selectImage),
              
              const SizedBox(height: 24),

              Autocomplete<String>(
                initialValue: TextEditingValue(text: _selectedSpecies), // Valeur initiale !
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return const Iterable<String>.empty();
                  return speciesWateringData.keys.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: _onSpeciesSelected,
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Astuce : Si le controller est vide (au démarrage) mais qu'on a une espèce sélectionnée (mode edit)
                  // on force le texte.
                  if (textEditingController.text.isEmpty && _selectedSpecies.isNotEmpty) {
                    textEditingController.text = _selectedSpecies;
                  }
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "Espèce",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) => _selectedSpecies = val,
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Surnom",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite_border),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _location,
                decoration: const InputDecoration(
                  labelText: "Emplacement",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                items: const [
                  DropdownMenuItem(value: 'Intérieur', child: Text("Intérieur 🏠")),
                  DropdownMenuItem(value: 'Extérieur', child: Text("Extérieur 🌳")),
                ],
                onChanged: (value) => setState(() => _location = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _roomController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _location == 'Intérieur' ? "Pièce" : "Zone",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop),
                        const SizedBox(width: 8),
                        Text(
                          "Fréquence : tous les $_waterFreqSummer jours",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _waterFreqSummer.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: "$_waterFreqSummer j",
                      onChanged: (val) => setState(() => _waterFreqSummer = val.toInt()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: _savePlant,
                icon: Icon(_isEditing ? Icons.save_as : Icons.save),
                label: Text(_isEditing ? "ENREGISTRER LES MODIFICATIONS" : "AJOUTER MA PLANTE"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Petit hack : Il faut importer dart:io pour le fichier image
// import 'dart:io' as java; // En haut du fichier