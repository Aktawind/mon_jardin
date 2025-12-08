import '../models/plant.dart';
import '../models/calendar_task.dart';
import '../services/encyclopedia_service.dart'; // Pour accéder à EncyclopediaService

class TaskService {
  
  // Génère toutes les tâches pour un mois donné (ex: Avril 2024)
  List<CalendarTask> getTasksForMonth(List<Plant> myPlants, int month, int year) {
    List<CalendarTask> tasks = [];

    for (var plant in myPlants) {
      // 1. Récupérer les infos encyclopédiques
      final speciesData = EncyclopediaService().getData(plant.species);
      if (speciesData == null) continue; // Si pas d'info, on passe

      // --- LOGIQUE POTAGER ---
      // 1. SEMIS : Seulement si on est au stade 'seed'
      if (plant.lifecycleStage == 'seed') {
        if (speciesData.sowingMonths.contains(month)) {
          tasks.add(CalendarTask(
            plant: plant,
            type: TaskType.sow,
            title: "Semis",
            subtitle: "C'est le moment de semer !",
          ));
        }
        // Si c'est une graine, on n'affiche PAS le reste (Taille, Récolte, Arrosage)
        continue; // On passe à la plante suivante
      }

      // 2. RECOLTE : Seulement si on est 'planted' (ou 'seedling' avancé ?)
      // Disons qu'on affiche la période de récolte dès qu'on a dépassé le stade graine, pour info.
      if (plant.lifecycleStage == 'planted') {
         if (speciesData.harvestMonths.contains(month)) {
          tasks.add(CalendarTask(
            plant: plant,
            type: TaskType.harvest,
            title: "Récolte",
            subtitle: "Période de récolte.",
          ));
        }
      }

      // 3. MISE EN TERRE (Repiquage)
      // On l'affiche si on est au stade 'seedling' (Semis) OU 'seed' (pour anticiper)
      // Mais surtout pas si on est déjà 'planted'.
      if (plant.location == 'Potager' && plant.lifecycleStage != 'planted') {
        if (speciesData.plantingMonths.contains(month)) {
          tasks.add(CalendarTask(
            plant: plant,
            type: TaskType.planting,
            title: "Mise en pleine terre",
            subtitle: "Les Saints de Glace sont passés ?",
          ));
        }
      }

      // Taille
      if (speciesData.pruningMonths.contains(month)) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.prune,
          title: "Taille",
          subtitle: "C'est la période idéale pour tailler.",
        ));
      }
    
      // Rempotage 
      if (plant.repottingFreq > 0) {
        if (speciesData.repottingMonths.contains(month) && plant.trackRepotting) {
          // Logique simplifiée : on le propose si c'est la saison
          tasks.add(CalendarTask(
            plant: plant,
            type: TaskType.repot,
            title: "Période de Rempotage",
            subtitle: "Vérifiez si les racines sortent du pot.",
          ));
        }
      }

      // --- B. Tâches basées sur le Calcul (Dates précises) ---
      
      // Arrosage : On regarde si la prochaine date tombe dans ce mois
      // (C'est approximatif pour la vue Mois, mais utile)
      if (plant.nextWateringDate.month == month && plant.nextWateringDate.year == year && plant.trackWatering) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.water,
          title: "Arrosage prévu",
          subtitle: "Le ${plant.nextWateringDate.day}",
          specificDate: plant.nextWateringDate,
        ));
      }

      // Engrais : Si c'est pas l'hiver et que c'est le moment
      if (plant.nextFertilizingDate.month == month && plant.nextFertilizingDate.year == year && plant.trackFertilizer) {
        if (plant.fertilizerFreq > 0) {
           tasks.add(CalendarTask(
            plant: plant,
            type: TaskType.fertilizer,
            title: "Apport d'engrais",
            subtitle: "Pour soutenir la croissance.",
            specificDate: plant.nextFertilizingDate,
          ));
        }
      }
    }
    
    // On peut trier les tâches : Celles avec date précise en premier, puis par type
    tasks.sort((a, b) {
      if (a.specificDate != null && b.specificDate != null) {
        return a.specificDate!.compareTo(b.specificDate!);
      }
      return 0; // On garde l'ordre par défaut pour les tâches "du mois"
    });

    return tasks;
  }

  // Pour la vue SEMAINE : On veut surtout les arrosages jour par jour
  List<CalendarTask> getTasksForDay(List<Plant> myPlants, DateTime date) {
    List<CalendarTask> tasks = [];
    
    for (var plant in myPlants) {
      if (plant.lifecycleStage == 'seed') continue; // Pas d'arrosage si graine
      // Arrosage ce jour là ?
      if (isSameDay(plant.nextWateringDate, date) && plant.trackWatering) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.water,
          title: "Arrosage",
          subtitle: "Cycle de ${plant.currentFrequency} jours",
          specificDate: plant.nextWateringDate,
        ));
      }
    }
    return tasks;
  }

  // Pour la vue ANNEE : On veut juste les gros travaux (Rempotage, Hivernage)
  // On retourne une Map : { Mois (1..12) : [Tâches] }
  Map<int, List<CalendarTask>> getTasksForYear(List<Plant> myPlants, int year) {
    Map<int, List<CalendarTask>> yearMap = {};

    // On initialise la map
    for (int i = 1; i <= 12; i++) yearMap[i] = [];

    for (var plant in myPlants) {
      final speciesData = EncyclopediaService().getData(plant.species);
      if (speciesData == null) continue;

      // 1. REMPOTAGE (Seulement le mois de DÉBUT)
      // On vérifie si on doit rempoter cette année (selon la fréquence)
      // Simplification : On affiche la période idéale si elle commence cette année
      if (plant.trackRepotting && plant.repottingFreq > 0) {
         // On calcule la vraie date cible pour cette plante
         final nextDate = plant.nextRepottingDate;
         
         // On vérifie si ça tombe cette année-là
         if (nextDate.year == year) {
            // On récupère le mois idéal de l'encyclopédie pour l'affichage "période"
            // (Si pas d'encyclo, on prend le mois calculé)
            int displayMonth = nextDate.month;
            String subtitle = "";

            if (speciesData.repottingMonths.isNotEmpty) {
               displayMonth = speciesData.repottingMonths.first;
               // Petite sécurité : si la date calculée est bien plus tard que le début de période
               // on peut ajuster, mais gardons la logique "Début de saison"
               int endMonth = speciesData.repottingMonths.last;
               subtitle = "Possible jusqu'en ${_getMonthName(endMonth)}";
            }

            yearMap[displayMonth]!.add(CalendarTask(
              plant: plant,
              type: TaskType.repot,
              title: "Rempotage",
              subtitle: subtitle,
            ));
         }
      }

      // 2. TAILLE (Idem, mois de début)
      if (speciesData.pruningMonths.isNotEmpty) {
        int startMonth = speciesData.pruningMonths.first;
        int endMonth = speciesData.pruningMonths.last;
        
        yearMap[startMonth]!.add(CalendarTask(
          plant: plant,
          type: TaskType.prune,
          title: "Taille",
          subtitle: "Jusqu'en ${_getMonthName(endMonth)}",
        ));
      }
      
      // 3. SEMIS (Si graine)
      if (plant.lifecycleStage == 'seed' && speciesData.sowingMonths.isNotEmpty) {
         int startMonth = speciesData.sowingMonths.first;
         yearMap[startMonth]!.add(CalendarTask(
          plant: plant,
          type: TaskType.sow,
          title: "Semis",
          subtitle: "Début de la période",
        ));
      }

       // 4. RÉCOLTE (Potager)
      // On l'affiche si la plante n'est PAS une graine (on peut prévoir à l'avance)
      if (plant.location == 'Potager' && speciesData.harvestMonths.isNotEmpty) {
        int start = speciesData.harvestMonths.first;
        int end = speciesData.harvestMonths.last;
        
        yearMap[start]!.add(CalendarTask(
          plant: plant,
          type: TaskType.harvest,
          title: "Début des récoltes",
          subtitle: "Jusqu'en ${_getMonthName(end)}",
        ));
      }
      
      // 5. MISE EN TERRE (Repiquage)
      // C'est souvent le repottingMonths pour les légumes ? Ou on utilise une logique spécifique ?
      // Dans notre modèle actuel, on n'a pas de champ "plantingMonths" spécifique.
      // Souvent "repottingMonths" est utilisé pour la mise en terre des légumes (Mars/Avril/Mai).
      // 5. MISE EN TERRE (Vue Année)
      if (plant.location == 'Potager' && speciesData.plantingMonths.isNotEmpty) {
         int start = speciesData.plantingMonths.first;
         int end = speciesData.plantingMonths.last;
         
         // On ne l'affiche que si ce n'est pas déjà fait
         if (plant.lifecycleStage != 'planted') {
            yearMap[start]!.add(CalendarTask(
              plant: plant,
              type: TaskType.planting,
              title: "Mise en terre",
              subtitle: "Jusqu'en ${_getMonthName(end)}",
            ));
         }
      }
    }
    return yearMap;
  }

  String _getMonthName(int month) {
    // Petit helper rapide (ou utiliser DateFormat)
    const months = ["Jan", "Fév", "Mars", "Avr", "Mai", "Juin", "Juil", "Août", "Sept", "Oct", "Nov", "Déc"];
    return months[month - 1];
  }

  // Petit helper pour comparer deux dates
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Récupère tout ce qui est en retard (tous types confondus, ou juste arrosage ?)
  // Disons Arrosage surtout.
  List<CalendarTask> getOverdueTasks(List<Plant> myPlants) {
    List<CalendarTask> overdue = [];
    final now = DateTime.now();
    // On normalise "aujourd'hui" à minuit pour comparer les dates pures
    final todayMidnight = DateTime(now.year, now.month, now.day);

    for (var plant in myPlants) {
      // Si la date d'arrosage est strictement AVANT aujourd'hui
      if (plant.nextWateringDate.isBefore(todayMidnight)) {
        final daysLate = todayMidnight.difference(plant.nextWateringDate).inDays;
        
        overdue.add(CalendarTask(
          plant: plant,
          type: TaskType.water,
          title: "En retard !",
          subtitle: "$daysLate jours de retard",
          specificDate: plant.nextWateringDate,
        ));
      }
    }
    return overdue;
  }
}