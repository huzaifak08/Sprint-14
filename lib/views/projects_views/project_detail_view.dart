import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/providers/project_provider/project_provider.dart';
import 'package:digital_munshi/views/projects_views/components/project_widgets.dart';
import 'package:digital_munshi/views/projects_views/components/share_project_sheet.dart';
import 'package:digital_munshi/views/projects_views/project_form_view.dart';

/// Read view of one project. Follows live updates, so edits made in the
/// form show here as soon as they're saved.
class ProjectDetailView extends ConsumerWidget {
  final ProjectModel project;
  const ProjectDetailView({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live =
        ref
            .watch(projectProvider)
            .value
            ?.where((p) => p.id == project.id)
            .firstOrNull ??
        project;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          live.appName.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Share as PDF",
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => showShareProjectSheet(context, live),
          ),
          IconButton(
            tooltip: "Edit",
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectFormView(project: live)),
            ),
          ),
          IconButton(
            tooltip: "Delete",
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _confirmDelete(context, ref, live),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _HeroHeader(project: live),
          const ProjectSectionLabel("Timeline"),
          _TimelineCard(project: live),
          const ProjectSectionLabel("Client account"),
          ProjectCardShell(
            child: Column(
              children: [
                ProjectInfoRow(
                  icon: Icons.person_rounded,
                  label: "Owner",
                  value: live.owner,
                ),
                ProjectInfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: "Email",
                  value: live.email,
                  copyable: true,
                ),
                ProjectInfoRow(
                  icon: Icons.lock_rounded,
                  label: "Password",
                  value: live.password,
                  secret: true,
                  copyable: true,
                ),
                ProjectInfoRow(
                  icon: Icons.key_rounded,
                  label: "Keystore password",
                  value: live.keystorePassword,
                  secret: true,
                  copyable: true,
                ),
              ],
            ),
          ),
          _BackupCodesSection(codes: live.backupCodes),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete project?"),
        content: Text(
          "\"${project.appName}\" and all its details will be permanently removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "DELETE",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Not awaited: offline, the delete applies locally right away and only
    // completes once uploaded. A rejection still surfaces as a toast.
    ref
        .read(projectProvider.notifier)
        .deleteProject(project.id)
        .catchError(
          (Object e) => AppToast.error("Couldn't delete ${project.appName}."),
        );
    Navigator.pop(context);
    AppToast.success("${project.appName} deleted");
  }
}

class _HeroHeader extends StatelessWidget {
  final ProjectModel project;
  const _HeroHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onPrimary = cs.onPrimary;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'project_avatar_${project.id}',
                child: ProjectAvatar(
                  appName: project.appName,
                  size: 56,
                  onPrimary: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.appName,
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.owner,
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PaymentChip(status: project.paymentStatus, onPrimary: true),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                project.isCompleted ? "COMPLETED" : "PROGRESS",
                style: TextStyle(
                  color: onPrimary.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                "STEP ${project.currentStep} OF ${ProjectModel.totalSteps}",
                style: TextStyle(
                  color: onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: project.progress,
              minHeight: 8,
              backgroundColor: onPrimary.withValues(alpha: 0.2),
              color: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final ProjectModel project;
  const _TimelineCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM yyyy');
    final days = project.daysLeft;
    final status = days < 0
        ? "Ended ${-days} ${days == -1 ? 'day' : 'days'} ago"
        : days == 0
        ? "Ends today"
        : "$days ${days == 1 ? 'day' : 'days'} left";
    final testingDay = project.testingDayAtUpdate;
    final testingDate = project.testingUpdateDate;

    return ProjectCardShell(
      child: Column(
        children: [
          ProjectInfoRow(
            icon: Icons.play_circle_outline_rounded,
            label: "Start date",
            value: date.format(project.createdAt),
          ),
          ProjectInfoRow(
            icon: Icons.flag_outlined,
            label: "End date",
            value: date.format(project.endDate),
          ),
          ProjectInfoRow(
            icon: Icons.hourglass_bottom_rounded,
            label: "Status",
            value: status,
          ),
          ProjectInfoRow(
            icon: Icons.science_outlined,
            label: "Testing day",
            value: testingDay == null
                ? ""
                : "Day $testingDay"
                      "${testingDate == null ? '' : ' · updated ${DateFormat('d MMM yyyy').format(testingDate)}'}",
          ),
        ],
      ),
    );
  }
}

class _BackupCodesSection extends StatefulWidget {
  final List<String> codes;
  const _BackupCodesSection({required this.codes});

  @override
  State<_BackupCodesSection> createState() => _BackupCodesSectionState();
}

class _BackupCodesSectionState extends State<_BackupCodesSection> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final codes = widget.codes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectSectionLabel(
          "Backup codes (${codes.length})",
          trailing: codes.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: _hidden ? "Show codes" : "Hide codes",
                      icon: Icon(
                        _hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _hidden = !_hidden),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: "Copy all",
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      onPressed: () =>
                          copyToClipboard(codes.join('\n'), "Backup codes"),
                    ),
                  ],
                ),
        ),
        ProjectCardShell(
          padding: const EdgeInsets.all(14),
          child: codes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    "No backup codes saved",
                    style: TextStyle(color: cs.outline),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final code in codes)
                      Material(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => copyToClipboard(code, "Code"),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              _hidden ? "••••••••" : code,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
