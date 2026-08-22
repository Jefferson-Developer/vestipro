import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';

/// The quantity increment/decrement control every quantity-entry screen
/// reuses: catalog product detail, order line, [AppSizeGrid] cell and any
/// other "how many units" prompt.
///
/// Fully controlled — [quantity] always comes from the caller's BLoC/domain
/// state and [onChanged] only reports the user's intended next value; this
/// widget never computes stock, price or order totals itself, and never
/// commits a value below [minQuantity] or above [maxQuantity]. Direct
/// keyboard input is preserved verbatim while the field has focus, even if
/// [quantity] is rebuilt from the outside (e.g. a sync/connectivity status
/// change elsewhere on the screen) — it is only reconciled once the field
/// loses focus or the user submits, so a value being typed is never
/// overwritten mid-keystroke.
///
/// ```dart
/// AppQuantityStepper(
///   quantity: state.quantity,
///   minQuantity: 0,
///   maxQuantity: state.availableStock,
///   onChanged: (next) => bloc.add(QuantityChanged(next)),
/// )
/// ```
class AppQuantityStepper extends StatefulWidget {
  const AppQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 0,
    this.maxQuantity,
    this.step = 1,
    this.isDisabled = false,
    this.decrementSemanticLabel = 'Diminuir quantidade',
    this.incrementSemanticLabel = 'Aumentar quantidade',
    this.semanticLabel,
  });

  final int quantity;

  /// Called with the next, already-clamped quantity whenever the user taps
  /// +/- or commits a directly-typed value. Never called with a value
  /// outside `[minQuantity, maxQuantity]`, and never called at all if the
  /// committed value equals [quantity].
  final ValueChanged<int> onChanged;

  final int minQuantity;

  /// The maximum acceptable quantity (e.g. available stock). `null` means
  /// no upper bound is enforced by this widget — the caller's domain layer
  /// remains the source of truth for stock/availability limits.
  final int? maxQuantity;

  /// How much +/- moves [quantity] per tap.
  final int step;

  final bool isDisabled;
  final String decrementSemanticLabel;
  final String incrementSemanticLabel;

  /// Overrides the accessibility announcement for the current value. Falls
  /// back to `"Quantidade: N"`.
  final String? semanticLabel;

  @override
  State<AppQuantityStepper> createState() => _AppQuantityStepperState();
}

class _AppQuantityStepperState extends State<AppQuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.quantity != widget.quantity) {
      _controller.text = '${widget.quantity}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit(_controller.text);
    }
  }

  int _clamp(int value) {
    var result = value < widget.minQuantity ? widget.minQuantity : value;
    final maxQuantity = widget.maxQuantity;
    if (maxQuantity != null && result > maxQuantity) {
      result = maxQuantity;
    }
    return result;
  }

  void _commit(String rawValue) {
    final parsed = int.tryParse(rawValue) ?? widget.minQuantity;
    final clamped = _clamp(parsed);
    _controller.text = '$clamped';
    if (clamped != widget.quantity) {
      widget.onChanged(clamped);
    }
  }

  void _decrement() {
    if (widget.isDisabled) {
      return;
    }
    _commit('${widget.quantity - widget.step}');
  }

  void _increment() {
    if (widget.isDisabled) {
      return;
    }
    _commit('${widget.quantity + widget.step}');
  }

  bool get _canDecrement =>
      !widget.isDisabled && widget.quantity > widget.minQuantity;

  bool get _canIncrement =>
      !widget.isDisabled &&
      (widget.maxQuantity == null || widget.quantity < widget.maxQuantity!);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: widget.semanticLabel ?? 'Quantidade: ${widget.quantity}',
      container: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: Icons.remove,
            semanticLabel: widget.decrementSemanticLabel,
            variant: AppButtonVariant.secondary,
            isDisabled: !_canDecrement,
            onPressed: _canDecrement ? _decrement : null,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          SizedBox(
            width: AppSpacing.spacing48,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !widget.isDisabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: _commit,
              style: AppTypography.bodyLarge.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spacing12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                  borderSide: BorderSide(
                    color: colors.outline.withValues(alpha: 0.32),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                  borderSide: BorderSide(
                    color: colors.outline.withValues(alpha: 0.32),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                  borderSide: BorderSide(color: colors.primary),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                  borderSide: BorderSide(color: colors.disabled),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          AppIconButton(
            icon: Icons.add,
            semanticLabel: widget.incrementSemanticLabel,
            variant: AppButtonVariant.secondary,
            isDisabled: !_canIncrement,
            onPressed: _canIncrement ? _increment : null,
          ),
        ],
      ),
    );
  }
}
