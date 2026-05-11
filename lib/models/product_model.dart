class ProductModel {
  final String id;
  final String businessId;
  final String title;
  final bool isTheya;

  /// Determines if the product is 'Open' (Continuous) or 'Fixed' (Limited)
  final String classification;

  final double retailPrice;
  final double msrpPrice;
  final String unitType;

  /// New Field: Tracks remaining inventory
  final double currentStock;

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
    required this.currentStock, // Added
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
      'title': title,
      'isTheya': isTheya,
      'classification': classification,
      'retailPrice': retailPrice,
      'msrpPrice': msrpPrice,
      'unitType': unitType,
      'currentStock': currentStock,
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
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
      isDeleted: (json['isDeleted'] ?? 0) == 1,
    );
  }

  // ===================== HELPER LOGIC =====================

  // Inside ProductModel
  bool get isInfinite {
    // If it's 'Matching' or 'Open' (depending on how you want to label Atal),
    // we treat it as infinite stock.
    return classification == "Matching" || classification == "Open";
  }

  bool get isAvailableForSale {
    if (isDeleted) return false;
    if (isInfinite) return true; // Always show Atal/Matching
    return currentStock > 0; // Only hide fixed articles (suits) when empty
  }

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
