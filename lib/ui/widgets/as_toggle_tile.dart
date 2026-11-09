import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'as_switch.dart';

/// A settings row: title, optional subtitle, and an [AsSwitch].
/// The whole row is tappable.
class AsToggleTile extends StatelessWidget {
  const AsToggleTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AsSpacing.lg,
            vertical: AsSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AsTextStyles.label
                            .copyWith(color: c.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: AsTextStyles.caption
                              .copyWith(color: c.textSecondary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AsSpacing.md),
              AsSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
