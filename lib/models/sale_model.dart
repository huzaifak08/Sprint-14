import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Meter and Gazz products are sold by length.
bool isLinearUnit(String unitType) => unitType == 'Meter' || unitType == 'Gazz';

/// One product line inside a sale, with the prices it was sold at.
///
/// Costs are a snapshot taken when the sale was recorded, so later price
/// changes (or deleting the product) never rewrite an old sale's profit.
class SaleItem {
  final String productId;
  final String title;
  final String unitType;

  /// Pieces sold.
  final double quantity;

  /// Length per piece for Meter/Gazz products, 1 for everything else.
  final double measurement;

  /// Cost (retail) price per unit at the time of sale.
  final double unitCost;

  /// List (MSRP) price per unit at the time of sale.
  final double unitMsrp;

  /// Whether this product's stock was counted when the sale was recorded
  /// ('Matching' products are unlimited and are not counted).
  final bool tracksStock;

  const SaleItem({
    required this.productId,
    required this.title,
    required this.unitType,
    required this.quantity,
    required this.measurement,
    required this.unitCost,
    required this.unitMsrp,
    required this.tracksStock,
  });

  bool get isLinear => isLinearUnit(unitType);

  /// Stock units this line consumes: pieces, or total length for Meter/Gazz.
  double get effectiveQuantity => isLinear ? quantity * measurement : quantity;

  double get totalCost => unitCost * effectiveQuantity;
  double get totalMsrp => unitMsrp * effectiveQuantity;

  SaleItem copyWith({double? quantity, double? measurement}) {
    return SaleItem(
      productId: productId,
      title: title,
      unitType: unitType,
      quantity: quantity ?? this.quantity,
      measurement: measurement ?? this.measurement,
      unitCost: unitCost,
      unitMsrp: unitMsrp,
      tracksStock: tracksStock,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'title': title,
    'unitType': unitType,
    'quantity': quantity,
    'measurement': measurement,
    'unitCost': unitCost,
    'unitMsrp': unitMsrp,
    'tracksStock': tracksStock,
  };

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      unitType: map['unitType']?.toString() ?? 'Piece',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      measurement: (map['measurement'] as num?)?.toDouble() ?? 1.0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      unitMsrp: (map['unitMsrp'] as num?)?.toDouble() ?? 0.0,
      tracksStock: map['tracksStock'] == true,
    );
  }
}

class SaleModel {
  final String id;
  final String businessId;
  final List<String> productIds;
  final List<String> productTitles;
  final double soldAtPrice;
  final double profit;

  /// Total pieces. Kept for older app versions and sales recorded before
  /// [items] existed; new code should read [items].
  final double quantity;

  /// Measurement of the first Meter/Gazz line (legacy, see [quantity]).
  final double measurement;
  final DateTime dateTime;

  /// Per-product lines. Empty for sales recorded before items existed.
  final List<SaleItem> items;

  /// UID of whoever recorded the sale (kept when it is edited).
  /// Empty for sales recorded before this was tracked.
  final String recordedById;

  /// True when this sale adjusts product stock. Sales recorded before stock
  /// tracking existed stay false, so editing or deleting them never moves
  /// stock that was counted by hand.
  final bool stockTracked;

  /// Last local edit time, used to keep the newest edit when two devices
  /// change the same sale.
  final DateTime? updatedAt;

