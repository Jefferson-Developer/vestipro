import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/organization_segment.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';

/// Curated currency options for the "Moeda e país" step. Not an exhaustive
/// ISO 4217 list — the handful most relevant to a fashion B2B sales force
/// operating out of Brazil, same "good enough for onboarding, refine later
/// in Settings" scope boundary the task itself draws.
const List<AppDropdownOption<String>> kOnboardingCurrencyOptions =
    <AppDropdownOption<String>>[
      AppDropdownOption(value: 'BRL', label: 'Real brasileiro (BRL)'),
      AppDropdownOption(value: 'USD', label: 'Dólar americano (USD)'),
      AppDropdownOption(value: 'EUR', label: 'Euro (EUR)'),
      AppDropdownOption(value: 'ARS', label: 'Peso argentino (ARS)'),
      AppDropdownOption(value: 'MXN', label: 'Peso mexicano (MXN)'),
    ];

const List<AppDropdownOption<String>> kOnboardingCountryOptions =
    <AppDropdownOption<String>>[
      AppDropdownOption(value: 'BR', label: 'Brasil'),
      AppDropdownOption(value: 'US', label: 'Estados Unidos'),
      AppDropdownOption(value: 'PT', label: 'Portugal'),
      AppDropdownOption(value: 'AR', label: 'Argentina'),
      AppDropdownOption(value: 'MX', label: 'México'),
    ];

const List<AppDropdownOption<String>> kOnboardingLanguageOptions =
    <AppDropdownOption<String>>[
      AppDropdownOption(value: 'pt-BR', label: 'Português (Brasil)'),
      AppDropdownOption(value: 'en-US', label: 'English (US)'),
      AppDropdownOption(value: 'es-ES', label: 'Español'),
    ];

/// Step 1: the organization's name (TASK-038).
///
/// A [StatefulWidget] (unlike every other step view here) so it can own a
/// [TextEditingController] seeded once, in [initState], from whatever
/// [OnboardingState.organizationName] already is at that point — the only
/// way a resumed/previously-typed name shows up in the field on first
/// render, since [AppTextField] (like `TextFormField`) never re-reads a
/// bloc's state on every rebuild the way `AppDropdown`'s selection display
/// does.
class OnboardingOrganizationDetailsStep extends StatefulWidget {
  const OnboardingOrganizationDetailsStep({super.key});

  @override
  State<OnboardingOrganizationDetailsStep> createState() =>
      _OnboardingOrganizationDetailsStepState();
}

class _OnboardingOrganizationDetailsStepState
    extends State<OnboardingOrganizationDetailsStep> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<OnboardingBloc>().state.organizationName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isSubmitting =
            state.submissionStatus == OnboardingSubmissionStatus.submitting;
        return AppTextField(
          key: const ValueKey('onboarding-organization-name-field'),
          controller: _controller,
          label: 'Nome da organização',
          isRequired: true,
          isDisabled: isSubmitting,
          errorText: state.organizationNameError,
          autofocus: true,
          semanticLabel: 'Campo de nome da organização',
          prefixIcon: const Icon(Icons.storefront_outlined),
          onChanged: (value) => context.read<OnboardingBloc>().add(
            OnboardingEvent.organizationNameChanged(value),
          ),
        );
      },
    );
  }
}

/// Step 2: the fashion segment the Organization operates in (TASK-038).
class OnboardingSegmentStep extends StatelessWidget {
  const OnboardingSegmentStep({super.key});

  String _labelFor(OrganizationSegment segment) => switch (segment) {
    OrganizationSegment.apparel => 'Vestuário',
    OrganizationSegment.footwear => 'Calçados',
    OrganizationSegment.accessories => 'Acessórios',
    OrganizationSegment.multiBrand => 'Multimarcas',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isSubmitting =
            state.submissionStatus == OnboardingSubmissionStatus.submitting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final segment in OrganizationSegment.values) ...<Widget>[
              _SegmentOption(
                label: _labelFor(segment),
                isSelected: state.segment == segment,
                isDisabled: isSubmitting,
                onTap: () => context.read<OnboardingBloc>().add(
                  OnboardingEvent.segmentSelected(segment),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
            ],
            if (state.segmentError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                child: Text(
                  state.segmentError!,
                  style: AppTypography.bodySmall.copyWith(color: colors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isDisabled,
      label: label,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? colors.primaryContainer : colors.surface,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? colors.primary : colors.outline,
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDisabled ? colors.disabled : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3: currency and country (TASK-038) — both condition future price/
/// report formatting (EPIC-23/TASK-175), so both are stored as normalized
/// codes (ISO 4217/3166), never a free-text/display label.
class OnboardingRegionalSettingsStep extends StatelessWidget {
  const OnboardingRegionalSettingsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isSubmitting =
            state.submissionStatus == OnboardingSubmissionStatus.submitting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppDropdown<String>(
              options: kOnboardingCurrencyOptions,
              selectedValues: <String>{state.currency},
              label: 'Moeda',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.currencyError,
              closeSemanticLabel: 'Fechar seleção de moeda',
              semanticLabel: 'Campo de moeda',
              onChanged: (values) {
                final value = values.firstOrNull;
                if (value == null) return;
                context.read<OnboardingBloc>().add(
                  OnboardingEvent.currencyChanged(value),
                );
              },
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppDropdown<String>(
              options: kOnboardingCountryOptions,
              selectedValues: <String>{state.country},
              label: 'País',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.countryError,
              closeSemanticLabel: 'Fechar seleção de país',
              semanticLabel: 'Campo de país',
              onChanged: (values) {
                final value = values.firstOrNull;
                if (value == null) return;
                context.read<OnboardingBloc>().add(
                  OnboardingEvent.countryChanged(value),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Step 4: initial preferences — today, only the default language
/// (TASK-038); the last step before the wizard can be completed.
class OnboardingPreferencesStep extends StatelessWidget {
  const OnboardingPreferencesStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isSubmitting =
            state.submissionStatus == OnboardingSubmissionStatus.submitting;

        return AppDropdown<String>(
          options: kOnboardingLanguageOptions,
          selectedValues: <String>{state.defaultLanguage},
          label: 'Idioma padrão',
          isRequired: true,
          isDisabled: isSubmitting,
          errorText: state.defaultLanguageError,
          closeSemanticLabel: 'Fechar seleção de idioma',
          semanticLabel: 'Campo de idioma padrão',
          onChanged: (values) {
            final value = values.firstOrNull;
            if (value == null) return;
            context.read<OnboardingBloc>().add(
              OnboardingEvent.defaultLanguageChanged(value),
            );
          },
        );
      },
    );
  }
}
