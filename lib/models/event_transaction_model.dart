import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventTransactionModel {
  final String id;
  final String eventId;
  final String paidById; // References unique EventParticipantModel ID string
  final double totalAmount;
  final String description;
  final String category; // 'food', 'utilities', or custom locally added strings
  final DateTime transactionDate;
  final String?
  milestoneId; // Linked if it passes a calculation freeze checkout pass

  /// Matrix layout tracking split profiles. Maps participant ID to their numeric cost obligation.
  /// Example structural configuration inside Firestore or SQLite fields:
  /// `{"participant_id_1": 450.00, "participant_id_2": 0.00}`
  final Map<String, double> splitDetails;

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncAttempt;

  EventTransactionModel({
    required this.id,
    required this.eventId,
    required this.paidById,
    required this.totalAmount,
    required this.description,
    required this.category,
    required this.transactionDate,
    this.milestoneId,
    required this.splitDetails,
    required this.isSynced,
    this.isDeleted = false,
    this.lastSyncAttempt,
  });

  // ===================== copyWith =====================
  EventTransactionModel copyWith({
    String? id,
    String? eventId,
    String? paidById,
    double? totalAmount,
    String? description,
    String? category,
    DateTime? transactionDate,
    String? milestoneId,
    Map<String, double>? splitDetails,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncAttempt,
  }) {
    return EventTransactionModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      paidById: paidById ?? this.paidById,
      totalAmount: totalAmount ?? this.totalAmount,
      description: description ?? this.description,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      milestoneId: milestoneId ?? this.milestoneId,
      splitDetails: splitDetails ?? this.splitDetails,
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
      'paidById': paidById,
      'totalAmount': totalAmount,
      'description': description,
      'category': category,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'milestoneId': milestoneId,
      'splitDetails': splitDetails,
    };
  }

  factory EventTransactionModel.fromMap(Map<String, dynamic> map) {
    // Dynamic cast safely into nested maps to prevent casting issues from Firestore maps
    final rawSplits = map['splitDetails'] as Map<String, dynamic>? ?? const {};
    final Map<String, double> castedSplits = rawSplits.map(
      (key, value) => MapEntry(key, (value is num) ? value.toDouble() : 0.0),
    );

    return EventTransactionModel(
      id: map['id'] ?? '',
      eventId: map['eventId'] ?? '',
      paidById: map['paidById'] ?? '',
      totalAmount: (map['totalAmount'] is num)
          ? (map['totalAmount'] as num).toDouble()
          : 0.0,
      description: map['description'] ?? '',
      category: map['category'] ?? 'uncategorized',
      transactionDate: map['transactionDate'] is Timestamp
          ? (map['transactionDate'] as Timestamp).toDate()
          : DateTime.now(),
      milestoneId: map['milestoneId'] as String?,
      splitDetails: castedSplits,
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
      'paidById': paidById,
      'totalAmount': totalAmount,
      'description': description,
      'category': category,
      'transactionDate': transactionDate.toIso8601String(),
      'milestoneId': milestoneId,
      'splitDetails': json.encode(splitDetails),
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory EventTransactionModel.fromJsonDb(Map<String, dynamic> jsonMap) {
    final rawSplits = jsonMap['splitDetails'] != null
        ? json.decode(jsonMap['splitDetails']) as Map<String, dynamic>
        : const {};

    final Map<String, double> castedSplits = rawSplits.map(
      (key, value) => MapEntry(key, (value is num) ? value.toDouble() : 0.0),
    );

    return EventTransactionModel(
      id: jsonMap['id'] ?? '',
      eventId: jsonMap['eventId'] ?? '',
      paidById: jsonMap['paidById'] ?? '',
      totalAmount: (jsonMap['totalAmount'] is num)
          ? (jsonMap['totalAmount'] as num).toDouble()
          : 0.0,
      description: jsonMap['description'] ?? '',
      category: jsonMap['category'] ?? 'uncategorized',
      transactionDate: DateTime.parse(jsonMap['transactionDate']),
      milestoneId: jsonMap['milestoneId'] as String?,
      splitDetails: castedSplits,
      isSynced: (jsonMap['isSynced'] ?? 0) == 1,
      isDeleted: (jsonMap['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: jsonMap['lastSyncAttempt'] != null
          ? DateTime.parse(jsonMap['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== JSON HELPERS =====================
  String toJson() => json.encode(toJsonDb());

  factory EventTransactionModel.fromJson(String source) =>
      EventTransactionModel.fromJsonDb(json.decode(source));

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventTransactionModel &&
        other.id == id &&
        other.eventId == eventId &&
        other.paidById == paidById &&
        other.totalAmount == totalAmount &&
        other.description == description &&
        other.category == category &&
        other.transactionDate == transactionDate &&
        other.milestoneId == milestoneId &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted &&
        other.lastSyncAttempt == lastSyncAttempt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventId.hashCode ^
        paidById.hashCode ^
        totalAmount.hashCode ^
        description.hashCode ^
        category.hashCode ^
        transactionDate.hashCode ^
        milestoneId.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'EventTransactionModel(id: $id, amount: $totalAmount, category: $category, isSynced: $isSynced)';
  }
}