  /// Local only: the stock use the cloud currently reflects for this sale
  /// (productId -> units). Used to work out stock changes still waiting to
  /// be uploaded.
  final Map<String, double> syncedStock;

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
    required this.measurement,
    required this.dateTime,
    this.items = const [],
    this.recordedById = '',
    this.stockTracked = false,
    this.updatedAt,
    this.syncedStock = const {},
    required this.isSynced,
    this.lastSyncAttempt,
    required this.isDeleted,
  });

  /// Stock this sale consumes (productId -> units). Empty when the sale does
  /// not track stock or is deleted.
  Map<String, double> get stockEffects {
    if (!stockTracked || isDeleted) return const {};
    final effects = <String, double>{};
    for (final item in items) {
      if (!item.tracksStock || item.effectiveQuantity == 0) continue;
      effects[item.productId] =
          (effects[item.productId] ?? 0) + item.effectiveQuantity;
    }
    return effects;
  }

  /// Short quantity text for lists, e.g. "3 pcs", "2 × 2.5 Meter", "3 items".
  String get quantityLabel {
    if (items.isEmpty) return _fmt(quantity);
    if (items.length > 1) return '${items.length} items';
    final item = items.first;
    if (item.isLinear) {
      final length = '${_fmt(item.measurement)} ${item.unitType}';
      return item.quantity == 1 ? length : '${_fmt(item.quantity)} × $length';
    }
    return '${_fmt(item.quantity)} pcs';
  }

  static String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  SaleModel copyWith({
    String? id,
    String? businessId,
    List<String>? productIds,
    List<String>? productTitles,
    double? soldAtPrice,
    double? profit,
    double? quantity,
    double? measurement,
    DateTime? dateTime,
    List<SaleItem>? items,
    String? recordedById,
    bool? stockTracked,
    DateTime? updatedAt,
    Map<String, double>? syncedStock,
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
      measurement: measurement ?? this.measurement,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      recordedById: recordedById ?? this.recordedById,
      stockTracked: stockTracked ?? this.stockTracked,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedStock: syncedStock ?? this.syncedStock,
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
      'measurement': measurement,
      'dateTime': Timestamp.fromDate(dateTime),
      'items': items.map((i) => i.toMap()).toList(),
      'recordedById': recordedById,
      'stockTracked': stockTracked,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      productIds: map['productIds'] is List
          ? List<String>.from(map['productIds'])
          : [map['productId']?.toString() ?? ''],
      productTitles: map['productTitles'] is List
          ? List<String>.from(map['productTitles'])
          : [map['productTitle']?.toString() ?? ''],
      soldAtPrice: (map['soldAtPrice'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      measurement: (map['measurement'] as num?)?.toDouble() ?? 1.0,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      items: map['items'] is List
          ? (map['items'] as List)
                .whereType<Map>()
                .map((m) => SaleItem.fromMap(Map<String, dynamic>.from(m)))
                .toList()
          : const [],
      recordedById: map['recordedById']?.toString() ?? '',
      stockTracked: map['stockTracked'] == true,
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
      // JSON so titles containing commas survive the round trip.
      'productIds': jsonEncode(productIds),
      'productTitles': jsonEncode(productTitles),
      'soldAtPrice': soldAtPrice,
      'profit': profit,
      'quantity': quantity,
      'measurement': measurement,
      'dateTime': dateTime.toIso8601String(),
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
      'recordedById': recordedById,
      'stockTracked': stockTracked ? 1 : 0,
      'updatedAt': updatedAt?.toIso8601String(),
      'syncedStock': jsonEncode(syncedStock),
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory SaleModel.fromJsonDb(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'],
      businessId: json['businessId'] ?? '',
      productIds: _parseDbList(json['productIds'] ?? json['productId']),
      productTitles: _parseDbList(
        json['productTitles'] ?? json['productTitle'],
      ),
      soldAtPrice: (json['soldAtPrice'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      measurement: (json['measurement'] as num?)?.toDouble() ?? 1.0,
      dateTime: DateTime.parse(json['dateTime']),
      items: _parseItems(json['items']),
      recordedById: json['recordedById']?.toString() ?? '',
      stockTracked: (json['stockTracked'] ?? 0) == 1,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      syncedStock: _parseStockMap(json['syncedStock']),
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
    );
  }

  /// Reads a list column: JSON for new rows, comma-separated for old rows.
  static List<String> _parseDbList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    final str = value.toString();
    if (str.isEmpty) return [];
    if (str.startsWith('[')) {
      try {
        return List<String>.from(jsonDecode(str) as List);
      } catch (_) {
        // Fall through to the legacy format.
      }
    }
    return str.split(',');
  }

  static List<SaleItem> _parseItems(dynamic value) {
    if (value == null || value.toString().isEmpty) return const [];
    try {
      return (jsonDecode(value.toString()) as List)
          .whereType<Map>()
          .map((m) => SaleItem.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Map<String, double> _parseStockMap(dynamic value) {
    if (value == null || value.toString().isEmpty) return const {};
    try {
      final decoded = jsonDecode(value.toString()) as Map;
      return {
        for (final e in decoded.entries)
          e.key.toString(): (e.value as num).toDouble(),
      };
    } catch (_) {
      return const {};
    }
  }
}
