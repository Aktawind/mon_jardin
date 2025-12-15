/*
* Écran principal pour le diagnostic des plantes.
* Utilise le DiagnosticService pour naviguer dans l'arbre de décision.
*/

import 'package:flutter/material.dart';
import '../../services/diagnostic_service.dart';
import '../../models/diagnostic_node.dart';
import '../common/main_drawer.dart'; // Si tu veux le menu

class DoctorPlantScreen extends StatefulWidget {
  const DoctorPlantScreen({super.key});

  @override
  State<DoctorPlantScreen> createState() => _DoctorPlantScreenState();
}

class _DoctorPlantScreenState extends State<DoctorPlantScreen> {
  final DiagnosticService _service = DiagnosticService();
  final ScrollController _scrollController = ScrollController();
  
  // Liste des messages (historique de la conversation)
  final List<Widget> _messages = [];
  
  // État actuel
  String _currentFile = 'root';
  DiagnosticNode? _currentNode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startDiagnosis();
  }

  Future<void> _startDiagnosis() async {
    final node = await _service.start();
    _displayNode(node);
  }

  void _displayNode(DiagnosticNode? node) {
    if (node == null) return;

    setState(() {
      _currentNode = node;
      _loading = false;
      
      // Ajout de la bulle du Docteur
      _messages.add(_DoctorBubble(
        text: node.isSolution 
            ? "Diagnostic : ${node.title}\n\n${node.description}\n\n💡 Conseil : ${node.advice}" 
            : node.question!,
        isSolution: node.isSolution,
        severity: node.severity,
      ));
    });
    
    // Scroll auto vers le bas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onChoiceSelected(DiagnosticChoice choice) async {
    // 1. Ajouter la réponse de l'utilisateur (sa bulle à lui)
    setState(() {
      _messages.add(_UserBubble(text: choice.label));
      _loading = true; // Petit effet d'attente
    });

    // 2. Charger la suite
    // Si targetFile est défini, on change de fichier
    if (choice.targetFile != null) {
      _currentFile = choice.targetFile!;
    }
    
    // Simulation délai "réflexion" (optionnel mais sympa)
    await Future.delayed(const Duration(milliseconds: 500));

    final nextNode = await _service.navigate(_currentFile, choice.targetNode);
    _displayNode(nextNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dr. Chlorofeel 🌱"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _currentFile = 'root';
                _startDiagnosis();
              });
            },
          )
        ],
      ),
      drawer: const MainDrawer(currentIndex: 4), // Index à définir dans ton drawer
      body: Column(
        children: [
          // ZONE DE CHAT
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircularProgressIndicator(strokeWidth: 2), // Indicateur "Dr écrit..."
                    ),
                  );
                }
                return _messages[index];
              },
            ),
          ),

          // ZONE DE REPONSE (Choix)
          if (!_loading && _currentNode != null && !_currentNode!.isSolution)
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4, // Max 40% de l'écran
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Scrollbar( // Ajout de la barre de scroll visuelle
                thumbVisibility: true,
                child: ListView(
                  shrinkWrap: true, // Important : prend juste la place nécessaire
                children: _currentNode!.choices!.map((choice) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _onChoiceSelected(choice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.teal),
                    ),
                    child: Text(choice.label),
                  ),
                )).toList(),
              ),
            ),
          ),
            
          // BOUTON RECOMMENCER (Si Solution)
          if (!_loading && _currentNode != null && _currentNode!.isSolution)
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: ElevatedButton.icon(
                 onPressed: () {
                    setState(() {
                      _messages.clear();
                      _currentFile = 'root';
                      _startDiagnosis();
                    });
                 }, 
                 icon: const Icon(Icons.refresh), 
                 label: const Text("Nouveau diagnostic"),
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
               ),
             ),
        ],
      ),
    );
  }
}

// --- BULLES DE CHAT ---

class _DoctorBubble extends StatelessWidget {
  final String text;
  final bool isSolution;
  final String? severity;

  const _DoctorBubble({required this.text, required this.isSolution, this.severity});

  @override
  Widget build(BuildContext context) {
    Color bubbleColor = Colors.teal.shade50;
    Color textColor = Colors.black87;
    
    if (isSolution) {
      if (severity == 'high') {
        bubbleColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
      } else if (severity == 'medium') {
        bubbleColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
      } else {
        bubbleColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: isSolution ? Border.all(color: textColor.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSolution) 
               const Row(children: [Icon(Icons.medical_services, size: 16), SizedBox(width: 8), Text("Diagnostic", style: TextStyle(fontWeight: FontWeight.bold))]),
            if (isSolution) const SizedBox(height: 8),
            Text(text, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}