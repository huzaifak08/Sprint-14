// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sprint14/components/verify_codes_alert.dart';
// import 'package:sprint14/models/project_model.dart';
// import 'package:sprint14/providers/app_provider_container.dart';
// import 'package:sprint14/providers/projects_provider/projects_provider.dart';
// import 'package:sprint14/providers/theme_provider/theme_provider.dart';
// import 'package:sprint14/services/export_service.dart';
// import 'package:sprint14/services/routes_service.dart';
// import 'package:sprint14/views/add_or_update_app_view.dart';
// import 'package:sprint14/views/app_detail_view/app_detail_view_model.dart';

// class AppDetailView extends ConsumerStatefulWidget {
//   final String projectId;
//   const AppDetailView({super.key, required this.projectId});

//   @override
//   ConsumerState<AppDetailView> createState() => _AppDetailViewState();
// }

// class _AppDetailViewState extends ConsumerState<AppDetailView> {
//   final List<String> taskLabels = [
//     'Console Setup',
//     'Acc. Verification',
//     'App Development',
//     '1st Release',
//     'Testing Start',
//     '2nd Release',
//     '3rd Release',
//     'Production App',
//     'Go Live',
//     'Delivery',
//   ];

//   void _copyToClipboard(String text) {
//     Clipboard.setData(ClipboardData(text: text));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Copied: $text'),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // ... (Calibration Dialog remains the same functionality-wise)
//   void _showCalibrationDialog({
//     required ProjectModel project,
//     required int currentTestingDay,
//     required AppDetailNotifier detailNotifier,
//   }) {
//     int dayInput = currentTestingDay;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('Calibrate Testing'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Enter the current day shown in Play Console (1-14):'),
//             const SizedBox(height: 15),
//             TextField(
//               keyboardType: TextInputType.number,
//               autofocus: true,
//               onChanged: (v) => dayInput = int.tryParse(v) ?? 1,
//               decoration: InputDecoration(
//                 prefixIcon: const Icon(Icons.calendar_today),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (dayInput >= 1 && dayInput <= 14) {
//                 detailNotifier.updateStep(5);

