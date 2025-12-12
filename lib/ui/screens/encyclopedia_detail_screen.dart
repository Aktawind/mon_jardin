/*
* Écran de détail de la fiche encyclopédique d'une espèce végétale.
* Affiche les informations détaillées issues de la base de données encyclopédique.
* Permet d'ajouter la plante au jardin depuis cette fiche.
* Utilise le modèle PlantSpeciesData pour structurer les données.
*/

import 'package:flutter/material.dart';
import '../../models/plant_species_data.dart';
import '../../models/enums.dart'; // Pour les labels
import 'add_plant_screen.dart'; // Pour le bouton ajouter
import '../common/ui_helpers.dart';

class EncyclopediaDetailScreen extends StatelessWidget {
  final PlantSpeciesData data;

  const EncyclopediaDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    bool hasCalendarData = data.sowingMonths.isNotEmpty ||
                data.plantingMonths.isNotEmpty ||
                data.harvestMonths.isNotEmpty ||
                data.pruningMonths.isNotEmpty ||
                data.repottingMonths.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.green[50], // Fond légèrement coloré pour distinguer
      appBar: AppBar(
        title: Text(data.species),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EN-TÊTE
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                child: Icon(getPlantIcon(data), size: 40, color:Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                data.species,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            if (data.synonyms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    "Aussi appelée : ${data.synonyms.join(', ')}",
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),

            // 1. CARTE D'IDENTITÉ
            _buildSectionTitle("Identité"),
            Card(
              child: Column(
                children: [
                  _buildRow(Icons.category, "Catégorie", _catToString(data.category)),
                  _buildRow(Icons.loop, "Cycle de vie", _cycleToString(data.cycle)),
                  _buildRow(Icons.signal_cellular_alt, "Difficulté", data.difficulty.label),
                  if (data.foliage != null)
                    _buildRow(Icons.palette, "Esthétique", data.foliage!.label),
                ],
              ),
            ),

            // 2. BESOINS VITAUX
            _buildSectionTitle("Besoins & Environnement"),
            Card(
              child: Column(
                children: [
                  _buildRow(Icons.wb_sunny, "Lumière", data.light.label),
                  _buildRow(Icons.thermostat, "Rusticité (Hiver)", data.temperature.label),
                  _buildRow(Icons.water_drop, "Besoin en eau", _waterNeedToString(data.waterSummer)), // Logique simple
                  _buildRow(Icons.science, "Engrais", _fertilizerToString(data.fertilizeFreq)),
                  _buildRow(Icons.water, "Humidité air", data.humidity.label),
                  _buildRow(Icons.grass, "Sol idéal", data.soilInfo),
                ],
              ),
            ),

            // 3. CALENDRIER THEORIQUE
            if (hasCalendarData) ...[
              _buildSectionTitle("Calendrier"),
              Card(
                child: Column(
                  children: [
                    if (data.sowingMonths.isNotEmpty)
                      _buildCalendarRow(Icons.grain, "Semis", data.sowingMonths),
                    if (data.plantingMonths.isNotEmpty)
                      _buildCalendarRow(Icons.agriculture, "Plantation", data.plantingMonths),
                    if (data.harvestMonths.isNotEmpty)
                      _buildCalendarRow(Icons.shopping_basket, "Récolte", data.harvestMonths),
                    if (data.pruningMonths.isNotEmpty)
                      _buildCalendarRow(Icons.content_cut, "Taille", data.pruningMonths),
                    if (data.repottingMonths.isNotEmpty)
                      _buildCalendarRow(Icons.change_circle, "Rempotage", data.repottingMonths),
                  ],
                ),
              ),
            ],

            // 4. INFOS SUPPLEMENTAIRES
            _buildSectionTitle("Bon à savoir"),
            Card(
              child: Column(
                children: [
                  _buildRow(Icons.pets, "Toxicité", data.toxicity.label),
                  if (data.pruningInfo.isNotEmpty)
                    _buildRow(Icons.info_outline, "Entretien", data.pruningInfo),
                ],
              ),
            ),
            
            const SizedBox(height: 80), // Espace pour le FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddPlantScreen(
                initialLocation: _catToString(data.category),
                preSelectedSpecies: data.species,
              ),
            ),
          );
        },
        label: const Text("Ajouter à mon jardin"),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green[800], letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return ListTile(
      //leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      dense: true,
    );
  }

  Widget _buildCalendarRow(IconData icon, String label, List<int> months) {
    // Convertir [3, 4, 5] en "Mars, Avril, Mai"
    final monthNames = months.map((m) => _monthName(m)).join(', ');
    return _buildRow(icon, label, monthNames);
  }

  String _monthName(int m) {
    const names = ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Aoû", "Sep", "Oct", "Nov", "Déc"];
    return names[m - 1];
  }

  String _catToString(PlantCategory cat) {
    switch (cat) {
      case PlantCategory.indoor: return "Intérieur";
      case PlantCategory.outdoor: return "Extérieur";
      case PlantCategory.vegetable: return "Potager";
      case PlantCategory.herb: return "Aromatique";
    }
  }
  
  String _cycleToString(PlantCycle cycle) {
    switch (cycle) {
      case PlantCycle.annual: return "Annuelle (1 an)";
      case PlantCycle.biennial: return "Bisannuelle (2 ans)";
      case PlantCycle.perennial: return "Vivace (Revient chaque année)";
    }
  }

  String _waterNeedToString(int freq) {
    if (freq < 3) return "Très élevé (Tous les jours)";
    if (freq < 7) return "Élevé (2-3 fois/semaine)";
    if (freq < 14) return "Moyen (1 fois/semaine)";
    return "Faible (Laisser sécher)";
  }

  String _fertilizerToString(int freq) {
    if (freq <= 0) return "Aucun besoin particulier";
    if (freq <= 15) return "Tous les 15 jours (Croissance)";
    if (freq <= 30) return "Mensuel (Croissance)";
    return "Tous les $freq jours";
  }
}