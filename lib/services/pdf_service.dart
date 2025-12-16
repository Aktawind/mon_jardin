/*
* Service de génération de PDF pour les fiches vacances.
* Il crée un document PDF listant les conseils d'arrosage et de soins
* pour chaque plante, adapté soit pour l'utilisateur, soit pour la nounou.
*/

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'holiday_service.dart';

enum PdfMode { all, preparation, nanny }

class PdfService {
  
  Future<void> generateHolidayPdf(List<HolidayAdvice> adviceList, String dateRange, PdfMode mode) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    
    // On groupe les plantes par Pièce (Room)
    Map<String, List<HolidayAdvice>> grouped = {};
    for (var item in adviceList) {
      String room = item.plant.room ?? item.plant.location;
      if (room.isEmpty) room = "Divers";
      if (!grouped.containsKey(room)) grouped[room] = [];
      grouped[room]!.add(item);
    }

    // PAGE 1 : PRÉPARATION (POUR MOI)
    if (mode == PdfMode.all || mode == PdfMode.preparation) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(dateRange, "Préparation (Avant départ)", fontBold),
          footer: (context) => _buildFooter(context, font),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Text("Liste des tâches à effectuer avant de partir :", style: pw.TextStyle(font: font, fontSize: 14)),
            pw.SizedBox(height: 20),

            // BLOC GENERAL
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.amber50, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Consignes générales pour toutes les plantes", style: pw.TextStyle(font: fontBold)),
                  pw.Bullet(text: "Couper les feuilles mortes et fleurs fanées."),
                  pw.Bullet(text: "Vérifier l'absence de nuisibles."),
                ],
              ),
            ),

            // LISTE SPECIFIQUE
            ...grouped.entries.map((entry) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildRoomHeader(entry.key, fontBold),
                  ...entry.value.map((item) {
                    if (item.preparation.isEmpty) return pw.SizedBox.shrink();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 12, height: 12,
                            margin: const pw.EdgeInsets.only(top: 2, right: 8),
                            decoration: pw.BoxDecoration(border: pw.Border.all(), borderRadius: pw.BorderRadius.circular(2)),
                          ),
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(text: "${item.plant.displayName} : ", style: pw.TextStyle(font: fontBold)),
                                  pw.TextSpan(text: item.preparation, style: pw.TextStyle(font: font)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 15),
                ],
              );
            }),
          ],
        ),
      );
    }

    // PAGE 2 : INSTRUCTIONS (POUR NOUNOU)
    if (mode == PdfMode.all || mode == PdfMode.nanny) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (context) => _buildHeader(dateRange, "Consignes d'Arrosage", fontBold),
          footer: (context) => _buildFooter(context, font),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.orange50, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Text(
                "Merci de prendre soin de mes plantes ! 🌱\nVoici les consignes pièce par pièce.",
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 20),

            ...grouped.entries.map((entry) {
              // Filtrer si pas d'instructions pour cette pièce
              final hasInstr = entry.value.any((i) => i.instruction.isNotEmpty);
              if (!hasInstr) return pw.SizedBox.shrink();

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildRoomHeader(entry.key, fontBold),
                  
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1), // Plante
                      1: const pw.FlexColumnWidth(2), // Consigne
                    },
                    children: entry.value.map((item) {
                      if (item.instruction.isEmpty) return pw.TableRow(children: []);

                      // Alerte rouge si "NE PAS ARROSER"
                      final isDanger = item.instruction.contains("NE PAS") || item.instruction.contains("Interdit");
                      
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isDanger ? PdfColors.red50 : null,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.plant.displayName, style: pw.TextStyle(font: fontBold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              item.instruction, 
                              style: pw.TextStyle(
                                font: font, 
                                color: isDanger ? PdfColors.red900 : PdfColors.black
                              )
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Seve_Vacances.pdf',
    );
  }

  // --- WIDGETS REUTILISABLES ---

  pw.Widget _buildHeader(String dateRange, String title, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Sève 🌿", style: pw.TextStyle(fontSize: 10, color: PdfColors.green)),
              pw.Text(title, style: pw.TextStyle(fontSize: 20, font: fontBold)),
            ],
          ),
          pw.Text(dateRange, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        "Page ${context.pageNumber}/${context.pagesCount} - Généré par Sève",
        style: pw.TextStyle(fontSize: 8, font: font, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildRoomHeader(String room, pw.Font fontBold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(room.toUpperCase(), style: pw.TextStyle(font: fontBold, color: PdfColors.green900)),
    );
  }
}