// ============================================
// FILE: log_dose_choice_card.dart
// LAYER: screen
// DOMAIN: dose_logs
// RESPONSIBLE FOR: Rendering a single tappable dose choice card with primary and secondary labels using surface/outline styling only
// RECEIVES: primary label, secondary label, optional tap callback, ThemeData
// RETURNS: A full-width tappable card with minimum 72dp height and no semantic color coding
// CONNECTS TO: Nothing
// MUST NEVER: Import from features or hold any state
// ============================================

// flutter
import 'package:flutter/material.dart';

class LogDoseChoiceCard extends StatelessWidget {
  const LogDoseChoiceCard({
    super.key,
    required this.primary,
    required this.secondary,
    required this.onTap,
    required this.theme,
  });

  final String primary;
  final String secondary;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(primary, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(
                secondary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
