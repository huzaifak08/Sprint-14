import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String businessId;
  final String category; // e.g., "Tea", "Guests", "Utilities", "Other"
  final String? note; // Optional description
  final double amount;
  final DateTime dateTime;
  final String recordedById; // Tracking who added the expense (for roles)

  // 🔁 Sync & Cache fields
  final bool isSynced;
  final DateTime? lastSyncAttempt;
  final bool isDeleted;

  ExpenseModel({
    required this.id,
    required this.businessId,
    required this.category,
    this.note,
    required this.amount,
    required this.dateTime,
    required this.recordedById,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
  });

  // ===================== copyWith =====================
  ExpenseModel copyWith({
    String? id,
    String? businessId,
    String? category,
    String? note,
    double? amount,
    DateTime? dateTime,
    String? recordedById,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      category: category ?? this.category,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      recordedById: recordedById ?? this.recordedById,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'category': category,
      'note': note,
      'amount': amount,
      'dateTime': Timestamp.fromDate(dateTime),
      'recordedById': recordedById,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      category: map['category'] ?? 'Other',
      note: map['note'],
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      recordedById: map['recordedById'] ?? '',
      isSynced: true,
      lastSyncAttempt: null,
      isDeleted: false,
    );
  }

  // ===================== LOCAL DB (SQLite) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'businessId': businessId,
      'category': category,
      'note': note,
      'amount': amount,
      'dateTime': dateTime.toIso8601String(),
      'recordedById': recordedById,
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory ExpenseModel.fromJsonDb(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      businessId: json['businessId'] ?? '',
      category: json['category'] ?? 'Other',
      note: json['note'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dateTime: DateTime.parse(json['dateTime']),
      recordedById: json['recordedById'] ?? '',
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
    );
  }
}
