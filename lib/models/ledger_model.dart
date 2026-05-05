import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerModel {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final bool isIncome; // true for Income, false for Expense
  final String? note;
  final String paymentMethod; // Cash, Bank, EasyPaisa, etc.

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final DateTime? lastSyncAttempt;
  final bool isDeleted;

  // 🕒 DateTimes
  final DateTime dateTime; // The actual time of the transaction

  LedgerModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.isIncome,
    this.note,
    required this.paymentMethod,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
    required this.dateTime,
  });

  // ===================== copyWith =====================
  LedgerModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    bool? isIncome,
    String? note,
    String? paymentMethod,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
    DateTime? dateTime,
  }) {
    return LedgerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isDeleted: isDeleted ?? this.isDeleted,
      dateTime: dateTime ?? this.dateTime,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'isIncome': isIncome,
      'note': note,
      'paymentMethod': paymentMethod,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }

  factory LedgerModel.fromMap(Map<String, dynamic> map) {
    return LedgerModel(
      id: map['id'],
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'General',
      isIncome: map['isIncome'] ?? false,
      note: map['note'],
      paymentMethod: map['paymentMethod'] ?? 'Cash',

      // Sync fields are strictly managed by Local DB logic
      isSynced: true,
      lastSyncAttempt: null,
      isDeleted: false,

      dateTime: (map['dateTime'] as Timestamp).toDate(),
    );
  }

  // ===================== LOCAL DB (SQLite) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'isIncome': isIncome ? 1 : 0,
      'note': note,
      'paymentMethod': paymentMethod,
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory LedgerModel.fromJsonDb(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'],
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'General',
      isIncome: (json['isIncome'] ?? 0) == 1,
      note: json['note'],
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
      dateTime: DateTime.parse(json['dateTime']),
    );
  }

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedgerModel &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.category == category &&
        other.isIncome == isIncome &&
        other.note == note &&
        other.paymentMethod == paymentMethod &&
        other.isSynced == isSynced &&
        other.lastSyncAttempt == lastSyncAttempt &&
        other.isDeleted == isDeleted &&
        other.dateTime == dateTime;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      amount.hashCode ^
      category.hashCode ^
      isIncome.hashCode ^
      note.hashCode ^
      paymentMethod.hashCode ^
      isSynced.hashCode ^
      lastSyncAttempt.hashCode ^
      isDeleted.hashCode ^
      dateTime.hashCode;
}
