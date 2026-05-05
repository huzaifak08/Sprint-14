import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProjectModel {
  final String? id;
  final String appName;
  final String owner;
  final String email;
  final String password;
  final int currentStep;
  final String paymentStatus;
  final String keystorePassword;
  final List<String> backupCodes;
  final int? testingDayAtUpdate;

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final DateTime? lastSyncAttempt;

  final bool isDeleted;

  // 🕒 DateTimes (ALWAYS LAST)
  final DateTime? testingUpdateDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  ProjectModel({
    this.id,
    required this.appName,
    required this.owner,
    required this.email,
    required this.password,
    required this.currentStep,
    required this.paymentStatus,
    required this.keystorePassword,
    required this.backupCodes,
    this.testingDayAtUpdate,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
    this.testingUpdateDate,
    this.endDate,
    this.createdAt,
  });

  // ===================== copyWith =====================
  ProjectModel copyWith({
    String? id,
    String? appName,
    String? owner,
    String? email,
    String? password,
    int? currentStep,
    String? paymentStatus,
    String? keystorePassword,
    List<String>? backupCodes,
    int? testingDayAtUpdate,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
    DateTime? testingUpdateDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      owner: owner ?? this.owner,
      email: email ?? this.email,
      password: password ?? this.password,
      currentStep: currentStep ?? this.currentStep,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      keystorePassword: keystorePassword ?? this.keystorePassword,
      backupCodes: backupCodes ?? this.backupCodes,
      testingDayAtUpdate: testingDayAtUpdate ?? this.testingDayAtUpdate,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isDeleted: isDeleted ?? this.isDeleted,
      testingUpdateDate: testingUpdateDate ?? this.testingUpdateDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'owner': owner,
      'email': email,
      'password': password,
      'currentStep': currentStep,
      'paymentStatus': paymentStatus,
      'keystorePassword': keystorePassword,
      'backupCodes': backupCodes,
      'testingDayAtUpdate': testingDayAtUpdate,
      'testingUpdateDate': testingUpdateDate != null
          ? Timestamp.fromDate(testingUpdateDate!)
          : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      appName: map['appName'] ?? '',
      owner: map['owner'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      currentStep: map['currentStep']?.toInt() ?? 0,
      paymentStatus: map['paymentStatus'] ?? '',
      keystorePassword: map['keystorePassword'] ?? '',
      backupCodes: map['backupCodes'] != null
          ? List<String>.from(map['backupCodes'])
          : [],
      testingDayAtUpdate: map['testingDayAtUpdate']?.toInt(),

      // 🔥 Firestore NEVER controls sync state
      isSynced: true,
      lastSyncAttempt: null,

      isDeleted: false,

      testingUpdateDate: map['testingUpdateDate'] != null
          ? (map['testingUpdateDate'] as Timestamp).toDate()
          : null,
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  // ===================== LOCAL DB =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'appName': appName,
      'owner': owner,
      'email': email,
      'password': password,
      'currentStep': currentStep,
      'paymentStatus': paymentStatus,
      'keystorePassword': keystorePassword,
      'backupCodes': json.encode(backupCodes),
      'testingDayAtUpdate': testingDayAtUpdate,
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'testingUpdateDate': testingUpdateDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ProjectModel.fromJsonDb(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      appName: json['appName'] ?? '',
      owner: json['owner'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      currentStep: json['currentStep']?.toInt() ?? 0,
      paymentStatus: json['paymentStatus'] ?? '',
      keystorePassword: json['keystorePassword'] ?? '',
      backupCodes: json['backupCodes'] != null
          ? List<String>.from(jsonDecode(json['backupCodes']))
          : [],
      testingDayAtUpdate: json['testingDayAtUpdate']?.toInt(),
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
      testingUpdateDate: json['testingUpdateDate'] != null
          ? DateTime.parse(json['testingUpdateDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  // ===================== JSON =====================
  String toJson() => json.encode(toJsonDb());

  factory ProjectModel.fromJson(String source) =>
      ProjectModel.fromJsonDb(json.decode(source));

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel &&
        other.id == id &&
        other.appName == appName &&
        other.owner == owner &&
        other.email == email &&
        other.password == password &&
        other.currentStep == currentStep &&
        other.paymentStatus == paymentStatus &&
        other.keystorePassword == keystorePassword &&
        listEquals(other.backupCodes, backupCodes) &&
        other.testingDayAtUpdate == testingDayAtUpdate &&
        other.isSynced == isSynced &&
        other.lastSyncAttempt == lastSyncAttempt &&
        other.isDeleted == isDeleted &&
        other.testingUpdateDate == testingUpdateDate &&
        other.endDate == endDate &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      appName.hashCode ^
      owner.hashCode ^
      email.hashCode ^
      password.hashCode ^
      currentStep.hashCode ^
      paymentStatus.hashCode ^
      keystorePassword.hashCode ^
      backupCodes.hashCode ^
      testingDayAtUpdate.hashCode ^
      isSynced.hashCode ^
      lastSyncAttempt.hashCode ^
      isDeleted.hashCode ^
      testingUpdateDate.hashCode ^
      endDate.hashCode ^
      createdAt.hashCode;
}
