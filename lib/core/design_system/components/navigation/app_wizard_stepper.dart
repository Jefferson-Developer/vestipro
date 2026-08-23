import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The horizontal progress indicator for multi-step wizards (first used by
/// the onboarding wizard, TASK-038): a segmented progress bar plus the
/// "Passo X de Y" caption and the current step's title.
///
/// Purely presentational — [currentStep] (1-based) and [stepLabels] are
/// supplied by the caller; this widget never decides which step is current
/// or validates anything itself.
class AppWizardStepper extends StatelessWidget {
  const AppWizardStepper({
    super.key,
    required this.currentStep,
    required this.stepLabels,
    this.semanticLabel,
  }) : assert(
         currentStep >= 1 && currentStep <= stepLabels.length,
         'currentStep must be a 1-based index into stepLabels.',
       );

  /// 1-based position of the step currently shown, out of
  /// `stepLabels.length` total steps.
  final int currentStep;

  /// The title of every step, in order — its length is the total step
  /// count.
  final List<String> stepLabels;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalSteps = stepLabels.length;
    final currentLabel = stepLabels[currentStep - 1];
    final progressCaption = 'Passo $currentStep de $totalSteps';

    return Semantics(
      label: semanticLabel ?? '$progressCaption: $currentLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: List<Widget>.generate(totalSteps, (index) {
              final isCompleteOrCurrent = index <= currentStep - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : AppSpacing.spacing4,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isCompleteOrCurrent
                          ? colors.primary
                          : colors.disabled,
                      borderRadius: BorderRadius.circular(AppRadius.radius4),
                    ),
                    child: const SizedBox(height: AppSpacing.spacing4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            progressCaption,
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            currentLabel,
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
