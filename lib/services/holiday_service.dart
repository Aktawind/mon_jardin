/*
* Ce service fournit des conseils d'arrosage et de soins avant une période d'absence (vacances).
* Il analyse la durée de l'absence, la saison, et les besoins spécifiques de chaque
* plante pour générer des instructions personnalisées.
*/

import '../models/plant.dart';
import '../models/enums.dart';
import 'encyclopedia_service.dart';

class HolidayAdvice {
  final Plant plant;
  final String preparation; // À faire avant de partir (Pour moi)
  final String instruction; // À faire pendant l'absence (Pour Nounou)

  HolidayAdvice(this.plant, this.preparation, this.instruction);
}

class HolidayService {
  
  List<HolidayAdvice> generateAdvice(List<Plant> plants, DateTime start, DateTime end) {
    List<HolidayAdvice> results = [];
    final duration = end.difference(start).inDays;
    
    // Analyse de la saison (Mois central des vacances)
    final midDate = start.add(Duration(days: duration ~/ 2));
    final isWinter = midDate.month >= 11 || midDate.month <= 2;
    final isSummer = midDate.month >= 6 && midDate.month <= 8;

    for (var plant in plants) {
      final data = EncyclopediaService().getData(plant.species);
      
      // Si on n'a pas de données, on donne un conseil générique
      if (data == null) {
        results.add(HolidayAdvice(plant, "Arroser normalement.", "Vérifier la terre."));
        continue;
      }

      String prep = "";
      String instr = "";

      // --- LOGIQUE POTAGER (Cycle court, besoins élevés) ---
      if (plant.location == 'Potager' && plant.lifecycleStage == 'planted') {
        prep = "Pailler généreusement le pied pour garder l'humidité. Récolter tout ce qui est mûr.";
        
        if (duration > 4) {
          instr = "Récolter les légumes mûrs.";
          if (isSummer) instr += " Arroser le soir au pied tous les 2-3 jours.";
        } else {
          instr = "Rien à faire.";
        }
      } 
      // --- LOGIQUE INTERIEUR / EXTERIEUR (Ornemental) ---
      else {
        // 1. PREPARATION (Avant de partir)
        // Gestion Lumière/Température (Intérieur Eté)
        if (plant.location == 'Intérieur' && isSummer && duration > 5) {
          prep += " Mettre dans une pièce tamisée (mi-ombre).";
        }
        
        // Gestion Humidité (Tropicales)
        if (data.humidity == HumidityNeed.high && plant.location == 'Intérieur') {
          prep += " Regrouper avec d'autres plantes pour maintenir l'humidité.";
        }

        // Arrosage Préparatoire
        if ((isSummer && data.waterSummer < 7) || (!isSummer && data.waterWinter < 7)) {
           prep += " Arroser légèrement.";
        } else {
           prep += " Arroser copieusement.";
        }

        // 2. INSTRUCTIONS (Pendant l'absence)
        
        // Cas A : Absence COURTE (< 5 jours)
        if (duration < 5) {
          instr = "Rien à faire.";
        }
        // Cas B : Absence MOYENNE (5 - 14 jours)
        else if (duration < 14) {
          if ((isSummer && data.waterSummer < 7) || (!isSummer && data.waterWinter < 7)) { // Cactus / Succulente
             instr = "Ne pas arroser. 🚫";
          } else if (((isSummer && data.waterSummer > 7) || (!isSummer && data.waterWinter > 7)) || (plant.location == 'Extérieur' && isSummer)) {
             instr = "Arroser 1 fois à mi-parcours.";
          } else {
              // Plante standard
              if (isSummer) {
                instr = "Vérifier la terre, arroser si elle est sèche.";
              } else {
                instr = "Rien à faire.";
              }
          }
        }
        // Cas C : Absence LONGUE (> 14 jours)
        else {
          if ((isSummer && data.waterSummer < 7) || (!isSummer && data.waterWinter < 7)) {
            if (isWinter) {
              instr = "Ne pas arroser.";
            }
            else {
              instr = "Un petit verre d'eau toutes les 2-3 semaines.";
            }
          } else if ((isSummer && data.waterSummer > 7) || (!isSummer && data.waterWinter > 7)) {
            instr = "Arroser 2 fois par semaine sans noyer.";
          } else {
            // Standard
            instr = "Arroser 1 fois par semaine (laisser sécher la surface entre deux).";
          }
        }
        
        // Cas Spécial Hiver (Dormance)
        if (isWinter && data.winteringMonths.contains(midDate.month)) {
           instr = "Plante au repos. Arroser très peu, seulement si la terre est totalement sèche.";
        }
      }

      results.add(HolidayAdvice(plant, prep.trim(), instr.trim()));
    }
    
    return results;
  }
}