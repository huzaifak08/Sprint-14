// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sprint14/helpers/app_data.dart';
// import 'package:sprint14/helpers/constants.dart';
// import 'package:sprint14/models/project_model.dart';
// import 'package:sprint14/providers/app_provider_container.dart';
// import 'package:sprint14/providers/projects_provider/projects_provider.dart';

// class AddOrUpdateAppView extends ConsumerStatefulWidget {
//   final ProjectModel? oldProject;
//   const AddOrUpdateAppView({super.key, this.oldProject});

//   @override
//   ConsumerState<AddOrUpdateAppView> createState() => _AddOrUpdateAppViewState();
// }

// class _AddOrUpdateAppViewState extends ConsumerState<AddOrUpdateAppView> {
//   late GlobalKey<FormState> _formKey;
//   late TextEditingController _appNameController;
//   late TextEditingController _ownerNameController;
//   late TextEditingController _emailController;
//   late TextEditingController _passwordController;
//   late TextEditingController _keystorePassController;

//   late FocusNode _appNameFocus;
//   late FocusNode _ownerNameFocus;
//   late FocusNode _emailFocus;
//   late FocusNode _passwordFocus;
//   late FocusNode _keystorePassFocus;

//   bool _obscurePassword = true;
//   bool _obsecureKeystore = true;
//   bool _isLoading = false;
//   DateTime? _startDate;
//   DateTime? _endDate;
//   String _paymentStatus = 'unpaid';
//   String _initialStep = 'Step 1: Console Setup';

//   @override
//   void initState() {
//     super.initState();
//     _formKey = GlobalKey<FormState>();
//     _appNameController = TextEditingController();
//     _ownerNameController = TextEditingController();
//     _emailController = TextEditingController();
//     _passwordController = TextEditingController();
//     _keystorePassController = TextEditingController();

//     if (widget.oldProject != null) {
//       _appNameController.text = widget.oldProject!.appName;
//       _ownerNameController.text = widget.oldProject!.owner;
//       _emailController.text = widget.oldProject!.email;
//       _passwordController.text = widget.oldProject!.password;
//       _keystorePassController.text = widget.oldProject!.keystorePassword;
//       _startDate = widget.oldProject!.createdAt;
//       _endDate = widget.oldProject!.endDate;
//       _paymentStatus = widget.oldProject!.paymentStatus;
//       _initialStep = getStepNameFromInteger(widget.oldProject!.currentStep);
//     }

//     _appNameFocus = FocusNode();
//     _ownerNameFocus = FocusNode();
//     _emailFocus = FocusNode();
//     _passwordFocus = FocusNode();
//     _keystorePassFocus = FocusNode();
//   }

//   @override
//   void dispose() {
//     _appNameController.dispose();
//     _ownerNameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _keystorePassController.dispose();

//     _appNameFocus.dispose();
//     _ownerNameFocus.dispose();
//     _emailFocus.dispose();
//     _passwordFocus.dispose();
//     _keystorePassFocus.dispose();
//     super.dispose();
//   }

//   Future<void> _selectDate(bool isStartDate) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }

//   void _createOrUpdateProject() async {
//     setState(() {
//       _isLoading = true;
//     });
//     int initialStepInteger = getIntegerStepFromString();

//     if (widget.oldProject != null) {
//       ProjectModel newButOldProject = ProjectModel(
//         id: widget.oldProject?.id,
//         appName: _appNameController.text.trim(),
//         owner: _ownerNameController.text.trim(),
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         currentStep: initialStepInteger,
//         paymentStatus: _paymentStatus,
//         keystorePassword: _keystorePassController.text.trim(),
//         backupCodes: widget.oldProject?.backupCodes ?? [],
//         isSynced: false,
//         isDeleted: false,
//         createdAt: _startDate ?? DateTime.now(),
//         endDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
//       );

//       final projectNotifier = AppProviderContainer.instance.read(
//         projectNotifierProvider.notifier,
//       );

//       projectNotifier.updateProject(newButOldProject);

