import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String businessId;
  final String title;
  final bool isTheya;

  /// 'Fixed' (counted pieces), 'Open' (fabric by length) or 'Matching'
  /// (unlimited, stock not counted).
  final String classification;

  final double retailPrice;
  final double msrpPrice;
  final String unitType;

  /// Stock as last known in the cloud. Never uploaded as a plain value:
  /// the cloud figure only changes through sales and stock adjustments
  /// applied in transactions, so devices can't overwrite each other's counts.
  /// For what is actually on the shelf, use `availableStock` in
  /// `helpers/stock_ledger.dart`, which also counts changes not uploaded yet.
  final double currentStock;

  /// Local only: a manual stock change (restock / correction) that hasn't
  /// reached the cloud yet, in units (+ adds stock, - removes it).
  final double pendingStockDelta;

  /// Local only: id of the pending adjustment, so a retried upload is never
  /// applied twice.
  final String? stockAdjustmentId;

  final DateTime? updatedAt;

  final bool isSynced;
  final DateTime? lastSyncAttempt;
  final bool isDeleted;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.isTheya,
    required this.classification,
    required this.retailPrice,
    required this.msrpPrice,
    required this.unitType,
    required this.currentStock,
    this.pendingStockDelta = 0,
    this.stockAdjustmentId,
    this.updatedAt,
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
  });

  // ===================== copyWith =====================
  ProductModel copyWith({
    String? id,
    String? businessId,
    String? title,
    bool? isTheya,
    String? classification,
    double? retailPrice,
    double? msrpPrice,
    String? unitType,
    double? currentStock,
    double? pendingStockDelta,
    String? stockAdjustmentId,
    bool clearStockAdjustment = false,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? lastSyncAttempt,
    bool? isDeleted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      isTheya: isTheya ?? this.isTheya,
      classification: classification ?? this.classification,
      retailPrice: retailPrice ?? this.retailPrice,
      msrpPrice: msrpPrice ?? this.msrpPrice,
      unitType: unitType ?? this.unitType,
      currentStock: currentStock ?? this.currentStock,
      pendingStockDelta: pendingStockDelta ?? this.pendingStockDelta,
      stockAdjustmentId: clearStockAdjustment
          ? null
          : (stockAdjustmentId ?? this.stockAdjustmentId),
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // ===================== FIRESTORE =====================
  /// Every field except stock, which ProductService writes in a transaction.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'title': title,
      'isTheya': isTheya,
      'classification': classification,
      'retailPrice': retailPrice,
      'msrpPrice': msrpPrice,
      'unitType': unitType,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      title: map['title'] ?? '',
      isTheya: map['isTheya'] ?? true,
      classification: map['classification'] ?? 'Fixed',
      retailPrice: (map['retailPrice'] as num?)?.toDouble() ?? 0.0,
      msrpPrice: (map['msrpPrice'] as num?)?.toDouble() ?? 0.0,
      unitType: map['unitType'] ?? 'Piece',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
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
      'title': title,
      'isTheya': isTheya ? 1 : 0,
      'classification': classification,
      'retailPrice': retailPrice,
      'msrpPrice': msrpPrice,
      'unitType': unitType,
      'currentStock': currentStock,
      'pendingStockDelta': pendingStockDelta,
      'stockAdjustmentId': stockAdjustmentId,
      'updatedAt': updatedAt?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory ProductModel.fromJsonDb(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      businessId: json['businessId'] ?? '',
      title: json['title'] ?? '',
      isTheya: (json['isTheya'] ?? 0) == 1,
      classification: json['classification'] ?? 'Fixed',
      retailPrice: (json['retailPrice'] as num?)?.toDouble() ?? 0.0,
      msrpPrice: (json['msrpPrice'] as num?)?.toDouble() ?? 0.0,
      unitType: json['unitType'] ?? 'Piece',
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      pendingStockDelta: (json['pendingStockDelta'] as num?)?.toDouble() ?? 0.0,
      stockAdjustmentId: json['stockAdjustmentId'] as String?,
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

  // ===================== HELPER LOGIC =====================

  /// 'Matching' products are unlimited; every other product's stock is
  /// counted and reduced by sales.
  bool get tracksStock => classification != 'Matching';

  /// Products that stay in the sale picker even when their counted stock
  /// reaches zero (fabric sold by length, and unlimited 'Matching' items).
  /// The sale form still warns when a sale exceeds the counted stock.
  bool get alwaysListed => classification == 'Matching' || classification == 'Open';

  /// Whether the product can be picked for a new sale, given its
  /// [available] stock (see `availableStock` in `helpers/stock_ledger.dart`).
  bool isAvailableForSale(double available) {
    if (isDeleted) return false;
    if (alwaysListed) return true;
    return available > 0;
  }

  /// Stock at or below this level is shown as running low.
  double get lowStockThreshold => unitType == 'Piece' ? 2 : 5;

  // Inside ProductModel class
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
