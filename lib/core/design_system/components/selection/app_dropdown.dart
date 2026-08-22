import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';
import '../inputs/app_input_decoration.dart';

/// A single selectable value inside an [AppDropdown].
@immutable
class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.enabled = true,
  });

  final T value;
  final String label;

  /// Disabled options are shown (never hidden) but cannot be selected —
  /// e.g. a blocked client or an out-of-stock reference in a picker.
  final bool enabled;
}

/// The single/multiple select field reused by every "choose a client/
/// product/status/rep" flow. Opens a searchable modal so long lists (a
/// product catalog, a client base) stay usable without scrolling a huge
/// inline menu.
///
/// Purely presentational: [options] and [selectedValues] are supplied by
/// the caller, and [onChanged] is only invoked with the user's final
/// selection — this widget does not fetch, filter server-side or persist
/// anything itself (the in-dialog text filter only narrows the already
/// provided [options] client-side).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    required this.closeSemanticLabel,
    this.multiple = false,
    this.label,
    this.hintText,
    this.errorText,
    this.isRequired = false,
    this.isDisabled = false,
    this.enableSearch = true,
    this.searchHintText,
    this.noResultsLabel,
    this.semanticLabel,
  });

  final List<AppDropdownOption<T>> options;
  final Set<T> selectedValues;

  /// Called once with the user's final selection when the picker is closed
  /// with a non-cancelled result. Never called while the picker is open.
  final ValueChanged<Set<T>> onChanged;

  /// Accessibility label for the picker's close button (there is no visible
  /// text on that icon-only control).
  final String closeSemanticLabel;

  final bool multiple;
  final String? label;
  final String? hintText;
  final String? errorText;
  final bool isRequired;
  final bool isDisabled;
  final bool enableSearch;
  final String? searchHintText;

  /// Shown instead of the list when the in-dialog search has no matches.
  /// Left blank (no caption) if not provided.
  final String? noResultsLabel;
  final String? semanticLabel;

  String get _displayText {
    if (selectedValues.isEmpty) {
      return '';
    }
    return options
        .where((option) => selectedValues.contains(option.value))
        .map((option) => option.label)
        .join(', ');
  }

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<Set<T>>(
      context: context,
      builder: (dialogContext) => _AppDropdownDialog<T>(
        options: options,
        initialSelected: selectedValues,
        multiple: multiple,
        closeSemanticLabel: closeSemanticLabel,
        title: label,
        enableSearch: enableSearch,
        searchHintText: searchHintText,
        noResultsLabel: noResultsLabel,
      ),
    );
    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayText = _displayText;

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: !isDisabled,
      child: InkWell(
        onTap: isDisabled ? null : () => _open(context),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        child: InputDecorator(
          decoration: buildAppInputDecoration(
            colors: colors,
            label: label,
            hintText: hintText,
            helperText: null,
            errorText: errorText,
            isRequired: isRequired,
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: isDisabled ? colors.disabled : colors.outline,
            ),
          ),
          isEmpty: displayText.isEmpty,
          child: Text(
            displayText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: isDisabled ? colors.disabled : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDropdownDialog<T> extends StatefulWidget {
  const _AppDropdownDialog({
    required this.options,
    required this.initialSelected,
    required this.multiple,
    required this.closeSemanticLabel,
    this.title,
    this.enableSearch = true,
    this.searchHintText,
    this.noResultsLabel,
  });

  final List<AppDropdownOption<T>> options;
  final Set<T> initialSelected;
  final bool multiple;
  final String closeSemanticLabel;
  final String? title;
  final bool enableSearch;
  final String? searchHintText;
  final String? noResultsLabel;

  @override
  State<_AppDropdownDialog<T>> createState() => _AppDropdownDialogState<T>();
}

class _AppDropdownDialogState<T> extends State<_AppDropdownDialog<T>> {
  late Set<T> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.of(widget.initialSelected);
  }

  List<AppDropdownOption<T>> get _filteredOptions {
    if (_query.isEmpty) {
      return widget.options;
    }
    final query = _query.toLowerCase();
    return widget.options
        .where((option) => option.label.toLowerCase().contains(query))
        .toList();
  }

  void _handleOptionTap(AppDropdownOption<T> option) {
    if (!option.enabled) {
      return;
    }
    if (widget.multiple) {
      setState(() {
        if (_selected.contains(option.value)) {
          _selected.remove(option.value);
        } else {
          _selected.add(option.value);
        }
      });
    } else {
      Navigator.of(context).pop(<T>{option.value});
    }
  }

  Widget _buildOptionList(
    AppColors colors,
    List<AppDropdownOption<T>> filtered,
  ) {
    final list = ListView.separated(
      shrinkWrap: true,
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spacing4),
      itemBuilder: (context, index) {
        final option = filtered[index];
        final textColor = option.enabled ? colors.onSurface : colors.disabled;
        final label = Text(
          option.label,
          style: AppTypography.bodyMedium.copyWith(color: textColor),
        );

        if (widget.multiple) {
          return CheckboxListTile(
            value: _selected.contains(option.value),
            onChanged: option.enabled ? (_) => _handleOptionTap(option) : null,
            title: label,
            activeColor: colors.primary,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }

        return RadioListTile<T>(
          value: option.value,
          enabled: option.enabled,
          title: label,
          activeColor: colors.primary,
          contentPadding: EdgeInsets.zero,
        );
      },
    );

    if (widget.multiple) {
      return list;
    }

    return RadioGroup<T>(
      groupValue: _selected.isEmpty ? null : _selected.first,
      onChanged: (value) {
        if (value == null) {
          return;
        }
        final option = filtered.firstWhere(
          (candidate) => candidate.value == value,
        );
        _handleOptionTap(option);
      },
      child: list,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filteredOptions;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  AppIconButton(
                    icon: Icons.close,
                    semanticLabel: widget.closeSemanticLabel,
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(widget.multiple ? _selected : null),
                  ),
                ],
              ),
              if (widget.enableSearch) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing8),
                TextField(
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                  decoration: buildAppInputDecoration(
                    colors: colors,
                    label: null,
                    hintText: widget.searchHintText,
                    helperText: null,
                    errorText: null,
                    isRequired: false,
                    prefixIcon: Icon(
                      Icons.search,
                      size: AppIconSizes.lg,
                      color: colors.outline,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.spacing8),
              Flexible(
                child: filtered.isEmpty
                    ? (widget.noResultsLabel == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.spacing24,
                              ),
                              child: Text(
                                widget.noResultsLabel!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: colors.outline,
                                ),
                              ),
                            ))
                    : _buildOptionList(colors, filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
