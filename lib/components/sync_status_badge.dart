import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  const SyncStatusBadge({super.key, required this.isSynced});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // When not synced, we show a subtle outline like a "waiting" state
        border: !isSynced
            ? Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1.5,
              )
            : null,
        color: isSynced
            ? primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: Icon(
        isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
        size: 14,
        color: isSynced
            ? primaryColor
            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
