// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sprint14/models/project_model.dart';
// import 'package:sprint14/providers/projects_provider/projects_provider.dart';

// class AppDetailState {
//   final int currentStep;
//   final int currentTestingDay;
//   final bool showPassword;
//   final bool showKeystorePass;
//   final bool stepsLocked;
//   AppDetailState({
//     required this.currentStep,
//     required this.currentTestingDay,
//     required this.showPassword,
//     required this.showKeystorePass,
//     required this.stepsLocked,
//   });

//   AppDetailState copyWith({
//     int? currentStep,
//     int? currentTestingDay,
//     bool? showPassword,
//     bool? showKeystorePass,
//     bool? stepsLocked,
//   }) {
//     return AppDetailState(
//       currentStep: currentStep ?? this.currentStep,
//       currentTestingDay: currentTestingDay ?? this.currentTestingDay,
//       showPassword: showPassword ?? this.showPassword,
//       showKeystorePass: showKeystorePass ?? this.showKeystorePass,
//       stepsLocked: stepsLocked ?? this.stepsLocked,
//     );
//   }
// }

// class AppDetailNotifier extends StateNotifier<AppDetailState> {
//   AppDetailNotifier(ProjectModel project)
//     : super(
//         AppDetailState(
//           currentStep: project.currentStep,
//           currentTestingDay: project.testingDayAtUpdate ?? 1,
//           showPassword: false,
//           showKeystorePass: false,
//           stepsLocked: false,
//         ),
//       );

//   void updateStep(int step) {
//     state = state.copyWith(currentStep: step);
//   }

//   void updateTestingDay(int day) {
//     state = state.copyWith(currentTestingDay: day);
//   }

//   void togglePassword() {
//     state = state.copyWith(showPassword: !state.showPassword);
//   }

//   void toggleKeystorePassword() {
//     state = state.copyWith(showKeystorePass: !state.showKeystorePass);
//   }

//   void toggleStepsLocked() {
//     state = state.copyWith(stepsLocked: !state.stepsLocked);
//   }
// }

// final appDetailNotifierProvider = StateNotifierProvider.autoDispose
//     .family<AppDetailNotifier, AppDetailState, String>((ref, projectId) {
//       final project = ref.watch(
//         projectNotifierProvider.select(
//           (list) => list.firstWhere((p) => p.id == projectId),
//         ),
//       );

//       return AppDetailNotifier(project);
//     });
