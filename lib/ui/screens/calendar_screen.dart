/*
* Écran principal du calendrier.
* Affiche les tâches à venir pour les plantes (arrosage, fertilisation, etc
* Permet de naviguer entre les vues Semaine, Mois et Année.
* Affiche une alerte pour les tâches en retard.
*/


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_service.dart';
import '../../models/plant.dart';
import '../../models/calendar_task.dart';
import '../../services/task_service.dart';
import 'plant_detail_screen.dart';
import '../common/main_drawer.dart';

// Enum pour savoir sur quelle vue on est
enum CalendarView { week, month, year }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Par défaut sur le MOIS
  CalendarView _currentView = CalendarView.week;
  
  DateTime _weekDate = DateTime.now();  // Pour la vue Semaine
  DateTime _monthDate = DateTime.now(); // Pour la vue Mois
  DateTime _yearDate = DateTime.now();  // Pour la vue Année
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

  void _changePeriod(int offset) {
    setState(() {
      if (_currentView == CalendarView.week) {
        _weekDate = _weekDate.add(Duration(days: offset * 7));
      } else if (_currentView == CalendarView.month) {
        _monthDate = DateTime(_monthDate.year, _monthDate.month + offset, 1);
      } else {
        _yearDate = DateTime(_yearDate.year + offset, 1, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. On calcule les retards
    final overdueTasks = TaskService().getOverdueTasks(_plants);

    return Scaffold(
      drawer: const MainDrawer(currentIndex: 1),
      appBar: AppBar(
        title: const Text("Calendrier"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. SELECTEUR DE VUE
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<CalendarView>(
              segments: const [
                ButtonSegment(value: CalendarView.week, label: Text('Semaine'), icon: Icon(Icons.view_week)),
                ButtonSegment(value: CalendarView.month, label: Text('Mois'), icon: Icon(Icons.calendar_view_month)),
                ButtonSegment(value: CalendarView.year, label: Text('Année'), icon: Icon(Icons.calendar_today)),
              ],
              selected: {_currentView},
              onSelectionChanged: (Set<CalendarView> newSelection) {
                setState(() {
                  _currentView = newSelection.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5);
                  }
                  return null;
                }),
              ),
            ),
          ),

          // ALERTE RETARD (Visible seulement s'il y en a)
          if (overdueTasks.isNotEmpty)
            Container(
              color: Colors.deepPurple[50], // Violet très clair
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.watch_later_outlined, color: Colors.deepPurple[300]), // Montre ou Sablier
                      const SizedBox(width: 8),
                      Text(
                        "${overdueTasks.length} action(s) en attente", // Wording doux
                        style: TextStyle(color: Colors.deepPurple[900], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Liste horizontale des plantes en retard
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: overdueTasks.length,
                      itemBuilder: (context, index) {
                        final task = overdueTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            avatar: CircleAvatar(
                               backgroundImage: task.plant.photoPath != null ? FileImage(File(task.plant.photoPath!)) : null,
                               backgroundColor: Colors.deepPurple[100],
                            ),
                            label: Text(task.plant.displayName, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.deepPurple[200]!),
                            onPressed: () => _goToDetail(task.plant),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),

          // 2. NAVIGATEUR DE PERIODE (Barre avec flèches)
          _buildNavigationHeader(),

          // 3. CONTENU (Change selon la vue)
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    String title = "";
    if (_currentView == CalendarView.week) {
      // Calcul du début et fin de semaine
      // Astuce : on trouve le lundi de la semaine courante
      final startOfWeek = _weekDate.subtract(Duration(days: _weekDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      title = "Sem. ${DateFormat('d MMM', 'fr_FR').format(startOfWeek)} - ${DateFormat('d MMM', 'fr_FR').format(endOfWeek)}";
    } else if (_currentView == CalendarView.month) {
      title = DateFormat('MMMM yyyy', 'fr_FR').format(_monthDate);
    } else {
      title = DateFormat('yyyy', 'fr_FR').format(_yearDate);
    }

    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changePeriod(-1)),
          Text(title.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changePeriod(1)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.month:
        return _buildMonthView();
      case CalendarView.year:
        return _buildYearView();
    }
  }

  // --- VUE SEMAINE (Liste verticale jour par jour) ---
  Widget _buildWeekView() {
    // On cale le début de semaine au Lundi
    final startOfWeek = _weekDate.subtract(Duration(days: _weekDate.weekday - 1));
    
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final dayDate = startOfWeek.add(Duration(days: index));
        // Si c'est avant aujourd'hui, on n'affiche rien
        final now = DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);
        if (dayDate.isBefore(todayMidnight)) {
           return const SizedBox.shrink(); // Widget vide
        }


        final isToday = TaskService().isSameDay(dayDate, DateTime.now());
        final tasks = TaskService().getTasksForDay(_plants, dayDate);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          // Si c'est aujourd'hui, on met une petite bordure colorée
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du jour (Lundi 12)
                Row(
                  children: [
                    Text(
                      DateFormat('EEEE d', 'fr_FR').format(dayDate).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey[700]
                      ),
                    ),
                    if (isToday) 
                       Container(
                         margin: const EdgeInsets.only(left: 8),
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                         child: const Text("Aujourd'hui", style: TextStyle(color: Colors.white, fontSize: 10)),
                       )
                  ],
                ),
                const Divider(),
                // Liste des tâches du jour
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("Rien à signaler", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                  )
                else
                  ...tasks.map((task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(Icons.water_drop, color: Colors.blue[300]), // Surtout de l'arrosage ici
                    title: Text(task.plant.displayName),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () => _goToDetail(task.plant),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- VUE MOIS (Celle qu'on avait avant, avec les Groupes) ---
  Widget _buildMonthView() {
    final allTasks = TaskService().getTasksForMonth(_plants, _monthDate.month, _monthDate.year);
    // Filtre : pas d'arrosage
    final tasks = allTasks.where((t) => t.type != TaskType.water).toList();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spa_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("Mois calme. Profitez du jardin !", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Groupement
    Map<TaskType, List<CalendarTask>> groupedTasks = {};
    for (var task in tasks) {
      if (!groupedTasks.containsKey(task.type)) groupedTasks[task.type] = [];
      groupedTasks[task.type]!.add(task);
    }
    var sortedKeys = groupedTasks.keys.toList()..sort((a, b) => a.index.compareTo(b.index));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final type = sortedKeys[index];
        return _TaskGroupCard( // On réutilise notre widget existant (il est défini plus bas)
          type: type,
          tasks: groupedTasks[type]!,
          onPlantTap: _loadPlants,
        );
      },
    );
  }

  // --- VUE ANNEE (Liste compacte mois par mois) ---
  Widget _buildYearView() {
    final yearTasks = TaskService().getTasksForYear(_plants, _yearDate.year);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        // Si l'année affichée est l'année courante ET que le mois est passé -> on cache
        final now = DateTime.now();
        if (_yearDate.year == now.year && month < now.month) {
           return const SizedBox.shrink();
        }
        final tasks = yearTasks[month] ?? [];
        
        // Si rien ce mois-ci, on affiche juste une ligne discrète ou rien ?
        // Affichons seulement les mois où il y a de l'action pour ne pas scroller pour rien
        if (tasks.isEmpty) return const SizedBox.shrink();

        final monthName = DateFormat('MMMM', 'fr_FR').format(DateTime(_yearDate.year, month));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                ...tasks.map((task) => Row(
                  children: [
                    // Petit point de couleur
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: (task.type == TaskType.prune || task.type == TaskType.planting) ? Colors.green : Colors.orange,
                        shape: BoxShape.circle
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(text: "${task.plant.displayName} : ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: task.title),
                          // AJOUT DU SOUS-TITRE (la durée)
                          if (task.subtitle.isNotEmpty)
                             TextSpan(text: " (${task.subtitle})", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  ],
                ))
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToDetail(Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlantDetailScreen(plant: plant)),
    ).then((_) => _loadPlants());
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
      case TaskType.planting: return Colors.brown;
      case TaskType.sow: return Colors.lime[800]!; 
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
      case TaskType.planting: return Icons.agriculture;
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
      case TaskType.planting: return "Mises en terre";
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
                color: color.withValues(alpha: 0.15),
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
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  // La flèche qui change de sens
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: color.withValues(alpha: 0.8),
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
                      backgroundColor: color.withValues(alpha: 0.1),
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