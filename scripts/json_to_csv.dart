import 'dart:io';
import 'dart:convert';

// -------------------------
// CONFIG
// -------------------------

const coreJsonPath = "assets/plants_data.json";
const coreCsvPath = "csv/plants_data_copie.csv";

// -------------------------
// MAIN
// -------------------------

Future<void> main() async {
  print("🔄 Conversion JSON → CSV...");

  final coreJson = json.decode(await File(coreJsonPath).readAsString(encoding: utf8))
      as Map<String, dynamic>;

  await exportCore(coreJson);

  print("✅ Conversion terminée !");
}

// -----------------------------------------------------
//                EXPORT CORE
// -----------------------------------------------------

// -----------------------------------------------------
//                EXPORT CARE
// -----------------------------------------------------

Future<void> exportCore(Map<String, dynamic> jsonMap) async {
  final buffer = StringBuffer();
  final bom = '\uFEFF'; // Le caractère magique

  buffer.writeln(
      "id;species;light;difficulty;humidity;temperature;toxicity;cycle;"
      "waterSummer;waterWinter;fertilizeFreq;repotFreq;"
      "sowingMonths;plantingMonths;harvestMonths;floweringMonths;repottingMonths;pruningMonths;winteringMonths;"
      "soilInfo;pruningInfo;careInfo;generalInfo"
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
    final flowering = listToCsv(data["flowering_months"]);
    final repotMonths = listToCsv(data["repotting_months"]);
    final pruningMonths = listToCsv(data["pruning_months"]);
    final winter = listToCsv(data["wintering_months"]);

    final soilInfo = data["soil"] ?? "";
    final pruningInfo = data["pruning"] ?? "";
    final careInfo = data["care"] ?? "";
    final generalInfo = data["general"] ?? "";

    buffer.writeln("$id;$species;"
        "$light;$difficulty;$humidity;$temperature;$toxicity;$cycle;"
        "$waterSummer;$waterWinter;$fertilizeFreq;$repotFreq;"
        "$sow;$plant;$harvest;$flowering;$repotMonths;$pruningMonths;$winter;"
        "$soilInfo;$pruningInfo;$careInfo;$generalInfo");
  });

  await File(coreCsvPath).writeAsString(bom + buffer.toString(), encoding: utf8);
}