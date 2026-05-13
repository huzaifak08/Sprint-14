import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as dev;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePic(String uid, File imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('profile_pic.jpg');

      // Upload with metadata
      await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));

      return await ref.getDownloadURL();
    } catch (e) {
      dev.log("Profile Pic Upload Error: $e");
      return null;
    }
  }

  Future<String?> uploadBusinessLogo(String businessId, File imageFile) async {
    try {
      dev.log("Uploading logo for business: $businessId");

      // Create reference: businesses/business_id/logo.jpg
      final ref = _storage
          .ref()
          .child('businesses')
          .child(businessId)
          .child('logo.jpg');

      // Upload file
      final uploadTask = await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      dev.log("Firebase Storage Error: $e");
      return null;
    }
  }

  Future<void> deleteBusinessLogo(String businessId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('businesses')
          .child(businessId)
          .child('logo.jpg');

      await storageRef.delete();
      dev.log("Storage logo deleted successfully", name: "BusinessService");
    } catch (e) {
      // If 404 error, the file didn't exist (which is fine during deletion)
      dev.log("Storage deletion skipped: $e", name: "BusinessService");
    }
  }
}
