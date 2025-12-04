import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../models/calendar_task.dart';
import '../../services/task_service.dart';
import 'plant_detail_screen.dart'; // Pour aller voir la plante au clic

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now(); // Le mois qu'on regarde
  List<Plant> _plants = [];
  
  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  // On charge les plantes depuis la BDD
  Future<void> _loadPlants() async {
    final plants = await DatabaseService().getPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
      });
    }
  }

  // Changer de mois
  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
    });
  }

  // Couleurs selon le type de tâche
  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.water: return Colors.blue;
      case TaskType.fertilizer: return Colors.purple;
      case TaskType.repot: return Colors.orange;
      case TaskType.prune: return Colors.green;
      case TaskType.harvest: return Colors.redAccent;
      case TaskType.sow: return Colors.brown;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.water: return Icons.water_drop;
      case TaskType.fertilizer: return Icons.science;
      case TaskType.repot: return Icons.change_circle;
      case TaskType.prune: return Icons.content_cut;
      case TaskType.harvest: return Icons.shopping_basket;
      case TaskType.sow: return Icons.grass;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. On génère toutes les tâches
    final allTasks = TaskService().getTasksForMonth(_plants, _currentDate.month, _currentDate.year);
    
    // 2. FILTRE : On enlève les arrosages pour la vue Mois
    final tasks = allTasks.where((t) => t.type != TaskType.water).toList();

    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_currentDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendrier"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // BARRE DE NAVIGATION MOIS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left), 
                  onPressed: () => _changeMonth(-1)
                ),
                Text(
                  monthName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right), 
                  onPressed: () => _changeMonth(1)
                ),
              ],
            ),
          ),

          // LISTE DES TACHES
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text("Rien à faire ce mois-ci ! Reposez-vous. 💤"))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(task.type).withOpacity(0.2),
                            child: Icon(_getTypeIcon(task.type), color: _getTypeColor(task.type)),
                          ),
                          title: Text(task.plant.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(task.title),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: task.plant)),
                            ).then((_) => _loadPlants()); // On recharge au retour au cas où on a fait l'action
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}