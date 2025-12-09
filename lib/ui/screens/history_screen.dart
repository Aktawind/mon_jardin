import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plant.dart';
import '../../models/plant_event.dart';
import '../../data/database_service.dart';

class HistoryScreen extends StatefulWidget {
  final Plant plant;

  const HistoryScreen({super.key, required this.plant});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // On stocke le Future dans une variable pour pouvoir le relancer
  late Future<List<PlantEvent>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = DatabaseService().getEventsForPlant(widget.plant.id);
    });
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'water': return Icons.water_drop;
      case 'fertilizer': return Icons.science;
      case 'repot': return Icons.change_circle;
      case 'prune': return Icons.content_cut;
      case 'sow': return Icons.grain;
      case 'harvest': return Icons.shopping_basket;
      // Ajoute ici tes nouveaux types si besoin (planting...)
      default: return Icons.history;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'water': return Colors.blue;
      case 'fertilizer': return Colors.purple;
      case 'repot': return Colors.orange;
      case 'prune': return Colors.green;
      case 'harvest': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _getText(String type) {
    switch (type) {
      case 'water': return "Arrosage";
      case 'fertilizer': return "Fertilisation";
      case 'repot': return "Rempotage";
      case 'prune': return "Taille";
      case 'sow': return "Semis";
      case 'harvest': return "Récolte";
      case 'planting': return "Mise en terre";
      default: return "Action";
    }
  }

  Future<void> _deleteEntry(int eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer cette entrée ?"),
        content: const Text("Cela effacera la trace de l'historique."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().deleteEvent(eventId);
      _loadHistory(); // On recharge la liste
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entrée supprimée")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Journal de ${widget.plant.displayName}"), // Utilise le getter intelligent
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: FutureBuilder<List<PlantEvent>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Aucun historique pour l'instant.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColor(event.type).withOpacity(0.2),
                  child: Icon(_getIcon(event.type), color: _getColor(event.type), size: 20),
                ),
                title: Text(_getText(event.type), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').format(event.date)),
                    if (event.note != null && event.note!.isNotEmpty)
                      Text(event.note!, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                trailing: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onTap: () {
                  // Clic simple : on pourrait ouvrir un détail, mais ici rien pour l'instant
                },
                onLongPress: () {
                  if (event.id != null) _deleteEntry(event.id!);
                },
              );
            },
          );
        },
      ),
    );
  }
}