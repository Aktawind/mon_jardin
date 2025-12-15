/*
* Modèle représentant un nœud dans l'arbre de diagnostic.
* Un nœud peut être une question avec des choix ou une solution.
*/

class DiagnosticNode {
  final String id;
  final bool isSolution;
  
  // Pour une QUESTION
  final String? question;
  final List<DiagnosticChoice>? choices;

  // Pour une SOLUTION
  final String? title;
  final String? description;
  final String? advice;
  final String? severity; // low, medium, high

  DiagnosticNode({
    required this.id,
    this.isSolution = false,
    this.question,
    this.choices,
    this.title,
    this.description,
    this.advice,
    this.severity,
  });

  factory DiagnosticNode.fromJson(String id, Map<String, dynamic> json) {
    if (json['type'] == 'solution') {
      return DiagnosticNode(
        id: id,
        isSolution: true,
        title: json['title'],
        description: json['description'],
        advice: json['advice'],
        severity: json['severity'],
      );
    } else {
      return DiagnosticNode(
        id: id,
        isSolution: false,
        question: json['question'],
        choices: (json['choices'] as List?)
            ?.map((c) => DiagnosticChoice.fromJson(c))
            .toList(),
      );
    }
  }
}

class DiagnosticChoice {
  final String label;
  final String targetNode;
  final String? targetFile; // Optionnel (si on change de fichier)

  DiagnosticChoice({
    required this.label,
    required this.targetNode,
    this.targetFile,
  });

  factory DiagnosticChoice.fromJson(Map<String, dynamic> json) {
    return DiagnosticChoice(
      label: json['label'],
      targetNode: json['target_node'],
      targetFile: json['target_file'],
    );
  }
}