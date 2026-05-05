// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sprint14/components/project_card.dart';
// import 'package:sprint14/providers/projects_provider/projects_provider.dart';
// import 'package:sprint14/views/add_or_update_app_view.dart';

// class AppsView extends ConsumerWidget {
//   const AppsView({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final projects = ref.watch(projectNotifierProvider);

//     // 1. Handle Empty State
//     if (projects.isEmpty) {
//       return const _EmptyProjectsView();
//     }

//     // 2. Sort Logic (Done once per build, not per item)
//     final sortedProjects = List.from(projects)
//       ..sort((a, b) {
//         if (a.paymentStatus != b.paymentStatus) {
//           return a.paymentStatus == 'unpaid' ? -1 : 1;
//         }
//         return a.createdAt.compareTo(b.createdAt);
//       });

//     return Column(
//       children: [
//         // Progress Summary could go here
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             itemCount: sortedProjects.length,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 12),
//                 child: ProjectCard(project: sortedProjects[index]),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _EmptyProjectsView extends StatelessWidget {
//   const _EmptyProjectsView();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Icon / Illustration Container
//             Container(
//               padding: const EdgeInsets.all(30),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.primary.withOpacity(0.05),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.app_registration_rounded,
//                 size: 80,
//                 color: theme.colorScheme.primary.withOpacity(0.4),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Text Content
//             Text(
//               "No Projects Yet",
//               style: theme.textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "Your trackable apps will appear here once you add them. Start by creating your first project!",
//               textAlign: TextAlign.center,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 32),

//             // Call to Action Button
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AddOrUpdateAppView()),
//                 );
//               },
//               icon: const Icon(Icons.add_rounded),
//               label: const Text("Add First Project"),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
