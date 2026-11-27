import 'dart:developer' as dev;
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:digital_munshi/helpers/backup_code_parser.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/models/project_model.dart';

/// Builds a one-page A4 PDF of a project and opens the share sheet.
///
/// The content is scaled down when needed (e.g. a long list of backup
/// codes), so the report always stays on a single page.
class ProjectPdfService {
  // Brand palette (light theme). Solid colors only: PDF viewers render
  // transparency inconsistently.
  static const _primary = PdfColor.fromInt(0xFF4285F4);
  static const _primaryDeep = PdfColor.fromInt(0xFF1F56D6);
  static const _onPrimarySoft = PdfColor.fromInt(0xFFD6E4FF);
  static const _track = PdfColor.fromInt(0xFF7FA9F7);
  static const _ink = PdfColor.fromInt(0xFF1A2233);
  static const _muted = PdfColor.fromInt(0xFF6B7385);
  static const _line = PdfColor.fromInt(0xFFE3E8F2);
  static const _card = PdfColor.fromInt(0xFFF6F8FC);
  static const _green = PdfColor.fromInt(0xFF2E9E5B);
  static const _red = PdfColor.fromInt(0xFFE5484D);
  static const _amber = PdfColor.fromInt(0xFFF08C00);

  static const _margin = 28.0;
  static const _codesPerRow = 5;

