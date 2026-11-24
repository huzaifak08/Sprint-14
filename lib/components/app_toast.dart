import 'dart:async';
import 'package:flutter/material.dart';
import 'package:digital_munshi/helpers/app_data.dart';
import 'package:digital_munshi/helpers/theme_widgets.dart';

enum ToastType { success, error, info }

/// App-wide toast shown at the top of the screen, styled from the theme.
///
/// Uses the root navigator's overlay, so it needs no BuildContext, stays
/// visible across navigation and appears above dialogs and bottom sheets.
/// Only one toast is shown at a time; a new one replaces the current one.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static GlobalKey<_ToastCardState>? _cardKey;

  static void success(String message) => show(message, type: ToastType.success);

  static void error(Object message) =>
      show(message.toString(), type: ToastType.error);

  static void info(String message) => show(message, type: ToastType.info);

  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = AppData.shared.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _removeNow();
    final key = GlobalKey<_ToastCardState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastCard(
        key: key,
        message: message,
        type: type,
        duration: type == ToastType.error
            ? duration + const Duration(seconds: 1)
            : duration,
        onDismissed: () {
          if (_entry == entry) _removeNow();
        },
      ),
    );
    _entry = entry;
    _cardKey = key;
    overlay.insert(entry);
  }

  /// Animates the current toast away.
  static void dismiss() => _cardKey?.currentState?.dismiss();

  static void _removeNow() {
    _entry?.remove();
    _entry = null;
    _cardKey = null;
  }
}

class _ToastCard extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastCard({
    super.key,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (Color accent, IconData icon) = switch (widget.type) {
      ToastType.success => (
        positiveMoneyColor(theme),
        Icons.check_circle_rounded,
      ),
      ToastType.error => (cs.error, Icons.error_rounded),
      ToastType.info => (cs.primary, Icons.info_rounded),
    };

    final top = MediaQuery.of(context).padding.top + 8;

    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _controller,
            child: Dismissible(
              key: const ValueKey('app_toast'),
              direction: DismissDirection.up,
              onDismissed: (_) {
                _timer?.cancel();
                widget.onDismissed();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.5
                              : 0.12,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Dismiss',
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.hintColor,
                        ),
                        onPressed: dismiss,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
