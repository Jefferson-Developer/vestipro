import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/catalog_share.dart';
import '../../domain/entities/catalog_share_item.dart';
import '../../domain/value_objects/catalog_share_scope.dart';
import '../bloc/catalog_share_sheet_bloc.dart';
import '../bloc/catalog_share_sheet_event.dart';
import '../bloc/catalog_share_sheet_state.dart';

/// Base URL every shareable catalog link is built from — same "hardcoded
/// today, no dedicated config surface yet" precedent already accepted by
/// `InviteUserPage`'s own invite link
/// (`lib/features/invites/presentation/pages/invite_user_page.dart`).
const String kCatalogShareBaseUrl = 'https://app.vestipro.com.br/share';

/// Opens the "Compartilhar" bottom sheet (TASK-081, EPIC-10) from the
/// catalog grid/detail: creates the share as soon as it opens and shows the
/// resulting link, ready to copy and send through whatever channel the
/// vendor picks (WhatsApp, e-mail, ...) — see this widget's own doc for why
/// that hand-off stops at "copy the link" rather than the OS share sheet.
abstract final class CatalogShareSheet {
  const CatalogShareSheet._();

  static Future<void> show({
    required BuildContext context,
    required CatalogShareSheetBloc Function() createBloc,
    required String organizationId,
    required CatalogShareScope scope,
    required List<CatalogShareItem> items,
    String? collectionId,
    String? collectionName,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      title: 'Compartilhar',
      builder: (_) => BlocProvider<CatalogShareSheetBloc>(
        create: (_) => createBloc()
          ..add(
            CatalogShareSheetStarted(
              organizationId: organizationId,
              scope: scope,
              items: items,
              collectionId: collectionId,
              collectionName: collectionName,
            ),
          ),
        child: const _CatalogShareSheetContent(),
      ),
    );
  }
}

class _CatalogShareSheetContent extends StatelessWidget {
  const _CatalogShareSheetContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogShareSheetBloc, CatalogShareSheetState>(
      builder: (context, state) {
        return switch (state.status) {
          CatalogShareSheetStatus.initial ||
          CatalogShareSheetStatus.submitting => const _LoadingContent(),
          CatalogShareSheetStatus.failure => _FailureContent(state: state),
          CatalogShareSheetStatus.success => _SuccessContent(state: state),
        };
      },
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _FailureContent extends StatelessWidget {
  const _FailureContent({required this.state});

  final CatalogShareSheetState state;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Não foi possível gerar o link',
      message: state.failure?.message ?? 'Tente novamente em breve.',
      retryLabel: 'Tentar novamente',
      onRetry: () => context.read<CatalogShareSheetBloc>().add(
        const CatalogShareSheetRetried(),
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.state});

  final CatalogShareSheetState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final issued = state.issuedShare;
    if (issued == null) return const SizedBox.shrink();
    final share = state.currentShare ?? issued.share;
    final link = '$kCatalogShareBaseUrl/${issued.token}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _titleFor(share),
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
          ),
          child: SelectableText(
            link,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Copiar link',
          leadingIcon: Icons.copy_outlined,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (context.mounted) {
              AppSnackbar.show(
                context,
                message: 'Link copiado.',
                variant: AppSnackbarVariant.success,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Row(
          children: <Widget>[
            Icon(
              share.openCount > 0
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: AppIconSizes.sm,
              color: colors.outline,
            ),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Text(
                _openStatusLabel(share),
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            ),
            if (state.isRefreshing)
              const SizedBox(
                width: AppSpacing.spacing16,
                height: AppSpacing.spacing16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              AppIconButton(
                icon: Icons.refresh,
                semanticLabel: 'Atualizar status de visualização',
                variant: AppButtonVariant.text,
                onPressed: () => context.read<CatalogShareSheetBloc>().add(
                  const CatalogShareSheetRefreshRequested(),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _titleFor(CatalogShare share) {
    return switch (share.scope) {
      CatalogShareScope.product => 'Link do produto pronto para enviar.',
      CatalogShareScope.selection =>
        'Link com ${share.items.length} produtos pronto para enviar.',
      CatalogShareScope.collection =>
        'Link da coleção "${share.collectionName ?? ''}" pronto para enviar.',
    };
  }

  String _openStatusLabel(CatalogShare share) {
    if (share.openCount <= 0) return 'Ainda não visualizado pelo destinatário.';
    final lastOpenedAt = share.lastOpenedAt;
    final when = lastOpenedAt == null
        ? ''
        : ' (última vez em ${_formatDateTime(lastOpenedAt)})';
    final times = share.openCount == 1 ? '1 vez' : '${share.openCount} vezes';
    return 'Visualizado $times$when.';
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
