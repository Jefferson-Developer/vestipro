import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../buttons/app_icon_button.dart';

/// The notification-center entry point every page's `AppAdminPageLayout`/
/// `AppBar` actions can add: a bell [AppIconButton] with an unread-count
/// badge, reusing [AppIconButton] itself (per TASK-151's "reaproveitar
/// componentes existentes, não criar componente isolado") plus Flutter's
/// own `Badge` for the counter overlay.
///
/// ```dart
/// AppAdminPageLayout(
///   title: 'Painel',
///   actions: [
///     AppNotificationBellButton(
///       unreadCount: state.unreadCount,
///       onPressed: () => context.go(NotificationCenterRoute(orgId: orgId).location),
///     ),
///   ],
///   content: ...,
/// )
/// ```
class AppNotificationBellButton extends StatelessWidget {
  const AppNotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
    this.semanticLabel = 'Notificações',
  });

  final int unreadCount;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasUnread = unreadCount > 0;
    final label = hasUnread
        ? '$semanticLabel ($unreadCount não lida${unreadCount == 1 ? '' : 's'})'
        : semanticLabel;

    return Badge(
      isLabelVisible: hasUnread,
      backgroundColor: colors.error,
      textColor: colors.onPrimary,
      label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
      child: AppIconButton(
        icon: Icons.notifications_outlined,
        semanticLabel: label,
        onPressed: onPressed,
      ),
    );
  }
}
