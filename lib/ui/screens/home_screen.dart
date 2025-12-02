import 'package:flutter/material.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import 'add_plant_screen.dart';

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
class _PlantList extends StatelessWidget {
  final String locationFilter;

  const _PlantList({required this.locationFilter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Plant>>(
      future: DatabaseService().getPlants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // On filtre la liste globale pour ne garder que le bon lieu
        final plants = snapshot.data!
            .where((p) => p.location == locationFilter)
            .toList();

        if (plants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("Aucune plante en $locationFilter", 
                  style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final plant = plants[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Text(plant.name[0].toUpperCase(), 
                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(plant.species),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Plus tard : aller vers le détail de la plante
                },
              ),
            );
          },
        );
      },
    );
  }
}