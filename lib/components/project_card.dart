// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sprint_14/models/project_model.dart';

// class ProjectCard extends ConsumerWidget {
//   final ProjectModel project;
//   const ProjectCard({required this.project, super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final stepLabels = [
//       'Console Setup',
//       'Verification',
//       'Development',
//       '1st Release',
//       'Testing Start',
//       '2nd Release',
//       '3rd Release',
//       'Production App',
//       'Go Live',
//       'Delivery',
//     ];
//     final isCountdownPhase =
//         project.currentStep >= 5 && project.currentStep <= 8;

//     return GestureDetector(
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => AppDetailView(projectId: project.id ?? "No Id"),
//         ),
//       ),
//       child: Card(
//         color: ref.watch(themeNotifier).themeMode == ThemeMode.light
//             ? Colors.white
//             : Colors.black,
//         margin: const EdgeInsets.only(bottom: 12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         project.appName,
//                         style: Theme.of(context).textTheme.titleMedium
//                             ?.copyWith(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         '${project.owner} • ${project.email}',
//                         style: Theme.of(
//                           context,
//                         ).textTheme.bodySmall?.copyWith(color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                   if (!project.isSynced) ...{
//                     Icon(Icons.sync, color: Colors.grey),
//                   },
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: List.generate(
//                   10,
//                   (i) => Expanded(
//                     child: Container(
//                       height: 6,
//                       margin: const EdgeInsets.symmetric(horizontal: 2),
//                       decoration: BoxDecoration(
//                         color: i < project.currentStep
//                             ? const Color(0xFF4285F4)
//                             : Colors.grey[300],
//                         borderRadius: BorderRadius.circular(3),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Step ${project.currentStep}: ${stepLabels[project.currentStep - 1]}',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF4285F4),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Chip(
//                     label: Text(
//                       project.paymentStatus == "paid" ? "Paid" : "Unpaid",
//                       style: TextStyle(color: Theme.of(context).primaryColor),
//                     ),
//                     backgroundColor: project.paymentStatus == 'paid'
//                         ? Colors.green[100]
//                         : Colors.orange[300],
//                   ),
//                   if (isCountdownPhase)
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFF9800),
//                         shape: BoxShape.rectangle,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Text(
//                         'Day ${project.testingDayAtUpdate! + DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(project.testingUpdateDate!.year, project.testingUpdateDate!.month, project.testingUpdateDate!.day)).inDays} of 14',
//                         style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   Text(
//                     'Start: ${project.createdAt.toString().split(' ')[0].split('-').reversed.join('-')}',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
