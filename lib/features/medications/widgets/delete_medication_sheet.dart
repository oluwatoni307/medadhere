//============================================
// FILE: delete_medication_sheet.dart
// LAYER: widget
// DOMAIN: medications
// RESPONSIBLE FOR: Declarative bottom sheet confirming medication deletion.
// RECEIVES: medicationName, onCancel, onDeleteConfirm via constructor
// RETURNS: Widget
// CONNECTS TO: app_colors.dart, app_spacing.dart, app_text_styles.dart
// MUST NEVER: Access providers, call services, or own any state
//============================================

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class DeleteMedicationSheet extends StatelessWidget {
  const DeleteMedicationSheet({
    super.key,
    required this.medicationName,
    required this.onCancel,
    required this.onDeleteConfirm,
  });

  final String medicationName;
  final VoidCallback onCancel;
  final VoidCallback onDeleteConfirm;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final screenWidth = MediaQuery.of(context).size.width;
    final useRowLayout = screenWidth >= 360;

    final bottomPadding = viewPadding.bottom > AppSpacing.space32
        ? viewPadding.bottom
        : AppSpacing.space32;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXL),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space32,
        AppSpacing.space32,
        AppSpacing.space32,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — drag handle —
          Semantics(
            excludeSemantics: true,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.space24),
                decoration: BoxDecoration(
                  color: AppColors.colorBorder,
                  borderRadius: BorderRadius.circular(AppRadius.radiusPill),
                ),
              ),
            ),
          ),

          // — title —
          Semantics(
            header: true,
            child: Text(
              'Delete $medicationName?',
              style: Theme.of(context)
                  .extension<AppTypography>()!
                  .textHeading2
                  .copyWith(color: AppColors.colorTextPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: AppSpacing.space12),

          // — body —
          Text(
            'This will also delete all your dose history for this medication. This cannot be undone.',
            style: Theme.of(context)
                .extension<AppTypography>()!
                .textBody
                .copyWith(color: AppColors.colorTextSecondary),
          ),

          const SizedBox(height: AppSpacing.space32),

          // — action group —
          useRowLayout
              ? Row(
                  children: [
                    Expanded(child: _cancelButton(context)),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(child: _deleteButton(context)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _cancelButton(context),
                    const SizedBox(height: AppSpacing.space12),
                    _deleteButton(context),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Cancel deletion',
      child: SizedBox(
        height: AppSpacing.buttonHeightPrimary,
        child: ElevatedButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.colorPrimary,
            foregroundColor: AppColors.colorOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
            ),
          ),
          child: Text(
            'Cancel',
            style: Theme.of(context)
                .extension<AppTypography>()!
                .textLabel
                .copyWith(color: AppColors.colorOnPrimary),
          ),
        ),
      ),
    );
  }

  Widget _deleteButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Confirm delete medication',
      child: SizedBox(
        height: AppSpacing.buttonHeightPrimary,
        child: OutlinedButton(
          onPressed: onDeleteConfirm,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.colorStateRiskSurface,
            foregroundColor: AppColors.colorStateRisk,
            side: BorderSide(color: AppColors.colorStateRisk, width: 1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusXL),
            ),
          ),
          child: Text(
            'Delete medication',
            style: Theme.of(context)
                .extension<AppTypography>()!
                .textLabel
                .copyWith(color: AppColors.colorStateRisk),
          ),
        ),
      ),
    );
  }
}
