import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../design_system/design_system.dart';
import '../../domain/entities/app_locale.dart';
import '../cubit/locale_cubit.dart';

/// The language selector screen (TASK-174): lets the current user pick the
/// VestiPro interface language for this device, from the two currently
/// shipped ([AppLocale.values]).
///
/// [LocaleCubit] is already provided at the app root (`VestiProApp` wraps
/// the whole `MaterialApp.router` in it, so `locale:` can react to it) —
/// this page never creates its own instance, it only reads/watches the one
/// singleton every other screen implicitly renders under too. Switching
/// language here takes effect immediately, on this very screen included:
/// there is no separate "aplicar"/restart step.
class LocaleSettingsPage extends StatelessWidget {
  const LocaleSettingsPage({
    required this.organizationId,
    required this.userId,
    super.key,
  });

  final String organizationId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: AppAdminPageLayout(
        title: l10n.languageSettingsTitle,
        content: BlocConsumer<LocaleCubit, AppLocale>(
          listenWhen: (previous, current) => previous != current,
          listener: (context, _) {
            AppSnackbar.show(
              context,
              message: l10n.languageChangedConfirmation,
              variant: AppSnackbarVariant.success,
            );
          },
          builder: (context, selected) => _LocaleOptionsList(
            selected: selected,
            description: l10n.languageSettingsDescription,
            availableCountLabel: l10n.languageSettingsAvailableCount(
              AppLocale.values.length,
            ),
            currentLanguageSemanticLabel: l10n.currentLanguageSemanticLabel,
            onSelected: (locale) => context.read<LocaleCubit>().changeLocale(
              locale,
              organizationId: organizationId,
              userId: userId,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocaleOptionsList extends StatelessWidget {
  const _LocaleOptionsList({
    required this.selected,
    required this.description,
    required this.availableCountLabel,
    required this.currentLanguageSemanticLabel,
    required this.onSelected,
  });

  final AppLocale selected;
  final String description;
  final String availableCountLabel;
  final String currentLanguageSemanticLabel;
  final ValueChanged<AppLocale> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            availableCountLabel,
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          for (final locale in AppLocale.values) ...<Widget>[
            _LocaleOptionTile(
              key: ValueKey<String>('locale-option-${locale.languageCode}'),
              locale: locale,
              isSelected: locale == selected,
              currentLanguageSemanticLabel: currentLanguageSemanticLabel,
              onTap: () => onSelected(locale),
            ),
            const SizedBox(height: AppSpacing.spacing12),
          ],
        ],
      ),
    );
  }
}

class _LocaleOptionTile extends StatelessWidget {
  const _LocaleOptionTile({
    required this.locale,
    required this.isSelected,
    required this.currentLanguageSemanticLabel,
    required this.onTap,
    super.key,
  });

  final AppLocale locale;
  final bool isSelected;
  final String currentLanguageSemanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      selected: isSelected,
      label: isSelected
          ? '${locale.displayName} — $currentLanguageSemanticLabel'
          : locale.displayName,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.radius16),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outline.withValues(
                alpha: 0.16,
              ),
              width: isSelected ? 2 : 1,
            ),
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
              Expanded(
                child: Text(
                  locale.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
