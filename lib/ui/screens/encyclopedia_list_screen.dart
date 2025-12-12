import 'package:flutter/material.dart';
import '../../services/encyclopedia_service.dart';
import '../../models/plant_species_data.dart';
import '../../models/enums.dart';
import '../common/main_drawer.dart'; // Pour le menu
import 'encyclopedia_detail_screen.dart';
import '../common/ui_helpers.dart';

class EncyclopediaListScreen extends StatefulWidget {
  const EncyclopediaListScreen({super.key});

  @override
  State<EncyclopediaListScreen> createState() => _EncyclopediaListScreenState();
}

class _EncyclopediaListScreenState extends State<EncyclopediaListScreen> {
  // Liste complète
  List<PlantSpeciesData> _allPlants = [];
  // Liste filtrée affichée
  List<PlantSpeciesData> _filteredPlants = [];
  
  // Filtres
  String _searchQuery = "";
  PlantCategory? _selectedCategory; // Null = Tout

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // On charge tout et on trie
    final list = EncyclopediaService().getAll();
    list.sort((a, b) => a.species.compareTo(b.species));
    
    setState(() {
      _allPlants = list;
      _filteredPlants = list;
    });
  }

  void _filter() {
    setState(() {
      _filteredPlants = _allPlants.where((p) {
        // 1. Filtre Texte (Nom ou Synonymes)
        bool matchText = true;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          matchText = p.species.toLowerCase().contains(q) || 
                      p.synonyms.any((s) => s.toLowerCase().contains(q));
        }

        // 2. Filtre Catégorie
        bool matchCat = true;
        if (_selectedCategory != null) {
          matchCat = p.category == _selectedCategory;
        }

        return matchText && matchCat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Encyclopédie"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const MainDrawer(currentIndex: 3), // Index 3 pour l'Encyclopédie (à ajouter dans le drawer)
      body: Column(
        children: [
          // BARRE DE RECHERCHE & FILTRES
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            child: Column(
              children: [
                // Champ Texte
                TextField(
                  decoration: InputDecoration(
                    hintText: "Rechercher une plante...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _filter();
                  },
                ),
                const SizedBox(height: 12),
                
                // Chips Catégorie
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Tout", null),
                      const SizedBox(width: 8),
                      _buildFilterChip("Intérieur", PlantCategory.indoor),
                      const SizedBox(width: 8),
                      _buildFilterChip("Extérieur", PlantCategory.outdoor),
                      const SizedBox(width: 8),
                      _buildFilterChip("Potager", PlantCategory.vegetable),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LISTE RESULTATS
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPlants.length,
              itemBuilder: (context, index) {
                final plant = _filteredPlants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    child: Icon(getPlantIcon(plant), color:Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                  ),
                  title: Text(plant.species, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plant.difficulty.label),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EncyclopediaDetailScreen(data: plant)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, PlantCategory? cat) {
    final isSelected = _selectedCategory == cat;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedCategory = selected ? cat : null; // Si on décoche, on revient à null
          _filter();
        });
      },
      checkmarkColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}