//       Navigator.pop(AppData.shared.navigatorKey.currentContext ?? context);
//     } else {
//       ProjectModel newProject = ProjectModel(
//         id: AppData.shared.uuid.v4(),
//         appName: _appNameController.text.trim(),
//         owner: _ownerNameController.text.trim(),
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         currentStep: initialStepInteger,
//         paymentStatus: _paymentStatus,
//         keystorePassword: _keystorePassController.text.trim(),
//         backupCodes: [],
//         isSynced: false,
//         isDeleted: false,
//         createdAt: _startDate ?? DateTime.now(),
//         endDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
//       );

//       final projectNotifier = AppProviderContainer.instance.read(
//         projectNotifierProvider.notifier,
//       );

//       projectNotifier.addNewProject(newProject);

//       Navigator.pop(AppData.shared.navigatorKey.currentContext ?? context);
//     }

//     setState(() {
//       _isLoading = false;
//     });
//   }

//   int getIntegerStepFromString() {
//     return int.parse(_initialStep.split(':')[0].replaceAll('Step ', ''));
//   }

//   String getStepNameFromInteger(int step) {
//     if (step >= 1 && step <= allSteps.length) {
//       return allSteps[step - 1];
//     }

//     return allSteps[0];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           SliverAppBar(
//             pinned: true,
//             elevation: 0,
//             title: Text(
//               widget.oldProject != null
//                   ? widget.oldProject?.appName ?? "NO NAME"
//                   : 'New Project',
//               style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//             ),
//           ),
//           SliverToBoxAdapter(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Section 1: General Info
//                     Card(
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'General Info',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF1976D2),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             TextFormField(
//                               controller: _appNameController,
//                               focusNode: _appNameFocus,
//                               onFieldSubmitted: (_) {
//                                 _appNameFocus.unfocus();
//                                 FocusScope.of(
//                                   context,
//                                 ).requestFocus(_ownerNameFocus);
//                               },
//                               decoration: InputDecoration(
//                                 labelText: 'App Name',
//                                 labelStyle: TextStyle(
//                                   color: Theme.of(
//                                     context,
//                                   ).colorScheme.secondary,
//                                 ),
//                                 prefixIcon: const Icon(Icons.apps),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               validator: (value) => value?.isEmpty ?? true
//                                   ? 'App name required'
//                                   : null,
//                             ),
//                             const SizedBox(height: 12),
//                             TextFormField(
//                               controller: _ownerNameController,
//                               focusNode: _ownerNameFocus,
//                               onFieldSubmitted: (_) {
//                                 _ownerNameFocus.unfocus();
//                                 FocusScope.of(
//                                   context,
//                                 ).requestFocus(_emailFocus);
//                               },
//                               decoration: InputDecoration(
//                                 labelText: 'Owner Name',
//                                 prefixIcon: const Icon(Icons.person),
//                                 labelStyle: TextStyle(
//                                   color: Theme.of(
//                                     context,
//                                   ).colorScheme.secondary,
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               validator: (value) => value?.isEmpty ?? true
//                                   ? 'Owner name required'
//                                   : null,
//                             ),
//                             const SizedBox(height: 12),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: InkWell(
//                                     onTap: () => _selectDate(true),
//                                     child: InputDecorator(
//                                       decoration: InputDecoration(
//                                         labelText: 'Start Date',
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                         ),
//                                         prefixIcon: const Icon(
//                                           Icons.calendar_today,
//                                         ),
//                                       ),
//                                       child: Text(
//                                         _startDate?.toString().split(' ')[0] ??
//                                             'Select',
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: InkWell(
//                                     onTap: () => _selectDate(false),
//                                     child: InputDecorator(
//                                       decoration: InputDecoration(
//                                         labelText: 'End Date',
//                                         border: OutlineInputBorder(
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                         ),
//                                         prefixIcon: const Icon(
//                                           Icons.calendar_today,
//                                         ),
//                                       ),
//                                       child: Text(
//                                         _endDate?.toString().split(' ')[0] ??
//                                             'Select',
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     // Section 2: Credentials
//                     Card(
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Credentials',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF1976D2),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             TextFormField(
//                               controller: _emailController,
//                               focusNode: _emailFocus,
//                               keyboardType: TextInputType.emailAddress,
//                               onFieldSubmitted: (_) {
//                                 _emailFocus.unfocus();
//                                 FocusScope.of(
//                                   context,
//                                 ).requestFocus(_passwordFocus);
//                               },
//                               decoration: InputDecoration(
//                                 labelText: 'Play Console Email',
//                                 labelStyle: TextStyle(
//                                   color: Theme.of(
//                                     context,
//                                   ).colorScheme.secondary,
//                                 ),
//                                 prefixIcon: const Icon(Icons.email),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               validator: (value) {
//                                 if (value?.isEmpty ?? true) {
//                                   return 'Email required';
//                                 }
//                                 if (!value!.contains('@')) {
//                                   return 'Invalid email';
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 12),
//                             TextFormField(
//                               controller: _passwordController,
//                               focusNode: _passwordFocus,
//                               obscureText: _obscurePassword,
//                               onFieldSubmitted: (_) {
//                                 FocusScope.of(
//                                   context,
//                                 ).requestFocus(_keystorePassFocus);
//                               },
//                               decoration: InputDecoration(
//                                 labelText: 'Password',
//                                 labelStyle: TextStyle(
//                                   color: Theme.of(
//                                     context,
//                                   ).colorScheme.secondary,
//                                 ),
//                                 prefixIcon: const Icon(Icons.lock),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _obscurePassword
//                                         ? Icons.visibility_off
//                                         : Icons.visibility,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _obscurePassword = !_obscurePassword;
//                                     });
//                                   },
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               validator: (value) => value?.isEmpty ?? true
//                                   ? 'Password required'
//                                   : null,
//                             ),
//                             const SizedBox(height: 12),
//                             TextFormField(
//                               controller: _keystorePassController,
//                               focusNode: _keystorePassFocus,
//                               obscureText: _obsecureKeystore,
//                               onFieldSubmitted: (_) {
//                                 _keystorePassFocus.unfocus();
//                               },
//                               decoration: InputDecoration(
//                                 labelText: 'Keystore Password',
//                                 labelStyle: TextStyle(
//                                   color: Theme.of(
//                                     context,
//                                   ).colorScheme.secondary,
//                                 ),
//                                 prefixIcon: const Icon(Icons.lock),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _obsecureKeystore
//                                         ? Icons.visibility_off
//                                         : Icons.visibility,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _obsecureKeystore = !_obsecureKeystore;
//                                     });
//                                   },
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               validator: (value) => value?.isEmpty ?? true
//                                   ? 'Password required'
//                                   : null,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     // Section 3: Project State
//                     Card(
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Project State',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                                 color: Color(0xFF1976D2),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             DropdownButtonFormField<String>(
//                               initialValue: _paymentStatus,
//                               decoration: InputDecoration(
//                                 labelText: 'Payment Status',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               items: ['unpaid', 'partial', 'paid']
//                                   .map(
//                                     (status) => DropdownMenuItem(
//                                       value: status,
//                                       child: Text(status),
//                                     ),
//                                   )
//                                   .toList(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   _paymentStatus = value ?? 'unpaid';
//                                 });
//                               },
//                             ),
//                             const SizedBox(height: 12),
//                             DropdownButtonFormField<String>(
//                               initialValue: _initialStep,
//                               decoration: InputDecoration(
//                                 labelText: 'Initial Step',
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 focusedBorder: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                   borderSide: const BorderSide(
//                                     color: Color(0xFF1976D2),
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                               items: allSteps
//                                   .map(
//                                     (step) => DropdownMenuItem(
//                                       value: step,
//                                       child: Text(step),
//                                     ),
//                                   )
//                                   .toList(),
//                               onChanged: (value) {
//                                 setState(() {
//                                   _initialStep =
//                                       value ?? 'Step 1: Console Setup';
//                                 });
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     // Action Button
//                     _isLoading
//                         ? Center(child: CircularProgressIndicator())
//                         : SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: _createOrUpdateProject,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFFFF9800),
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               child: Text(
//                                 widget.oldProject != null
//                                     ? 'Update Project'
//                                     : 'Create Project',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
