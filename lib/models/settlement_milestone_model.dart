import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettlementMilestoneModel {
  final String id;
  final String eventId;
  final String settledByUserId;
  final DateTime settledAt;
  final double totalPoolSpent;
  final List<String>
  settlementSummary; // Audited text lines: e.g., ["Huzaifa paid Ali 1500"]

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncAttempt;

  SettlementMilestoneModel({
    required this.id,
    required this.eventId,
    required this.settledByUserId,
    required this.settledAt,
    required this.totalPoolSpent,
    required this.settlementSummary,
    required this.isSynced,
    this.isDeleted = false,
    this.lastSyncAttempt,
  });

  // ===================== copyWith =====================
  SettlementMilestoneModel copyWith({
    String? id,
    String? eventId,
    String? settledByUserId,
    DateTime? settledAt,
    double? totalPoolSpent,
    List<String>? settlementSummary,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncAttempt,
  }) {
    return SettlementMilestoneModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      settledByUserId: settledByUserId ?? this.settledByUserId,
      settledAt: settledAt ?? this.settledAt,
      totalPoolSpent: totalPoolSpent ?? this.totalPoolSpent,
      settlementSummary: settlementSummary ?? this.settlementSummary,
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
      'settledByUserId': settledByUserId,
      'settledAt': Timestamp.fromDate(settledAt),
      'totalPoolSpent': totalPoolSpent,
      'settlementSummary': settlementSummary,
    };
  }

  factory SettlementMilestoneModel.fromMap(Map<String, dynamic> map) {
    return SettlementMilestoneModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      settledByUserId: map['settledByUserId'] ?? '',
      settledAt: map['settledAt'] is Timestamp
          ? (map['settledAt'] as Timestamp).toDate()
          : DateTime.now(),
      totalPoolSpent: (map['totalPoolSpent'] is num)
          ? (map['totalPoolSpent'] as num).toDouble()
          : 0.0,
      settlementSummary: map['settlementSummary'] != null
          ? List<String>.from(map['settlementSummary'])
          : const [],
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
      'settledByUserId': settledByUserId,
      'settledAt': settledAt.toIso8601String(),
      'totalPoolSpent': totalPoolSpent,
      'settlementSummary': json.encode(settlementSummary),
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory SettlementMilestoneModel.fromJsonDb(Map<String, dynamic> jsonMap) {
    return SettlementMilestoneModel(
      id: jsonMap['id'] ?? '',
      eventId: jsonMap['eventId'] ?? '',
      settledByUserId: jsonMap['settledByUserId'] ?? '',
      settledAt: DateTime.parse(jsonMap['settledAt']),
      totalPoolSpent: (jsonMap['totalPoolSpent'] is num)
          ? (jsonMap['totalPoolSpent'] as num).toDouble()
          : 0.0,
      settlementSummary: jsonMap['settlementSummary'] != null
          ? List<String>.from(json.decode(jsonMap['settlementSummary']))
          : const [],
      isSynced: (jsonMap['isSynced'] ?? 0) == 1,
      isDeleted: (jsonMap['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: jsonMap['lastSyncAttempt'] != null
          ? DateTime.parse(jsonMap['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== JSON HELPERS =====================
  String toJson() => json.encode(toJsonDb());

  factory SettlementMilestoneModel.fromJson(String source) =>
      SettlementMilestoneModel.fromJsonDb(json.decode(source));

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettlementMilestoneModel &&
        other.id == id &&
        other.eventId == eventId &&
        other.settledByUserId == settledByUserId &&
        other.settledAt == settledAt &&
        other.totalPoolSpent == totalPoolSpent &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted &&
        other.lastSyncAttempt == lastSyncAttempt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        settledByUserId.hashCode ^
        settledAt.hashCode ^
        totalPoolSpent.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'SettlementMilestoneModel(id: $id, totalPoolSpent: $totalPoolSpent, isSynced: $isSynced)';
  }
}
