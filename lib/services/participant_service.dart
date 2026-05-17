import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sprint_14/helpers/constants.dart'; // Contains our central firestore refs
import 'package:sprint_14/models/participant_model.dart';

class ParticipantService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// --- 1. INVITE / ADD PARTICIPANT BY EMAIL ---
  /// Finds a user by their registered email address and adds them to the business
  Future<void> inviteParticipantByEmail({
    required String businessId,
    required String email,
    required String role,
  }) async {
    try {
      dev.log(
        "Searching for user with email: $email",
        name: "ParticipantService",
      );

      // A. Query users collection to find the matching UID
      final userQuery = await firestore
          .collection(usersCollection)
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception("No user found with this email address.");
      }

      final targetUid = userQuery.docs.first.id;

      // B. Check if they are already added to this business
      final compositeId = "${businessId}_$targetUid";
      final existingCheck = await firestore
          .collection(participantsCollection)
          .doc(compositeId)
          .get();

      if (existingCheck.exists) {
        throw Exception("This user is already a participant in this business.");
      }

      // C. Build the document model
      final newParticipant = ParticipantModel(
        id: compositeId,
        businessId: businessId,
        userId: targetUid,
        role: role,
        isActive: true,
        assignedAt: DateTime.now(),
        isSynced: true,
        isDeleted: false,
      );

      // D. Atomically run batch write to update participant record AND business roster list
      final batch = firestore.batch();

      final participantRef = firestore
          .collection(participantsCollection)
          .doc(compositeId);
      final businessRef = firestore
          .collection(businessesCollection)
          .doc(businessId);

      batch.set(participantRef, newParticipant.toMap());
      batch.update(businessRef, {
        'participantIds': FieldValue.arrayUnion([targetUid]),
      });

      await batch.commit();
      dev.log(
        "Participant successfully added inside batch workflow.",
        name: "ParticipantService",
      );
    } catch (e) {
      dev.log("Error in inviteParticipantByEmail: $e", error: e);
      rethrow;
    }
  }

  /// --- 2. UPDATE PARTICIPANT ROLE ---
  /// Changes user capability group (e.g., promotional switch from 'salesman' to 'admin')
  Future<void> changeParticipantRole({
    required String businessId,
    required String userId,
    required String newRole,
  }) async {
    try {
      final compositeId = "${businessId}_$userId";
      await firestore
          .collection(participantsCollection)
          .doc(compositeId)
          .update({'role': newRole});

      dev.log(
        "Updated role to $newRole for user $userId",
        name: "ParticipantService",
      );
    } catch (e) {
      dev.log("Error changing participant role: $e", error: e);
      throw Exception("Failed to change user access privileges: $e");
    }
  }

  /// --- 3. TOGGLE ACTIVE STATUS (SUSPEND STAFF) ---
  /// Instantly locks a worker out of the shop data collection without deleting logs
  Future<void> toggleParticipantStatus({
    required String businessId,
    required String userId,
    required bool isActive,
  }) async {
    try {
      final compositeId = "${businessId}_$userId";
      await firestore
          .collection(participantsCollection)
          .doc(compositeId)
          .update({'isActive': isActive});

      dev.log(
        "Toggled active status to: $isActive for user $userId",
        name: "ParticipantService",
      );
    } catch (e) {
      dev.log("Error toggling status: $e", error: e);
      throw Exception("Failed to modify active workplace lock state.");
    }
  }

  /// --- 4. REMOVE PARTICIPANT (OFFBOARD) ---
  /// Completely removes employee from the store access arrays
  Future<void> removeParticipant({
    required String businessId,
    required String userId,
  }) async {
    try {
      final compositeId = "${businessId}_$userId";

      final batch = firestore.batch();
      final participantRef = firestore
          .collection(participantsCollection)
          .doc(compositeId);
      final businessRef = firestore
          .collection(businessesCollection)
          .doc(businessId);

      // Remove access document and pull them from the flat lookup array
      batch.delete(participantRef);
      batch.update(businessRef, {
        'participantIds': FieldValue.arrayRemove([userId]),
      });

      await batch.commit();
      dev.log(
        "Successfully offboarded user $userId from business workspace.",
        name: "ParticipantService",
      );
    } catch (e) {
      dev.log("Error offboarding participant: $e", error: e);
      throw Exception(
        "Failed to completely remove participant from workspace.",
      );
    }
  }

  /// --- 5. STREAM ALL STAFF FOR A BUSINESS ---
  /// Real-time listener stream for the staff roster dashboard view
  Stream<List<ParticipantModel>> streamBusinessParticipants(String businessId) {
    return firestore
        .collection(participantsCollection)
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ParticipantModel.fromMap(doc.data()))
              .toList();
        });
  }

  /// --- 6. FETCH SINGLE PARTICIPATION RIGHTS ---
  /// Direct read call to verify a user's role permissions instantly
  Future<ParticipantModel?> fetchPermissions({
    required String businessId,
    required String userId,
  }) async {
    try {
      final compositeId = "${businessId}_$userId";
      final doc = await firestore
          .collection(participantsCollection)
          .doc(compositeId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ParticipantModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      dev.log("Failed fetching individual permission assignment: $e");
      return null;
    }
  }
}