  /// --- 1. BUILD PDF ---
  /// With [includeSecrets] false, passwords and backup codes are withheld.
  Future<Uint8List> buildPdf(
    ProjectModel project, {
    required bool includeSecrets,
  }) async {
    final logo = await rootBundle.loadString('assets/images/logo.svg');
    final format = PdfPageFormat.a4;

    final doc = pw.Document(
      title: '${project.appName} - Project details',
      author: appName,
      creator: appName,
    );
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(_margin),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (_) => pw.Column(
          children: [
            pw.Expanded(
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                alignment: pw.Alignment.topCenter,
                child: pw.SizedBox(
                  width: format.width - _margin * 2,
                  child: _content(project, logo, includeSecrets),
                ),
              ),
            ),
            _footer(includeSecrets),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// --- 2. SHARE PDF ---
  /// [origin] anchors the share popover on iPad. Throws on failure.
  Future<void> share(
    ProjectModel project, {
    required bool includeSecrets,
    Rect? origin,
  }) async {
    try {
      final bytes = await buildPdf(project, includeSecrets: includeSecrets);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
          fileNameOverrides: ['${_fileSafe(project.appName)}_project.pdf'],
          subject: '${project.appName} - Project details',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      dev.log("Share project PDF failed: $e", name: "ProjectPdfService");
      rethrow;
    }
  }

  // ===================== LAYOUT =====================

  pw.Widget _content(ProjectModel p, String logo, bool includeSecrets) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _header(p, logo),
        pw.SizedBox(height: 16),
        _statTiles(p),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _section('Project overview', [
                _field('App name', p.appName),
                _field('Owner', p.owner),
                _field(
                  'Payment',
                  p.isPaid ? 'Paid' : 'Unpaid',
                  color: p.isPaid ? _green : _red,
                ),
                _field(
                  'Progress',
                  'Step ${p.currentStep} of ${ProjectModel.totalSteps} '
                      '(${(p.progress * 100).round()}%)',
                ),
              ]),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: _section('Client account', [
                _field('Email', p.email),
                _field('Password', _secret(p.password, includeSecrets)),
                _field(
                  'Keystore password',
                  _secret(p.keystorePassword, includeSecrets),
                ),
                _field('Backup codes', '${p.backupCodes.length} saved'),
              ]),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        _backupCodes(p.backupCodes, includeSecrets),
      ],
    );
  }

  pw.Widget _header(ProjectModel p, String logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(18),
        gradient: const pw.LinearGradient(
          colors: [_primary, _primaryDeep],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.SvgImage(svg: logo, width: 48, height: 48),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROJECT DETAILS',
                      style: const pw.TextStyle(
                        color: _onPrimarySoft,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _orDash(p.appName),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Owner: ${_orDash(p.owner)}',
                      style: const pw.TextStyle(
                        color: _onPrimarySoft,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              _pill(p.isPaid ? 'PAID' : 'UNPAID', p.isPaid ? _green : _red),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              pw.Text(
                p.isCompleted ? 'COMPLETED' : 'PROGRESS',
                style: pw.TextStyle(
                  color: _onPrimarySoft,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'STEP ${p.currentStep} OF ${ProjectModel.totalSteps}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          _progressBar(p.currentStep.clamp(0, ProjectModel.totalSteps)),
        ],
      ),
    );
  }

  pw.Widget _progressBar(int step) {
    const total = ProjectModel.totalSteps;
    return pw.ClipRRect(
      horizontalRadius: 4,
      verticalRadius: 4,
      child: pw.Container(
        height: 8,
        color: _track,
        child: pw.Row(
          children: [
            if (step > 0)
              pw.Expanded(
                flex: step,
                child: pw.Container(color: PdfColors.white),
              ),
            if (step < total)
              pw.Expanded(flex: total - step, child: pw.SizedBox()),
          ],
        ),
      ),
    );
  }

  pw.Widget _statTiles(ProjectModel p) {
    final days = p.daysLeft;
    final (String status, PdfColor statusColor) = days < 0
        ? ('Ended', _muted)
        : days == 0
        ? ('Ends today', _amber)
        : (
            '$days ${days == 1 ? 'day' : 'days'} left',
            days <= 3 ? _amber : _primary,
          );
    final testingDate = p.testingUpdateDate;

    final tiles = [
      _tile('START DATE', _date(p.createdAt), _weekday(p.createdAt)),
      _tile('END DATE', _date(p.endDate), _weekday(p.endDate)),
      _tile(
        'STATUS',
        status,
        days < 0
            ? '${-days} ${days == -1 ? 'day' : 'days'} ago'
            : 'In progress',
        valueColor: statusColor,
      ),
      _tile(
        'TESTING DAY',
        p.testingDayAtUpdate == null ? '-' : 'Day ${p.testingDayAtUpdate}',
        testingDate == null ? 'Not tracked' : 'Updated ${_date(testingDate)}',
      ),
    ];

    return pw.Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 10),
          pw.Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  pw.Widget _tile(
    String label,
    String value,
    String sub, {
    PdfColor valueColor = _ink,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _label(label),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(sub, style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ],
      ),
    );
  }

  pw.Widget _section(String title, List<pw.Widget> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [_sectionTitle(title), pw.SizedBox(height: 10), ...rows],
      ),
    );
  }

  pw.Widget _sectionTitle(String title, {String? trailing}) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 12,
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
              color: _ink,
            ),
          ),
        ),
        if (trailing != null)
          pw.Text(
            trailing,
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
      ],
    );
  }

  pw.Widget _field(String label, String value, {PdfColor? color}) {
    final empty = value.trim().isEmpty;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _label(label.toUpperCase()),
          pw.SizedBox(height: 3),
          pw.Text(
            empty ? 'Not set' : value,
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: empty ? _muted : (color ?? _ink),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _backupCodes(List<String> codes, bool includeSecrets) {
    final pw.Widget body;
    if (codes.isEmpty || !includeSecrets) {
      body = pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(
          codes.isEmpty
              ? 'No backup codes saved.'
              : 'Withheld for privacy (${codes.length} codes saved).',
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
      );
    } else {
      body = pw.Column(
        children: [
          for (var start = 0; start < codes.length; start += _codesPerRow)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  for (var i = start; i < start + _codesPerRow; i++) ...[
                    if (i > start) pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: i < codes.length
                          ? _codeCell(i + 1, codes[i])
                          : pw.SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: pw.BoxDecoration(
        color: _card,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(
            'Backup codes',
            trailing: codes.isEmpty || !includeSecrets
                ? null
                : 'Each code works once',
          ),
          pw.SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  pw.Widget _codeCell(int index, String code) {
    // Show standard codes as "1234 5678", the way Google prints them.
    final display = isStandardBackupCode(code)
        ? '${code.substring(0, 4)} ${code.substring(4)}'
        : code;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            index.toString().padLeft(2, '0'),
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              display,
              style: pw.TextStyle(
                font: pw.Font.courierBold(),
                fontSize: 11,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(bool includeSecrets) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Generated with $appName on '
              '${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ),
          pw.Text(
            includeSecrets
                ? 'CONFIDENTIAL - CONTAINS ACCOUNT CREDENTIALS'
                : 'CREDENTIALS WITHHELD',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
              color: includeSecrets ? _red : _muted,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SMALL PIECES =====================

  pw.Widget _label(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 1.2,
      color: _muted,
    ),
  );

  pw.Widget _pill(String text, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      // At most half the pill's height: larger radii render with spikes.
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );

  static String _secret(String value, bool include) =>
      value.isEmpty ? '' : (include ? value : 'Hidden');

  static String _orDash(String value) => value.trim().isEmpty ? '-' : value;

  static String _date(DateTime d) => DateFormat('d MMM yyyy').format(d);

  static String _weekday(DateTime d) => DateFormat('EEEE').format(d);

  /// File name made of letters, digits and underscores only.
  static String _fileSafe(String name) {
    final safe = name
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return safe.isEmpty ? 'project' : safe;
  }
}
