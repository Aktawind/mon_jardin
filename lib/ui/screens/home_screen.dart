import 'package:flutter/material.dart';
import 'my_plants_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // 0 = Mes Plantes, 1 = Calendrier

  // La liste des pages
  final List<Widget> _pages = [
    const MyPlantsScreen(),
    const CalendarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On affiche la page active
      // Astuce : IndexedStack garde l'état des pages (ne recharge pas tout quand on change d'onglet)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Couleurs harmonisées avec ton thème
        backgroundColor: Colors.white,
        indicatorColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa),
            label: 'Mes Plantes',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendrier',
          ),
        ],
      ),
    );
  }
}