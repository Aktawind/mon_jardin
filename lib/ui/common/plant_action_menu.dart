import 'package:flutter/material.dart';
import '../../models/plant.dart';
import '../../models/plant_event.dart'; // Pour les types d'events
import '../../data/database_service.dart';
import '../../services/notification_service.dart';
import 'smart_watering_sheet.dart';

class PlantActionMenu extends StatelessWidget {
  final Plant plant;
  final VoidCallback onSuccess; // Pour rafraichir l'écran parent

  const PlantActionMenu({
    super.key, 
    required this.plant, 
    required this.onSuccess
  });

  // Action générique pour logger et mettre à jour
  Future<void> _performAction(BuildContext context, String type, String successMessage) async {
    Navigator.pop(context); // On ferme le menu tout de suite

    final db = DatabaseService();
    
    // Selon le type, on met à jour la date spécifique dans la table Plant
    if (type == 'water') await db.updatePlantWatering(plant.id);
    if (type == 'fertilizer') await db.updatePlantFertilizing(plant.id);
    if (type == 'repot') await db.updatePlantRepotting(plant.id);
    
    // Pour Taille et Récolte, on logue juste l'événement sans changer de date "future" spécifique
    // (sauf si on ajoute des champs later, mais pour l'instant c'est juste historique)
    if (type == 'prune' || type == 'harvest') {
      await db.logEvent(PlantEvent(
        plantId: plant.id,
        type: type,
        date: DateTime.now(),
      ));
    }

    // On reprogramme les notifs
    // (Astuce : on recharge la plante fraiche pour avoir les nouvelles dates)
    final plants = await db.getPlants();
    final updatedPlant = plants.firstWhere((p) => p.id == plant.id);
    try {
      await NotificationService().scheduleAllNotifications(updatedPlant);
    } catch (e) {
      print("Erreur notif: $e");
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating, // Plus joli
        ),
      );
    }
    
    onSuccess();
  }

  // L'action "Magique" pour les retards (Anti-Culpabilité)
  Future<void> _resetAll(BuildContext context) async {
    Navigator.pop(context);
    final db = DatabaseService();
    
    // On considère qu'on a arrosé et fertilisé aujourd'hui
    await db.updatePlantWatering(plant.id);
    if (plant.trackFertilizer) {
      await db.updatePlantFertilizing(plant.id);
    }
    
    onSuccess();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tout est remis au vert ! 🌿")),
      );
    }
  }

  // Nouvelle méthode pour ouvrir l'observation
  void _openObservation(BuildContext context) {
    // On ferme le menu actuel d'abord pour ouvrir le suivant proprement
    Navigator.pop(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartWateringSheet(
        plant: plant,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Padding réduit en hauteur
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea( // Ajout de SafeArea au cas où
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Petit indicateur pour tirer le menu (optionnel mais joli et prend peu de place)
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            
            Text(
              "Prendre soin de ${plant.name}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16), // Réduit de 24 à 16

            // 1. ACTIONS RAPIDES
            // On enlève le titre "ACTIONS RAPIDES" pour gagner de la place, c'est implicite avec les icônes
            
            Wrap(
              spacing: 12, // Réduit de 16 à 12
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.water_drop,
                  label: "Arroser",
                  color: Colors.blue.shade100,
                  iconColor: Colors.blue.shade800,
                  onTap: () => _performAction(context, 'water', "Plante arrosée ! 💧"),
                ),
                
                if (plant.trackFertilizer)
                  _ActionButton(
                    icon: Icons.science,
                    label: "Engrais", // "Fertiliser" est parfois long, "Engrais" est plus court
                    color: Colors.purple.shade100,
                    iconColor: Colors.purple.shade800,
                    onTap: () => _performAction(context, 'fertilizer', "Miam ! 🧪"),
                  ),

                _ActionButton(
                  icon: Icons.content_cut,
                  label: "Tailler",
                  color: Colors.green.shade100,
                  iconColor: Colors.green.shade800,
                  onTap: () => _performAction(context, 'prune', "Coup de frais ! ✂️"),
                ),

                if (plant.lifecycleStage == 'planted' || plant.location == 'Potager')
                   _ActionButton(
                    icon: Icons.shopping_basket,
                    label: "Récolter",
                    color: Colors.orange.shade100,
                    iconColor: Colors.deepOrange,
                    onTap: () => _performAction(context, 'harvest', "Bon appétit ! 🍅"),
                  ),

                _ActionButton(
                  icon: Icons.change_circle,
                  label: "Rempoter",
                  color: Colors.brown.shade100,
                  iconColor: Colors.brown.shade800,
                  onTap: () => _performAction(context, 'repot', "Nouvelle maison ! 🪴"),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            // On enlève le titre "OBSERVATIONS" aussi

            // 2. OBSERVATIONS (Compacté)
            ListTile(
              dense: true, // Rend le ListTile plus compact
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 16, backgroundColor: Colors.teal.shade50, child: Icon(Icons.touch_app, size: 18, color: Colors.teal)),
              title: const Text("Ajuster (Terre sèche/humide)", style: TextStyle(fontSize: 14)),
              onTap: () => _openObservation(context),
            ),
            
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade50, child: const Icon(Icons.history, size: 18, color: Colors.grey)),
              title: const Text("J'ai tout fait sans noter", style: TextStyle(fontSize: 14)),
              onTap: () => _resetAll(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Petit Widget interne pour les boutons carrés
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    // Calcul un peu plus serré
    final width = (MediaQuery.of(context).size.width - 48 - 24) / 3; 

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Un peu moins rond
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12), // Réduit de 16 à 12
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: iconColor), // Réduit de 32 à 28
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}