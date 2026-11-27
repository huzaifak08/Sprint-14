import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:digital_munshi/helpers/app_data.dart';
import 'package:digital_munshi/helpers/backup_code_parser.dart';
import 'package:digital_munshi/helpers/theme_widgets.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/providers/project_provider/project_provider.dart';
import 'package:digital_munshi/services/backup_code_scanner_service.dart';
import 'package:digital_munshi/views/auth/widgets/auth_widgets.dart';
import 'package:digital_munshi/views/projects_views/components/project_widgets.dart';

/// Creates a project, or edits [project] when given.
class ProjectFormView extends ConsumerStatefulWidget {
  final ProjectModel? project;
  const ProjectFormView({super.key, this.project});

  @override
  ConsumerState<ProjectFormView> createState() => _ProjectFormViewState();
}

class _ProjectFormViewState extends ConsumerState<ProjectFormView> {
  static const _defaultDuration = Duration(days: 30);

  final _formKey = GlobalKey<FormState>();
  late final ProjectModel? _initial = widget.project;
  late final _appName = TextEditingController(text: _initial?.appName);
  late final _owner = TextEditingController(text: _initial?.owner);
  late final _email = TextEditingController(text: _initial?.email);
  late final _password = TextEditingController(text: _initial?.password);
  late final _keystore = TextEditingController(
    text: _initial?.keystorePassword,
  );
  late final _backupCodes = TextEditingController(
    text: _initial?.backupCodes.join('\n'),
  );
  late final _testingDay = TextEditingController(
    text: _initial?.testingDayAtUpdate?.toString(),
  );

  late DateTime _startDate = _initial?.createdAt ?? _today();
  late DateTime _endDate =
      _initial?.endDate ?? _startDate.add(_defaultDuration);
  late int _step = (_initial?.currentStep ?? 0).clamp(
    0,
    ProjectModel.totalSteps,
  );
  late PaymentStatus _payment = _initial?.paymentStatus ?? PaymentStatus.unpaid;
  bool _showPassword = false;
  bool _showKeystore = false;
  bool _scanning = false;

