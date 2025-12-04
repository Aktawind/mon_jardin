import '../models/plant.dart';
import '../models/calendar_task.dart';
import '../data/plant_data.dart'; // Pour accéder à getSpeciesData

class TaskService {
  
  // Génère toutes les tâches pour un mois donné (ex: Avril 2024)
  List<CalendarTask> getTasksForMonth(List<Plant> myPlants, int month, int year) {
    List<CalendarTask> tasks = [];

    for (var plant in myPlants) {
      // 1. Récupérer les infos encyclopédiques
      final speciesData = getSpeciesData(plant.species);
      if (speciesData == null) continue; // Si pas d'info, on passe

      // --- A. Tâches basées sur l'Encyclopédie (Mois fixes) ---

      // Taille
      if (speciesData.pruningMonths.contains(month)) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.prune,
          title: "Taille",
          subtitle: "C'est la période idéale pour tailler.",
        ));
      }

      // Semis (Uniquement si la plante est au Potager ou pas encore plantée ?)
      // On affiche le conseil de semis si c'est le bon mois
      if (speciesData.sowingMonths.contains(month)) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.sow,
          title: "Semis",
          subtitle: "Période de semis (si besoin).",
        ));
      }

      // Récolte
      if (speciesData.harvestMonths.contains(month)) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.harvest,
          title: "Récolte",
          subtitle: "Profitez de vos récoltes !",
        ));
      }
      
      // Rempotage (Encyclopédie dit que c'est le bon mois)
      // On croise avec la fréquence perso : est-ce que ça fait longtemps ?
      if (speciesData.repottingMonths.contains(month)) {
        // Logique simplifiée : on le propose si c'est la saison
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.repot,
          title: "Période de Rempotage",
          subtitle: "Vérifiez si les racines sortent du pot.",
        ));
      }

      // --- B. Tâches basées sur le Calcul (Dates précises) ---
      
      // Arrosage : On regarde si la prochaine date tombe dans ce mois
      // (C'est approximatif pour la vue Mois, mais utile)
      if (plant.nextWateringDate.month == month && plant.nextWateringDate.year == year) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.water,
          title: "Arrosage prévu",
          subtitle: "Le ${plant.nextWateringDate.day}",
          specificDate: plant.nextWateringDate,
        ));
      }

      // Engrais : Si c'est pas l'hiver et que c'est le moment
      if (plant.nextFertilizingDate.month == month && plant.nextFertilizingDate.year == year) {
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
      // Arrosage ce jour là ?
      if (isSameDay(plant.nextWateringDate, date)) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.water,
          title: "Arrosage",
          subtitle: "Cycle de ${plant.currentFrequency} jours",
          specificDate: plant.nextWateringDate,
        ));
      }
      
      // On peut aussi ajouter les engrais s'ils tombent ce jour précis
      if (isSameDay(plant.nextFertilizingDate, date) && plant.fertilizerFreq > 0) {
        tasks.add(CalendarTask(
          plant: plant,
          type: TaskType.fertilizer,
          title: "Engrais",
          subtitle: "Jour J !",
          specificDate: plant.nextFertilizingDate,
        ));
      }
    }
    return tasks;
  }

  // Pour la vue ANNEE : On veut juste les gros travaux (Rempotage, Hivernage)
  // On retourne une Map : { Mois (1..12) : [Tâches] }
  Map<int, List<CalendarTask>> getTasksForYear(List<Plant> myPlants, int year) {
    Map<int, List<CalendarTask>> yearMap = {};

    for (int m = 1; m <= 12; m++) {
      yearMap[m] = [];
      // On réutilise notre moteur existant mais on ne garde que les gros trucs
      final tasksOfMonth = getTasksForMonth(myPlants, m, year);
      
      for (var task in tasksOfMonth) {
        // On ne garde que Rempotage et Taille pour la vue Année (vision long terme)
        if (task.type == TaskType.repot || task.type == TaskType.prune) {
          yearMap[m]!.add(task);
        }
      }
    }
    return yearMap;
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