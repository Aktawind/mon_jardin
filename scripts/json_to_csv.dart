import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// -------------------------
// CONFIG
// -------------------------

const coreJsonPath = "assets/plants_core.json";
const careJsonPath = "assets/plants_care.json";
const tagsJsonPath = "assets/plants_tags.json";

const coreCsvPath = "csv/plants_core.csv";
const careCsvPath = "csv/plants_care.csv";
const tagsCsvPath = "csv/plants_tags.csv";

// -------------------------
// MAIN
// -------------------------

Future<void> main() async {
  debugPrint("🔄 Conversion JSON → CSV...");

  final coreJson = json.decode(await File(coreJsonPath).readAsString(encoding: utf8))
      as Map<String, dynamic>;

  final careJson = json.decode(await File(careJsonPath).readAsString(encoding: utf8))
      as Map<String, dynamic>;

  final tagsJson = json.decode(await File(tagsJsonPath).readAsString(encoding: utf8))
      as Map<String, dynamic>;

  await exportCore(coreJson);
  await exportCare(careJson);
  await exportTags(tagsJson);

  debugPrint("✅ Conversion terminée !");
}

// -----------------------------------------------------
//                EXPORT CORE
// -----------------------------------------------------

Future<void> exportCore(Map<String, dynamic> jsonMap) async {
  final buffer = StringBuffer();
  final bom = '\uFEFF'; // Le caractère magique
  buffer.writeln("id;species;synonyms;category");

  jsonMap.forEach((id, data) {
    final species = data["species"] ?? "";
    final category = data["category"] ?? "";
    final synonyms = (data["synonyms"] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .join(", ");

    buffer.writeln("$id;$species;$synonyms;$category");
  });

  await File(coreCsvPath).writeAsString(bom + buffer.toString(), encoding: utf8);
}

// -----------------------------------------------------
//                EXPORT CARE
// -----------------------------------------------------

Future<void> exportCare(Map<String, dynamic> jsonMap) async {
  final buffer = StringBuffer();
  final bom = '\uFEFF'; // Le caractère magique

  buffer.writeln(
      "id;species;light;difficulty;humidity;temperature;toxicity;cycle;"
      "waterSummer;waterWinter;fertilizeFreq;repotFreq;"
      "sowingMonths;plantingMonths;harvestMonths;repottingMonths;winteringMonths;"
      "soilInfo;pruningInfo"
  );

  jsonMap.forEach((id, data) {
    String listToCsv(List<dynamic>? list) =>
        list == null ? "" : list.map((e) => e.toString()).join(",");

    final species = data["species"] ?? "";
    final light = data["light"] ?? "";
    final difficulty = data["difficulty"] ?? "";
    final humidity = data["humidity"] ?? "";
    final temperature = data["temperature"] ?? "";
    final toxicity = data["toxicity"] ?? "";
    final cycle = data["cycle"] ?? "";

    final waterSummer = data["water_summer"]?.toString() ?? "";
    final waterWinter = data["water_winter"]?.toString() ?? "";
    final fertilizeFreq = data["fertilize_freq"]?.toString() ?? "";
    final repotFreq = data["repot_freq"]?.toString() ?? "";

    final sow = listToCsv(data["sowing_months"]);
    final plant = listToCsv(data["planting_months"]);
    final harvest = listToCsv(data["harvest_months"]);
    final repotMonths = listToCsv(data["repotting_months"]);
    final winter = listToCsv(data["wintering_months"]);

    final soilInfo = data["soil"] ?? "";
    final pruningInfo = data["pruning"] ?? "";

    buffer.writeln("$id;$species;"
        "$light;$difficulty;$humidity;$temperature;$toxicity;$cycle;"
        "$waterSummer;$waterWinter;$fertilizeFreq;$repotFreq;"
        "$sow;$plant;$harvest;$repotMonths;$winter;"
        "$soilInfo;$pruningInfo");
  });

  await File(careCsvPath).writeAsString(bom + buffer.toString(), encoding: utf8);
}

// -----------------------------------------------------
//                EXPORT TAGS
// -----------------------------------------------------

Future<void> exportTags(Map<String, dynamic> jsonMap) async {
  final buffer = StringBuffer();
  final bom = '\uFEFF'; // Le caractère magique

  buffer.writeln("id;species;category;esthetic;foliage;type;height");

  jsonMap.forEach((id, data) {
    final species = data["species"] ?? "";
    final category = data["category"] ?? "";
    final esthetic = data["esthetic"] ?? "";
    final foliage = data["foliage"] ?? "";
    final type = data["type"] ?? "";
    final height = data["height"] ?? "";

    buffer.writeln("$id;$species;$category;$esthetic;$foliage;$type;$height");
  });

  await File(tagsCsvPath).writeAsString(bom + buffer.toString(), encoding: utf8);
}
