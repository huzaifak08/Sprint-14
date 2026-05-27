import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventParticipantModel {
  final String id;
  final String eventId;
  final String? userId;
  final String displayName;
  final bool isActive;
  final DateTime joinedAt;

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncAttempt;

  EventParticipantModel({
    required this.id,
    required this.eventId,
    this.userId,
    required this.displayName,
    this.isActive = true,
    required this.joinedAt,
    required this.isSynced,
    this.isDeleted = false,
    this.lastSyncAttempt,
  });

  bool get isGuest => userId == null;

  // ===================== copyWith =====================
  EventParticipantModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? displayName,
    bool? isActive,
    DateTime? joinedAt,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncAttempt,
  }) {
    return EventParticipantModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'displayName': displayName,
      'isActive': isActive,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory EventParticipantModel.fromMap(Map<String, dynamic> map) {
    return EventParticipantModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      userId: map['userId'] as String?,
      displayName: map['displayName'] ?? '',
      isActive: map['isActive'] ?? true,
      joinedAt: map['joinedAt'] is Timestamp
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isSynced: true,
      isDeleted: false,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL DB (CACHE) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'displayName': displayName,
      'isActive': isActive ? 1 : 0,
      'joinedAt': joinedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory EventParticipantModel.fromJsonDb(Map<String, dynamic> jsonMap) {
    return EventParticipantModel(
      id: jsonMap['id'] ?? '',
      eventId: jsonMap['eventId'] ?? '',
      userId: jsonMap['userId'] as String?,
      displayName: jsonMap['displayName'] ?? '',
      isActive: (jsonMap['isActive'] ?? 1) == 1,
      joinedAt: DateTime.parse(jsonMap['joinedAt']),
      isSynced: (jsonMap['isSynced'] ?? 0) == 1,
      isDeleted: (jsonMap['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: jsonMap['lastSyncAttempt'] != null
          ? DateTime.parse(jsonMap['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== JSON HELPERS =====================
  String toJson() => json.encode(toJsonDb());

  factory EventParticipantModel.fromJson(String source) =>
      EventParticipantModel.fromJsonDb(json.decode(source));

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventParticipantModel &&
        other.id == id &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.displayName == displayName &&
        other.isActive == isActive &&
        other.joinedAt == joinedAt &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted &&
        other.lastSyncAttempt == lastSyncAttempt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        userId.hashCode ^
        displayName.hashCode ^
        isActive.hashCode ^
        joinedAt.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'EventParticipantModel(id: $id, name: $displayName, isGuest: $isGuest, isSynced: $isSynced)';
  }
}
