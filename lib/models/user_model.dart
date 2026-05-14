import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String password;
  final String? profilePic;
  final List<String> deviceTokens;
  final DateTime createdAt;

  // 🔐 Verification Flag
  final bool isEmailVerified;

  // 🔁 Sync fields (LOCAL ONLY)
  final bool isSynced;
  final DateTime? lastSyncAttempt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.password,
    this.profilePic,
    required this.deviceTokens,
    required this.createdAt,
    required this.isEmailVerified,
    required this.isSynced,
    this.lastSyncAttempt,
  });

  // ===================== copyWith =====================
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? password,
    String? profilePic,
    List<String>? deviceTokens,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isSynced,
    DateTime? lastSyncAttempt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePic: profilePic ?? this.profilePic,
      deviceTokens: deviceTokens ?? this.deviceTokens,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isSynced: isSynced ?? this.isSynced,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
    );
  }

  // ===================== FIRESTORE =====================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
      'profilePic': profilePic,
      'deviceTokens': deviceTokens,
      'isEmailVerified': isEmailVerified, // Save status to cloud
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      profilePic: map['profilePic'] as String?,
      // 🔥 The Fix: Safely convert dynamic list to String list
      deviceTokens: map['deviceTokens'] != null
          ? List<String>.from(map['deviceTokens'])
          : [],
      isEmailVerified: map['isEmailVerified'] ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isSynced: true,
      lastSyncAttempt: null,
    );
  }

  // ===================== LOCAL DB (CACHE) =====================
  Map<String, dynamic> toJsonDb() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
      'profilePic': profilePic,
      'deviceTokens': json.encode(deviceTokens),
      'isEmailVerified': isEmailVerified ? 1 : 0, // SQLite friendly
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
      'lastSyncAttempt': lastSyncAttempt?.toIso8601String(),
    };
  }

  factory UserModel.fromJsonDb(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      profilePic: json['profilePic'] as String?,
      deviceTokens: json['deviceTokens'] != null
          ? List<String>.from(jsonDecode(json['deviceTokens']))
          : [],
      isEmailVerified: (json['isEmailVerified'] ?? 0) == 1,
      createdAt: DateTime.parse(json['createdAt']),
      isSynced: (json['isSynced'] ?? 0) == 1,
      lastSyncAttempt: json['lastSyncAttempt'] != null
          ? DateTime.parse(json['lastSyncAttempt'])
          : null,
    );
  }

  // ===================== JSON HELPERS =====================
  String toJson() => json.encode(toJsonDb());

  factory UserModel.fromJson(String source) =>
      UserModel.fromJsonDb(json.decode(source));

  // ===================== Equality =====================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.password == password &&
        other.profilePic == profilePic &&
        other.deviceTokens == deviceTokens &&
        other.createdAt == createdAt &&
        other.isEmailVerified == isEmailVerified &&
        other.isSynced == isSynced &&
        other.lastSyncAttempt == lastSyncAttempt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        email.hashCode ^
        password.hashCode ^
        profilePic.hashCode ^
        deviceTokens.hashCode ^
        createdAt.hashCode ^
        isEmailVerified.hashCode ^
        isSynced.hashCode ^
        lastSyncAttempt.hashCode;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, isEmailVerified: $isEmailVerified, isSynced: $isSynced, profilePic: $profilePic)';
  }
}
