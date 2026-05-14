import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart';
import 'package:sprint_14/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      dev.log("Failed to sync user data to Firestore: $e");
      throw Exception("Failed to sync user data to Firestore: $e");
    }
  }

  /// 2. Fetch User Data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      dev.log("User data null found", name: "User Service");
      return null;
    } catch (e) {
      dev.log("Failed to fetch user data: $e", name: "User Service");
      throw Exception("Failed to fetch user data: $e");
    }
  }

  /// Updates the device token list for multi-device notification support
  Future<void> updateDeviceToken({
    required String uid,
    required String token,
    bool isAdding = true,
  }) async {
    try {
      final docRef = _firestore.collection(usersCollection).doc(uid);

      if (isAdding) {
        // 🔥 arrayUnion adds the token only if it does not already exist in the list
        await docRef.update({
          'deviceTokens': FieldValue.arrayUnion([token]),
        });
        dev.log("Device token added/verified for user: $uid");
      } else {
        // 🔥 arrayRemove removes the specific token (useful for logout)
        await docRef.update({
          'deviceTokens': FieldValue.arrayRemove([token]),
        });
        dev.log("Device token removed for user: $uid");
      }
    } catch (e) {
      dev.log("Failed to update device token: $e");
      throw Exception("Failed to update device token: $e");
    }
  }
}
