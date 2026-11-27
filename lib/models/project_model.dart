import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  paid,
  unpaid;

  static PaymentStatus parse(Object? value) =>
      value == 'paid' ? PaymentStatus.paid : PaymentStatus.unpaid;
}

/// A client app project, stored at `users/{uid}/projects/{id}` and cached
/// locally in SQLite (see ProjectTable).
class ProjectModel {
  /// Number of steps in a project's workflow; [currentStep] runs 0..this.
  static const int totalSteps = 10;

  final String id;
  final String appName;
  final String owner;

  // Client account used for the project.
  final String email;
  final String password;
  final String keystorePassword;
  final List<String> backupCodes;

  final DateTime createdAt;
  final DateTime endDate;
  final int currentStep;
  final PaymentStatus paymentStatus;

  /// Testing day as last reported, and when it was reported.
  final int? testingDayAtUpdate;
  final DateTime? testingUpdateDate;

  /// Last local edit time, used to keep the newest edit when two devices
  /// change the same project.
  final DateTime? updatedAt;

  // 🔁 Sync & Cache fields (local only)
  final bool isSynced;
  final DateTime? lastSyncAttempt;
  final bool isDeleted;

  const ProjectModel({
    required this.id,
    required this.appName,
    required this.owner,
    required this.email,
    required this.password,
    required this.keystorePassword,
    required this.backupCodes,
    required this.createdAt,
    required this.endDate,
    required this.currentStep,
    required this.paymentStatus,
    this.testingDayAtUpdate,
    this.testingUpdateDate,
    this.updatedAt,
    this.isSynced = false,
    this.lastSyncAttempt,
    this.isDeleted = false,
  });

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isCompleted => currentStep >= totalSteps;

  /// Still running: ends today or later.
  bool get isActive => daysLeft >= 0;
  double get progress => (currentStep / totalSteps).clamp(0.0, 1.0);

  /// Whole calendar days until [endDate] (negative once it has passed).
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return (end.difference(today).inHours / 24).round();
  }

  // ===================== copyWith =====================
  /// Pass [clearTesting] to remove both testing fields.
  ProjectModel copyWith({
    String? appName,
    String? owner,
    String? email,
    String? password,
    String? keystorePassword,
    List<String>? backupCodes,
    DateTime? createdAt,
    DateTime? endDate,
    int? currentStep,
    PaymentStatus? paymentStatus,
    int? testingDayAtUpdate,
    DateTime? testingUpdateDate,
    bool clearTesting = false,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
  }) {
    return ProjectModel(
      id: id,
      appName: appName ?? this.appName,
      owner: owner ?? this.owner,
      email: email ?? this.email,
      password: password ?? this.password,
      keystorePassword: keystorePassword ?? this.keystorePassword,
      backupCodes: backupCodes ?? this.backupCodes,
      createdAt: createdAt ?? this.createdAt,
      endDate: endDate ?? this.endDate,
      currentStep: currentStep ?? this.currentStep,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      testingDayAtUpdate: clearTesting
          ? null
          : (testingDayAtUpdate ?? this.testingDayAtUpdate),
      testingUpdateDate: clearTesting
          ? null
          : (testingUpdateDate ?? this.testingUpdateDate),
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'owner': owner,
      'email': email,
      'password': password,
      'keystorePassword': keystorePassword,
      'backupCodes': backupCodes,
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': Timestamp.fromDate(endDate),
      'currentStep': currentStep,
      'paymentStatus': paymentStatus.name,
      'testingDayAtUpdate': testingDayAtUpdate,
      'testingUpdateDate': _timestamp(testingUpdateDate),
      'updatedAt': _timestamp(updatedAt),
    };
  }

  /// Cloud copies are synced by definition.
  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    final createdAt = _date(map['createdAt']) ?? DateTime.now();
    return ProjectModel(
      id: map['id'] ?? '',
      appName: map['appName'] ?? '',
      owner: map['owner'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      keystorePassword: map['keystorePassword'] ?? '',
      backupCodes: [
        for (final code in (map['backupCodes'] as List?) ?? const [])
          code.toString(),
      ],
      createdAt: createdAt,
      endDate: _date(map['endDate']) ?? createdAt,
      currentStep: (map['currentStep'] as num?)?.toInt() ?? 0,
      paymentStatus: PaymentStatus.parse(map['paymentStatus']),
      testingDayAtUpdate: (map['testingDayAtUpdate'] as num?)?.toInt(),
      testingUpdateDate: _date(map['testingUpdateDate']),
      updatedAt: _date(map['updatedAt']),
      isSynced: true,
    );
  }

  // ===================== LOCAL DB (SQLite) =====================
  Map<String, Object?> toJsonDb() {
    return {
      'id': id,
      'appName': appName,
      'owner': owner,
      'email': email,
      'password': password,
      'keystorePassword': keystorePassword,
      'backupCodes': jsonEncode(backupCodes),
      'createdAt': createdAt.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'currentStep': currentStep,
      'paymentStatus': paymentStatus.name,
      'testingDayAtUpdate': testingDayAtUpdate,
      'testingUpdateDate': testingUpdateDate?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory ProjectModel.fromJsonDb(Map<String, Object?> json) {
    final createdAt = _date(json['createdAt']) ?? DateTime.now();
    return ProjectModel(
      id: json['id'] as String,
      appName: json['appName'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      keystorePassword: json['keystorePassword'] as String? ?? '',
      backupCodes: _decodeCodes(json['backupCodes']),
      createdAt: createdAt,
      endDate: _date(json['endDate']) ?? createdAt,
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
      paymentStatus: PaymentStatus.parse(json['paymentStatus']),
      testingDayAtUpdate: (json['testingDayAtUpdate'] as num?)?.toInt(),
      testingUpdateDate: _date(json['testingUpdateDate']),
      updatedAt: _date(json['updatedAt']),
      isSynced: json['isSynced'] == 1,
      lastSyncAttempt: _date(json['lastSyncAttempt']),
      isDeleted: json['isDeleted'] == 1,
    );
  }

  // ===================== HELPERS =====================
  static DateTime? _date(Object? value) => switch (value) {
    Timestamp t => t.toDate(),
    String s => DateTime.tryParse(s),
    _ => null,
  };

  static Timestamp? _timestamp(DateTime? d) =>
      d == null ? null : Timestamp.fromDate(d);

  static List<String> _decodeCodes(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    try {
      return [for (final c in jsonDecode(value) as List) c.toString()];
    } on FormatException {
      return const [];
    }
  }
}
