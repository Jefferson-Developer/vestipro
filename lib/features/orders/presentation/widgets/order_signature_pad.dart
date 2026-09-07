import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/design_system/design_system.dart';

/// A single continuous stroke drawn on [OrderSignaturePad] — one entry per
/// finger-down..finger-up gesture, each holding every point sampled along
/// the way. Kept as plain [Offset]s (never re-hydrated into a vector format
/// a future external e-signature provider might expect) — this task only
/// needs a raster PNG capture (`exportPng`), never the stroke data itself
/// (see `ExternalESignatureProviderGateway`'s own docs for that extension
/// point).
typedef OrderSignatureStroke = List<Offset>;

/// Manuscript signature capture canvas (EPIC-13, TASK-180) — the "desenho em
/// tela" mechanism `tasks.md` asks for as the default/standard electronic
/// signature method (see the CONCLUIDA doc's own "validade jurídica" section
/// for why this is enough for VestiPro's own commercial process today).
///
/// Purely presentational: never touches Firestore/Storage/Drift itself —
/// [OrderSignatureCubit] is the one that turns [exportPng]'s bytes into a
/// persisted `OrderSignature`. Exposes [hasStrokes]/[clear]/[exportPng]
/// through its [State] via [key], the same "caller drives it through a
/// `GlobalKey`" shape already used by a handful of other stateful,
/// non-Bloc-driven widgets in this codebase.
class OrderSignaturePad extends StatefulWidget {
  const OrderSignaturePad({super.key});

  @override
  State<OrderSignaturePad> createState() => OrderSignaturePadState();
}

class OrderSignaturePadState extends State<OrderSignaturePad> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<OrderSignatureStroke> _strokes = <OrderSignatureStroke>[];

  bool get hasStrokes => _strokes.any((stroke) => stroke.length > 1);

  void clear() {
    setState(_strokes.clear);
  }

  /// Rasterizes every stroke drawn so far into PNG bytes, or `null` when
  /// nothing was drawn yet (a caller must check [hasStrokes] first — this
  /// never throws for an empty canvas, it simply has nothing useful to
  /// return).
  Future<Uint8List?> exportPng() async {
    if (!hasStrokes) return null;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    // `pixelRatio: 3` keeps the exported signature legible on the PDF
    // comprovante regardless of the capturing device's own screen density.
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _strokes.add(<Offset>[details.localPosition]);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _strokes.last.add(details.localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Área para desenhar a assinatura',
      child: RepaintBoundary(
        key: _boundaryKey,
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
          ),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            child: CustomPaint(
              painter: _SignaturePainter(strokes: _strokes),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes});

  final List<OrderSignatureStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var index = 0; index < stroke.length - 1; index++) {
        canvas.drawLine(stroke[index], stroke[index + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return !identical(oldDelegate.strokes, strokes);
  }
}
