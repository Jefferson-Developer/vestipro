import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/communication_preferences.dart';
import '../bloc/communication_preferences_cubit.dart';
import '../bloc/communication_preferences_state.dart';

/// The preferências de comunicação screen (TASK-154): lets the current user
/// control, per category (CRM/comercial/sistema) and per channel (push,
/// e-mail, central de notificações), how often they want to be notified —
/// "imediato", "resumo diário" or "desativado" — avoiding notification
/// fatigue without ever letting critical system alerts be fully silenced.
class CommunicationPreferencesPage extends StatelessWidget {
  const CommunicationPreferencesPage({
    required this.organizationId,
    required this.userId,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String userId;
  final CommunicationPreferencesCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunicationPreferencesCubit>(
      create: (_) =>
          createCubit()..start(organizationId: organizationId, userId: userId),
      child: const _CommunicationPreferencesScaffold(),
    );
  }
}

class _CommunicationPreferencesScaffold extends StatelessWidget {
  const _CommunicationPreferencesScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Preferências de comunicação',
        content:
            BlocConsumer<
              CommunicationPreferencesCubit,
              CommunicationPreferencesState
            >(
              listenWhen: (previous, current) =>
                  previous.saveStatus != current.saveStatus &&
                  current.saveStatus ==
                      CommunicationPreferencesSaveStatus.failure,
              listener: (context, state) {
                AppSnackbar.show(
                  context,
                  message:
                      state.saveFailure?.message ??
                      'Não foi possível salvar sua preferência.',
                  variant: AppSnackbarVariant.error,
                );
                context
                    .read<CommunicationPreferencesCubit>()
                    .acknowledgeSaveResult();
              },
              builder: (context, state) => _buildBody(context, state),
            ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CommunicationPreferencesState state) {
    if (state.status == CommunicationPreferencesLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar suas preferências',
        message: state.failure?.message ?? 'Tente novamente em breve.',
      );
    }
    if (state.isLoading || state.preferences == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final preferences = state.preferences!;
    final isSaving =
        state.saveStatus == CommunicationPreferencesSaveStatus.saving;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'A alteração aqui vale para todos os seus dispositivos conectados '
            'a esta organização.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          for (final category in AppNotificationCategory.values) ...<Widget>[
            _CategoryPreferenceSection(
              category: category,
              preference: preferences.preferenceFor(category),
              isSaving: isSaving,
              onChanged: (channel, frequency) =>
                  context.read<CommunicationPreferencesCubit>().updateFrequency(
                    category: category,
                    channel: channel,
                    frequency: frequency,
                  ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
          ],
        ],
      ),
    );
  }
}

class _CategoryPreferenceSection extends StatelessWidget {
  const _CategoryPreferenceSection({
    required this.category,
    required this.preference,
    required this.isSaving,
    required this.onChanged,
  });

  final AppNotificationCategory category;
  final CategoryCommunicationPreference preference;
  final bool isSaving;
  final void Function(
    CommunicationChannel channel,
    CommunicationFrequency frequency,
  )
  onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_categoryIcon(category), color: colors.primary),
              const SizedBox(width: AppSpacing.spacing8),
              Text(
                _categoryLabel(category),
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          if (category == AppNotificationCategory.system) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              'Ao menos um canal precisa continuar ativo para esta '
              'categoria.',
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
            ),
          ],
          const SizedBox(height: AppSpacing.spacing16),
          for (final channel in CommunicationChannel.values) ...<Widget>[
            _ChannelFrequencyRow(
              category: category,
              channel: channel,
              selected: preference.frequencyFor(channel),
              isDisabled: isSaving,
              onSelected: (frequency) => onChanged(channel, frequency),
            ),
            if (channel != CommunicationChannel.values.last)
              const SizedBox(height: AppSpacing.spacing12),
          ],
        ],
      ),
    );
  }
}

class _ChannelFrequencyRow extends StatelessWidget {
  const _ChannelFrequencyRow({
    required this.category,
    required this.channel,
    required this.selected,
    required this.isDisabled,
    required this.onSelected,
  });

  final AppNotificationCategory category;
  final CommunicationChannel channel;
  final CommunicationFrequency selected;
  final bool isDisabled;
  final ValueChanged<CommunicationFrequency> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _channelLabel(channel),
          style: AppTypography.labelMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            for (final frequency in CommunicationFrequency.values)
              AppFilterChip(
                key: ValueKey<String>(
                  'preference-chip-${category.name}-${channel.name}-'
                  '${frequency.name}',
                ),
                label: _frequencyLabel(frequency),
                selected: selected == frequency,
                isDisabled: isDisabled,
                onSelected: (_) => onSelected(frequency),
              ),
          ],
        ),
      ],
    );
  }
}

String _categoryLabel(AppNotificationCategory category) {
  return switch (category) {
    AppNotificationCategory.crm => 'CRM',
    AppNotificationCategory.commercial => 'Comercial',
    AppNotificationCategory.system => 'Sistema',
  };
}

IconData _categoryIcon(AppNotificationCategory category) {
  return switch (category) {
    AppNotificationCategory.crm => Icons.support_agent,
    AppNotificationCategory.commercial => Icons.trending_up,
    AppNotificationCategory.system => Icons.settings_outlined,
  };
}

String _channelLabel(CommunicationChannel channel) {
  return switch (channel) {
    CommunicationChannel.push => 'Push',
    CommunicationChannel.email => 'E-mail',
    CommunicationChannel.inApp => 'Central de notificações',
  };
}

String _frequencyLabel(CommunicationFrequency frequency) {
  return switch (frequency) {
    CommunicationFrequency.immediate => 'Imediato',
    CommunicationFrequency.dailyDigest => 'Resumo diário',
    CommunicationFrequency.disabled => 'Desativado',
  };
}
