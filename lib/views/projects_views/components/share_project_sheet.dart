import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:digital_munshi/models/project_model.dart';
import 'package:digital_munshi/providers/project_provider/project_provider.dart';
import 'package:digital_munshi/views/projects_views/components/project_widgets.dart';

/// Opens the "Share as PDF" sheet for [project].
Future<void> showShareProjectSheet(BuildContext context, ProjectModel project) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (_) => _ShareProjectSheet(project: project),
  );
}

class _ShareProjectSheet extends ConsumerStatefulWidget {
  final ProjectModel project;
  const _ShareProjectSheet({required this.project});

  @override
  ConsumerState<_ShareProjectSheet> createState() => _ShareProjectSheetState();
}

class _ShareProjectSheetState extends ConsumerState<_ShareProjectSheet> {
  final _buttonKey = GlobalKey();
  bool _includeSecrets = true;
  bool _sharing = false;

  Future<void> _share() async {
    // Anchor for the iPad share popover.
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    setState(() => _sharing = true);
    try {
      await ref
          .read(projectPdfServiceProvider)
          .share(
            widget.project,
            includeSecrets: _includeSecrets,
            origin: origin,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      AppToast.error("Couldn't create the PDF. Please try again.");
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = widget.project;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "SHARE AS PDF",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 20),
            ProjectCardShell(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "One-page A4 report · all project details",
                          style: TextStyle(fontSize: 12, color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ProjectCardShell(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                value: _includeSecrets,
                onChanged: _sharing
                    ? null
                    : (v) => setState(() => _includeSecrets = v),
                title: const Text(
                  "Include passwords & backup codes",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  _includeSecrets
                      ? "Anyone with the PDF can sign in to this account."
                      : "They'll show as hidden in the PDF.",
                  style: TextStyle(
                    fontSize: 12,
                    color: _includeSecrets ? cs.tertiary : cs.outline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                key: _buttonKey,
                onPressed: _sharing ? null : _share,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _sharing
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(
                  _sharing ? "PREPARING PDF…" : "SHARE PDF",
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
}
