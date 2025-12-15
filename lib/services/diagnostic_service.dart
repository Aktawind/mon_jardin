/*
* Service pour gérer le diagnostic des problèmes des plantes.
* Utilise des fichiers JSON pour représenter l'arbre de décision.
*/

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/diagnostic_node.dart';
import 'package:flutter/material.dart';

class DiagnosticService {
  // Cache pour ne pas recharger les fichiers
  final Map<String, Map<String, DiagnosticNode>> _cache = {};

  // Charger un fichier JSON complet
  Future<void> _loadFile(String filename) async {
    if (_cache.containsKey(filename)) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/diagnostic/$filename.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      final Map<String, dynamic> nodesMap = data['nodes'];

      _cache[filename] = nodesMap.map((key, value) => 
          MapEntry(key, DiagnosticNode.fromJson(key, value)));
      
    } catch (e) {
      debugPrint("Erreur chargement diagnostic ($filename): $e");
      // Fallback vide pour éviter le crash
      _cache[filename] = {};
    }
  }

  // Récupérer le nœud de départ
  Future<DiagnosticNode?> start() async {
    await _loadFile('root');
    return _getNode('root', 'start');
  }

  // Naviguer vers le prochain nœud
  Future<DiagnosticNode?> navigate(String currentFile, String targetNodeId, {String? targetFile}) async {
    final file = targetFile ?? currentFile; // Si pas de fichier cible, on reste sur le même
    await _loadFile(file);
    return _getNode(file, targetNodeId);
  }

  DiagnosticNode? _getNode(String file, String nodeId) {
    return _cache[file]?[nodeId];
  }
}