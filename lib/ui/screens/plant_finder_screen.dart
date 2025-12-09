/*
* Écran pour trouver des plantes en fonction de critères donnés.
* Utilise le PlantMatchMaker pour filtrer l'encyclopédie.
*/

import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../services/plant_match_maker.dart';
import '../../models/plant_species_data.dart';
import '../common/main_drawer.dart';

class PlantFinderScreen extends StatefulWidget {
  const PlantFinderScreen({super.key});

  @override
  State<PlantFinderScreen> createState() => _PlantFinderScreenState();
}

class _PlantFinderScreenState extends State<PlantFinderScreen> {
  // État du formulaire
  final _criteria = PlantMatchCriteria();
  
  // Résultats
  List<PlantSpeciesData>? _results;
  bool _hasSearched = false;

  void _search() {
    setState(() {
      _results = PlantMatchMaker().findMatches(_criteria);
      _hasSearched = true;
    });
  }

  void _reset() {
    setState(() {
      // Réinitialisation manuelle ou recréer l'objet
      _criteria.category = null;
      _criteria.light = null;
      _criteria.lowMaintenance = null;
      _criteria.petSafe = null;
      _results = null;
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guide d'Achat"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_hasSearched)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _reset)
        ],
      ),
      drawer: const MainDrawer(currentIndex: 2),
      body: _hasSearched ? _buildResults() : _buildForm(),
    );
  }

 // --- LE FORMULAIRE DYNAMIQUE ---
  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Trouvons votre plante idéale 🌱",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // 1. LE CHOIX MAÎTRE (Catégorie)
        _buildQuestionCard(
          title: "Où ira cette plante ?",
          icon: Icons.place,
          child: Column(
            children: [
              _buildRadioTile("Intérieur (Salon, Chambre...)", PlantCategory.indoor, (v) => _criteria.category = v),
              _buildRadioTile("Extérieur (Jardin, Balcon)", PlantCategory.outdoor, (v) => _criteria.category = v),
              _buildRadioTile("Potager (Légumes, Fruits)", PlantCategory.vegetable, (v) => _criteria.category = v),
            ],
          ),
        ),

        // 2. QUESTIONS SPECIFIQUES (Affichage conditionnel)
        if (_criteria.category == PlantCategory.indoor) ...[
          _buildIndoorQuestions(),
        ],
        
        if (_criteria.category == PlantCategory.outdoor) ...[
          _buildOutdoorQuestions(),
        ],
        
        if (_criteria.category == PlantCategory.vegetable) ...[
          _buildVegetableQuestions(),
        ],

        // BOUTON RECHERCHE
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _criteria.category == null ? null : _search,
          icon: const Icon(Icons.search),
          label: const Text("VOIR LES RESULTATS"),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- BLOCS DE QUESTIONS ---

  Widget _buildIndoorQuestions() {
    return Column(
      children: [
        _buildQuestionCard(
          title: "Luminosité",
          icon: Icons.wb_sunny,
          child: Column(
            children: [
              _buildRadioLight("Ombre / Peu de lumière", LightLevel.low),
              _buildRadioLight("Lumineux (sans soleil direct)", LightLevel.brightInd),
              _buildRadioLight("Plein Soleil", LightLevel.direct),
            ],
          ),
        ),
        _buildQuestionCard(
          title: "Esthétique",
          icon: Icons.palette,
          child: Column(
            children: [
              _buildRadioTileGeneric("Plante Verte (Feuillage)", FoliageType.foliage, (v) => _criteria.aesthetic = v),
              _buildRadioTileGeneric("Plante Fleurie", FoliageType.flowering, (v) => _criteria.aesthetic = v),
            ],
          ),
        ),
        _buildQuestionCard(
          title: "Placement",
          icon: Icons.format_shapes,
          child: Column(
            children: [
              _buildRadioTileGeneric("Suspendue / Etagère haute", PlantHeight.hanging, (v) => _criteria.shape = v),
              _buildRadioTileGeneric("Au sol / Sur table", PlantHeight.shrub, (v) => _criteria.shape = v),
            ],
          ),
        ),
        _buildQuestionCard(
          title: "Contraintes & Sécurité",
          icon: Icons.shield,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Facile (Oublis d'arrosage)"),
                subtitle: const Text("Plantes résistantes"),
                value: _criteria.lowMaintenance ?? false,
                onChanged: (v) => setState(() => _criteria.lowMaintenance = v),
              ),
              SwitchListTile(
                title: const Text("Animaux / Enfants"),
                subtitle: const Text("Exclure les plantes toxiques"),
                value: _criteria.petSafe ?? false,
                onChanged: (v) => setState(() => _criteria.petSafe = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutdoorQuestions() {
    return Column(
      children: [
        _buildQuestionCard(
          title: "Exposition",
          icon: Icons.wb_sunny,
          child: Column(
            children: [
              _buildRadioLight("Ombre", LightLevel.low),
              _buildRadioLight("Mi-ombre", LightLevel.partial),
              _buildRadioLight("Plein Soleil", LightLevel.direct),
            ],
          ),
        ),
        _buildQuestionCard(
          title: "Climat Hiver",
          icon: Icons.ac_unit,
          child: Column(
            children: [
              // On mappe vers TemperatureTolerance
              RadioListTile<TemperatureTolerance>(
                title: const Text("Il gèle fort (-15°C)"),
                value: TemperatureTolerance.hardy,
                groupValue: _criteria.minTemp,
                onChanged: (v) => setState(() => _criteria.minTemp = v),
              ),
              RadioListTile<TemperatureTolerance>(
                title: const Text("Il gèle un peu (-5°C)"),
                value: TemperatureTolerance.semiHardy,
                groupValue: _criteria.minTemp,
                onChanged: (v) => setState(() => _criteria.minTemp = v),
              ),
              RadioListTile<TemperatureTolerance>(
                title: const Text("Pas de gel"),
                value: TemperatureTolerance.frostTender,
                groupValue: _criteria.minTemp,
                onChanged: (v) => setState(() => _criteria.minTemp = v),
              ),
            ],
          ),
        ),
        // Esthétique
        _buildQuestionCard(
          title: "Esthétique",
          icon: Icons.palette,
          child: Column(
            children: [
              _buildRadioTileGeneric("Plante Verte (Feuillage)", FoliageType.foliage, (v) => _criteria.aesthetic = v),
              _buildRadioTileGeneric("Plante Fleurie", FoliageType.flowering, (v) => _criteria.aesthetic = v),
            ],
          ),
        ),
        // Type de feuillage (persistant etc...)
        _buildQuestionCard(
          title: "Type de feuillage",
          icon: Icons.filter_vintage,
          child: Column(
            children: [
              _buildRadioTileGeneric("Feuillage persistant", LeafPersistence.evergreen, (v) => _criteria.leafPersistence = v),
              _buildRadioTileGeneric("Feuillage caduc", LeafPersistence.deciduous, (v) => _criteria.leafPersistence = v),
            ],
          ),
        ),
        // Type de port
        _buildQuestionCard(
          title: "Type de port",
          icon: Icons.account_tree,
          child: Column(
            children: [
              _buildRadioTileGeneric("Plante basse / Couvre-sol", PlantHeight.ground, (v) => _criteria.shape = v),
              _buildRadioTileGeneric("Plante moyenne / Arbuste", PlantHeight.shrub, (v) => _criteria.shape = v),
              _buildRadioTileGeneric("Arbre / Grand format", PlantHeight.tree, (v) => _criteria.shape = v),
              _buildRadioTileGeneric("Plante grimpante", PlantHeight.climber, (v) => _criteria.shape = v),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVegetableQuestions() {
    return Column(
      children: [
        _buildQuestionCard(
          title: "Exposition",
          icon: Icons.wb_sunny,
          child: Column(
            children: [
              _buildRadioLight("Mi-ombre", LightLevel.partial),
              _buildRadioLight("Plein Soleil", LightLevel.direct),
            ],
          ),
        ),
        //Climat
        _buildQuestionCard(
          title: "Climat Hiver",
          icon: Icons.ac_unit,
          child: Column(
            children: [
              // On mappe vers TemperatureTolerance
              RadioListTile<TemperatureTolerance>(
                title: const Text("Il gèle fort (-15°C)"),
                value: TemperatureTolerance.hardy,
                groupValue: _criteria.minTemp,
                onChanged: (v) => setState(() => _criteria.minTemp = v),
              ),
              RadioListTile<TemperatureTolerance>(
                title: const Text("Il gèle un peu (-5°C)"),
                value: TemperatureTolerance.semiHardy,
                groupValue: _criteria.minTemp,
                onChanged: (v) => setState(() => _criteria.minTemp = v),
              ),
              RadioListTile<TemperatureTolerance>(
                title: const Text("Pas de gel"),
                value: TemperatureTolerance.frostTender,
                groupValue: _criteria.minTemp,
                onChanged: (v) => setState(() => _criteria.minTemp = v),
              ),
            ],
          ),
        ),
        _buildQuestionCard(
          title: "Niveau",
          icon: Icons.emoji_events,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Débutant (Facile à réussir)"),
                value: _criteria.lowMaintenance ?? false, // On réutilise ce champ pour "Facile"
                onChanged: (v) => setState(() => _criteria.lowMaintenance = v),
              ),
            ],
          ),
        ),
        // Type
        _buildQuestionCard(
          title: "Type de légume",
          icon: Icons.restaurant,
          child: Column(
            children: [
              _buildRadioTileGeneric("Légume feuille", VegetableType.leaf, (v) => _criteria.vegType = v),
              _buildRadioTileGeneric("Légume racine", VegetableType.root, (v) => _criteria.vegType = v),
              _buildRadioTileGeneric("Fruits comestibles", VegetableType.fruit, (v) => _criteria.vegType = v),
              _buildRadioTileGeneric("Herbes aromatiques", VegetableType.herb, (v) => _criteria.vegType = v),
              _buildRadioTileGeneric("Petit fruitier", VegetableType.fruitTree, (v) => _criteria.vegType = v),
            ],
          ),
        ),
      ],
    );
  }

  // --- LES RESULTATS ---
  Widget _buildResults() {
    if (_results == null || _results!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Aucune plante ne correspond exactement...", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(onPressed: _reset, child: const Text("Essayer d'autres critères"))
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("${_results!.length} plantes trouvées !", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results!.length,
            itemBuilder: (context, index) {
              final plantData = _results![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(plantData.species[0]),
                    backgroundColor: Colors.green[100],
                  ),
                  title: Text(plantData.species, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plantData.difficulty.label), // Utilise ton extension .label
                  trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onTap: () {
                    // Magie : On va vers l'ajout avec la plante pré-sélectionnée !
                    // Il faudra modifier AddPlantScreen pour accepter une 'preSelectedSpecies'
                    // Pour l'instant, on peut juste copier le nom dans le presse-papier ou afficher un détail
                    
                    // Idéalement :
                    /*
                    Navigator.push(context, MaterialPageRoute(builder: (_) => 
                      AddPlantScreen(initialLocation: _catToString(_criteria.category!), preSelectedSpecies: plantData.species)
                    ));
                    */
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- HELPERS UI ---
  Widget _buildQuestionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title, PlantCategory val, Function(PlantCategory) onChanged) {
    return RadioListTile<PlantCategory>(
      title: Text(title),
      value: val,
      groupValue: _criteria.category,
      onChanged: (v) {
        setState(() {
          _criteria.category = v!;
          // Reset des critères spécifiques pour éviter les conflits
          _criteria.minTemp = null;
          _criteria.light = null; 
          // etc.
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildRadioLight(String title, LightLevel val) {
    return RadioListTile<LightLevel>(
      title: Text(title),
      value: val,
      groupValue: _criteria.light,
      onChanged: (v) => setState(() => _criteria.light = v),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRadioTileGeneric<T>(String title, T val, Function(T) onChanged) {
    T? groupValue;
    if (T == FoliageType) {
      groupValue = _criteria.aesthetic as T?;
    } else if (T == VegetableType) {
      groupValue = _criteria.vegType as T?;
    }
    return RadioListTile<T>(
      title: Text(title),
      value: val,
      groupValue: groupValue,
      onChanged: (v) => setState(() {
        onChanged(v!);
      }),
      contentPadding: EdgeInsets.zero,
    );
  }
}