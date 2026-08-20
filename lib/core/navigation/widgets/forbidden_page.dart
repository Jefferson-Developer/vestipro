import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_route_paths.dart';

/// Generic "no permission" (403) route.
///
/// Reused by every feature until the Design System (EPIC-02) ships a
/// dedicated empty-state component for this case.
class ForbiddenPage extends StatelessWidget {
  const ForbiddenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sem permissão')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Você não tem permissão para acessar esta página.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(
                const AboutAppRoute(orgId: kPlaceholderOrganizationId).location,
              ),
              child: const Text('Voltar para o início'),
            ),
          ],
        ),
      ),
    );
  }
}
