import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../services/notification_service.dart';
import '../common/image_input.dart';
import 'package:intl/intl.dart';
import '../../services/encyclopedia_service.dart';
import '../../models/enums.dart'; // Pour PlantCategory
import '../../models/plant_species_data.dart'; // Pour le type

class AddPlantScreen extends StatefulWidget {
  // Si cette variable est remplie, on est en mode "Édition", sinon "Création"
  final Plant? plantToEdit;
  final String? initialLocation;
  final String? preSelectedSpecies;

  const AddPlantScreen({
    super.key, 
    this.plantToEdit, 
    this.initialLocation, 
    this.preSelectedSpecies,
    
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
  String _lifecycleStage = 'planted'; // Valeur par défaut (En terre/pot)
  bool _trackWatering = true;
  bool _trackFertilizer = true;
  bool _trackRepotting = true;

  DateTime _lastWateredDate = DateTime.now();
  DateTime? _lastFertilizedDate = DateTime.now();
  DateTime? _lastRepottedDate = DateTime.now();
  
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
      _lifecycleStage = p.lifecycleStage; // On reprend le stade existant
      _trackWatering = p.trackWatering;
      _trackFertilizer = p.trackFertilizer;
      _trackRepotting = p.trackRepotting;
      _lastWateredDate = p.lastWatered ?? DateTime.now();
      _lastFertilizedDate = p.lastFertilized;
      _lastRepottedDate = p.lastRepotted;

      final data = EncyclopediaService().getData(p.species);
      if (data != null) _foundSpeciesData = data;
      
    } else {
      _nameController = TextEditingController();
      _roomController = TextEditingController();
      _location = widget.initialLocation ?? 'Intérieur';

      if (_location == 'Extérieur' || _location == 'Potager') {
          _trackWatering = false;   // Dehors, la pluie s'en charge
          _trackFertilizer = false; // Souvent moins critique
          _trackRepotting = false;  // Pas de rempotage en pleine terre
      } else {
          _trackWatering = true;
          _trackFertilizer = true;
          _trackRepotting = true;
      }
    }
    if (widget.preSelectedSpecies != null) {
      _selectedSpecies = widget.preSelectedSpecies!;
      // On charge les infos tout de suite
      final data = EncyclopediaService().getData(_selectedSpecies);
      if (data != null) _foundSpeciesData = data;
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
      
      // NOUVEL APPEL AU SERVICE
      final data = EncyclopediaService().getData(species);
      
      if (data != null) {
        _foundSpeciesData = data; 
        
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
      String speciesRaw = _selectedSpecies.trim();
      String speciesClean = speciesRaw.isNotEmpty 
          ? '${speciesRaw[0].toUpperCase()}${speciesRaw.substring(1)}' 
          : 'Plante inconnue';

      // 2. Création de l'objet (Nouvel ID ou Ancien ID)
      final plant = Plant(
        // 1. Identifiants et infos de base
        id: _isEditing ? widget.plantToEdit!.id : const Uuid().v4(),
        species: speciesClean,
        name: _nameController.text.trim(),
        location: _location,
        room: _roomController.text.trim(),
        photoPath: _selectedImage,
        
        // 2. Dates
        dateAdded: _isEditing ? widget.plantToEdit!.dateAdded : DateTime.now(),
        lastWatered: _lastWateredDate,
        lastFertilized: _lastFertilizedDate,
        lastRepotted: _lastRepottedDate,

        // 3. Arrosage (Priorité : Slider actuel > Données encyclopédie > Valeur par défaut)
        waterFrequencySummer: _waterFreqSummer,
        waterFrequencyWinter: _foundSpeciesData?.waterWinter ?? (_isEditing ? widget.plantToEdit!.waterFrequencyWinter : _waterFreqSummer * 2),
        
        // 4. Infos Encyclopédiques (Priorité : Encyclopédie > Existant > Null)
        lightLevel: _foundSpeciesData != null 
            ? _foundSpeciesData!.light.name
            : widget.plantToEdit?.lightLevel,
            
        temperatureInfo: _foundSpeciesData != null
            ? _foundSpeciesData!.temperature.name 
            : widget.plantToEdit?.temperatureInfo,
            
        humidityPref: _foundSpeciesData != null
            ? _foundSpeciesData!.humidity.name
            : widget.plantToEdit?.humidityPref,
            
        soilType: _foundSpeciesData?.soilInfo ?? widget.plantToEdit?.soilType,
        
        // 5. Fréquences techniques
        fertilizerFreq: _foundSpeciesData?.fertilizeFreq ?? widget.plantToEdit?.fertilizerFreq ?? 30,
        repottingFreq: _foundSpeciesData?.repotFreq ?? widget.plantToEdit?.repottingFreq ?? 24,

        // 6. Suivi et stade de vie
        lifecycleStage: _location == 'Potager' ? _lifecycleStage : 'planted', // Sécurité : si pas potager, c'est 'planted'

        trackWatering: _trackWatering,
        trackFertilizer: _trackFertilizer,
        trackRepotting: _trackRepotting,
        
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
        // On pourrait afficher un petit message discret à l'utilisateur ici
      }

      // 5. Fermeture (On est sûr d'arriver ici maintenant)
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Modifier la plante" : "Nouvelle Plante"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
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
                  initialValue: _location,
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
                  // 1. Récupération de la liste brute (selon catégorie)
                  PlantCategory targetCategory;
                  if (_location == 'Intérieur') {
                    targetCategory = PlantCategory.indoor;
                  }
                  else if (_location == 'Potager') {
                    targetCategory = PlantCategory.vegetable;
                  }
                  else {
                    targetCategory = PlantCategory.outdoor;
                  }

                  final sourceList = EncyclopediaService().getByCategory(targetCategory);
                  final input = textEditingValue.text.toLowerCase();

                  // 2. Si vide, on affiche tout (ou rien)
                  if (input.isEmpty) {
                    return sourceList.map((e) => e.species);
                  }

                  // 3. Filtrage intelligent
                  final filteredList = sourceList.where((data) {
                    // Match Nom
                    if (data.species.toLowerCase().contains(input)) return true;
                    
                    // Match Synonymes
                    // (On vérifie que la liste n'est pas vide pour optimiser)
                    if (data.synonyms.isNotEmpty) {
                      for (var s in data.synonyms) {
                        if (s.toLowerCase().contains(input)) return true;
                      }
                    }
                    
                    return false;
                  });

                  // 4. Retour des noms OFFICIELS
                  return filteredList.map((e) => e.species);
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
                      textCapitalization: TextCapitalization.sentences,
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

                const SizedBox(height: 16),

              // SELECTEUR DE STADE (Uniquement pour Potager)
              if (_location == 'Potager') ...[
                const Text("Stade actuel", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'seed', label: Text('Graine'), icon: Icon(Icons.grain)),
                    ButtonSegment(value: 'seedling', label: Text('Semis'), icon: Icon(Icons.spa)), // Petite pousse
                    ButtonSegment(value: 'planted', label: Text('En terre'), icon: Icon(Icons.grass)),
                  ],
                  selected: {_lifecycleStage},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _lifecycleStage = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(height: 24),
              ],

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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

                const Divider(),
                const Text("OPTIONS DE SUIVI", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                
                SwitchListTile(
                  title: const Text("Suivre l'arrosage"),
                  value: _trackWatering,
                  onChanged: (val) => setState(() => _trackWatering = val),
                ),
                SwitchListTile(
                  title: const Text("Suivre l'engrais"),
                  value: _trackFertilizer,
                  onChanged: (val) => setState(() => _trackFertilizer = val),
                ),
                SwitchListTile(
                  title: const Text("Suivre le rempotage"),
                  value: _trackRepotting,
                  onChanged: (val) => setState(() => _trackRepotting = val),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const Text("DERNIERS SOINS (Pour caler le cycle)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                
                // 1. ARROSAGE (Date précise)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  title: const Text("Dernier arrosage"),
                  subtitle: Text(DateFormat('d MMMM yyyy', 'fr_FR').format(_lastWateredDate)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale("fr", "FR"),
                      initialDate: _lastWateredDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _lastWateredDate = picked);
                  },
                ),

                // 2. FERTILISATION (Mois/Année)
                // On triche un peu : on stocke le 1er du mois choisi
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.science, color: Colors.purple),
                  title: const Text("Dernier engrais"),
                  subtitle: Text(_lastFertilizedDate == null 
                      ? "Jamais / Je ne sais plus" 
                      : DateFormat('MMMM yyyy', 'fr_FR').format(_lastFertilizedDate!)),
                  trailing: _lastFertilizedDate == null ? const Icon(Icons.add) : const Icon(Icons.edit_calendar),
                  onTap: () async {
                    // Astuce : un DatePicker classique, mais on ne regarde que le mois
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale("fr", "FR"),
                      initialDate: _lastFertilizedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      helpText: "CHOISISSEZ UNE DATE DANS LE MOIS",
                    );
                    if (picked != null) setState(() => _lastFertilizedDate = picked);
                  },
                  // Petit bouton croix pour effacer si besoin
                  onLongPress: () => setState(() => _lastFertilizedDate = null),
                ),

                // 3. REMPOTAGE (Année)
                // On stocke le 1er Janvier de l'année choisie
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.change_circle, color: Colors.orange),
                  title: const Text("Dernier rempotage"),
                  subtitle: Text(_lastRepottedDate == null 
                      ? "Jamais / Je ne sais plus" 
                      : DateFormat('yyyy', 'fr_FR').format(_lastRepottedDate!)),
                  trailing: _lastRepottedDate == null ? const Icon(Icons.add) : const Icon(Icons.edit_calendar),
                  onTap: () async {
                    // Pour l'année, on peut faire un simple Dialog avec une liste ou un DatePicker mode année (dispo sur Android récents)
                    // Faisons simple : DatePicker classique
                    final picked = await showDatePicker(
                      context: context,
                      locale: const Locale("fr", "FR"),
                      initialDate: _lastRepottedDate ?? DateTime.now(),
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                      initialDatePickerMode: DatePickerMode.year, // <--- Mode Année !
                      helpText: "CHOISISSEZ L'ANNÉE",
                    );
                    if (picked != null) setState(() => _lastRepottedDate = picked);
                  },
                  onLongPress: () => setState(() => _lastRepottedDate = null),
                ),
                const SizedBox(height: 24),
                
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