//                 ref
//                     .read(projectNotifierProvider.notifier)
//                     .updateProject(
//                       project.copyWith(
//                         currentStep: 5,
//                         testingDayAtUpdate: dayInput,
//                         testingUpdateDate: DateTime.now(),
//                       ),
//                     );
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('Confirm'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final detailState = ref.watch(appDetailNotifierProvider(widget.projectId));
//     final detailNotifier = ref.read(
//       appDetailNotifierProvider(widget.projectId).notifier,
//     );
//     final project = ref.watch(
//       projectNotifierProvider.select(
//         (projects) =>
//             projects.where((proj) => proj.id == widget.projectId).firstOrNull,
//       ),
//     );

//     if (project == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         title: Text(
//           project.appName,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download_outlined),
//             onPressed: () async {
//               await ExportService().exportProjectPdf(project);
//             },
//           ),

//           IconButton(
//             icon: const Icon(Icons.edit_note),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (c) => AddOrUpdateAppView(oldProject: project),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_outline),
//             onPressed: () => _confirmDelete(
//               project: project,
//               detailNotifier: detailNotifier,
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             _buildProgressHeader(
//               currentStep: detailState.currentStep,
//               currentTestingDay: detailState.currentTestingDay,
//               project: project,
//               detailNotifier: detailNotifier,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSectionHeader(
//                     "Project Workflow",
//                     trailing: _buildLockSwitch(
//                       stepsLocked: detailState.stepsLocked,
//                       detailNotifier: detailNotifier,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   _buildTaskTimeline(
//                     currentStep: detailState.currentStep,
//                     currentTestingDay: detailState.currentTestingDay,
//                     stepsLocked: detailState.stepsLocked,
//                     project: project,
//                     detailNotifier: detailNotifier,
//                   ),
//                   const SizedBox(height: 25),
//                   _buildSectionHeader("Credentials & Security"),
//                   const SizedBox(height: 10),
//                   _buildCredentialsCard(
//                     showPassword: detailState.showPassword,
//                     showKeystorePass: detailState.showKeystorePass,
//                     project: project,
//                     detailNotifier: detailNotifier,
//                   ),
//                   const SizedBox(height: 15),
//                   _buildBackupCodesCard(project: project),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressHeader({
//     required int currentStep,
//     required int currentTestingDay,
//     required ProjectModel project,
//     required AppDetailNotifier detailNotifier,
//   }) {
//     if (currentStep < 5 || currentStep > 8) return const SizedBox.shrink();
//     return Container(
//       width: double.infinity,
//       // color: googleBlue,
//       padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           // color: actionOrange,
//           borderRadius: BorderRadius.circular(15),
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
//         ),
//         child: Row(
//           children: [
//             const Icon(Icons.speed, color: Colors.white, size: 30),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "LIVE TESTING TRACKER",
//                     style: TextStyle(
//                       color: Colors.white70,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     "Day $currentTestingDay of 14",
//                     style: const TextStyle(
//                       // color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             IconButton(
//               onPressed: () {
//                 _showCalibrationDialog(
//                   currentTestingDay: currentTestingDay,
//                   project: project,
//                   detailNotifier: detailNotifier,
//                 );
//               },
//               icon: const Icon(
//                 Icons.settings_backup_restore,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLockSwitch({
//     required bool stepsLocked,
//     required AppDetailNotifier detailNotifier,
//   }) {
//     return Row(
//       children: [
//         Icon(
//           stepsLocked ? Icons.lock_open : Icons.lock,
//           size: 16,
//           color: stepsLocked ? Colors.green : Colors.red,
//         ),
//         Transform.scale(
//           scale: 0.7,
//           child: Switch(
//             value: stepsLocked,
//             onChanged: (value) => detailNotifier.toggleStepsLocked(),
//             activeThumbColor: Colors.green,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionHeader(String title, {Widget? trailing}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         if (trailing != null) trailing,
//       ],
//     );
//   }

//   Widget _buildTaskTimeline({
//     required int currentStep,
//     required int currentTestingDay,
//     required bool stepsLocked,
//     required ProjectModel project,
//     required AppDetailNotifier detailNotifier,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.grey[700]!),
//       ),
//       child: ListView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: taskLabels.length,
//         itemBuilder: (context, index) {
//           bool isCompleted = index < currentStep - 1;
//           bool isActive = index == currentStep - 1;

//           return IntrinsicHeight(
//             child: Row(
//               children: [
//                 const SizedBox(width: 20),
//                 Column(
//                   children: [
//                     Container(
//                       width: 24,
//                       height: 24,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: isCompleted
//                             ? Colors.green
//                             : (isActive ? Colors.orange : Colors.grey[300]),
//                       ),
//                       child: Icon(
//                         isCompleted
//                             ? Icons.check
//                             : (isActive ? Icons.play_arrow : null),
//                         size: 14,
//                         color: Colors.white,
//                       ),
//                     ),
//                     if (index != taskLabels.length - 1)
//                       Expanded(
//                         child: Container(width: 2, color: Colors.grey[200]),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () {
//                       if (!stepsLocked) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             duration: Duration(seconds: 1),
//                             content: Text("Unlock the lock to change steps"),
//                           ),
//                         );
//                         return;
//                       }
//                       if (index == 4 && currentStep < 5) {
//                         _showCalibrationDialog(
//                           currentTestingDay: currentTestingDay,
//                           project: project,
//                           detailNotifier: detailNotifier,
//                         );
//                       } else {
//                         detailNotifier.updateStep(index + 1);
//                         ref
//                             .read(projectNotifierProvider.notifier)
//                             .updateProject(
//                               project.copyWith(currentStep: index + 1),
//                             );
//                       }
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 12),
//                       child: Text(
//                         taskLabels[index],
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight: isActive
//                               ? FontWeight.bold
//                               : FontWeight.normal,
//                           color: isCompleted
//                               ? Colors.grey
//                               : (isActive
//                                     ? Colors.blueAccent
//                                     : Theme.of(context).colorScheme.secondary),
//                           decoration: isCompleted
//                               ? TextDecoration.lineThrough
//                               : null,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 if (isActive)
//                   const Padding(
//                     padding: EdgeInsets.only(right: 20),
//                     child: Icon(
//                       Icons.arrow_forward_ios,
//                       size: 12,
//                       color: Colors.grey,
//                     ),
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCredentialsCard({
//     required bool showPassword,
//     required bool showKeystorePass,
//     required ProjectModel project,
//     required AppDetailNotifier detailNotifier,
//   }) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(color: Colors.grey[700]!),
//       ),
//       child: ExpansionTile(
//         maintainState: true,
//         shape: const RoundedRectangleBorder(side: BorderSide.none),
//         leading: Icon(Icons.badge_outlined, color: Colors.blue),
//         title: const Text(
//           "Account Details",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//         children: [
//           _buildDetailTile(
//             "Owner",
//             project.owner,
//             Icons.account_circle_outlined,
//           ),
//           _buildDetailTile(
//             "Play Email",
//             project.email,
//             Icons.email_outlined,
//             onCopy: () => _copyToClipboard(project.email),
//           ),
//           _buildDetailTile(
//             "Password",
//             showPassword ? project.password : "••••••••",
//             Icons.lock_outline,
//             onToggle: () => detailNotifier.togglePassword(),
//             isVisible: showPassword,
//           ),
//           _buildDetailTile(
//             "Keystore",
//             showKeystorePass ? project.keystorePassword : "••••••••",
//             Icons.vpn_key_outlined,
//             onToggle: () => detailNotifier.toggleKeystorePassword(),
//             isVisible: showKeystorePass,
//           ),
//           _buildDetailTile(
//             "Payment",
//             project.paymentStatus,
//             Icons.payments_outlined,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackupCodesCard({required ProjectModel project}) {
//     bool hasCodes = project.backupCodes.isNotEmpty;
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(color: Colors.grey[700]!),
//       ),
//       child: ExpansionTile(
//         shape: const RoundedRectangleBorder(
//           side: BorderSide(color: Colors.transparent),
//         ),
//         collapsedShape: const RoundedRectangleBorder(
//           side: BorderSide(color: Colors.transparent),
//         ),
//         leading: Icon(
//           Icons.security,
//           color: hasCodes ? Colors.green : Colors.grey,
//         ),
//         title: const Text(
//           "Backup Codes",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text(
//           hasCodes
//               ? "${project.backupCodes.length} codes ready"
//               : "No codes saved",
//         ),
//         trailing: hasCodes
//             ? IconButton(
//                 icon: const Icon(Icons.copy_all, size: 20),
//                 onPressed: () =>
//                     _copyToClipboard(project.backupCodes.join('\n')),
//               )
//             : null,
//         childrenPadding: const EdgeInsets.all(16),
//         children: [
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: project.backupCodes.length,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 2.8,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//             ),
//             itemBuilder: (c, i) => _buildCodeChip(project.backupCodes[i]),
//           ),

//           SizedBox(height: hasCodes ? 5 : 0),

//           ElevatedButton.icon(
//             onPressed: () => showDialog(
//               context: context,
//               builder: (c) =>
//                   AlertDialog(content: VerifyCodesAlert(project: project)),
//             ),
//             icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
//             label: const Text(
//               "Scan/Add Codes",
//               style: TextStyle(color: Colors.white),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blueAccent,
//               foregroundColor: Theme.of(context).colorScheme.primary,
//               minimumSize: const Size(double.infinity, 45),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCodeChip(String code) {
//     return Container(
//       decoration: BoxDecoration(
//         color: ref.watch(themeNotifier).themeMode == ThemeMode.light
//             ? Colors.grey[100]
//             : Colors.black,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: ref.watch(themeNotifier).themeMode == ThemeMode.light
//               ? Colors.grey[300]!
//               : Colors.black,
//         ),
//       ),
//       child: InkWell(
//         onTap: () => _copyToClipboard(code),
//         borderRadius: BorderRadius.circular(12),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               code,
//               style: const TextStyle(
//                 fontFamily: 'monospace',
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(width: 5),
//             const Icon(Icons.copy, size: 14, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailTile(
//     String label,
//     String value,
//     IconData icon, {
//     VoidCallback? onCopy,
//     VoidCallback? onToggle,
//     bool? isVisible,
//   }) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: Icon(icon, size: 20, color: Colors.grey),
//       title: Text(
//         label,
//         style: const TextStyle(fontSize: 12, color: Colors.grey),
//       ),
//       subtitle: Text(
//         value,
//         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
//       ),
//       trailing: onToggle != null
//           ? IconButton(
//               icon: Icon(
//                 isVisible! ? Icons.visibility_off : Icons.visibility,
//                 size: 20,
//               ),
//               onPressed: onToggle,
//             )
//           : (onCopy != null
//                 ? IconButton(
//                     icon: const Icon(Icons.copy, size: 18),
//                     onPressed: onCopy,
//                   )
//                 : null),
//     );
//   }

//   void _confirmDelete({
//     required ProjectModel project,
//     required AppDetailNotifier detailNotifier,
//   }) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Delete Project?"),
//         content: Text("This will permanently remove ${project.appName}."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () async {
//               Navigator.pop(context);

//               if (context.mounted) {
//                 Navigator.pushNamedAndRemoveUntil(
//                   context,
//                   RouteName.homeView,
//                   (route) => false,
//                 );
//               }

//               Future.delayed(Duration(seconds: 1), () {
//                 AppProviderContainer.instance
//                     .read(projectNotifierProvider.notifier)
//                     .deleteProject(project.id!);
//               });
//             },
//             child: const Text("Delete", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }
