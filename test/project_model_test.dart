import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectModel', () {
    test('parses a stored document, including null testing fields', () {
      final p = ProjectModel.fromMap({
        'id': 'abc',
        'appName': 'Sample App',
        'owner': 'Alex',
        'email': 'a@b.com',
        'password': 'x',
        'keystorePassword': 'y',
        'backupCodes': ['0042', 1234],
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 1, 31)),
        'currentStep': 10,
        'paymentStatus': 'paid',
        'testingDayAtUpdate': null,
        'testingUpdateDate': null,
      });

      expect(p.backupCodes, ['0042', '1234']);
      expect(p.isPaid, isTrue);
      expect(p.isCompleted, isTrue);
      expect(p.progress, 1.0);
      expect(p.testingDayAtUpdate, isNull);
      expect(p.isActive, isFalse);
    });

    test('defaults missing fields safely', () {
      final p = ProjectModel.fromMap({'id': 'x'});
      expect(p.paymentStatus, PaymentStatus.unpaid);
      expect(p.currentStep, 0);
      expect(p.backupCodes, isEmpty);
      expect(p.endDate, p.createdAt);
    });

    test('round-trips through toMap', () {
      final p = ProjectModel.fromMap({
        'id': 'r',
        'appName': 'App',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
        'endDate': Timestamp.fromDate(DateTime(2026, 3, 31)),
        'currentStep': 4,
        'testingDayAtUpdate': 7,
        'testingUpdateDate': Timestamp.fromDate(DateTime(2026, 3, 10)),
      });
      final again = ProjectModel.fromMap(p.toMap());
      expect(again.toMap(), p.toMap());
      expect(again.paymentStatus, PaymentStatus.unpaid);
    });

    test('cloud copies are synced; SQLite round-trip keeps every field', () {
      final cloud = ProjectModel.fromMap({
        'id': 'db',
        'appName': 'Demo App',
        'owner': 'Sam',
        'email': 'g@x.com',
        'password': 'p',
        'keystorePassword': 'k',
        'backupCodes': ['11112222', '33334444'],
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 10)),
        'endDate': Timestamp.fromDate(DateTime(2026, 2, 8)),
        'currentStep': 6,
        'paymentStatus': 'paid',
        'testingDayAtUpdate': 4,
        'testingUpdateDate': Timestamp.fromDate(DateTime(2026, 1, 20)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 21, 9, 30)),
      });
      expect(cloud.isSynced, isTrue);
      expect(cloud.isDeleted, isFalse);

      final pending = cloud.copyWith(isSynced: false, isDeleted: true);
      final back = ProjectModel.fromJsonDb(pending.toJsonDb());
      expect(back.toJsonDb(), pending.toJsonDb());
      expect(back.backupCodes, ['11112222', '33334444']);
      expect(back.isSynced, isFalse);
      expect(back.isDeleted, isTrue);
      expect(back.updatedAt, DateTime(2026, 1, 21, 9, 30));
    });

    test('corrupt cached backup codes decode to an empty list', () {
      final row = ProjectModel.fromMap({'id': 'c'}).toJsonDb()
        ..['backupCodes'] = 'not json';
      expect(ProjectModel.fromJsonDb(row).backupCodes, isEmpty);
    });

    test('copyWith clearTesting removes both testing fields', () {
      final p = ProjectModel.fromMap({
        'testingDayAtUpdate': 3,
        'testingUpdateDate': Timestamp.now(),
      }).copyWith(clearTesting: true);
      expect(p.testingDayAtUpdate, isNull);
      expect(p.testingUpdateDate, isNull);
    });

    test('daysLeft counts calendar days', () {
      final now = DateTime.now();
      ProjectModel ending(int days) => ProjectModel.fromMap({
        'createdAt': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + days, 23, 59),
        ),
      });
      expect(ending(0).daysLeft, 0);
      expect(ending(0).isActive, isTrue);
      expect(ending(5).daysLeft, 5);
      expect(ending(-2).daysLeft, -2);
    });
  });
}
