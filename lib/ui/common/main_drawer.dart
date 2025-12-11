/*
* Widget pour le menu drawer principal de l'application.
* Permet de naviguer entre les écrans principaux et d'accéder aux paramètres.
* Le drawer affiche un en-tête personnalisé avec le logo et le nom de l'application.
* Chaque élément de menu met en évidence l'écran actuel.
* La navigation vers les paramètres utilise une pile (push) tandis que la navigation principale remplace l'écran actuel (replacement).
* Utilise des animations de transition pour une expérience utilisateur fluide.
* Gère la fermeture du drawer avant la navigation.
*/

import 'package:flutter/material.dart';
import '../screens/my_plants_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/plant_finder_screen.dart';
import '../screens/encyclopedia_list_screen.dart';

class MainDrawer extends StatelessWidget {
  final int currentIndex; // 0 = Plantes, 1 = Calendrier

  const MainDrawer({super.key, required this.currentIndex});

  // La méthode centrale de navigation
  void _navigateTo(BuildContext context, int index) {
    Navigator.pop(context); // 1. Ferme le drawer d'abord

    if (index == currentIndex) return; // Si on est déjà sur la page, on ne fait rien

    if (index == 99) {
      // Cas Paramètres : On empile par dessus (Push)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    } else {
      // Cas Navigation Principale : On remplace la page (Replacement)
      // pour ne pas avoir de bouton "Retour" infini
      Widget nextPage;
      if (index == 0) {
        nextPage = const MyPlantsScreen();
      }
      else if (index == 1) {
        nextPage = const CalendarScreen();
      } 
      else if (index == 2) {
        nextPage = const PlantFinderScreen();
      }
      else if (index == 3) {
        nextPage = const EncyclopediaListScreen();
      }
      else {
        nextPage = const MyPlantsScreen(); // Fallback
      }

      // Petite animation de transition fluide (Fade) optionnelle, 
      // sinon MaterialPageRoute classique
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => nextPage,
          transitionDuration: Duration.zero, // Instantané (comme des onglets)
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      child: Column(
        children: [
          // EN-TÊTE
          // EN-TÊTE PERSONNALISÉ (Centré)
          Container(
            width: double.infinity, // Prend toute la largeur
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24, // Marge safe area + espacement
              bottom: 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36, // Taille 72x72
                  backgroundColor: Colors.white,
                  child: Icon(Icons.spa, color: theme.colorScheme.primary, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Sève",
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mon compagnon végétal",
                  style: TextStyle(
                    fontSize: 14, 
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // LISTE DES ÉCRANS
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(context, 0, "Mes Plantes", Icons.home_filled),
                _buildNavItem(context, 1, "Calendrier", Icons.calendar_month),
                _buildNavItem(context, 2, "Guide d'Achat", Icons.search),
                _buildNavItem(context, 3, "Encyclopédie", Icons.menu_book),
                
                const Divider(indent: 16, endIndent: 16),
                
                // FUTUR (Décommenter quand prêt)
                /*
                _buildNavItem(context, 3, "Docteur Plante", Icons.local_hospital),
                */
              ],
            ),
          ),

          // PIED DE PAGE (Paramètres)
          const Divider(),
           SafeArea(
            top: false, 
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Paramètres"),
              onTap: () => _navigateTo(context, 99),
            ),
          ),
          const SizedBox(height: 16), 
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String title, IconData icon) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Petit espacement
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? theme.colorScheme.primary : Colors.grey[700]
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : Colors.black87,
          ),
        ),
        onTap: () => _navigateTo(context, index),
      ),
    );
  }
}