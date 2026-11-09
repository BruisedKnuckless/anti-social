import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum AsButtonVariant { primary, secondary }

/// Our one button. Primary = filled accent, secondary = subtle surface.
class AsButton extends StatefulWidget {
  const AsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AsButtonVariant.primary,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AsButtonVariant variant;
  final bool expand;

  @override
  State<AsButton> createState() => _AsButtonState();
}

class _AsButtonState extends State<AsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final enabled = widget.onPressed != null;
    final primary = widget.variant == AsButtonVariant.primary;
    final bg = primary ? c.accent : c.surfaceRaised;
    final fg = primary ? c.onAccent : c.textPrimary;

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
            style: AsTextStyles.label.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: !enabled ? 0.4 : (_pressed ? 0.75 : 1),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(
                horizontal: AsSpacing.xl, vertical: AsSpacing.md),
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
