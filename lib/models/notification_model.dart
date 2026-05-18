import 'dart:convert';

class NotificationModel {
  final String id;
  final String userId;
  final String? businessId;
  final String title;
  final String body;
  final String actionType;
  final Map<String, dynamic> payload;

  final DateTime createdAt;
  final DateTime? readAt;

  final bool isRead;
  final bool isSynced;
  final bool isDeleted;
  final DateTime? lastSyncAttempt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.title,
    required this.body,
    this.actionType = 'none',
    this.payload = const {},
    required this.createdAt,
    this.readAt,
    this.isRead = false,
    this.isSynced = false,
    this.isDeleted = false,
    this.lastSyncAttempt,
  });

  // ===================== copyWith =====================
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? title,
    String? body,
    String? actionType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? readAt,
    bool? isRead,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastSyncAttempt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      body: body ?? this.body,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE DEVIATIONS =====================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'businessId': businessId,
      'title': title,
      'body': body,
      'actionType': actionType,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      businessId: map['businessId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      actionType: map['actionType'] ?? 'none',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      isRead: map['isRead'] ?? false,
      isSynced: true,
      isDeleted: false,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL SQLITE ENCODING =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'id': id,
      'userId': userId,
      'businessId': businessId,
      'title': title,
      'body': body,
      'actionType': actionType,
      'payload': json.encode(
        payload,
      ), // Flat string serialization rule for SQLite
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory NotificationModel.fromJsonDb(Map<String, dynamic> jsonMap) {
    return NotificationModel(
      id: jsonMap['id'] ?? '',
      userId: jsonMap['userId'] ?? '',
      businessId: jsonMap['businessId'],
      title: jsonMap['title'] ?? '',
      body: jsonMap['body'] ?? '',
      actionType: jsonMap['actionType'] ?? 'none',
      payload: jsonMap['payload'] != null
          ? Map<String, dynamic>.from(json.decode(jsonMap['payload']))
          : {},
      createdAt: DateTime.parse(jsonMap['createdAt']),
      readAt: jsonMap['readAt'] != null
          ? DateTime.parse(jsonMap['readAt'])
          : null,
      isRead: (jsonMap['isRead'] ?? 0) == 1,
      isSynced: (jsonMap['isSynced'] ?? 0) == 1,
      isDeleted: (jsonMap['isDeleted'] ?? 0) == 1,
      lastSyncAttempt: jsonMap['lastSyncAttempt'] != null
          ? DateTime.parse(jsonMap['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== STRINGS & EQUALITY MAPS =====================
  String toJson() => json.encode(toJsonDb());
  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromJsonDb(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.businessId == businessId &&
        other.title == title &&
        other.body == body &&
        other.actionType == actionType &&
        other.createdAt == createdAt &&
        other.readAt == readAt &&
        other.isRead == isRead &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        businessId.hashCode ^
        title.hashCode ^
        body.hashCode ^
        actionType.hashCode ^
        createdAt.hashCode ^
        readAt.hashCode ^
        isRead.hashCode ^
        isSynced.hashCode ^
        isDeleted.hashCode;
  }
}
