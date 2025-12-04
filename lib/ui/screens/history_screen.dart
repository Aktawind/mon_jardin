import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/plant.dart';
import '../../models/plant_event.dart';
import '../../data/database_service.dart';

class HistoryScreen extends StatelessWidget {
  final Plant plant;

  const HistoryScreen({super.key, required this.plant});

  IconData _getIcon(String type) {
    switch (type) {
      case 'water': return Icons.water_drop;
      case 'fertilizer': return Icons.science;
      case 'repot': return Icons.change_circle;
      case 'prune': return Icons.content_cut;
      default: return Icons.history;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'water': return Colors.blue;
      case 'fertilizer': return Colors.purple;
      case 'repot': return Colors.orange;
      case 'prune': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getText(String type) {
    switch (type) {
      case 'water': return "Arrosage";
      case 'fertilizer': return "Fertilisation";
      case 'repot': return "Rempotage";
      case 'prune': return "Taille";
      default: return "Action";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Journal de ${plant.displayName}"),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: FutureBuilder<List<PlantEvent>>(
        future: DatabaseService().getEventsForPlant(plant.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text("Aucun historique pour l'instant."));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColor(event.type).withOpacity(0.2),
                  child: Icon(_getIcon(event.type), color: _getColor(event.type), size: 20),
                ),
                title: Text(_getText(event.type)),
                subtitle: Text(DateFormat('EEEE d MMMM à HH:mm', 'fr_FR').format(event.date)),
              );
            },
          );
        },
      ),
    );
  }
}