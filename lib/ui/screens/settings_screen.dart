import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/preferences_service.dart';

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