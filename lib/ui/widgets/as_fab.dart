import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Small floating round button (the settings button over the WebView).
class AsFab extends StatefulWidget {
  const AsFab({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

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
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: AsDurations.fast,
          scale: _pressed ? 0.92 : 1,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.surface.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
              boxShadow: [
                BoxShadow(
                    color: c.shadow, blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(widget.icon, size: 22, color: c.textPrimary),
          ),
        ),
      ),
    );
  }
}
