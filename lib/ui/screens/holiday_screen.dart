/*
* Écran "Mode Vacances" : Permet à l'utilisateur de sélectionner une plage de dates
* correspondant à son absence, et génère une liste de conseils d'arrosage et de
* soins pour chaque plante suivie durant cette période.
* Utilise le HolidayService pour analyser les besoins des plantes.
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database_service.dart';
import '../../services/holiday_service.dart';
import '../../services/pdf_service.dart';
import '../common/main_drawer.dart';

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  DateTimeRange? _selectedRange;
  List<HolidayAdvice> _adviceList = [];
  bool _showNannyMode = false; // false = Moi, true = Nounou
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
      locale: const Locale("fr", "FR"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              onPrimary: Colors.white, // Texte sur sélection
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _loading = true;
      });
      await _generate();
    }
  }

  Future<void> _generate() async {
    final plants = await DatabaseService().getPlants();
    // On prend toutes les plantes (même celles sans suivi arrosage peuvent avoir besoin d'ombre/taille)
    // Mais on peut filtrer si on veut. Gardons tout pour la sécurité.
    
    final advice = HolidayService().generateAdvice(plants, _selectedRange!.start, _selectedRange!.end);
    
    // On trie par pièce pour l'affichage (optionnel mais sympa)
    advice.sort((a, b) {
      String roomA = a.plant.room ?? a.plant.location;
      String roomB = b.plant.room ?? b.plant.location;
      return roomA.compareTo(roomB);
    });

    setState(() {
      _adviceList = advice;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mode Vacances"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const MainDrawer(currentIndex: 5), // Index à ajuster
      body: Column(
        children: [
          // 1. HEADER (Sélection Dates)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  "Préparez votre absence sereinement",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickDates,
                  icon: const Icon(Icons.edit_calendar),
                  label: Text(_selectedRange == null 
                      ? "Choisir mes dates" 
                      : "${DateFormat('d MMM').format(_selectedRange!.start)} - ${DateFormat('d MMM').format(_selectedRange!.end)} (${_selectedRange!.duration.inDays + 1} jours)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // 2. CONTENU
          Expanded(
            child: _loading 
                ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                : _adviceList.isEmpty
                ? _buildEmptyState()
                : ListView( // <--- ListView unique pour scroller tout
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      children: [
                        // TOGGLE MODE
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: false, label: Text("Préparation"), icon: Icon(Icons.checklist)),
                              ButtonSegment(value: true, label: Text("Consignes"), icon: Icon(Icons.people)),
                            ],
                            selected: {_showNannyMode},
                            onSelectionChanged: (s) => setState(() => _showNannyMode = s.first),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.teal.withValues(alpha: 0.2);
                                }
                                return null;
                              }),
                            ),
                          ),
                        ),

                        // CONSIGNES GENERALES
                        if (!_showNannyMode)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber),
                                SizedBox(width: 12),
                                Expanded(child: Text("Pour toutes les plantes, retirer les feuilles mortes et les fleurs fanées\n")),
                              ],
                            ),
                          ),

                          // TITRE LISTE
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _showNannyMode ? "Consignes spécifiques par plante" : "Préparations spécifiques",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                            ),
                          ),

                          // LA LISTE DES CARTES
                          // Comme on est déjà dans une ListView, on ne remet pas une ListView.builder
                          // On utilise une boucle simple ou .map()
                          ..._adviceList.map((item) {
                              final text = _showNannyMode ? item.instruction : item.preparation;
                              if (text.isEmpty) return const SizedBox.shrink();

                              final isDanger = text.contains("NE PAS") || text.contains("Interdit");

                              return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      side: isDanger ? BorderSide(color: Colors.red.shade200, width: 2) : BorderSide.none,
                                      borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isDanger ? Colors.red.shade100 : Colors.teal.shade100,
                                        child: Text(item.plant.displayName[0], style: TextStyle(color: isDanger ? Colors.red : Colors.teal)),
                                      ),
                                      title: Text(item.plant.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        text, 
                                        style: TextStyle(
                                          color: isDanger ? Colors.red.shade900 : Colors.black87,
                                          fontWeight: isDanger ? FontWeight.bold : FontWeight.normal
                                        )
                                      ),
                                      trailing: Text(
                                        item.plant.room ?? item.plant.location,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
          ),
        ],
      ),
      
      // FAB EXPORT PDF
      floatingActionButton: (_adviceList.isNotEmpty) 
          ? FloatingActionButton.extended(
              onPressed: () {
                // Choix du mode d'export
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: const Text("Dossier Complet"),
                          subtitle: const Text("Préparation + Consignes"),
                          onTap: () {
                            Navigator.pop(ctx);
                            _exportPdf(PdfMode.all);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.checklist),
                          title: const Text("Fiche préparation"),
                          subtitle: const Text("Pour moi avant de partir"),
                          onTap: () {
                            Navigator.pop(ctx);
                            _exportPdf(PdfMode.preparation);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text("Fiche instructions"),
                          subtitle: const Text("Pour la personne qui va venir"),
                          onTap: () {
                            Navigator.pop(ctx);
                            _exportPdf(PdfMode.nanny);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              label: const Text("Exporter"),
              icon: const Icon(Icons.share),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.date_range_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Sélectionnez vos dates", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _exportPdf(PdfMode mode) {
    final rangeText = "${DateFormat('d MMMM').format(_selectedRange!.start)} au ${DateFormat('d MMMM').format(_selectedRange!.end)}";
    PdfService().generateHolidayPdf(_adviceList, rangeText, mode);
  }
}