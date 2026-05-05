// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:sprint14/cache/tables/project_table.dart';
// import 'package:sprint14/models/project_model.dart';
// import 'package:sprint14/services/project_service.dart';
// import 'package:sprint14/providers/user_provider/user_provider.dart'; // Import your user provider
// import 'dart:developer' as dev;

// part 'projects_provider.g.dart';

// @Riverpod(keepAlive: true)
// class ProjectNotifier extends _$ProjectNotifier {
//   // 🔥 Helper to get the UID safely from the UserNotifier state
//   String? get _currentUid => ref.read(userNotifierProvider).value?.uid;

//   @override
//   List<ProjectModel> build() {
//     // 1. Watch the user. If the user logs out or changes, this provider rebuilds.
//     final userState = ref.watch(userNotifierProvider);

//     userState.whenData((user) {
//       if (user != null) {
//         _loadProjects(user.uid);
//       } else {
//         // If user is null (logged out), clear the project list
//         state = [];
//       }
//     });

//     return [];
//   }

//   Future<void> _loadProjects(String uid) async {
//     // 2. Load from cache first
//     final cacheProjects = await ProjectTable.getAllProjectsFromCache();
//     if (cacheProjects.isNotEmpty) {
//       state = cacheProjects;
//     }

//     // 3. Fetch from Firestore using the specific UID subcollection
//     try {
//       final service = ProjectService(uid: uid);
//       final cloudProjects = await service.getAllProjects();

//       final Map<String, ProjectModel> cacheMap = {
//         for (final p in cacheProjects) p.id!: p,
//       };

//       final List<ProjectModel> mergedProjects = [];

//       for (final cloud in cloudProjects) {
//         final local = cacheMap[cloud.id];
//         if (local != null && !local.isSynced) {
//           mergedProjects.add(local); // Protect unsynced local edits
//         } else {
//           mergedProjects.add(cloud.copyWith(isSynced: true));
//         }
//       }

//       await ProjectTable.saveAllFetchedProjects(mergedProjects);
//       state = mergedProjects;

//       // Auto-sync any pending items found during load
//       syncPendingProjects();
//     } catch (e) {
//       dev.log("ProjectNotifier Error: $e");
//     }
//   }

//   // --- CRUD Operations ---

//   Future<void> addNewProject(ProjectModel project) async {
//     final offlineProject = project.copyWith(isSynced: false);
//     await ProjectTable.saveSingleProject(offlineProject);
//     state = [...state, offlineProject];
//     syncPendingProjects();
//   }

//   Future<void> updateProject(ProjectModel updatedProject) async {
//     final localUpdated = updatedProject.copyWith(
//       isSynced: false,
//       lastSyncAttempt: null,
//     );
//     state = [
//       for (final p in state)
//         if (p.id == localUpdated.id) localUpdated else p,
//     ];
//     await ProjectTable.saveSingleProject(localUpdated);
//     syncPendingProjects();
//   }

//   Future<void> deleteProject(String projectId) async {
//     final project = state.firstWhere((p) => p.id == projectId);
//     final deletedProject = project.copyWith(isDeleted: true, isSynced: false);

//     state = state.where((p) => p.id != projectId).toList();
//     await ProjectTable.saveSingleProject(deletedProject);
//     await syncPendingProjects();
//   }

//   // --- Sync Logic ---

//   Future<void> syncPendingProjects() async {
//     final uid = _currentUid;
//     if (uid == null) return;

//     final connectivity = await Connectivity().checkConnectivity();
//     final isOnline = connectivity.any(
//       (result) =>
//           result == ConnectivityResult.mobile ||
//           result == ConnectivityResult.wifi,
//     );

//     if (!isOnline) return;

//     final service = ProjectService(uid: uid);
//     final unsyncedProjects = await ProjectTable.getUnsyncedProjects();

//     for (final project in unsyncedProjects) {
//       try {
//         if (project.isDeleted) {
//           await service.deleteProjectData(projectId: project.id!);
//           await ProjectTable.deleteSingleProject(project.id!);
//         } else {
//           final success = await service.saveProject(project: project);
//           if (success) {
//             final synced = project.copyWith(
//               isSynced: true,
//               lastSyncAttempt: DateTime.now(),
//             );
//             await ProjectTable.saveSingleProject(synced);
//             state = [
//               for (final p in state)
//                 if (p.id == synced.id) synced else p,
//             ];
//           }
//         }
//       } catch (e) {
//         dev.log("Sync failed for project ${project.id}: $e");
//       }
//     }
//   }
// }
