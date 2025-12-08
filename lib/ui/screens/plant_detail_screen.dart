import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import '../../models/plant.dart';
import '../../data/database_service.dart';
import '../../services/notification_service.dart';
import 'add_plant_screen.dart';
import 'history_screen.dart';
import '../common/plant_action_menu.dart';
import '../common/plant_management_menu.dart';
import 'photo_gallery_screen.dart';
import '../../models/plant_event.dart';
import '../../services/encyclopedia_service.dart';
import '../../models/enums.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late Plant _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant; // On initialise avec la plante passée en paramètre
  }

  // --- ACTIONS DU MENU ---
  void _openAlbum() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhotoGalleryScreen(plant: _plant)),
    );
  }

  Future<void> _editPlant() async {
    // On ouvre l'écran d'ajout en mode "Édition"
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPlantScreen(plantToEdit: _plant)),
    );

    // Au retour, on recharge les données fraiches depuis la BDD
    final updatedList = await DatabaseService().getPlants();
    final updatedPlant = updatedList.firstWhere((p) => p.id == _plant.id);

    setState(() {
      _plant = updatedPlant;
    });
  }

  Future<void> _deletePlant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous vraiment dire au revoir à ${_plant.displayName} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Non")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Oui, supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().deletePlant(_plant.id);
      await NotificationService().cancelAllNotifications(_plant);
      if (mounted) {
        Navigator.pop(context, true); // On revient à l'accueil en disant "J'ai changé qqchose"
      }
    }
  }

  // --- WIDGETS D'AFFICHAGE (Helpers) ---

  Widget _buildInfoRow(IconData icon, String title, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  // Widget pour visualiser et changer le stade
  Widget _buildLifecycleStepper() {
    // On n'affiche ça que pour le Potager
    if (_plant.location != 'Potager') return const SizedBox.shrink();

    int currentStep = 0;
    if (_plant.lifecycleStage == 'seedling') currentStep = 1;
    if (_plant.lifecycleStage == 'planted') currentStep = 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Cycle de vie"),
        
        // On utilise un simple Row avec des icônes colorées
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepIcon('seed', Icons.grain, "Graine", currentStep >= 0, currentStep == 0),
              _buildArrow(),
              _buildStepIcon('seedling', Icons.spa, "Semis", currentStep >= 1, currentStep == 1),
              _buildArrow(),
              _buildStepIcon('planted', Icons.grass, "En terre", currentStep >= 2, currentStep == 2),
            ],
          ),
        ),
        
        // Bouton d'action pour avancer
        if (currentStep < 2)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ElevatedButton.icon(
              onPressed: _advanceLifecycle,
              icon: const Icon(Icons.arrow_forward),
              label: Text(currentStep == 0 ? "J'ai semé (Passer en Semis)" : "J'ai planté (Passer en Terre)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.green[900],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepIcon(String stage, IconData icon, String label, bool isReached, bool isCurrent) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: isReached ? (isCurrent ? Colors.green : Colors.green[200]) : Colors.grey[300],
          radius: 20,
          child: Icon(icon, color: isReached ? Colors.white : Colors.grey, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return const Icon(Icons.chevron_right, color: Colors.grey, size: 20);
  }

  // Action pour avancer d'une étape
  Future<void> _advanceLifecycle() async {
    String nextStage = 'planted';
    if (_plant.lifecycleStage == 'seed') nextStage = 'seedling';
    
    // Mise à jour BDD
    final db = DatabaseService();
    // Il nous faut une méthode updatePlantStage ou on update toute la plante
    // Pour faire simple et propre, on update toute la plante en changeant juste le champ
    
    // Copie de la plante avec nouveau stade
    final updatedPlant = Plant(
      id: _plant.id,
      name: _plant.name,
      species: _plant.species,
      location: _plant.location,
      room: _plant.room,
      photoPath: _plant.photoPath,
      dateAdded: _plant.dateAdded,
      lastWatered: _plant.lastWatered,
      lastFertilized: _plant.lastFertilized,
      lastRepotted: _plant.lastRepotted,
      waterFrequencySummer: _plant.waterFrequencySummer,
      waterFrequencyWinter: _plant.waterFrequencyWinter,
      lightLevel: _plant.lightLevel,
      temperatureInfo: _plant.temperatureInfo,
      humidityPref: _plant.humidityPref,
      soilType: _plant.soilType,
      pruningInfo: _plant.pruningInfo,
      fertilizerFreq: _plant.fertilizerFreq,
      repottingFreq: _plant.repottingFreq,
      trackWatering: _plant.trackWatering,
      trackFertilizer: _plant.trackFertilizer,
      
      lifecycleStage: nextStage, // <--- CHANGEMENT ICI
    );

    await db.updatePlant(updatedPlant);
    
    // On logue l'événement dans l'historique
    // ex: "Semis effectué" ou "Mise en terre"
    String eventType = nextStage == 'seedling' ? 'sow' : 'repot'; // On utilise 'repot' pour la plantation en terre
    await db.logEvent(PlantEvent(
      plantId: _plant.id,
      type: eventType,
      date: DateTime.now(),
      note: "Changement de stade : $nextStage",
    ));

    setState(() {
      _plant = updatedPlant;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stade mis à jour ! 🌱")));
  }

  @override
  Widget build(BuildContext context) {
    // Calculs pour l'affichage
    String nextWaterText;
    if (_plant.currentFrequency <= 0) {
      nextWaterText = "Repos";
    } else {
      nextWaterText = DateFormat('dd/MM', 'fr_FR').format(_plant.nextWateringDate);
    }
    final nextFertilizer = DateFormat('MMM yyyy', 'fr_FR').format(_plant.nextFertilizingDate);
    final nextRepot = DateFormat('yyyy', 'fr_FR').format(_plant.nextRepottingDate);
    final speciesData = EncyclopediaService().getData(_plant.species);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. L'IMAGE EN HAUT (SliverAppBar)
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true, // La barre reste visible quand on scrolle
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert), // Les 3 points verticaux (Standard)
                // Ou Icons.menu si tu préfères les barres
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => PlantManagementMenu(
                      plant: _plant,
                      onEdit: _editPlant,
                      onDelete: _deletePlant,
                      onHistory: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HistoryScreen(plant: _plant)),
                        );
                      },
                      onAlbum: _openAlbum,
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_plant.displayName, 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)]
                )
              ),
              background: Hero(
                tag: _plant.id, // L'animation Hero !
                child: _plant.photoPath != null
                    ? Image.file(File(_plant.photoPath!), fit: BoxFit.cover)
                    : Container(color: Colors.grey[300], child: const Icon(Icons.spa, size: 80, color: Colors.white)),
              ),
            ),
          ),

          // 2. LE CONTENU
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Identité
                  Text(_plant.species, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        // Condition ternaire : Si on a une pièce, on l'affiche avec le tiret, sinon juste le lieu
                        (_plant.room != null && _plant.room!.isNotEmpty)
                            ? "${_plant.location} - ${_plant.room}"
                            : _plant.location,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),

                  // CYCLE DE VIE
                  _buildLifecycleStepper(),
                  const SizedBox(height: 16),

                  // BESOINS ACTUELS
                  if (_plant.lifecycleStage != 'seed') 
                     _buildSectionTitle("Besoins actuels"),

                  // PLANNING (Prochaines actions)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Opacity(
                        opacity: _plant.lifecycleStage == 'seed' ? 0.3 : 1.0, // <--- Grisé
                        child: _StatusBadge(
                          label: "Arrosage",
                          date: nextWaterText,
                          icon: Icons.water_drop,
                          color: Colors.blue[100]!,
                        ),
                      ),
                      
                      if(_plant.trackFertilizer && _plant.fertilizerFreq > 0)
                        Opacity(
                          opacity: _plant.lifecycleStage == 'seed' ? 0.3 : 1.0, // <--- Grisé
                          child: _StatusBadge(
                            label: "Engrais",
                            date: nextFertilizer,
                            icon: Icons.science,
                            color: Colors.purple[100]!,
                          ),
                        ),
                        
                      if(_plant.repottingFreq > 0)
                        _StatusBadge(
                          label: "Rempotage",
                          date: nextRepot,
                          icon: Icons.change_circle,
                          color: Colors.orange[100]!,
                        ),
                    ],
                  ),

                  // ENVIRONNEMENT
                  _buildSectionTitle("Environnement Idéal"),
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.wb_sunny, "Lumière", speciesData?.light.label ?? _plant.lightLevel),
                          _buildInfoRow(Icons.thermostat, "Rusticité", speciesData?.temperature.label ?? _plant.temperatureInfo),
                          _buildInfoRow(Icons.water, "Humidité", speciesData?.humidity.label ?? _plant.humidityPref),
                          _buildInfoRow(Icons.pets, "Toxicité", speciesData?.toxicity.label ?? "Inconnu"),
                        ],
                      ),
                    ),
                  ),

                  // ENTRETIEN
                  _buildSectionTitle("Soins & Entretien"),
                  _buildInfoRow(Icons.grass, "Terreau recommandé", _plant.soilType),
                  _buildInfoRow(Icons.content_cut, "Taille", _plant.pruningInfo),
                  
                  // Info technique (fréquence)
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Cette plante a besoin d'eau environ tous les ${_plant.waterFrequencySummer} jours en été.",
                            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50), // Marge en bas
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Petit bouton flottant pour valider l'arrosage rapidement
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent, // Important pour voir les coins ronds
            builder: (ctx) => PlantActionMenu(
              plant: _plant,
              onSuccess: () async {
                // Rafraichissement
                final updatedList = await DatabaseService().getPlants();
                final updatedPlant = updatedList.firstWhere((p) => p.id == _plant.id);
                setState(() {
                  _plant = updatedPlant;
                });
              },
            ),
          );
        },
        // Un Label bien explicite pour ta maman
        label: const Text("Prendre soin...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        icon: const Icon(Icons.volunteer_activism), // Une icône "main qui donne" ou un coeur
        elevation: 4,
      ),
    );
  }
}

// Petit widget interne pour les badges ronds (Planning)
class _StatusBadge extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap; // Si null, pas d'action

  const _StatusBadge({
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si on a une action (onTap), on affiche différemment
    final isActionable = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // L'icône avec potentiellement un petit badge "+"
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    // Une petite ombre si c'est cliquable pour donner du relief
                    boxShadow: isActionable
                        ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Icon(icon, color: Colors.black54, size: 24),
                ),
                
                // La petite pastille d'action
                if (isActionable)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                      ),
                      child: const Icon(Icons.edit, size: 10, color: Colors.black87),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            // On souligne légèrement la date si c'est cliquable
            Text(
              date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
