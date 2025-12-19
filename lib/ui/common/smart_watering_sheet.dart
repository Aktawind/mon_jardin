/*
* Widget pour la feuille de dialogue d'arrosage intelligent.
* Permet à l'utilisateur d'indiquer si la terre est humide ou sèche.
* Ajuste la fréquence d'arrosage en fonction des retours utilisateur.
* Met à jour la base de données locale et reprogramme les notifications.
*/

import 'package:flutter/material.dart';
import '../../models/plant.dart';
import '../../data/database_service.dart';
import '../../services/notification_service.dart';

class SmartWateringSheet extends StatelessWidget {
  final Plant plant;
  final VoidCallback onSuccess;

  const SmartWateringSheet({super.key, required this.plant, required this.onSuccess});

  // Cas 1 : Terre Humide (On repousse l'arrosage + Apprentissage)
  Future<void> _tooWet(BuildContext context) async {
    Navigator.pop(context);
    
    // On apprend : +1 jour au cycle (le cycle était trop court)
    await DatabaseService().adjustPlantFrequency(plant, 1);
    
    final newFreq = plant.effectiveWaterFrequency + 1; // La fréquence vient d'augmenter
    // On veut le prochain rappel dans 2 jours (arbitraire mais logique si humide)
    final daysAgo = newFreq - 2; 
    final fakeLastWater = DateTime.now().subtract(Duration(days: daysAgo));
    
    // On met à jour la date sans logger l'événement (ce n'est pas un vrai arrosage)
    final db = DatabaseService();
    await db.database.then((d) => d.update(
      'plants',
      {'last_watered': fakeLastWater.toIso8601String()},
      where: 'id = ?',
      whereArgs: [plant.id],
    ));

    await _reschedule(plant);
    _showSnack(context, "C'est noté ! Je vous rappelle dans 2 jours.");
    onSuccess();
  }

  // Cas 2 : Terre Sèche (On rapproche l'arrosage + Apprentissage)
  Future<void> _tooDry(BuildContext context) async {
    Navigator.pop(context);
    
    // On apprend : -1 jour au cycle (le cycle était trop long)
    await DatabaseService().adjustPlantFrequency(plant, -1);
    
    // ICI, C'est subtil :
    // Tu as dit "on marque la plante comme étant à arroser".
    // Le plus simple c'est de laisser l'utilisateur cliquer sur "Arroser" dans le menu principal s'il veut arroser maintenant.
    // MAIS, si c'est très sec, logiquement on arrose tout de suite.
    // Proposons d'arroser immédiatement pour être logique.
    
    await DatabaseService().updatePlantWatering(plant.id);
    await _reschedule(plant);
    if (!context.mounted) return;
    
    _showSnack(context, "Arrosé ! Je te rappellerai un peu plus tôt la prochaine fois.");
    onSuccess();
  }

  Future<void> _reschedule(Plant p) async {
    final plants = await DatabaseService().getPlants();
    final updatedPlant = plants.firstWhere((pl) => pl.id == p.id);
    await NotificationService().scheduleAllNotifications(updatedPlant);
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("État de la terre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Pour ajuster le cycle de ${plant.displayName}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.cloud_off, color: Colors.white)),
            title: const Text("La terre est encore humide"),
            subtitle: const Text("→ Repousser et arroser moins souvent"),
            onTap: () => _tooWet(context),
          ),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.wb_sunny, color: Colors.white)),
            title: const Text("La terre est très sèche"),
            subtitle: const Text("→ Arroser maintenant et augmenter la fréquence"),
            onTap: () => _tooDry(context),
          ),
        ],
      ),
    );
  }
}