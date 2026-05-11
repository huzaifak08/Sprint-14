import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String businessId;
  final List<String> productIds;
  final List<String> productTitles;
  final double soldAtPrice;
  final double profit;
  final double quantity;
  final DateTime dateTime;

  final bool isSynced;
  final DateTime? lastSyncAttempt;
  final bool isDeleted;

  SaleModel({
    required this.id,
    required this.businessId,
    required this.productIds,
    required this.productTitles,
    required this.soldAtPrice,
    required this.profit,
    required this.quantity,
    required this.dateTime,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
  });

  SaleModel copyWith({
    String? id,
    String? businessId,
    List<String>? productIds,
    List<String>? productTitles,
    double? soldAtPrice,
    double? profit,
    double? quantity,
    DateTime? dateTime,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
  }) {
    return SaleModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      productIds: productIds ?? this.productIds,
      productTitles: productTitles ?? this.productTitles,
      soldAtPrice: soldAtPrice ?? this.soldAtPrice,
      profit: profit ?? this.profit,
      quantity: quantity ?? this.quantity,
      dateTime: dateTime ?? this.dateTime,
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
      'productIds': productIds,
      'productTitles': productTitles,
      'soldAtPrice': soldAtPrice,
      'profit': profit,
      'quantity': quantity,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      // Defensive check for Firestore (handles legacy single string fields)
      productIds: map['productIds'] is List
          ? List<String>.from(map['productIds'])
          : [map['productId']?.toString() ?? ''],
      productTitles: map['productTitles'] is List
          ? List<String>.from(map['productTitles'])
          : [map['productTitle']?.toString() ?? ''],
      soldAtPrice: (map['soldAtPrice'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
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
      'productIds': productIds.join(','), // Store as CSV
      'productTitles': productTitles.join(','), // Store as CSV
      'soldAtPrice': soldAtPrice,
      'profit': profit,
      'quantity': quantity,
      'dateTime': dateTime.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory SaleModel.fromJsonDb(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'],
      businessId: json['businessId'] ?? '',
      // Defensive split: if it's already a list or empty, handle it
      productIds: _parseDbList(json['productIds'] ?? json['productId']),
      productTitles: _parseDbList(
        json['productTitles'] ?? json['productTitle'],
      ),
      soldAtPrice: (json['soldAtPrice'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      dateTime: DateTime.parse(json['dateTime']),
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
    );
  }

  static List<String> _parseDbList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    final str = value.toString();
    return str.isEmpty ? [] : str.split(',');
  }
}
