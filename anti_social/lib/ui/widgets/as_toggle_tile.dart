import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// A settings row with our own switch (NOT `Switch.adaptive`), so it looks
/// identical on iOS and Android. Tapping anywhere on the row toggles it.
class AsToggleTile extends StatelessWidget {
  const AsToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: title,
      hint: subtitle,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AsSpacing.lg, vertical: AsSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AsTextStyles.label.copyWith(color: c.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AsSpacing.xs),
                        Text(subtitle!,
                            style: AsTextStyles.caption
                                .copyWith(color: c.textSecondary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AsSpacing.md),
                AsSwitch(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The visual switch on its own (no gesture handling).
class AsSwitch extends StatelessWidget {
  const AsSwitch({super.key, required this.value});

  final bool value;

  static const double _width = 50;
  static const double _height = 30;
  static const double _pad = 3;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    const duration = Duration(milliseconds: 180);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: value ? c.accent : c.toggleOff,
        borderRadius: BorderRadius.circular(AsRadius.pill),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _height - _pad * 2,
          height: _height - _pad * 2,
          decoration: BoxDecoration(
            color: c.knob,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
