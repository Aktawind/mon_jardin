/*
* Écran des paramètres de l'application.
* Permet de configurer les notifications pour les rappels d'arrosage, fertilisation et rempotage.
* Affiche aussi des informations sur l'application (version, développeur).
*/

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/preferences_service.dart';
import '../../services/backup_service.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "";
  
  // États des switchs
  bool _notifyWater = true;
  bool _notifyFertilizer = true;
  bool _notifyRepot = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Version
    final info = await PackageInfo.fromPlatform();
    
    // 2. Préférences
    final prefs = PreferencesService();
    final water = await prefs.getBool(PreferencesService.keyNotifyWater);
    final fert = await prefs.getBool(PreferencesService.keyNotifyFertilizer);
    final repot = await prefs.getBool(PreferencesService.keyNotifyRepot);

    setState(() {
      _version = info.version;
      _notifyWater = water;
      _notifyFertilizer = fert;
      _notifyRepot = repot;
    });
  }

  // Action quand on clique sur un switch
  Future<void> _toggleSetting(String key, bool currentValue, Function(bool) updateState) async {
    final newValue = !currentValue;
    await PreferencesService().setBool(key, newValue);
    setState(() {
      updateState(newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Notifications"),
          
          SwitchListTile(
            title: const Text("Rappels d'arrosage"),
            subtitle: const Text("Soyez prévenu quand une plante a soif"),
            secondary: const Icon(Icons.water_drop, color: Colors.blue),
            value: _notifyWater,
            onChanged: (val) => _toggleSetting(PreferencesService.keyNotifyWater, _notifyWater, (v) => _notifyWater = v),
          ),
          
          SwitchListTile(
            title: const Text("Rappels de fertilisation"),
            subtitle: const Text("Pour ne pas oublier l'engrais"),
            secondary: const Icon(Icons.science, color: Colors.purple),
            value: _notifyFertilizer,
            onChanged: (val) => _toggleSetting(PreferencesService.keyNotifyFertilizer, _notifyFertilizer, (v) => _notifyFertilizer = v),
          ),
          
          SwitchListTile(
            title: const Text("Rappels de rempotage"),
            subtitle: const Text("Une fois par an ou tous les 2 ans"),
            secondary: const Icon(Icons.change_circle, color: Colors.orange),
            value: _notifyRepot,
            onChanged: (val) => _toggleSetting(PreferencesService.keyNotifyRepot, _notifyRepot, (v) => _notifyRepot = v),
          ),

          const Divider(height: 32),

          _buildSectionTitle("Données"),

          // BOUTON SAUVEGARDER
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.blue),
            title: const Text("Sauvegarder mes données"),
            subtitle: const Text("Export (Zip)"),
            onTap: () async {
              // On demande à l'utilisateur ce qu'il préfère
              final choice = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.share),
                        title: const Text("Envoyer / Partager"),
                        subtitle: const Text("Via Email, Drive, WhatsApp..."),
                        onTap: () => Navigator.pop(ctx, 'share'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.save_alt),
                        title: const Text("Enregistrer sur le téléphone"),
                        subtitle: const Text("Dans Téléchargements ou autre"),
                        onTap: () => Navigator.pop(ctx, 'save'),
                      ),
                    ],
                  ),
                ),
              );

              if (choice == null) return; // Annulé

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Préparation...")));
              }

              try {
                if (choice == 'share') {
                  await BackupService().exportViaShare();
                } else {
                  final success = await BackupService().exportToDevice();
                  if (success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sauvegarde enregistrée avec succès ! ✅")));
                    }
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red));
                }
              }
            },
          ),

          // BOUTON RESTAURER
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text("Restaurer une sauvegarde"),
            subtitle: const Text("Importer un fichier .zip"),
            onTap: () async {
              // 1. Avertissement avant d'écraser
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Attention"),
                  content: const Text("La restauration va REMPLACER toutes vos données actuelles par celles du fichier.\n\nVoulez-vous continuer ?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Continuer", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm != true) return;

              // 2. Sélection du fichier
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['zip'], // On filtre pour n'accepter que les zips
                );

                if (result != null) {
                  final path = result.files.single.path!;
                  
                  // 3. Import
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Restauration en cours...")),
                  );
                  }
                  
                  await BackupService().importData(path);
                  
                  // 4. Succès
                  // Idéalement, on pourrait redémarrer l'appli ou recharger les providers, 
                  // mais un message clair suffit pour l'instant.
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Succès !"),
                        content: const Text("Vos données ont été restaurées.\n\nVeuillez redémarrer l'application pour voir les changements."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
                        ],
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur lors de l'import : $e"), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
          const Divider(height: 32),

          _buildSectionTitle("Application"),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Version"),
            subtitle: Text(_version.isNotEmpty ? _version : "Chargement..."),
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: const Text("Développé avec ❤️"),
            subtitle: const Text("Flutter & Dart"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}