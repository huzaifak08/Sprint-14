import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventLedgerModel {
  final String id;
  final String title;
  final String creatorId;
  final String
  type; // 'hostel', 'trip', 'function', or any future dynamic configuration type
  final bool isSettled;
  final DateTime createdAt;
  final Map<String, dynamic> metadata; // For open-ended future configurations

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncAttempt;

  EventLedgerModel({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.type,
    this.isSettled = false,
    required this.createdAt,
    this.metadata = const {},
    required this.isSynced,
    this.isDeleted = false,
    this.lastSyncAttempt,
  });

  // ===================== copyWith =====================
  EventLedgerModel copyWith({
    String? id,
    String? title,
    String? creatorId,
    String? type,
    bool? isSettled,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncAttempt,
  }) {
    return EventLedgerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      creatorId: creatorId ?? this.creatorId,
      type: type ?? this.type,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'creatorId': creatorId,
      'type': type,
      'isSettled': isSettled,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  factory EventLedgerModel.fromMap(Map<String, dynamic> map) {
    return EventLedgerModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      creatorId: map['creatorId'] ?? '',
      type: map['type'] ?? 'custom',
      isSettled: map['isSettled'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : const {},
      isSynced: true,
      isDeleted: false,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL DB (CACHE) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'title': title,
      'creatorId': creatorId,
      'type': type,
      'isSettled': isSettled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'metadata': json.encode(metadata),
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory EventLedgerModel.fromJsonDb(Map<String, dynamic> jsonMap) {
    return EventLedgerModel(
      id: jsonMap['id'] ?? '',
      title: jsonMap['title'] ?? '',
      creatorId: jsonMap['creatorId'] ?? '',
      type: jsonMap['type'] ?? 'custom',
      isSettled: (jsonMap['isSettled'] ?? 0) == 1,
      createdAt: DateTime.parse(jsonMap['createdAt']),
      metadata: jsonMap['metadata'] != null
          ? Map<String, dynamic>.from(json.decode(jsonMap['metadata']))
          : const {},
      isSynced: (jsonMap['isSynced'] ?? 0) == 1,
      isDeleted: (jsonMap['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: jsonMap['lastSyncAttempt'] != null
          ? DateTime.parse(jsonMap['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== JSON HELPERS =====================
  String toJson() => json.encode(toJsonDb());

  factory EventLedgerModel.fromJson(String source) =>
      EventLedgerModel.fromJsonDb(json.decode(source));

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventLedgerModel &&
        other.id == id &&
        other.title == title &&
        other.creatorId == creatorId &&
        other.type == type &&
        other.isSettled == isSettled &&
        other.createdAt == createdAt &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted &&
        other.lastSyncAttempt == lastSyncAttempt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        creatorId.hashCode ^
        type.hashCode ^
        isSettled.hashCode ^
        createdAt.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'EventLedgerModel(id: $id, title: $title, type: $type, isSettled: $isSettled, isSynced: $isSynced)';
  }
}
