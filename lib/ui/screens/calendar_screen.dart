import 'dart:io'; // N'oublie pas cet import pour les photos !
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../models/calendar_task.dart';
import '../../services/task_service.dart';
import 'plant_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentDate = DateTime.now();
  List<Plant> _plants = [];
  
  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await DatabaseService().getPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
    });
  }

  // --- COULEURS ET ICONES ---
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

  String _getTypeTitle(TaskType type) {
    switch (type) {
      case TaskType.water: return "Arrosages";
      case TaskType.fertilizer: return "Fertilisations";
      case TaskType.repot: return "Rempotages";
      case TaskType.prune: return "Tailles";
      case TaskType.harvest: return "Récoltes";
      case TaskType.sow: return "Semis";
      default: return "Autres";
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Récupération des tâches brutes
    final allTasks = TaskService().getTasksForMonth(_plants, _currentDate.month, _currentDate.year);
    
    // 2. Filtre (pas d'arrosage en vue mois)
    final tasks = allTasks.where((t) => t.type != TaskType.water).toList();

    // 3. GROUPEMENT PAR TYPE (La magie opère ici)
    // On crée une Map : { TaskType.prune : [Task1, Task2], TaskType.fert : [Task3] }
    Map<TaskType, List<CalendarTask>> groupedTasks = {};
    for (var task in tasks) {
      if (!groupedTasks.containsKey(task.type)) {
        groupedTasks[task.type] = [];
      }
      groupedTasks[task.type]!.add(task);
    }

    // 4. On trie les clés pour avoir un ordre logique (Récolte avant Taille par exemple)
    // Ici on trie simplement par l'index de l'enum pour que ce soit stable
    var sortedKeys = groupedTasks.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

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
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Text(
                  monthName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),

          // LISTE DES GROUPES
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text("Rien à faire ce mois-ci ! 💤"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final type = sortedKeys[index];
                      final groupTasks = groupedTasks[type]!;
                      
                      // ON APPELLE LE NOUVEAU WIDGET ICI
                      return _TaskGroupCard(
                        type: type,
                        tasks: groupTasks,
                        // On passe la méthode de rechargement en callback
                        onPlantTap: _loadPlants, 
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une "Carte d'action" (ex: Bloc Taille)
  Widget _buildGroupCard(TaskType type, List<CalendarTask> groupTasks) {
    final color = _getTypeColor(type);
    final title = _getTypeTitle(type);
    final icon = _getTypeIcon(type);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // En-tête du groupe (Bandeau coloré)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  "$title (${groupTasks.length})", // ex: Tailles (3)
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: color.withOpacity(0.8) // Un peu plus foncé pour le texte
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des plantes concernées
          ...groupTasks.map((task) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            // La photo en rond
            leading: Hero(
              tag: 'calendar_${task.plant.id}', // Tag unique pour éviter conflit avec l'autre liste
              child: CircleAvatar(
                radius: 20,
                backgroundImage: task.plant.photoPath != null
                    ? FileImage(File(task.plant.photoPath!))
                    : null,
                backgroundColor: color.withOpacity(0.1),
                child: task.plant.photoPath == null 
                    ? Icon(icon, size: 20, color: color) 
                    : null,
              ),
            ),
            title: Text(task.plant.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
            // On affiche le sous-titre seulement s'il apporte une info précise (ex: date)
            subtitle: task.specificDate != null 
                ? Text("Prévu le ${DateFormat('dd/MM').format(task.specificDate!)}") 
                : null,
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: task.plant)),
              ).then((_) => _loadPlants());
            },
          )),
          const SizedBox(height: 8), // Petit espace en bas
        ],
      ),
    );
  }
}

// --- NOUVEAU WIDGET SEPARE ---
class _TaskGroupCard extends StatefulWidget {
  final TaskType type;
  final List<CalendarTask> tasks;
  final VoidCallback onPlantTap;

  const _TaskGroupCard({
    required this.type,
    required this.tasks,
    required this.onPlantTap,
  });

  @override
  State<_TaskGroupCard> createState() => _TaskGroupCardState();
}

class _TaskGroupCardState extends State<_TaskGroupCard> {
  // Par défaut, on laisse ouvert, sauf si la liste est très longue (> 5)
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.tasks.length < 5; 
  }

  // --- Helpers de couleurs copiés ici pour être autonomes ---
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

  String _getTypeTitle(TaskType type) {
    switch (type) {
      case TaskType.water: return "Arrosages";
      case TaskType.fertilizer: return "Fertilisations";
      case TaskType.repot: return "Rempotages";
      case TaskType.prune: return "Tailles";
      case TaskType.harvest: return "Récoltes";
      case TaskType.sow: return "Semis";
      default: return "Autres";
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(widget.type);
    final title = _getTypeTitle(widget.type);
    final icon = _getTypeIcon(widget.type);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // EN-TÊTE CLIQUABLE
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                // Si fermé, on arrondit aussi le bas, sinon que le haut
                borderRadius: _isExpanded 
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 12),
                  Text(
                    "$title (${widget.tasks.length})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  // La flèche qui change de sens
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: color.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),

          // CORPS ANIMÉ
          AnimatedCrossFade(
            firstChild: Container(), // État fermé (vide)
            secondChild: Column(
              children: [
                 ...widget.tasks.map((task) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Hero(
                    tag: 'calendar_${task.plant.id}_${widget.type}', // Tag unique renforcé
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: task.plant.photoPath != null
                          ? FileImage(File(task.plant.photoPath!))
                          : null,
                      backgroundColor: color.withOpacity(0.1),
                      child: task.plant.photoPath == null 
                          ? Icon(icon, size: 20, color: color) 
                          : null,
                    ),
                  ),
                  title: Text(task.plant.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: task.specificDate != null 
                      ? Text("Prévu le ${DateFormat('dd/MM').format(task.specificDate!)}") 
                      : null,
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: task.plant)),
                    ).then((_) => widget.onPlantTap());
                  },
                )),
                const SizedBox(height: 8),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}