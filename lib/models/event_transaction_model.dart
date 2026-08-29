import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventTransactionModel {
  final String id;
  final String eventId;
  final String paidById;
  final double totalAmount;
  final String description;
  final String category;
  final DateTime transactionDate;
  final String? milestoneId;
  final Map<String, double> splitDetails;
  final bool isFundDeposit;
  final bool paidFromPool;
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
    this.isFundDeposit = false,
    this.paidFromPool = false,
    required this.isSynced,
    this.isDeleted = false,
    this.lastSyncAttempt,
  });

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
    bool? isFundDeposit,
    bool? paidFromPool,
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
      isFundDeposit: isFundDeposit ?? this.isFundDeposit,
      paidFromPool: paidFromPool ?? this.paidFromPool,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

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
      'isFundDeposit': isFundDeposit,
      'paidFromPool': paidFromPool,
    };
  }

  factory EventTransactionModel.fromMap(Map<String, dynamic> map) {
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
      isFundDeposit: map['isFundDeposit'] ?? false,
      paidFromPool: map['paidFromPool'] ?? false,
      isSynced: true,
      isDeleted: false,
      lastSyncAttempt: null,
    );
  }

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
      'isFundDeposit': isFundDeposit ? 1 : 0,
      'paidFromPool': paidFromPool ? 1 : 0,
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
      isFundDeposit: (jsonMap['isFundDeposit'] ?? 0) == 1,
      paidFromPool: (jsonMap['paidFromPool'] ?? 0) == 1,
      isSynced: (jsonMap['isSynced'] ?? 0) == 1,
      isDeleted: (jsonMap['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: jsonMap['lastSyncAttempt'] != null
          ? DateTime.parse(jsonMap['lastSyncAttempt'])
          : null,
    );
  }

  String toJson() => json.encode(toJsonDb());

  factory EventTransactionModel.fromJson(String source) =>
      EventTransactionModel.fromJsonDb(json.decode(source));

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
        other.isFundDeposit == isFundDeposit &&
        other.paidFromPool == paidFromPool &&
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
        isFundDeposit.hashCode ^
        paidFromPool.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'EventTransactionModel(id: $id, amount: $totalAmount, category: $category, isFundDeposit: $isFundDeposit, paidFromPool: $paidFromPool, isSynced: $isSynced)';
  }
}