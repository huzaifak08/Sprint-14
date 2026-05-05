import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String name;
  final String type;
  final String currency;
  final DateTime createdAt;
  final String ownerId;

  // 🔁 Sync & Cache fields
  final bool isSynced;
  final DateTime? lastSyncAttempt;
  final bool isDeleted;

  BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.createdAt,
    required this.ownerId,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
  });

  // ===================== copyWith =====================
  BusinessModel copyWith({
    String? id,
    String? name,
    String? type,
    String? currency,
    DateTime? createdAt,
    String? ownerId,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Clothing',
      currency: map['currency'] ?? 'PKR',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      ownerId: map['ownerId'] ?? '',
      isSynced: true,
      lastSyncAttempt: null,
      isDeleted: false,
    );
  }

  // ===================== LOCAL DB (SQLite) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'ownerId': ownerId,
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory BusinessModel.fromJsonDb(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'Clothing',
      currency: json['currency'] ?? 'PKR',
      createdAt: DateTime.parse(json['createdAt']),
      ownerId: json['ownerId'] ?? '',
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
    );
  }
}
