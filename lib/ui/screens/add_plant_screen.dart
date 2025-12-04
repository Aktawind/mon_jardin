import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../data/plant_data.dart';
import '../../services/notification_service.dart';
import '../common/image_input.dart';

class AddPlantScreen extends StatefulWidget {
  // Si cette variable est remplie, on est en mode "Édition", sinon "Création"
  final Plant? plantToEdit;
  final String? initialLocation;

  const AddPlantScreen({
    super.key, 
    this.plantToEdit, 
    this.initialLocation // <--- AJOUT
  });

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
  PlantSpeciesData? _foundSpeciesData;
  
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

      final data = getSpeciesData(p.species);
      if (data != null) _foundSpeciesData = data;
      
    } else {
      _nameController = TextEditingController();
      _roomController = TextEditingController();
      _location = widget.initialLocation ?? 'Intérieur';
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
      
      // On cherche dans la nouvelle encyclopédie
      final data = getSpeciesData(species);
      
      if (data != null) {
        _foundSpeciesData = data; // On stocke tout (lumière, terre, etc.)
        
        // On met à jour la fréquence si on est en création
        if (!_isEditing || _selectedSpecies != widget.plantToEdit?.species) {
          _waterFreqSummer = data.waterSummer;
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
        // 1. Identifiants et infos de base
        id: _isEditing ? widget.plantToEdit!.id : const Uuid().v4(),
        name: finalName,
        species: _selectedSpecies,
        location: _location,
        room: _roomController.text.trim(),
        photoPath: _selectedImage,
        
        // 2. Dates
        dateAdded: _isEditing ? widget.plantToEdit!.dateAdded : DateTime.now(),
        lastWatered: _isEditing ? widget.plantToEdit!.lastWatered : null,
        // On garde l'historique de fertilisation/rempotage si on édite
        lastFertilized: _isEditing ? widget.plantToEdit!.lastFertilized : null,
        lastRepotted: _isEditing ? widget.plantToEdit!.lastRepotted : null,

        // 3. Arrosage (Priorité : Slider actuel > Données encyclopédie > Valeur par défaut)
        waterFrequencySummer: _waterFreqSummer,
        waterFrequencyWinter: _foundSpeciesData?.waterWinter ?? (_isEditing ? widget.plantToEdit!.waterFrequencyWinter : _waterFreqSummer * 2),
        
        // 4. Infos Encyclopédiques (Priorité : Encyclopédie > Existant > Null)
        lightLevel: _foundSpeciesData?.light ?? widget.plantToEdit?.lightLevel,
        temperatureInfo: _foundSpeciesData?.temp ?? widget.plantToEdit?.temperatureInfo,
        humidityPref: _foundSpeciesData?.humidity ?? widget.plantToEdit?.humidityPref,
        soilType: _foundSpeciesData?.soil ?? widget.plantToEdit?.soilType,
        pruningInfo: _foundSpeciesData?.pruning ?? widget.plantToEdit?.pruningInfo,
        
        // 5. Fréquences techniques
        fertilizerFreq: _foundSpeciesData?.fertilizeFreq ?? widget.plantToEdit?.fertilizerFreq ?? 30,
        repottingFreq: _foundSpeciesData?.repotFreq ?? widget.plantToEdit?.repottingFreq ?? 24,
      );

      // 3. Sauvegarde (Update ou Insert)
      // On sauvegarde D'ABORD en base (le plus important)
      if (_isEditing) {
        await DatabaseService().updatePlant(plant);
      } else {
        await DatabaseService().insertPlant(plant);
      }

      // 4. Notifications (BLOC SÉCURISÉ)
      // On met ça dans un try-catch pour que si ça plante (ex: permissions Android),
      // ça ne bloque pas la fermeture de l'écran.
      try {
        if (_isEditing) {
          await NotificationService().cancelAllNotifications(plant); // Nettoyage
        }
        await NotificationService().scheduleAllNotifications(plant); // Programmation
      } catch (e) {
        print("Erreur lors de la programmation des notifs : $e");
        // On pourrait afficher un petit message discret à l'utilisateur ici
      }

      // 5. Fermeture (On est sûr d'arriver ici maintenant)
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
      // Suppression BDD
      await DatabaseService().deletePlant(widget.plantToEdit!.id);
      
      // Suppression Notif (Sécurisé)
      try {
        await NotificationService().cancelAllNotifications(widget.plantToEdit!);
      } catch (e) {
        print("Erreur suppression notif : $e");
      }

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
      body: SafeArea( 
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                /// 1. IMAGE
                ImageInput(
                  onSelectImage: _selectImage,
                  // On passe l'image actuelle pour qu'elle s'affiche dedans
                  initialImage: _selectedImage, 
                  // On passe l'ID de la plante comme "Tag" pour l'animation
                  heroTag: _isEditing ? widget.plantToEdit!.id : null,
                ),
                
                const SizedBox(height: 24),

                // 2. EMPLACEMENT (On le met AVANT de choisir l'espèce)
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
                    DropdownMenuItem(value: 'Potager', child: Text("Potager 🥕")),
                  ],
                  onChanged: (value) => setState(() => _location = value!),
                ),
                const SizedBox(height: 16),

                // 3. ESPECE (Autocomplete)
                Autocomplete<String>(
                initialValue: TextEditingValue(text: _selectedSpecies),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // 1. On choisit la bonne liste selon la sélection actuelle
                  List<PlantSpeciesData> sourceList;
                  
                  if (_location == 'Intérieur') {
                    sourceList = getIndoorSorted();
                  } else if (_location == 'Extérieur') {
                    sourceList = getOutdoorSorted();
                  } else {
                    sourceList = getVegetablesSorted(); // Potager
                  }

                  // 2. Si le champ est vide, on peut tout afficher (ou rien, selon ton goût)
                  // Ici j'affiche tout pour que l'utilisateur puisse scroller la liste alphabétique
                  if (textEditingValue.text == '') {
                    return sourceList.map((e) => e.species);
                  }

                  // 3. Sinon on filtre ce que l'utilisateur tape
                  return sourceList
                      .map((e) => e.species)
                      .where((String option) {
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

                // 4. SURNOM
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Surnom",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.favorite_border),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. PIECE PRECISE
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
      ),
    );
  }
}

// Petit hack : Il faut importer dart:io pour le fichier image
// import 'dart:io' as java; // En haut du fichier