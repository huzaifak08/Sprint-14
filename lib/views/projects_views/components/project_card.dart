import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/views/projects_views/components/project_widgets.dart';

/// Project summary tile in the Projects list.
class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'project_avatar_${project.id}',
                      child: ProjectAvatar(appName: project.appName),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  project.owner,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.outline,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Same sync indicator as the other ledgers.
                              Tooltip(
                                message: project.isSynced
                                    ? "Synced"
                                    : "Waiting to sync",
                                child: Icon(
                                  project.isSynced
                                      ? Icons.cloud_done_rounded
                                      : Icons.sync_rounded,
                                  size: 13,
                                  color: project.isSynced
                                      ? Colors.green.withValues(alpha: 0.7)
                                      : cs.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PaymentChip(status: project.paymentStatus),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: project.progress,
                          minHeight: 6,
                          backgroundColor: cs.primary.withValues(alpha: 0.1),
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "STEP ${project.currentStep}/${ProjectModel.totalSteps}",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.event_rounded, size: 14, color: cs.outline),
                    const SizedBox(width: 6),
                    Text(
                      "${DateFormat('d MMM').format(project.createdAt)} – "
                      "${DateFormat('d MMM yyyy').format(project.endDate)}",
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                    const Spacer(),
                    _DeadlineBadge(project: project),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  final ProjectModel project;
  const _DeadlineBadge({required this.project});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = project.daysLeft;
    final (String text, Color color) = days < 0
        ? ("ENDED", cs.outline)
        : days == 0
        ? ("ENDS TODAY", cs.tertiary)
        : (
            "$days ${days == 1 ? 'DAY' : 'DAYS'} LEFT",
            days <= 3 ? cs.tertiary : cs.primary,
          );

    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}
