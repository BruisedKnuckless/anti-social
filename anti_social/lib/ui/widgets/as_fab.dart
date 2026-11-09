import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Small round floating button (the settings button over Instagram).
/// Our own widget, not Material's FloatingActionButton, so it looks the
/// same on iOS and Android.
class AsFab extends StatefulWidget {
  const AsFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  static const double size = 48;

  @override
  State<AsFab> createState() => _AsFabState();
}

class _AsFabState extends State<AsFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return Semantics(
      button: true,
      label: widget.tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _pressed ? 0.92 : 1,
          child: Container(
            width: AsFab.size,
            height: AsFab.size,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.border, width: 0.5),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x29000000), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(widget.icon, size: AsSizes.icon, color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}
