import 'package:flutter/material.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import 'add_plant_screen.dart';
import '../../services/notification_service.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Cette méthode permet de rafraichir la liste quand on revient de l'ajout
  void _refreshPlants() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Deux onglets
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mon Jardin"),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary, // Vert d'eau
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.home), text: "Intérieur"),
              Tab(icon: Icon(Icons.park), text: "Extérieur"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlantList(locationFilter: 'Intérieur'),
            _PlantList(locationFilter: 'Extérieur'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // On attend le retour de l'écran d'ajout
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPlantScreen()),
            );
            // Si on a ajouté une plante, on rafraichit la liste
            if (result == true) {
              _refreshPlants();
            }
          },
          label: const Text("Ajouter"),
          icon: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.secondary, // Rose
        ),
      ),
    );
  }
}

// Widget séparé pour afficher la liste, pour ne pas surcharger le code principal
class _PlantList extends StatefulWidget {
  final String locationFilter;

  const _PlantList({required this.locationFilter});

  @override
  State<_PlantList> createState() => _PlantListState();
}

class _PlantListState extends State<_PlantList> {
  
  // Fonction pour gérer le clic sur la goutte d'eau
  Future<void> _waterPlant(Plant plant) async {
    // 1. Mise à jour BDD
    await DatabaseService().updatePlantWatering(plant.id);
    
    // 2. On récupère la plante mise à jour pour avoir la NOUVELLE date calculée
    // (Petite astuce : comme updatePlantWatering ne renvoie pas l'objet, 
    // on peut recalculer manuellement ou recharger, ici on recrée une instance temporaire propre)
    final updatedPlant = Plant(
      id: plant.id,
      name: plant.name,
      species: plant.species,
      location: plant.location,
      room: plant.room,
      dateAdded: plant.dateAdded,
      waterFrequencySummer: plant.waterFrequencySummer,
      waterFrequencyWinter: plant.waterFrequencyWinter,
      // Le point clé : on simule que lastWatered est "Maintenant"
      lastWatered: DateTime.now(), 
    );

    // 3. On programme la prochaine notif
    await NotificationService().schedulePlantNotification(updatedPlant);

    setState(() {});
    
    // Petit feedback visuel en bas de l'écran
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${plant.name} a été arrosée ! 💧"),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plant>>(
      future: DatabaseService().getPlants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final plants = snapshot.data!
            .where((p) => p.location == widget.locationFilter)
            .toList();
            
        // Optionnel : Trier pour mettre ceux qui ont soif en premier !
        plants.sort((a, b) => a.daysUntilWatering.compareTo(b.daysUntilWatering));

        if (plants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Aucune plante en ${widget.locationFilter}", 
                  style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            final days = plant.daysUntilWatering;
            
            // Gestion des couleurs et textes selon l'urgence
            Color statusColor;
            String statusText;
            
            if (days < 0) {
              statusColor = Colors.redAccent;
              statusText = "En retard de ${days.abs()} j !";
            } else if (days == 0) {
              statusColor = Colors.orange;
              statusText = "Aujourd'hui !";
            } else {
              statusColor = Colors.green;
              statusText = "Dans $days j";
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                // Avatar avec la première lettre
                leading: plant.photoPath != null
                    ? CircleAvatar(
                        radius: 25,
                        backgroundImage: FileImage(File(plant.photoPath!)),
                      )
                    : CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          plant.name.isNotEmpty ? plant.name[0].toUpperCase() : "?",
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                
                // Titre et info pièce
                title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.species),
                    if (plant.room != null && plant.room!.isNotEmpty)
                      Text("📍 ${plant.room}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    // Le petit indicateur de temps
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                
                // Le bouton d'action rapide
                trailing: IconButton(
                  icon: Icon(
                    days <= 0 ? Icons.water_drop : Icons.check_circle_outline,
                    color: days <= 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
                    size: 32,
                  ),
                  onPressed: () => _waterPlant(plant),
                  tooltip: "Marquer comme arrosée",
                ),
                
                onTap: () async {
                  // Navigation vers l'écran d'ajout, mais en passant la plante existante
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPlantScreen(plantToEdit: plant),
                    ),
                  );
                  
                  // Si on a supprimé ou modifié, on rafraichit la liste
                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}