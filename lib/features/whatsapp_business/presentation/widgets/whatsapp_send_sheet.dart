import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/whatsapp_models.dart';
import '../cubit/whatsapp_send_cubit.dart';

abstract final class WhatsAppSendSheet {
  const WhatsAppSendSheet._();

  static Future<void> show({
    required BuildContext context,
    required WhatsAppSendCubit Function() createCubit,
    required String organizationId,
    required String customerId,
    String? catalogShareId,
    String? notificationId,
  }) => AppBottomSheet.show<void>(
    context: context,
    title: 'Enviar por WhatsApp',
    builder: (_) => BlocProvider(
      create: (_) {
        final cubit = createCubit();
        unawaited(
          cubit.load(
            organizationId: organizationId,
            customerId: customerId,
            catalogShareId: catalogShareId,
            notificationId: notificationId,
          ),
        );
        return cubit;
      },
      child: const _WhatsAppSendContent(),
    ),
  );
}

class _WhatsAppSendContent extends StatelessWidget {
  const _WhatsAppSendContent();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.65,
    ),
    child: BlocConsumer<WhatsAppSendCubit, WhatsAppSendState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == WhatsAppSendStatus.sent,
      listener: (context, state) => AppSnackbar.show(
        context,
        message: 'Mensagem enviada ao WhatsApp.',
        variant: AppSnackbarVariant.success,
      ),
      builder: (context, state) {
        if (state.status == WhatsAppSendStatus.initial ||
            state.status == WhatsAppSendStatus.loading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.spacing32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == WhatsAppSendStatus.failure) {
          return AppErrorState(
            title: 'Nao foi possivel concluir o envio',
            message: state.failure?.message ?? 'Tente novamente.',
            retryLabel: 'Tentar novamente',
            onRetry: context.read<WhatsAppSendCubit>().retry,
          );
        }
        final optIn = state.context?.optIn;
        if (optIn?.isActive != true) {
          return _OptInRequired(
            optIn: optIn,
            isLoading: state.status == WhatsAppSendStatus.requestingOptIn,
          );
        }
        return _Composer(state: state);
      },
    ),
  );
}

class _OptInRequired extends StatelessWidget {
  const _OptInRequired({required this.optIn, required this.isLoading});
  final WhatsAppOptIn? optIn;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final requested = optIn?.status == WhatsAppOptInStatus.requested;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppStatusBadge(
          label: 'Consentimento obrigatorio',
          variant: AppStatusBadgeVariant.warning,
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Text(
          requested
              ? 'A solicitacao ja foi registrada. Aguarde o aceite do cliente antes de enviar.'
              : 'Registre a solicitacao de consentimento. Nenhuma mensagem sera enviada antes do aceite explicito.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        AppButton(
          label: requested
              ? 'Consentimento solicitado'
              : 'Solicitar consentimento',
          leadingIcon: Icons.how_to_reg_outlined,
          isDisabled: requested || isLoading,
          isLoading: isLoading,
          onPressed: requested
              ? null
              : context.read<WhatsAppSendCubit>().requestOptIn,
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.state});
  final WhatsAppSendState state;

  @override
  Widget build(BuildContext context) {
    final templates = state.context?.templates ?? const <WhatsAppTemplate>[];
    if (templates.isEmpty) {
      return const AppEmptyState(
        icon: Icons.message_outlined,
        title: 'Nenhum template aprovado',
        description:
            'Um administrador precisa cadastrar e aprovar um template na Meta antes do envio.',
      );
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppStatusBadge(
            label: 'Opt-in ativo',
            variant: AppStatusBadgeVariant.success,
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: AppSpacing.spacing16),
          DropdownButtonFormField<WhatsAppTemplate>(
            initialValue: state.selectedTemplate,
            decoration: const InputDecoration(labelText: 'Template aprovado'),
            items: templates
                .map(
                  (template) => DropdownMenuItem(
                    value: template,
                    child: Text(template.description ?? template.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (template) {
              if (template != null) {
                context.read<WhatsAppSendCubit>().selectTemplate(template);
              }
            },
          ),
          if (state.selectedTemplate case final template?) ...[
            const SizedBox(height: AppSpacing.spacing12),
            Text(
              'Idioma: ${template.language}',
              style: AppTypography.bodySmall,
            ),
            for (var index = 0; index < template.variables.length; index++) ...[
              const SizedBox(height: AppSpacing.spacing12),
              TextFormField(
                key: ValueKey('whatsapp_variable_$index'),
                decoration: InputDecoration(
                  labelText: template.variables[index],
                ),
                onChanged: (value) {
                  context.read<WhatsAppSendCubit>().updateVariable(
                    index,
                    value,
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Enviar por WhatsApp',
            leadingIcon: Icons.send_outlined,
            isLoading: state.status == WhatsAppSendStatus.sending,
            isDisabled: !state.canSend,
            onPressed: state.canSend
                ? context.read<WhatsAppSendCubit>().send
                : null,
          ),
          if ((state.context?.messages ?? const []).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spacing24),
            Text('Historico de comunicacao', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.spacing8),
            for (final message in state.context!.messages)
              _MessageHistoryTile(message: message),
          ],
        ],
      ),
    );
  }
}

class _MessageHistoryTile extends StatelessWidget {
  const _MessageHistoryTile({required this.message});
  final WhatsAppMessage message;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(_icon(message.status), semanticLabel: _label(message.status)),
    title: Text(message.templateName),
    subtitle: Text(message.failureReason ?? _label(message.status)),
  );

  String _label(WhatsAppDeliveryStatus status) => switch (status) {
    WhatsAppDeliveryStatus.sent => 'Enviado',
    WhatsAppDeliveryStatus.delivered => 'Entregue',
    WhatsAppDeliveryStatus.read => 'Lido',
    WhatsAppDeliveryStatus.failed => 'Falhou',
  };
  IconData _icon(WhatsAppDeliveryStatus status) => switch (status) {
    WhatsAppDeliveryStatus.sent => Icons.check,
    WhatsAppDeliveryStatus.delivered => Icons.done_all,
    WhatsAppDeliveryStatus.read => Icons.mark_chat_read_outlined,
    WhatsAppDeliveryStatus.failed => Icons.error_outline,
  };
}
