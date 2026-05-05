// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:sprint14/clients/notifications/notification_service.dart';
// import 'package:sprint14/helpers/constants.dart';
// import 'dart:developer' as dev;
// import 'package:sprint14/models/project_model.dart';
// import 'package:sprint14/providers/app_provider_container.dart';
// import 'package:sprint14/providers/reminders_provider/reminders_provider.dart';

// class ProjectService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextRecognizer _textRecognizer = TextRecognizer();

//   // 🔥 Added UID to scope all database calls to the specific user
//   final String uid;

//   ProjectService({required this.uid});

//   // 🔥 Helper getter for the new subcollection path
//   CollectionReference<Map<String, dynamic>> get _projectRef => _firestore
//       .collection(usersCollection)
//       .doc(uid)
//       .collection(projectsCollection);

//   Future<bool> saveProject({required ProjectModel project}) async {
//     try {
//       // 1. Notifications Logic
//       await NotificationService().cancelProjectNotifications(
//         id: project.id.hashCode,
//       );

//       if (project.currentStep >= 5 && project.currentStep <= 7) {
//         await _scheduleNextReminder(project, project.currentStep);
//         AppProviderContainer.instance.refresh(remindersNotifierProvider);
//       }

//       // 2. The "Upsert" Operation using the SUBCOLLECTION path
//       await _projectRef.doc(project.id).set({
//         'appName': project.appName,
//         'email': project.email,
//         'password': project.password,
//         'owner': project.owner,
//         'currentStep': project.currentStep,
//         'paymentStatus': project.paymentStatus,
//         'backupCodes': project.backupCodes,
//         'endDate': project.endDate,
//         'createdAt': project.createdAt,
//         'testingDayAtUpdate': project.testingDayAtUpdate,
//         'testingUpdateDate': project.testingUpdateDate,
//         'keystorePassword': project.keystorePassword,
//       }, SetOptions(merge: true));

//       return true;
//     } catch (err) {
//       dev.log("Subcollection Update Error: $err");
//       return false;
//     }
//   }

//   Future<List<ProjectModel>> getAllProjects() async {
//     try {
//       dev.log("Fetching projects from: users/$uid/projects");

//       // 🔥 Fetching from subcollection instead of root
//       final snapshot = await _projectRef.get();

//       final projects = snapshot.docs.map((doc) {
//         return ProjectModel.fromMap({...doc.data(), 'id': doc.id});
//       }).toList();

//       return projects;
//     } on FirebaseException catch (exception) {
//       dev.log(exception.message.toString());
//       throw Exception(exception.message.toString());
//     } catch (err) {
//       dev.log(err.toString());
//       throw Exception(err.toString());
//     }
//   }

//   Future<void> deleteProjectData({required String projectId}) async {
//     try {
//       // 🔥 Deleting from subcollection path
//       await _projectRef.doc(projectId).delete();
//       dev.log("Project Deleted Successfully from Subcollection");
//     } on FirebaseException catch (exp) {
//       dev.log(exp.message ?? "FIREBASE DELETE EXCEPTION");
//     } catch (err) {
//       dev.log(err.toString());
//     }
//   }

//   // --- Helper Methods (Logic remains the same) ---

//   Future<void> _scheduleNextReminder(
//     ProjectModel project,
//     int currentStep,
//   ) async {
//     int startDay = project.testingDayAtUpdate ?? 1;
//     DateTime actualDayOne = (project.testingUpdateDate ?? DateTime.now())
//         .subtract(Duration(days: startDay - 1));

//     await NotificationService().cancelProjectNotifications(
//       id: project.id.hashCode,
//     );

//     int? targetDay;
//     String milestone = "";

//     if (currentStep == 5) {
//       targetDay = 5;
//       milestone = "2nd Release";
//     } else if (currentStep == 6) {
//       targetDay = 11;
//       milestone = "3rd Release";
//     } else if (currentStep == 7) {
//       targetDay = 14;
//       milestone = "Production Apply";
//     }

//     if (targetDay != null) {
//       DateTime scheduledDate = actualDayOne.add(Duration(days: targetDay - 1));

//       if (scheduledDate.isAfter(DateTime.now())) {
//         String body = _getNudgeMessage(
//           targetDay,
//           milestone,
//           project.owner,
//           project.appName,
//         );

//         await NotificationService().scheduleNotification(
//           id: project.id.hashCode + targetDay,
//           title: "Sprint14: $milestone",
//           body: body,
//           scheduledDateTime: scheduledDate,
//         );
//       }
//     }
//   }

//   Future<List<String>> extractCodes(String imagePath) async {
//     final inputImage = InputImage.fromFilePath(imagePath);
//     final RecognizedText recognizedText = await _textRecognizer.processImage(
//       inputImage,
//     );

//     List<String> foundCodes = [];
//     final RegExp codeRegex = RegExp(r'\d{4}\s?\d{4}');

//     for (TextBlock block in recognizedText.blocks) {
//       for (TextLine line in block.lines) {
//         final Iterable<RegExpMatch> matches = codeRegex.allMatches(line.text);
//         for (var match in matches) {
//           String cleanCode = match[0]!.replaceAll(' ', '');
//           if (cleanCode.length == 8) foundCodes.add(cleanCode);
//         }
//       }
//     }

//     List<String> finalCodes = foundCodes.toSet().toList();
//     if (finalCodes.length > 10) finalCodes = finalCodes.sublist(0, 10);
//     return finalCodes;
//   }

//   String _getNudgeMessage(int day, String milestone, String owner, String app) {
//     if (day == 5 || day == 11)
//       return "Tomorrow: Schedule $milestone meeting with $owner for $app.";
//     if (day == 6 || day == 12 || day == 14)
//       return "Today: Deadline for $milestone of $app. Contact $owner.";
//     return "Overdue: You missed the $milestone for $app yesterday!";
//   }
// }
