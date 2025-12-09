/*
* Écran affichant la liste des plantes de l'utilisateur, triées par emplacement.
*/

import 'package:flutter/material.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import 'add_plant_screen.dart';
import '../../services/notification_service.dart';
import 'dart:io';
import 'plant_detail_screen.dart';
import 'settings_screen.dart';
import '../common/main_drawer.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> with SingleTickerProviderStateMixin {
  // Cette méthode permet de rafraichir la liste quand on revient de l'ajout

  late TabController _tabController;
  int _refreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On n'utilise plus DefaultTabController ici
    return Scaffold(
      drawer: const MainDrawer(currentIndex: 0),
      appBar: AppBar(
        title: const Text("Sève"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
           IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: "Intérieur"),
            Tab(icon: Icon(Icons.park), text: "Extérieur"),
            Tab(icon: Icon(Icons.local_florist), text: "Potager"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
              // On ajoute le paramètre "key" qui combine le lieu et le trigger
              _PlantList(
                key: ValueKey("indoor_$_refreshTrigger"), 
                locationFilter: 'Intérieur'
              ),
              _PlantList(
                key: ValueKey("outdoor_$_refreshTrigger"), 
                locationFilter: 'Extérieur'
              ),
              _PlantList(
                key: ValueKey("veg_$_refreshTrigger"), 
                locationFilter: 'Potager'
              ),
            ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          String currentLocation = 'Intérieur';
          if (_tabController.index == 1) currentLocation = 'Extérieur';
          if (_tabController.index == 2) currentLocation = 'Potager';

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlantScreen(
                initialLocation: currentLocation 
              ),
            ),
          );

          if (result == true) {
              setState(() {
                 _refreshTrigger++;
              });
            }
        },
        label: const Text("Ajouter"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

// Widget séparé pour afficher la liste, pour ne pas surcharger le code principal
class _PlantList extends StatefulWidget {
  final String locationFilter;

  // On ajoute "super.key" pour accepter la clé qu'on lui envoie
  const _PlantList({
    super.key, 
    required this.locationFilter
  });

  @override
  State<_PlantList> createState() => _PlantListState();
}

class _PlantListState extends State<_PlantList> {
  
  // Fonction pour gérer le clic sur la goutte d'eau
  Future<void> _waterPlant(Plant plant) async {
    await DatabaseService().updatePlantWatering(plant.id);
    
    // Reprogrammation
    final plants = await DatabaseService().getPlants();
    final updated = plants.firstWhere((p) => p.id == plant.id);
    await NotificationService().scheduleAllNotifications(updated);

    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${plant.name} a été arrosée ! 💧"),
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
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                // Avatar avec la première lettre
                leading: Hero(
                  // Le tag doit être IDENTIQUE à celui de l'autre écran (l'ID de la plante)
                  tag: plant.id, 
                  child: plant.photoPath != null
                      ? CircleAvatar(
                          radius: 25,
                          backgroundImage: FileImage(File(plant.photoPath!)),
                        )
                      : CircleAvatar(
                          // ... ton avatar par défaut ...
                        ),
                ),
                
                // Titre et info pièce
                // TITRE : On utilise le nom intelligent
                title: Text(plant.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                
                // SOUS-TITRE : On affiche juste la pièce/lieu (plus besoin de répéter l'espèce)
                subtitle: Text(
                  plant.room != null && plant.room!.isNotEmpty 
                      ? plant.room! 
                      : plant.location,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                // Le bouton d'action rapide
                trailing: plant.trackWatering 
                    ? IconButton( // Si suivi activé -> Bouton normal
                        icon: Icon(
                          days <= 0 ? Icons.water_drop : Icons.check_circle_outline,
                          color: days <= 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
                          size: 32,
                        ),
                        onPressed: () => _waterPlant(plant),
                      )
                    : const Icon(Icons.nature, color: Colors.grey),
                
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailScreen(plant: plant),
                    ),
                  );
                  // On recharge TOUJOURS au retour, comme ça zéro risque.
                  setState(() {});
                }
              ),
            );
          },
        );
      },
    );
  }
}