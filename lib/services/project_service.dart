import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_munshi/cache/sync/sync_utils.dart';
import 'package:digital_munshi/helpers/constants.dart';
import 'package:digital_munshi/models/project_model.dart';

/// Firestore access for `users/{uid}/projects`.
class ProjectService {
  final String uid;

  ProjectService({required this.uid});

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(uid)
          .collection(projectsCollection);

  /// --- 1. LIVE PROJECT LIST (server-confirmed only) ---
  /// Snapshots served from Firestore's own offline cache are skipped: they
  /// can be partial, and a missing project would then look deleted to the
  /// sync merge. Metadata changes are included so the server confirmation
  /// of an unchanged cached result still arrives.
  Stream<List<ProjectModel>> watchProjects() {
    return _projectsRef
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProjectModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  /// --- 2. SAVE OR UPDATE PROJECT ---
  /// Writes the project unless the cloud copy was edited more recently, in
  /// which case nothing is written and the newer cloud copy is returned.
  /// Returns null when the local copy was saved. Merges, so fields this app
  /// doesn't know about are kept. Throws on failure.
  Future<ProjectModel?> saveProject(ProjectModel project) {
    final doc = _projectsRef.doc(project.id);
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final data = snap.data();
      if (data != null) {
        final cloud = ProjectModel.fromMap({...data, 'id': snap.id});
        if (isNewerEdit(cloud.updatedAt, project.updatedAt)) return cloud;
      }
      tx.set(doc, project.toMap(), SetOptions(merge: true));
      return null;
    });
  }

  /// --- 3. DELETE PROJECT ---
  /// Throws on failure.
  Future<void> deleteProject(String projectId) async {
    try {
      await _projectsRef.doc(projectId).delete();
    } catch (e) {
      dev.log("Delete project $projectId failed: $e", name: "ProjectService");
      rethrow;
    }
  }
}
