import 'dart:async';

import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The shape a skeleton placeholder mimics.
enum AppSkeletonShape {
  /// A single line of text (e.g. a list-item title placeholder).
  line,

  /// A generic rectangular block (e.g. a thumbnail/avatar placeholder).
  block,

  /// A full card-sized placeholder (e.g. a product/client card while its
  /// data loads).
  card,
}

/// A shimmering placeholder shown while real content is loading. Never
/// carries data/business logic — the caller decides *when* to show it
/// (typically the `loading` branch of a BLoC state).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.shape = AppSkeletonShape.line,
    this.width,
    this.height,
    this.radius,
  });

  /// A single line placeholder, defaulting to a `bodyMedium`-sized row.
  const AppSkeleton.line({super.key, this.width, double? height})
    : shape = AppSkeletonShape.line,
      height = height ?? AppSpacing.spacing16,
      radius = AppRadius.radius4;

  /// A rectangular block placeholder (thumbnail, avatar, chart bar).
  const AppSkeleton.block({
    super.key,
    this.width,
    double? height,
    double? radius,
  }) : shape = AppSkeletonShape.block,
       height = height ?? AppSpacing.spacing48,
       radius = radius ?? AppRadius.radius8;

  /// A full card-sized placeholder.
  const AppSkeleton.card({super.key, this.width, double? height})
    : shape = AppSkeletonShape.card,
      height = height ?? AppSpacing.spacing64 * 2,
      radius = AppRadius.radius16;

  final AppSkeletonShape shape;
  final double? width;
  final double? height;
  final double? radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppDurations.slow);
    unawaited(_controller.repeat(reverse: true));
    _opacity = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: 'Carregando',
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) {
          return Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(
                  widget.radius ?? AppRadius.radius8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
