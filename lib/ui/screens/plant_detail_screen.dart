import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import '../../models/plant.dart';
import '../../data/database_service.dart';
import '../../services/notification_service.dart';
import 'add_plant_screen.dart';
import '../common/smart_watering_sheet.dart';
import 'history_screen.dart';

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
        content: Text("Voulez-vous vraiment dire au revoir à ${_plant.name} ?"),
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
      await NotificationService().cancelNotification(_plant);
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

  @override
  Widget build(BuildContext context) {
    // Calculs pour l'affichage
    final nextWater = DateFormat('dd/MM', 'fr_FR').format(_plant.nextWateringDate);
    final nextFertilizer = DateFormat('MMM yyyy', 'fr_FR').format(_plant.nextFertilizingDate);
    final nextRepot = DateFormat('yyyy', 'fr_FR').format(_plant.nextRepottingDate);

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
                icon: const Icon(Icons.history),
                tooltip: "Voir le journal",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HistoryScreen(plant: _plant)),
                  );
                },
              ),
              // Le fameux menu "3 points"
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editPlant();
                  if (value == 'delete') _deletePlant();
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.grey), SizedBox(width: 8), Text("Modifier")])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Supprimer", style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_plant.name, 
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
                      Text("${_plant.location} - ${_plant.room ?? 'Non précisé'}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                  
                  const Divider(height: 32),

                  // PLANNING (Prochaines actions)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatusBadge(label: "Arrosage", date: nextWater, icon: Icons.water_drop, color: Colors.blue[100]!),
                      if(_plant.fertilizerFreq > 0)
                        _StatusBadge(label: "Engrais", date: nextFertilizer, icon: Icons.science, color: Colors.purple[100]!),
                      _StatusBadge(label: "Rempotage", date: nextRepot, icon: Icons.change_circle, color: Colors.orange[100]!),
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
                          _buildInfoRow(Icons.wb_sunny, "Lumière", _plant.lightLevel),
                          _buildInfoRow(Icons.thermostat, "Température", _plant.temperatureInfo),
                          _buildInfoRow(Icons.water, "Humidité", _plant.humidityPref),
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
              backgroundColor: Colors.transparent,
              builder: (ctx) => SmartWateringSheet(
                plant: _plant,
                onSuccess: () async {
                  // On recharge la plante affichée
                  final updatedList = await DatabaseService().getPlants();
                  final updatedPlant = updatedList.firstWhere((p) => p.id == _plant.id);
                  setState(() {
                    _plant = updatedPlant;
                  });
                }, 
              ),
            );
        },
        label: const Text("Arroser..."), // Petit changement de texte pour indiquer qu'il y a un menu
        icon: const Icon(Icons.water_drop),
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

  const _StatusBadge({required this.label, required this.date, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color,
          child: Icon(icon, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}