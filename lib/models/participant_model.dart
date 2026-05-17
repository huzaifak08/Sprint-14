import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String id;
  final String businessId;
  final String userId;
  final String role;
  final bool isActive;
  final DateTime assignedAt;

  // 🔁 Sync tracking fields consistent with your other models
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncAttempt;

  ParticipantModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.role,
    required this.isActive,
    required this.assignedAt,
    required this.isSynced,
    required this.isDeleted,
    this.lastSyncAttempt,
  });

  // --- Convenience Helpers for Permission Control ---
  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isSalesman => role.toLowerCase() == 'salesman';

  // ===================== copyWith =====================
  ParticipantModel copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? role,
    bool? isActive,
    DateTime? assignedAt,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncAttempt,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE / CLOUD =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'userId': userId,
      'role': role,
      'isActive': isActive,
      'assignedAt': Timestamp.fromDate(assignedAt),
      // Note: Cloud Firestore tracks structural parameters, local sync engine flags stay local
    };
  }

  factory ParticipantModel.fromMap(Map<String, dynamic> map) {
    return ParticipantModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'salesman',
      isActive: map['isActive'] ?? true,
      assignedAt: map['assignedAt'] is Timestamp
          ? (map['assignedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isSynced: true,
      isDeleted: false,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL CACHE / SQLITE =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'businessId': businessId,
      'userId': userId,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'assignedAt': assignedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory ParticipantModel.fromJsonDb(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'salesman',
      isActive: (json['isActive'] ?? 1) == 1,
      assignedAt: DateTime.parse(json['assignedAt']),
      isSynced: (json['isSynced'] ?? 0) == 1,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null, // 🔥 ISO string parser fallback
    );
  }

  // ===================== STRINGS & EQUALITY =====================
  String toJson() => json.encode(toJsonDb());

  factory ParticipantModel.fromJson(String source) =>
      ParticipantModel.fromJsonDb(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParticipantModel &&
        other.id == id &&
        other.businessId == businessId &&
        other.userId == userId &&
        other.role == role &&
        other.isActive == isActive &&
        other.assignedAt == assignedAt &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted &&
        other.lastSyncAttempt == lastSyncAttempt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        businessId.hashCode ^
        userId.hashCode ^
        role.hashCode ^
        isActive.hashCode ^
        assignedAt.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'ParticipantModel(id: $id, role: $role, userId: $userId, lastSyncAttempt: $lastSyncAttempt)';
  }
}
