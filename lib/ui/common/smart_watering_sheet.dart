import 'package:flutter/material.dart';
import '../../models/plant.dart';
import '../../data/database_service.dart';
import '../../services/notification_service.dart';

class SmartWateringSheet extends StatelessWidget {
  final Plant plant;
  final VoidCallback onSuccess; // Pour dire à l'écran parent de rafraichir

  const SmartWateringSheet({super.key, required this.plant, required this.onSuccess});

  // 1. Cas Standard : On arrose, on ne change rien
  Future<void> _waterStandard(BuildContext context) async {
    Navigator.pop(context); // Ferme le menu
    await DatabaseService().updatePlantWatering(plant.id);
    await _reschedule(plant);
    _showSnack(context, "Arrosée ! À dans ${plant.currentFrequency} jours.");
    onSuccess();
  }

  // 2. Cas "Terre Humide" : On n'arrose pas, on décale et on augmente la fréquence
  Future<void> _snoozeAndLearn(BuildContext context) async {
    Navigator.pop(context);
    
    // On apprend : +1 jour au cycle
    await DatabaseService().adjustPlantFrequency(plant, 1);
    
    // On ne touche PAS à last_watered (car on n'a pas arrosé).
    // Mais comme on a augmenté la fréquence, la "nextWateringDate" va reculer mécaniquement.
    // Cependant, pour le Snooze immédiat (ne pas rappeler demain), c'est l'augmentation de fréquence qui va jouer.
    
    // Note : Pour faire un vrai "Snooze" de 2 jours fixes sans toucher à la fréquence, il faudrait une colonne "snooze_until".
    // Ici, on fait le pari de l'apprentissage : si c'est humide, c'est que le cycle est trop court.
    
    // On force la reprogrammation de la notif avec la nouvelle fréquence
    // Astuce : on recharche la plante pour avoir la nouvelle fréquence à jour
    final plants = await DatabaseService().getPlants();
    final updatedPlant = plants.firstWhere((p) => p.id == plant.id);
    await NotificationService().schedulePlantNotification(updatedPlant);

    _showSnack(context, "C'est noté ! Je la laisserai tranquille un peu plus longtemps.");
    onSuccess();
  }

  // 3. Cas "Trop sec / Urgence" : On arrose et on réduit la fréquence
  Future<void> _waterEarlyAndLearn(BuildContext context) async {
    Navigator.pop(context);
    
    // On arrose
    await DatabaseService().updatePlantWatering(plant.id);
    // On apprend : -1 jour au cycle
    await DatabaseService().adjustPlantFrequency(plant, -1);
    
    await _reschedule(plant);
    
    _showSnack(context, "Arrosée ! Je te rappellerai un peu plus tôt la prochaine fois.");
    onSuccess();
  }

  // Helper pour reprogrammer
  Future<void> _reschedule(Plant p) async {
    // Il faut recharger la plante depuis la BDD pour avoir les dates à jour si on vient de modifier
    final plants = await DatabaseService().getPlants();
    final updatedPlant = plants.firstWhere((pl) => pl.id == p.id);
    await NotificationService().schedulePlantNotification(updatedPlant);
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      // On stylise un peu le haut pour faire joli
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prend juste la place nécessaire
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text("Arrosage de ${plant.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Comment est la terre ?", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          
          // Option 1 : Trop humide
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.cloud_off, color: Colors.white)),
            title: const Text("Encore humide"),
            subtitle: const Text("Repousser et arroser moins souvent"),
            onTap: () => _snoozeAndLearn(context),
          ),
          
          // Option 2 : Parfait (Standard)
          Container(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.check, color: Colors.white)),
              title: const Text("Arroser maintenant"),
              subtitle: const Text("Cycle normal"),
              onTap: () => _waterStandard(context),
            ),
          ),
          
          // Option 3 : Trop sec
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.wb_sunny, color: Colors.white)),
            title: const Text("Terre très sèche"),
            subtitle: const Text("Arroser et augmenter la fréquence"),
            onTap: () => _waterEarlyAndLearn(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}