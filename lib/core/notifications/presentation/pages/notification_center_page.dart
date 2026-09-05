import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notification_center_bloc.dart';
import '../bloc/notification_center_event.dart';
import '../bloc/notification_center_state.dart';

/// The central de notificações internas (TASK-151): every alert the current
/// user received — originated from push (TASK-150) or from an internal
/// event with no push at all — listed newest first, filterable by
/// category, with an always-correct unread count and "marcar todas como
/// lidas".
///
/// Tapping a notification marks it read and resolves [onOpenDeepLink] with
/// its stored `deepLink` — this widget never imports `go_router` itself
/// (same "page takes a callback, composition root supplies `context.go`"
/// convention `SavedReportsPage`/`ReportBuilderPage` already set), so an
/// invalid/removed destination is entirely the router's own guard/
/// `NotFoundPage` concern, never something this page has to special-case.
class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({
    required this.organizationId,
    required this.userId,
    required this.createBloc,
    this.onOpenDeepLink,
    super.key,
  });

  final String organizationId;
  final String userId;
  final NotificationCenterBloc Function() createBloc;

  /// Called with a tapped notification's `deepLink` once it is non-blank.
  final ValueChanged<String>? onOpenDeepLink;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationCenterBloc>(
      create: (_) => createBloc()
        ..add(
          NotificationCenterStarted(
            organizationId: organizationId,
            userId: userId,
          ),
        ),
      child: _NotificationCenterScaffold(onOpenDeepLink: onOpenDeepLink),
    );
  }
}

class _NotificationCenterScaffold extends StatelessWidget {
  const _NotificationCenterScaffold({this.onOpenDeepLink});

  final ValueChanged<String>? onOpenDeepLink;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Notificações',
        actions: <Widget>[
          BlocBuilder<NotificationCenterBloc, NotificationCenterState>(
            buildWhen: (previous, current) =>
                previous.unreadCount != current.unreadCount ||
                previous.actionStatus != current.actionStatus,
            builder: (context, state) {
              return AppButton(
                label: 'Marcar todas como lidas',
                variant: AppButtonVariant.text,
                isLoading:
                    state.actionStatus ==
                    NotificationCenterActionStatus.processing,
                isDisabled: state.unreadCount == 0,
                onPressed: () => context.read<NotificationCenterBloc>().add(
                  const NotificationCenterMarkAllAsReadRequested(),
                ),
              );
            },
          ),
        ],
        content: _NotificationCenterContent(onOpenDeepLink: onOpenDeepLink),
      ),
    );
  }
}

class _NotificationCenterContent extends StatelessWidget {
  const _NotificationCenterContent({this.onOpenDeepLink});

  final ValueChanged<String>? onOpenDeepLink;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationCenterBloc, NotificationCenterState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus == NotificationCenterActionStatus.failure,
      listener: (context, state) {
        AppSnackbar.show(
          context,
          message:
              state.actionFailure?.message ??
              'Não foi possível marcar as notificações como lidas.',
          variant: AppSnackbarVariant.error,
        );
        context.read<NotificationCenterBloc>().add(
          const NotificationCenterActionDismissed(),
        );
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _CategoryFilterRow(categoryFilter: state.categoryFilter),
            const SizedBox(height: AppSpacing.spacing16),
            Expanded(child: _buildBody(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationCenterState state) {
    if (state.status == NotificationCenterLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar as notificações',
        message: state.failure?.message ?? 'Tente novamente em breve.',
        retryLabel: 'Tentar novamente',
        onRetry: () => context.read<NotificationCenterBloc>().add(
          const NotificationCenterRetried(),
        ),
      );
    }
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visible = state.visibleNotifications;
    if (visible.isEmpty) {
      return AppEmptyState(
        icon: Icons.notifications_none,
        title: state.categoryFilter == null
            ? 'Nenhuma notificação por aqui'
            : 'Nenhuma notificação nesta categoria',
        description:
            'Alertas de metas, pedidos, oportunidades e follow-ups '
            'aparecem aqui assim que existirem.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationCenterBloc>().add(
          const NotificationCenterRefreshed(),
        );
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visible.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.spacing8),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing8),
              child: AppPagination(
                hasMore: state.hasMore,
                onLoadMore: () => context.read<NotificationCenterBloc>().add(
                  const NotificationCenterMoreRequested(),
                ),
              ),
            );
          }

          final notification = visible[index];
          return AppNotificationListTile(
            key: Key('notification-${notification.id}'),
            title: notification.title,
            body: notification.body,
            category: _tileCategory(notification.category),
            timestampLabel: _timestampLabel(notification.createdAt),
            isUnread: notification.readAt == null,
            isCritical:
                notification.priority == AppNotificationPriority.critical,
            onTap: () => _handleTap(context, notification),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, AppNotification notification) {
    context.read<NotificationCenterBloc>().add(
      NotificationCenterNotificationTapped(notification.id),
    );

    final deepLink = notification.deepLink.trim();
    if (deepLink.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Este item não está mais disponível.',
        variant: AppSnackbarVariant.info,
      );
      return;
    }
    onOpenDeepLink?.call(deepLink);
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({required this.categoryFilter});

  final AppNotificationCategory? categoryFilter;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.spacing8,
      runSpacing: AppSpacing.spacing8,
      children: <Widget>[
        AppFilterChip(
          label: 'Todas',
          selected: categoryFilter == null,
          onSelected: (_) => context.read<NotificationCenterBloc>().add(
            const NotificationCenterCategoryFilterChanged(null),
          ),
        ),
        for (final category in AppNotificationCategory.values)
          AppFilterChip(
            label: _categoryLabel(category),
            leadingIcon: _categoryIcon(category),
            selected: categoryFilter == category,
            onSelected: (_) => context.read<NotificationCenterBloc>().add(
              NotificationCenterCategoryFilterChanged(category),
            ),
          ),
      ],
    );
  }
}

AppNotificationTileCategory _tileCategory(AppNotificationCategory category) {
  return switch (category) {
    AppNotificationCategory.crm => AppNotificationTileCategory.crm,
    AppNotificationCategory.commercial =>
      AppNotificationTileCategory.commercial,
    AppNotificationCategory.system => AppNotificationTileCategory.system,
  };
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

String _timestampLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
