/*
* Ce fichier gère la création et la restauration des sauvegardes.
* Une sauvegarde est un fichier ZIP contenant :
* - La base de données SQLite
* - Les photos des plantes
*/

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../data/database_service.dart';
import 'package:flutter/material.dart';


class BackupService {
  
  // Etape 1 : Créer le fichier ZIP (Méthode privée réutilisable)
  Future<String> _createZipFile() async {
    final archive = Archive();
    
    // A. Base de données
    final dbFolder = await getDatabasesPath();
    final dbFile = File(p.join(dbFolder, 'mon_jardin.db'));
    if (await dbFile.exists()) {
      final bytes = await dbFile.readAsBytes();
      // On force le nom "mon_jardin.db" à la racine du zip
      archive.addFile(ArchiveFile('mon_jardin.db', bytes.length, bytes));
    }

    // B. Photos
    final appDir = await getApplicationDocumentsDirectory();
    try {
      final files = appDir.listSync();
      for (var file in files) {
        if (file is File && (file.path.endsWith('.jpg') || file.path.endsWith('.png'))) {
          final bytes = await file.readAsBytes();
          final name = p.basename(file.path);
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }
    } catch (e) { debugPrint("Erreur photos: $e"); }

    // C. Ecriture du ZIP
    final tempDir = await getTemporaryDirectory();
    final zipPath = '${tempDir.path}/seve_backup.zip';
    final zipFile = File(zipPath);
    
    // Encodage
    final encodedZip = ZipEncoder().encode(archive);
    
    if (encodedZip != null) {
      await zipFile.writeAsBytes(encodedZip);
    } else {
      debugPrint('Erreur : L\'encodage ZIP a retourné une valeur nulle.');
    }
   
    return zipPath;
  }

  // OPTION A : Partager (Mail, Drive, WhatsApp...)
  Future<void> exportViaShare() async {
    final zipPath = await _createZipFile();
    await Share.shareXFiles([XFile(zipPath)], text: 'Ma sauvegarde Sève 🌱');
  }

  // OPTION B : Enregistrer sur le téléphone (Téléchargements...)
  Future<bool> exportToDevice() async {
    final zipPath = await _createZipFile();
    
    final params = SaveFileDialogParams(
      sourceFilePath: zipPath,
      fileName: 'sauvegarde_seve_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}.zip'
    );

    try {
      final filePath = await FlutterFileDialog.saveFile(params: params);
      return filePath != null; // Renvoie true si l'utilisateur a sauvegardé
    } catch (e) {
      debugPrint("Erreur de sauvegarde locale : $e");
      return false;
    }
  }

  // Import (Reste identique)
  Future<void> importData(String zipPath) async {
    // 1. FERMER LA BDD (Indispensable)
    await DatabaseService().close();

    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dbFolder = await getDatabasesPath();
    final appDir = await getApplicationDocumentsDirectory();

    for (final file in archive) {
      if (!file.isFile) continue; // On ignore les dossiers

      final filename = p.basename(file.name); // On prend juste le nom, on ignore les dossiers parents éventuels
      final data = file.content as List<int>;
        
      if (filename == 'mon_jardin.db') { // Nom exact
        // On écrase la BDD
        final targetFile = File(p.join(dbFolder, 'mon_jardin.db'));
        if (await targetFile.exists()) await targetFile.delete();
        await targetFile.writeAsBytes(data, flush: true);
        debugPrint("BDD Restaurée");
      } 
      else if (filename.endsWith('.jpg') || filename.endsWith('.png')) {
        // On écrase les photos
        final targetFile = File(p.join(appDir.path, filename));
        // Pas besoin de delete avant, writeAsBytes écrase
        await targetFile.writeAsBytes(data);
      }
    }
    
    // Astuce : On ré-ouvre la BDD pour vérifier que c'est bon
    // (L'appel suivant à .database la ré-ouvrira automatiquement)
  }
}