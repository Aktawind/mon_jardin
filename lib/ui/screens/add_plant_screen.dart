import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../data/plant_data.dart';
import '../../services/notification_service.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  // Note: Pour l'Autocomplete, on n'utilise pas un contrôleur classique de la même façon
  String _selectedSpecies = '';
  
  String _location = 'Intérieur'; 
  int _waterFreqSummer = 7;

  // Quand on sélectionne une espèce dans la liste
  void _onSpeciesSelected(String species) {
    setState(() {
      _selectedSpecies = species;
      // Si on connait cette plante, on met à jour la fréquence
      if (speciesWateringData.containsKey(species)) {
        _waterFreqSummer = speciesWateringData[species]!;
      }
    });
  }

  Future<void> _savePlant() async {
    if (_formKey.currentState!.validate()) {
      // Logique : Si pas de surnom, on prend l'espèce
      String finalName = _nameController.text.trim();
      if (finalName.isEmpty) {
        finalName = _selectedSpecies.isNotEmpty ? _selectedSpecies : 'Plante inconnue';
      }

      final newPlant = Plant(
        id: const Uuid().v4(),
        name: finalName,
        species: _selectedSpecies,
        location: _location,
        room: _roomController.text.trim(), // On sauvegarde la pièce
        dateAdded: DateTime.now(),
        waterFrequencySummer: _waterFreqSummer,
        waterFrequencyWinter: _waterFreqSummer * 2, 
      );

      await DatabaseService().insertPlant(newPlant);
      await NotificationService().schedulePlantNotification(newPlant);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouvelle Plante"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      // SingleChildScrollView permet de scroller si le clavier cache l'écran
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ESPECE (Avec auto-complétion)
              // C'est le champ le plus important maintenant
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return speciesWateringData.keys.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: _onSpeciesSelected,
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "Quelle est cette plante ? (ex: Cactus, Ficus...)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      helperText: "Tapez les premières lettres pour voir les suggestions",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'espèce est obligatoire';
                      }
                      return null;
                    },
                    onChanged: (val) => _selectedSpecies = val,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. SURNOM (Facultatif)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Surnom (Facultatif)",
                  hintText: "ex: Pépette",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite_border),
                ),
              ),
              const SizedBox(height: 16),

              // 3. LIEU (Dropdown)
              DropdownButtonFormField<String>(
                value: _location,
                decoration: const InputDecoration(
                  labelText: "Emplacement global",
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

              // 4. PIECE PRECISE (ex: Salon)
              TextFormField(
                controller: _roomController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _location == 'Intérieur' ? "Pièce (ex: Salon, Cuisine)" : "Zone (ex: Jardin sud, Terrasse)",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // 5. FREQUENCE (Automatique mais modifiable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.water_drop),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Arrosage été : tous les $_waterFreqSummer jours",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                    const Text(
                      "Cette valeur a été suggérée selon l'espèce choisie.",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _savePlant,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("AJOUTER MA PLANTE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}