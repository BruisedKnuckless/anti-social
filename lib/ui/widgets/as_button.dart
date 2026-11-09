import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum AsButtonVariant { primary, secondary, danger }

/// Our own button: same look and press feedback (opacity dip) everywhere.
class AsButton extends StatefulWidget {
  const AsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AsButtonVariant.primary,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AsButtonVariant variant;
  final IconData? icon;
  final bool expand;

  @override
  State<AsButton> createState() => _AsButtonState();
}

class _AsButtonState extends State<AsButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final enabled = widget.onPressed != null;
    final (bg, fg) = switch (widget.variant) {
      AsButtonVariant.primary => (c.accent, c.onAccent),
      AsButtonVariant.secondary => (c.surfaceMuted, c.textPrimary),
      AsButtonVariant.danger => (c.danger, c.onDanger),
    };

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: AsSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AsTextStyles.label.copyWith(color: fg),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: AsDurations.fast,
          opacity: !enabled ? 0.4 : (_pressed ? 0.7 : 1),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AsSpacing.xl),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AsRadius.md),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
