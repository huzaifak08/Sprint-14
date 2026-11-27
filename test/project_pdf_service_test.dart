import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/services/project_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectModel _project({int codes = 10, int step = 7}) => ProjectModel.fromMap({
  'id': 'p1',
  'appName': 'Sample App',
  'owner': 'Alex Client',
  'email': 'client.account@example.com',
  'password': 'Sample@123',
  'keystorePassword': 'keystore-pass',
  'backupCodes': [
    for (var i = 0; i < codes; i++) '${10000000 + i * 1234567}',
  ],
  'createdAt': Timestamp.fromDate(DateTime(2026, 3, 4)),
  'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 6))),
  'currentStep': step,
  'paymentStatus': 'unpaid',
  'testingDayAtUpdate': 9,
  'testingUpdateDate': Timestamp.fromDate(DateTime(2026, 3, 18)),
});

/// Pages in the document (counts page objects, not the page tree).
int _pageCount(List<int> bytes) =>
    RegExp(r'/Type\s*/Page(?!s)').allMatches(String.fromCharCodes(bytes)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = ProjectPdfService();
  // Set PDF_OUT to a folder to save the samples for a visual check.
  final out = Platform.environment['PDF_OUT'];

  final cases = {
    'standard': (_project(), true),
    'withheld': (_project(), false),
    'many_codes': (_project(codes: 60, step: 10), true),
    'empty': (
      ProjectModel.fromMap({'id': 'e', 'createdAt': Timestamp.now()}),
      true,
    ),
  };

  for (final MapEntry(key: name, value: (project, secrets)) in cases.entries) {
    test('builds a single-page PDF: $name', () async {
      final bytes = await service.buildPdf(project, includeSecrets: secrets);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(_pageCount(bytes), 1);
      if (out != null) await File('$out/project_$name.pdf').writeAsBytes(bytes);
    });
  }
}
