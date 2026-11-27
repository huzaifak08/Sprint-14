import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digital_munshi/components/app_toast.dart';
import 'package:digital_munshi/helpers/theme_widgets.dart';
import 'package:digital_munshi/models/project_model.dart';

/// Copies [text] and confirms with a toast.
Future<void> copyToClipboard(String text, String label) async {
  await Clipboard.setData(ClipboardData(text: text));
  AppToast.success("$label copied");
}

/// Uppercase, letter-spaced section label used across the project screens.
class ProjectSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const ProjectSectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Bordered surface card that groups related rows.
///
/// A [Material] (not a decorated Container) so ListTiles and InkWells
/// inside it draw their background and ripple on the card itself.
class ProjectCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ProjectCardShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Paid / unpaid pill.
class PaymentChip extends StatelessWidget {
  final PaymentStatus status;
  final bool onPrimary;
  const PaymentChip({super.key, required this.status, this.onPrimary = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paid = status == PaymentStatus.paid;
    final color = onPrimary
        ? theme.colorScheme.onPrimary
        : (paid ? positiveMoneyColor(theme) : negativeMoneyColor(theme));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: onPrimary ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paid ? Icons.verified_rounded : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            paid ? "PAID" : "UNPAID",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded avatar with the app's initial.
class ProjectAvatar extends StatelessWidget {
  final String appName;
  final double size;
  final bool onPrimary;
  const ProjectAvatar({
    super.key,
    required this.appName,
    this.size = 48,
    this.onPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = appName.trim();
    final fg = onPrimary ? cs.onPrimary : cs.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fg.withValues(alpha: onPrimary ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        name.isEmpty ? "?" : name[0].toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Label + value row with optional masking and a copy button.
class ProjectInfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool secret;
  final bool copyable;

  const ProjectInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.secret = false,
    this.copyable = false,
  });

  @override
  State<ProjectInfoRow> createState() => _ProjectInfoRowState();
}

class _ProjectInfoRowState extends State<ProjectInfoRow> {
  late bool _hidden = widget.secret;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final empty = widget.value.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 11, color: cs.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? "Not set" : (_hidden ? "••••••••" : widget.value),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: empty ? cs.outline : cs.onSurface,
                    letterSpacing: _hidden && !empty ? 2 : null,
                  ),
                ),
              ],
            ),
          ),
          if (widget.secret && !empty)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: _hidden ? "Show" : "Hide",
              icon: Icon(
                _hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          if (widget.copyable && !empty)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: "Copy",
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () => copyToClipboard(widget.value, widget.label),
            ),
        ],
      ),
    );
  }
}
