import 'dart:io';
import 'dart:convert';

// ---------------------
// CONFIG
// ---------------------

const coreCsvPath = "csv/plants_data.csv";
const coreJsonPath = "assets/plants_data.json";

// ---------------------
// MAIN
// ---------------------

Future<void> main() async {
  print("🔄 Conversion CSV → JSON...");

  final coreJson = await convertCoreCsv();
  await File(coreJsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(coreJson), encoding: utf8);

  print("✅ Conversion terminée !");
}

// ---------------------
// HELPERS
// ---------------------

Future<List<Map<String, dynamic>>> readCsv(String path) async {
  final file = File(path);

  if (!await file.exists()) {
    throw Exception("CSV introuvable : $path");
  }

  final content = await file.readAsString(encoding: utf8);
  final lines = const LineSplitter().convert(content);

  final headers = lines.first.split(';');

  return lines.skip(1).map((line) {
    final cells = line.split(';');

    final map = <String, String>{};
    for (int i = 0; i < headers.length; i++) {
      map[headers[i]] = i < cells.length ? cells[i] : "";
    }
    return map;
  }).toList();
}

// ---------------------
// CONVERSION DATA
// ---------------------

Future<Map<String, dynamic>> convertCoreCsv() async {
  final rows = await readCsv(coreCsvPath);
  final result = <String, dynamic>{};

  for (var row in rows) {
    result[row["id"]!] = {
      "species": row["species"] ?? "",
      "category": row["category"] ?? "",
      "light": row["light"],
      "difficulty": row["difficulty"],
      "humidity": row["humidity"],
      "temperature": row["temperature"],
      "toxicity": row["toxicity"],
      "cycle": row["cycle"],
      "water_summer": int.tryParse(row["waterSummer"] ?? ""),
      "water_winter": int.tryParse(row["waterWinter"] ?? ""),
      "fertilize_freq": int.tryParse(row["fertilizeFreq"] ?? ""),
      "repot_freq": int.tryParse(row["repotFreq"] ?? ""),
      "sowing_months": _listOrEmpty(row["sowingMonths"]),
      "planting_months": _listOrEmpty(row["plantingMonths"]),
      "harvest_months": _listOrEmpty(row["harvestMonths"]),
      "repotting_months": _listOrEmpty(row["repottingMonths"]),
      "pruning_months": _listOrEmpty(row["pruningMonths"]),
      "wintering_months": _listOrEmpty(row["winteringMonths"]),
      "soil": row["soilInfo"],
      "pruning": row["pruningInfo"],
      "esthetic": row["esthetic"] ?? "", 
      "foliage": row["foliage"] ?? "",
      "height": row["height"] ?? "",
      "vegType": row["vegType"] ?? "",
    };
  }
  return result;
}

List<int> _listOrEmpty(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  
  // 1. On enlève les crochets et les guillemets potentiels
  String clean = raw.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
  
  // 2. On split et on parse
  return clean.split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty) // Sécurité si "11, 12,"
      .map((e) => int.tryParse(e) ?? 0)
      .toList(); // On peut ajouter .where((e) => e != 0) pour être sûr
}