import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_route_paths.dart';

/// Generic "page not found" (404) route.
///
/// Reused by every feature until the Design System (EPIC-02) ships a
/// dedicated empty-state component for this case.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não encontramos o que você procurava.'),
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
