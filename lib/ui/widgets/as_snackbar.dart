import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Our own toast, drawn in Flutter (never the native Android toast).
/// One at a time; a new message replaces the current one.
abstract final class AsSnackbar {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String message, {IconData? icon}) {
    hide();
    final overlay = Overlay.of(context, rootOverlay: true);
    final key = GlobalKey<_SnackState>();
    final entry = OverlayEntry(
      builder: (_) => _Snack(key: key, message: message, icon: icon),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(AsDurations.snackbar, () async {
      await key.currentState?.dismiss();
      if (_entry == entry) hide();
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _Snack extends StatefulWidget {
  const _Snack({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  State<_Snack> createState() => _SnackState();
}

class _SnackState extends State<_Snack> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: AsDurations.normal)
        ..forward();

  Future<void> dismiss() async {
    if (mounted) await _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    // Inverted colours so it stands out over Instagram in both modes.
    final bg = c.textPrimary;
    final fg = c.background;
    return Positioned(
      left: AsSpacing.lg,
      right: AsSpacing.lg,
      bottom: MediaQuery.paddingOf(context).bottom + AsSpacing.xxl * 2,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                .animate(curved),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AsSpacing.lg, vertical: AsSpacing.md),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AsRadius.pill),
                  boxShadow: [
                    BoxShadow(
                        color: c.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: fg),
                      const SizedBox(width: AsSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        widget.message,
                        style: AsTextStyles.label.copyWith(
                            color: fg, decoration: TextDecoration.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
