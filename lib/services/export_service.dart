import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:sprint_14/models/project_model.dart';

class ExportService {
  Future<void> exportProjectPdf(ProjectModel project) async {
    final pdf = pw.Document();

    final Uint8List logoBytes = (await rootBundle.load(
      'assets/images/sprint14-512.png',
    )).buffer.asUint8List();

    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) => _buildFooter(),
        build: (pw.Context context) => [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    height: 40,
                    width: 40,
                    child: pw.Image(logoImage),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    "Sprint14",
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF4285F4),
                    ),
                  ),
                ],
              ),
              pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
            ],
          ),
          pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFF4285F4)),
          pw.SizedBox(height: 25),

          pw.Text(
            "PROJECT REPORT: ${project.appName.toUpperCase()}",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),

          // PRIMARY DATA TABLE
          _buildDataTable(project),

          pw.SizedBox(height: 30),

          // BACKUP CODES TABLE
          if (project.backupCodes.isNotEmpty) ...[
            _buildBackupCodesTable(project.backupCodes),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${project.appName}_Report',
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 5),
          pw.Text(
            "Huzaifa Khan",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "Generated via Sprint14",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDataTable(ProjectModel project) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF4285F4),
      ),
      cellHeight: 25,
      data: <List<String>>[
        ['Field', 'Details'],
        ['Owner', project.owner],
        ['Email', project.email],
        ['Password', project.password],
        ['Keystore', project.keystorePassword],
        ['Step', "${project.currentStep}"],
        ['Payment', project.paymentStatus],
      ],
    );
  }

  pw.Widget _buildBackupCodesTable(List<String> codes) {
    // Header for the 2-column table
    List<List<String>> tableData = [
      ['Code Block A', 'Code Block B'],
    ];

    for (var i = 0; i < codes.length; i += 2) {
      // Format the first code: Clean then add TWO spaces in middle
      String rawFirst = codes[i].replaceAll(' ', '');
      String first = rawFirst.length == 8
          ? "${rawFirst.substring(0, 4)}  ${rawFirst.substring(4)}" // Double Space
          : rawFirst;

      // Format the second code if it exists
      String second = "";
      if (i + 1 < codes.length) {
        String rawSecond = codes[i + 1].replaceAll(' ', '');
        second = rawSecond.length == 8
            ? "${rawSecond.substring(0, 4)}  ${rawSecond.substring(4)}" // Double Space
            : rawSecond;
      }

      tableData.add([first, second]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "AUTHENTICATION BACKUP CODES",
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
          cellAlignment: pw.Alignment.center,
          // Courier is essential here so the two spaces occupy a predictable width
          cellStyle: pw.TextStyle(
            fontSize: 13, // Slightly larger to make the gap clear
            fontWeight: pw.FontWeight.bold,
          ),
          data: tableData,
        ),
      ],
    );
  }
}
