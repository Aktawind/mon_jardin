/*
* Widget pour le menu de gestion d'une plante.
* Permet d'accéder aux actions principales : modifier, supprimer, voir l'album photo, voir l'historique.
* Utilise des ListTile pour une interface utilisateur claire.
*/

import 'package:flutter/material.dart';
import '../../models/plant.dart';

class PlantManagementMenu extends StatelessWidget {
  final Plant plant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback onAlbum;
  final VoidCallback onEncyclopedia;

  const PlantManagementMenu({
    super.key,
    required this.plant,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
    required this.onAlbum,
    required this.onEncyclopedia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [          
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.blueGrey),
              title: const Text("Fiche encyclopédique"),
              onTap: () {
                Navigator.pop(context);
                onEncyclopedia();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blueGrey),
              title: const Text("Album Photo"),
              onTap: () {
                Navigator.pop(context);
                onAlbum();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blueGrey),
              title: const Text("Journal des actions"),
              onTap: () {
                Navigator.pop(context);
                onHistory();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.grey),
              title: const Text("Modifier la fiche"),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text("Supprimer la plante", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}