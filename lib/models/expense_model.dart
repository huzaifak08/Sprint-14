import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String businessId;
  final String category; // e.g., "Tea", "Guests", "Utilities", "Other"
  final String? note; // Optional description
  final double amount;
  final DateTime dateTime;
  final String recordedById; // Tracking who added the expense (for roles)

  /// Last local edit time, used to keep the newest edit when two devices
  /// change the same expense.
  final DateTime? updatedAt;

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
    this.updatedAt,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
  });

  // ===================== copyWith =====================
  /// Pass [clearNote] to remove the note (a null [note] keeps the old one).
  ExpenseModel copyWith({
    String? id,
    String? businessId,
    String? category,
    String? note,
    bool clearNote = false,
    double? amount,
    DateTime? dateTime,
    String? recordedById,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      category: category ?? this.category,
      note: clearNote ? null : (note ?? this.note),
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      recordedById: recordedById ?? this.recordedById,
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
      'businessId': businessId,
      'category': category,
      'note': note,
      'amount': amount,
      'dateTime': Timestamp.fromDate(dateTime),
      'recordedById': recordedById,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
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
      'updatedAt': updatedAt?.toIso8601String(),
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
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
    );
  }
}
