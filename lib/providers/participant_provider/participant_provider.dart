import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sprint_14/cache/tables/participant_table.dart';
import 'package:sprint_14/models/participant_model.dart';
import 'package:sprint_14/providers/auth_provider/auth_provider.dart';
import 'package:sprint_14/services/participant_service.dart';
import 'dart:developer' as dev;

part 'participant_provider.g.dart';

// 🔥 Added the parameter to the build method to make it a Family Provider
@Riverpod(keepAlive: true)
class ParticipantNotifier extends _$ParticipantNotifier {
  final ParticipantService _participantService = ParticipantService();
  StreamSubscription<List<ParticipantModel>>? _streamSubscription;

  @override
  FutureOr<List<ParticipantModel>> build(String businessId) async {
    // Automatically tear down live streams when the UI completely stops watching this specific businessId scope
    ref.onDispose(() => _streamSubscription?.cancel());

    // Initialize Cache-First Data Engine for the passed parameter
    return await _initParticipants(businessId);
  }

  /// --- CACHE-FIRST INITIALIZER ---
  Future<List<ParticipantModel>> _initParticipants(String businessId) async {
    final localList = await ParticipantTable.getBusinessParticipants(
      businessId: businessId,
    );

    if (localList.isNotEmpty) {
      dev.log(
        "Participants Cache Hit for $businessId. Streaming cloud in background.",
        name: "ParticipantProvider",
      );
      _startCloudStreaming(businessId);
      return localList;
    }

    dev.log(
      "Participants Cache Empty for $businessId. Bootstrapping data from Cloud.",
      name: "ParticipantProvider",
    );
    _startCloudStreaming(businessId);

    return [];
  }

  /// --- REAL-TIME CLOUD STREAM PIPELINE ---
  void _startCloudStreaming(String businessId) {
    _streamSubscription?.cancel();

    _streamSubscription = _participantService
        .streamBusinessParticipants(businessId)
        .listen(
          (cloudList) async {
            await ParticipantTable.saveAllFetchedParticipants(cloudList);
            state = AsyncData(cloudList);
          },
          onError: (error) {
            dev.log(
              "Cloud Participant Stream broken for $businessId: $error",
              name: "ParticipantProvider",
            );
          },
        );
  }

  /// --- MUTATION: INVITE TEAM MEMBER ---
  Future<void> inviteUser({
    required String businessId,
    required String email,
    required String role,
  }) async {
    await _participantService.inviteParticipantByEmail(
      businessId: businessId,
      email: email,
      role: role,
    );
  }

  /// --- MUTATION: TOGGLE ACCESS STATUS (LOCK / SUSPEND) ---
  Future<void> toggleStaffAccess({
    required String businessId,
    required String userId,
    required bool isActive,
  }) async {
    final currentList = state.value ?? [];
    final targetIndex = currentList.indexWhere((p) => p.userId == userId);
    if (targetIndex == -1) return;

    final originalParticipant = currentList[targetIndex];
    final modifiedParticipant = originalParticipant.copyWith(
      isActive: isActive,
      isSynced: false,
      lastSyncAttempt: DateTime.now(),
    );

    // 1. Optimistic Cache Update
    final updatedList = [...currentList];
    updatedList[targetIndex] = modifiedParticipant;
    state = AsyncData(updatedList);
    await ParticipantTable.saveParticipant(modifiedParticipant);

    try {
      // 2. Dispatch payload to Cloud
      await _participantService.toggleParticipantStatus(
        businessId: businessId,
        userId: userId,
        isActive: isActive,
      );

      final cleanParticipant = modifiedParticipant.copyWith(isSynced: true);
      await ParticipantTable.saveParticipant(cleanParticipant);
    } catch (e) {
      dev.log("Failed updating status online, cached offline: $e");
    }
  }