  bool get _isEditing => _initial != null;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    for (final c in [
      _appName,
      _owner,
      _email,
      _password,
      _keystore,
      _backupCodes,
      _testingDay,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Photo → on-device OCR → codes in the text field, ready to review.
  Future<void> _scanBackupCodes() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;

    final XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: source,
        // Large enough for small print to stay legible to OCR.
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
    } on PlatformException catch (e) {
      AppToast.error(
        e.code.contains('denied')
            ? "Permission denied. Allow access in your phone settings."
            : "Couldn't open the ${source == ImageSource.camera ? 'camera' : 'gallery'}.",
      );
      return;
    }
    if (image == null || !mounted) return;

    setState(() => _scanning = true);
    final List<String> found;
    try {
      found = await ref.read(backupCodeScannerProvider).scan(image.path);
    } catch (_) {
      AppToast.error("Couldn't read that photo. Please try again.");
      return;
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
    if (!mounted) return;

    if (found.isEmpty) {
      AppToast.error("No backup codes found. Try a sharper, well-lit photo.");
      return;
    }

    final existing = splitBackupCodes(_backupCodes.text);
    var replace = true;
    if (existing.isNotEmpty) {
      final choice = await _askReplaceOrAdd(found.length);
      if (choice == null || !mounted) return;
      replace = choice;
    }

    final codes = replace ? found : {...existing, ...found}.toList();
    _backupCodes.text = codes.join('\n');
    AppToast.info(
      "Found ${found.length} ${found.length == 1 ? 'code' : 'codes'}. "
      "Check them before saving.",
    );
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text("Take a photo"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from gallery"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// True = replace the current codes, false = add to them, null = cancel.
  Future<bool?> _askReplaceOrAdd(int foundCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Backup codes found"),
        content: Text(
          "Found $foundCount ${foundCount == 1 ? 'code' : 'codes'}. "
          "Replace the codes already entered, or add these to them?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ADD"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("REPLACE"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    // Legacy rows may end before they start; never open below the minimum.
    final current = isStart || _endDate.isAfter(_startDate)
        ? (isStart ? _startDate : _endDate)
        : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: isStart ? DateTime(2000) : _startDate,
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    // Keep the original time of day so editing only changes the date.
    final date = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current.hour,
      current.minute,
      current.second,
    );
    setState(() {
      if (isStart) {
        _startDate = date;
        if (_endDate.isBefore(date)) _endDate = date.add(_defaultDuration);
      } else {
        _endDate = date;
      }
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final testingDay = int.tryParse(_testingDay.text.trim());
    final testingChanged = testingDay != _initial?.testingDayAtUpdate;

    final base =
        _initial ??
        ProjectModel(
          id: AppData.shared.uuid.v4(),
          appName: '',
          owner: '',
          email: '',
          password: '',
          keystorePassword: '',
          backupCodes: const [],
          createdAt: _startDate,
          endDate: _endDate,
          currentStep: 0,
          paymentStatus: PaymentStatus.unpaid,
        );

    final project = base.copyWith(
      appName: _appName.text.trim(),
      owner: _owner.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      keystorePassword: _keystore.text,
      backupCodes: splitBackupCodes(_backupCodes.text),
      createdAt: _startDate,
      endDate: _endDate,
      currentStep: _step,
      paymentStatus: _payment,
      clearTesting: testingDay == null,
      testingDayAtUpdate: testingDay,
      // Stamp the date only when the day actually changes.
      testingUpdateDate: testingDay != null && testingChanged
          ? DateTime.now()
          : null,
    );

    // Not awaited: offline the write applies locally at once and completes
    // only when uploaded. A rejection still surfaces as a toast.
    ref
        .read(projectProvider.notifier)
        .saveProject(project)
        .catchError(
          (Object e) => AppToast.error("Couldn't save ${project.appName}."),
        );
    Navigator.pop(context);
    AppToast.success(
      _isEditing ? "${project.appName} updated" : "${project.appName} created",
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canScan = BackupCodeScannerService.isSupported;
    // Keeps the recognizer alive while this form is open, so it isn't
    // closed in the middle of a scan.
    if (canScan) ref.watch(backupCodeScannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? "EDIT PROJECT" : "NEW PROJECT",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const ProjectSectionLabel("Project"),
            _field(
              controller: _appName,
              label: "App name",
              icon: Icons.apps_rounded,
              validator: _required("App name"),
            ),
            _field(
              controller: _owner,
              label: "Owner",
              icon: Icons.person_rounded,
              validator: _required("Owner"),
            ),
            const ProjectSectionLabel("Client account"),
            _field(
              controller: _email,
              label: "Email",
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            _field(
              controller: _password,
              label: "Password",
              icon: Icons.lock_rounded,
              obscure: !_showPassword,
              onToggleObscure: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
            _field(
              controller: _keystore,
              label: "Keystore password",
              icon: Icons.key_rounded,
              obscure: !_showKeystore,
              onToggleObscure: () =>
                  setState(() => _showKeystore = !_showKeystore),
            ),
            ProjectSectionLabel(
              "Backup codes",
              trailing: canScan
                  ? TextButton.icon(
                      onPressed: _scanning ? null : _scanBackupCodes,
                      icon: _scanning
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.document_scanner_outlined,
                              size: 18,
                            ),
                      label: Text(
                        _scanning ? "SCANNING…" : "SCAN PHOTO",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  : null,
            ),
            _field(
              controller: _backupCodes,
              label: "Backup codes",
              hint: canScan
                  ? "Scan a photo, or type one code per line"
                  : "One per line, or separated by spaces/commas",
              icon: Icons.password_rounded,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              bottomPadding: 6,
            ),
            _BackupCodesStatus(controller: _backupCodes),
            const ProjectSectionLabel("Timeline"),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: "Start date",
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateTile(
                    label: "End date",
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(
              controller: _testingDay,
              label: "Testing day (optional)",
              icon: Icons.science_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
            const ProjectSectionLabel("Progress"),
            ProjectCardShell(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        "Current step",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        "$_step / ${ProjectModel.totalSteps}",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _step.toDouble(),
                    max: ProjectModel.totalSteps.toDouble(),
                    divisions: ProjectModel.totalSteps,
                    label: "$_step",
                    onChanged: (v) => setState(() => _step = v.round()),
                  ),
                ],
              ),
            ),
            const ProjectSectionLabel("Payment"),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<PaymentStatus>(
                segments: const [
                  ButtonSegment(
                    value: PaymentStatus.unpaid,
                    label: Text("Unpaid"),
                    icon: Icon(Icons.schedule_rounded),
                  ),
                  ButtonSegment(
                    value: PaymentStatus.paid,
                    label: Text("Paid"),
                    icon: Icon(Icons.verified_rounded),
                  ),
                ],
                selected: {_payment},
                onSelectionChanged: (v) => setState(() => _payment = v.first),
                style: themedSegments(theme).copyWith(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  _isEditing ? Icons.save_rounded : Icons.add_task_rounded,
                ),
                label: Text(
                  _isEditing ? "UPDATE PROJECT" : "CREATE PROJECT",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static FormFieldValidator<String> _required(String label) =>
      (v) => (v == null || v.trim().isEmpty) ? "$label is required" : null;

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    double bottomPadding = 14,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: onToggleObscure == null,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          prefixIcon: Icon(icon),
          suffixIcon: onToggleObscure == null
              ? null
              : IconButton(
                  tooltip: obscure ? "Show" : "Hide",
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: onToggleObscure,
                ),
          filled: true,
          fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}

/// Live code count under the field, flagging entries that aren't 8 digits
/// so OCR slips are easy to spot before saving.
class _BackupCodesStatus extends StatelessWidget {
  final TextEditingController controller;
  const _BackupCodesStatus({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final codes = splitBackupCodes(value.text);
        final unusual = codes.where((c) => !isStandardBackupCode(c)).length;
        final warn = unusual > 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
          child: Row(
            children: [
              Icon(
                warn ? Icons.error_outline_rounded : Icons.check_circle_outline,
                size: 14,
                color: warn ? cs.tertiary : cs.outline,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  codes.isEmpty
                      ? "No codes added"
                      : "${codes.length} ${codes.length == 1 ? 'code' : 'codes'}"
                            "${warn ? ' · $unusual not 8 digits, please check' : ''}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: warn ? FontWeight.w700 : FontWeight.normal,
                    color: warn ? cs.tertiary : cs.outline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: cs.outline.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: cs.outline),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('d MMM yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
