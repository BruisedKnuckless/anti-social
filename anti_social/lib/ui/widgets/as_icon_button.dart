import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Icon button used in [AsTopBar]. Same look and tap feedback on both OSes:
/// a light haptic and a dim on press, no ripple.
class AsIconButton extends StatefulWidget {
  const AsIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  State<AsIconButton> createState() => _AsIconButtonState();
}

class _AsIconButtonState extends State<AsIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final enabled = widget.onPressed != null;
    final color = widget.color ?? c.textPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
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
        child: SizedBox(
          width: AsSizes.iconButton,
          height: AsSizes.iconButton,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 90),
              opacity: !enabled ? 0.3 : (_pressed ? 0.5 : 1),
              child: Icon(widget.icon, size: AsSizes.icon, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