  /// --- MUTATION: CHANGE PRIVILEGES / ROLES ---
  Future<void> updateStaffRole({
    required String businessId,
    required String userId,
    required String newRole,
  }) async {
    final currentList = state.value ?? [];
    final targetIndex = currentList.indexWhere((p) => p.userId == userId);
    if (targetIndex == -1) return;

    final originalParticipant = currentList[targetIndex];
    final modifiedParticipant = originalParticipant.copyWith(
      role: newRole,
      isSynced: false,
      lastSyncAttempt: DateTime.now(),
    );

    // 1. Optimistic Update
    final updatedList = [...currentList];
    updatedList[targetIndex] = modifiedParticipant;
    state = AsyncData(updatedList);
    await ParticipantTable.saveParticipant(modifiedParticipant);

    try {
      // 2. Sync to Cloud
      await _participantService.changeParticipantRole(
        businessId: businessId,
        userId: userId,
        newRole: newRole,
      );

      final cleanParticipant = modifiedParticipant.copyWith(isSynced: true);
      await ParticipantTable.saveParticipant(cleanParticipant);
    } catch (e) {
      dev.log("Failed updating role online, cached offline: $e");
    }
  }

  /// --- MUTATION: REMOVE PARTICIPANT (OFFBOARD) ---
  Future<void> removeStaff({
    required String businessId,
    required String userId,
  }) async {
    final currentList = state.value ?? [];
    final targetIndex = currentList.indexWhere((p) => p.userId == userId);
    if (targetIndex == -1) return;

    final targetParticipant = currentList[targetIndex];

    // 1. Optimistic Delete from View
    final updatedList = [...currentList]..removeAt(targetIndex);
    state = AsyncData(updatedList);

    // Flag local DB as soft-deleted for async reconciliation
    final deletedRecord = targetParticipant.copyWith(
      isDeleted: true,
      isSynced: false,
    );
    await ParticipantTable.saveParticipant(deletedRecord);

    try {
      // 2. Run Firestore array extraction workflow
      await _participantService.removeParticipant(
        businessId: businessId,
        userId: userId,
      );

      // 3. Purge data completely from device on success
      await ParticipantTable.hardDeleteParticipant(targetParticipant.id);
    } catch (e) {
      dev.log("Offboarding failed network pass. Flagged for async retry: $e");
    }
  }

  /// --- BACKSTAGE CORE ENGINE: SYNC ALL PENDING MODIFICATIONS ---
  Future<void> syncPendingParticipants() async {
    dev.log(
      "Running background synchronization for participants ledger...",
      name: "ParticipantProvider",
    );

    final unsyncedList = await ParticipantTable.getUnsyncedParticipants();
    if (unsyncedList.isEmpty) return;

    for (var participant in unsyncedList) {
      try {
        if (participant.isDeleted) {
          await _participantService.removeParticipant(
            businessId: participant.businessId,
            userId: participant.userId,
          );
          await ParticipantTable.hardDeleteParticipant(participant.id);
        } else {
          await _participantService.toggleParticipantStatus(
            businessId: participant.businessId,
            userId: participant.userId,
            isActive: participant.isActive,
          );
          await _participantService.changeParticipantRole(
            businessId: participant.businessId,
            userId: participant.userId,
            newRole: participant.role,
          );

          await ParticipantTable.saveParticipant(
            participant.copyWith(isSynced: true),
          );
        }
      } catch (e) {
        dev.log(
          "Sync sequence failed for transaction ID [${participant.id}]: $e",
        );
        await ParticipantTable.saveParticipant(
          participant.copyWith(lastSyncAttempt: DateTime.now()),
        );
      }
    }
  }
}

@riverpod
FutureOr<ParticipantModel?> currentParticipantRole(
  Ref ref,
  String businessId,
) async {
  // 1. Get the current logged-in user's UID
  final user = ref.watch(authControllerProvider).value;
  if (user == null || businessId.isEmpty) return null;

  // 2. Query your SQLite cache instantly using the composite fields
  return await ParticipantTable.getSpecificParticipant(
    businessId: businessId,
    userId: user.uid,
  );
}
