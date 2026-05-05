// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:sprint14/helpers/app_data.dart';
// import 'package:sprint14/models/project_model.dart';
// import 'package:sprint14/providers/app_provider_container.dart';
// import 'package:sprint14/providers/projects_provider/projects_provider.dart';
// import 'package:sprint14/providers/user_provider/user_provider.dart';
// import 'package:sprint14/services/project_service.dart';

// class VerifyCodesAlert extends StatefulWidget {
//   final ProjectModel project;
//   const VerifyCodesAlert({super.key, required this.project});

//   @override
//   State<VerifyCodesAlert> createState() => _VerifyCodesAlertState();
// }

// class _VerifyCodesAlertState extends State<VerifyCodesAlert> {
//   late final TextEditingController _codesController;
//   final ImagePicker _picker = ImagePicker();
//   bool _isProcessing = false;
//   String? _imagePath;

//   @override
//   void initState() {
//     _codesController = TextEditingController();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _codesController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleImageAction(ImageSource source) async {
//     // 🔥 Get UID from UserProvider
//     final uid = AppProviderContainer.instance
//         .read(userNotifierProvider)
//         .value
//         ?.uid;
//     if (uid == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("User session expired. Please login again."),
//         ),
//       );
//       return;
//     }

//     setState(() => _isProcessing = true);

//     try {
//       final pickedImage = await _picker.pickImage(source: source);
//       if (pickedImage != null) {
//         // 🔥 Pass UID to ProjectService
//         List<String> codes = await ProjectService(
//           uid: uid,
//         ).extractCodes(pickedImage.path);
//         setState(() {
//           _imagePath = pickedImage.path;
//           _codesController.text = codes.join("\n");
//         });
//       }
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.maxFinite,
//       padding: const EdgeInsets.only(top: 10),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(),
//             const SizedBox(height: 20),
//             if (_isProcessing)
//               _buildLoadingState()
//             else if (_imagePath == null)
//               _buildSourceSelection()
//             else
//               _buildVerificationState(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Column(
//       children: [
//         Icon(
//           Icons.security_rounded,
//           size: 40,
//           color: Theme.of(context).colorScheme.tertiary,
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           "Backup Codes OCR",
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         const Text(
//           "Scan screenshot to extract codes",
//           style: TextStyle(fontSize: 13, color: Colors.grey),
//         ),
//       ],
//     );
//   }

//   Widget _buildSourceSelection() {
//     return Row(
//       children: [
//         _buildSourceCard(
//           icon: Icons.camera_alt_rounded,
//           label: "Camera",
//           onTap: () => _handleImageAction(ImageSource.camera),
//         ),
//         const SizedBox(width: 12),
//         _buildSourceCard(
//           icon: Icons.photo_library_rounded,
//           label: "Gallery",
//           onTap: () => _handleImageAction(ImageSource.gallery),
//         ),
//       ],
//     );
//   }

//   Widget _buildSourceCard({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 20),
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 icon,
//                 color: Theme.of(context).colorScheme.primary,
//                 size: 30,
//               ),
//               const SizedBox(height: 8),
//               Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildVerificationState() {
//     return Column(
//       children: [
//         // Image Preview with Badge
//         Stack(
//           children: [
//             Container(
//               height: 160,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.grey[300]!),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(15),
//                 child: Image.file(File(_imagePath!), fit: BoxFit.cover),
//               ),
//             ),
//             Positioned(
//               top: 8,
//               right: 8,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   "Extracted Image",
//                   style: TextStyle(color: Colors.white, fontSize: 10),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Editable Text Field
//         TextField(
//           controller: _codesController,
//           maxLines: 6,
//           style: const TextStyle(
//             fontFamily: 'monospace',
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//           ),
//           decoration: InputDecoration(
//             labelText: "Verify 10 Codes",
//             hintText: "Codes will appear here...",
//             filled: true,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide(color: Theme.of(context).primaryColor),
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),

//         // Action Buttons
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: () => setState(() => _imagePath = null),
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   side: BorderSide(color: Colors.grey[300]!),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Text(
//                   "Retake",
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.onSecondary,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: _onVerifyAndSave,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Theme.of(context).colorScheme.onSecondary,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: const Text("Confirm & Save"),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildLoadingState() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 40),
//       child: Column(
//         children: [
//           CircularProgressIndicator(
//             color: Theme.of(context).colorScheme.secondary,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             "Scanning image for codes...",
//             style: TextStyle(color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _onVerifyAndSave() async {
//     final verifiedCodes = _codesController.text
//         .split('\n')
//         .map((code) => code.trim())
//         .where((code) => code.isNotEmpty)
//         .toList();

//     final updatedProject = widget.project.copyWith(
//       backupCodes: List<String>.from(verifiedCodes), // 🔒 immutable safety
//     );

//     await AppProviderContainer.instance
//         .read(projectNotifierProvider.notifier)
//         .updateProject(updatedProject);

//     if (!context.mounted) return;

//     final ctx = AppData.shared.navigatorKey.currentContext ?? context;

//     Navigator.pop(ctx);

//     ScaffoldMessenger.of(ctx).showSnackBar(
//       SnackBar(
//         content: const Text("Backup codes updated!"),
//         backgroundColor: Colors.green[700],
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
// }
