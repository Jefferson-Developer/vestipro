import 'dart:async';

import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_icon_button.dart';
import '../buttons/app_button.dart' show AppButtonVariant;
import 'app_input_decoration.dart';

/// The search field reused by every "find client/product/reference" flow.
///
/// Debounces [onSearch] by [debounceDuration] (default
/// [AppDurations.standard]) so the caller does not query
/// Firestore/Drift/cache on every keystroke, while [onChanged] — if
/// provided — still fires immediately for local, cheap UI feedback (e.g.
/// echoing the typed text). A clear ("x") button appears once there is
/// text and resets the field, immediately re-triggering [onSearch] with an
/// empty string (never debounced, so "clear" always feels instant).
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onSearch,
    this.controller,
    this.hintText,
    this.onChanged,
    this.debounceDuration = AppDurations.standard,
    this.isDisabled = false,
    this.isSearching = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Called [debounceDuration] after the user stops typing, and immediately
  /// (not debounced) when the field is cleared.
  final ValueChanged<String> onSearch;
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final Duration debounceDuration;
  final bool isDisabled;

  /// Shows a spinner in place of the search icon while a search request is
  /// in flight (state owned by the caller's BLoC, never by this widget).
  final bool isSearching;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_handleTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTextChanged() {
    final text = _controller.text;
    if (_hasText != text.isNotEmpty) {
      setState(() => _hasText = text.isNotEmpty);
    }
    widget.onChanged?.call(text);
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () => widget.onSearch(text));
  }

  void _handleClear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: widget.semanticLabel ?? widget.hintText ?? 'Buscar',
      textField: true,
      enabled: !widget.isDisabled,
      child: TextField(
        controller: _controller,
        enabled: !widget.isDisabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyLarge.copyWith(color: colors.onSurface),
        onSubmitted: widget.onSearch,
        decoration: buildAppInputDecoration(
          colors: colors,
          label: null,
          hintText: widget.hintText,
          helperText: null,
          errorText: null,
          isRequired: false,
          prefixIcon: widget.isSearching
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacing12),
                  child: SizedBox(
                    width: AppIconSizes.md,
                    height: AppIconSizes.md,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                )
              : Icon(
                  Icons.search,
                  size: AppIconSizes.lg,
                  color: colors.outline,
                ),
          suffixIcon: _hasText
              ? AppIconButton(
                  icon: Icons.close,
                  semanticLabel: 'Limpar busca',
                  variant: AppButtonVariant.text,
                  onPressed: widget.isDisabled ? null : _handleClear,
                )
              : null,
        ),
      ),
    );
  }
}
