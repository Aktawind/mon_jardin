import 'dart:io';
import 'dart:convert';

// ---------------------
// CONFIG
// ---------------------

const coreCsvPath = "csv/plants_core.csv";
const careCsvPath = "csv/plants_care.csv";
const tagsCsvPath = "csv/plants_tags.csv";

const coreJsonPath = "assets/plants_core.json";
const careJsonPath = "assets/plants_care.json";
const tagsJsonPath = "assets/plants_tags.json";

// ---------------------
// MAIN
// ---------------------

Future<void> main() async {
  print("🔄 Conversion CSV → JSON...");

  final coreJson = await convertCoreCsv();
  final careJson = await convertCareCsv();
  final tagsJson = await convertTagsCsv();

  await File(coreJsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(coreJson), encoding: utf8);
  await File(careJsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(careJson), encoding: utf8);
  await File(tagsJsonPath).writeAsString(const JsonEncoder.withIndent('  ').convert(tagsJson), encoding: utf8);

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
// CONVERSION CORE
// ---------------------

Future<Map<String, dynamic>> convertCoreCsv() async {
  final rows = await readCsv(coreCsvPath);
  final result = <String, dynamic>{};

  for (var row in rows) {
    result[row["id"]!] = {
      "species": row["species"] ?? "",
      "synonyms": row["synonyms"]?.split(",").map((e) => e.trim()).toList() ?? [],
      "category": row["category"] ?? "",
    };
  }
  return result;
}

// ---------------------
// CONVERSION CARE
// ---------------------

Future<Map<String, dynamic>> convertCareCsv() async {
  final rows = await readCsv(careCsvPath);
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
    };
  }
  return result;
}

List<int> _listOrEmpty(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  return raw.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList();
}

// ---------------------
// CONVERSION TAGS
// ---------------------

Future<Map<String, dynamic>> convertTagsCsv() async {
  final rows = await readCsv(tagsCsvPath);
  final result = <String, dynamic>{};

  for (var row in rows) {
    result[row["id"]!] = {
      "species": row["species"] ?? "",
      "category": row["category"] ?? "",
      "esthetic": row["esthetic"] ?? "", 
      "foliage": row["foliage"] ?? "",
      "type": row["type"] ?? "",
      "height": row["height"] ?? "",
    };
  }
  return result;
}