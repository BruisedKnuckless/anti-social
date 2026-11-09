import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// Our own switch. Never `Switch.adaptive` (it looks different per platform).
class AsSwitch extends StatelessWidget {
  const AsSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _width = 50;
  static const double _height = 30;
  static const double _knob = 24;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: AnimatedOpacity(
          duration: AsDurations.fast,
          opacity: enabled ? 1 : 0.4,
          child: AnimatedContainer(
            duration: AsDurations.normal,
            curve: Curves.easeOutCubic,
            width: _width,
            height: _height,
            padding: const EdgeInsets.all((_height - _knob) / 2),
            decoration: BoxDecoration(
              color: value ? c.accent : c.switchTrackOff,
              borderRadius: BorderRadius.circular(AsRadius.pill),
            ),
            child: AnimatedAlign(
              duration: AsDurations.normal,
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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
