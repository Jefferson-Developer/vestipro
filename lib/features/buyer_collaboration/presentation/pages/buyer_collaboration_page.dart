import 'package:flutter/material.dart';

import '../bloc/buyer_collaboration_cubit.dart';
import '../widgets/buyer_collaboration_panel.dart';

/// Full-screen destination for a `BuyerCollaborationSession` (TASK-211) —
/// reached from the buyer's customer-portal ([BuyerCollaborationViewerRole.buyer])
/// or, on Web/tablet, as an alternative to the seller's bottom-sheet entry
/// point ([BuyerCollaborationViewerRole.seller]). Just a [Scaffold] around
/// [BuyerCollaborationPanel] — every real behavior lives in the panel/Cubit
/// so both entry points share the exact same code.
class BuyerCollaborationPage extends StatelessWidget {
  const BuyerCollaborationPage({
    required this.organizationId,
    required this.sessionId,
    required this.role,
    required this.createCubit,
    this.onConvertRequested,
    super.key,
  });

  final String organizationId;
  final String sessionId;
  final BuyerCollaborationViewerRole role;
  final BuyerCollaborationCubit Function() createCubit;
  final Future<String?> Function()? onConvertRequested;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colaboração com comprador')),
      body: BuyerCollaborationPanel(
        organizationId: organizationId,
        sessionId: sessionId,
        role: role,
        createCubit: createCubit,
        onConvertRequested: onConvertRequested,
      ),
    );
  }
}
