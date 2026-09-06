import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/customer_import_field.dart';
import '../bloc/customer_import_bloc.dart';
import '../bloc/customer_import_event.dart';
import '../bloc/customer_import_state.dart';

/// Sentinel value for "não mapear esta coluna" inside the [AppDropdown]s
/// below — `AppDropdown<int>` cannot carry a `null` option value itself, so
/// column indexes are shifted by one and `0` means unmapped.
const int _kUnmappedOption = -1;

/// Step 2 of the customer-import wizard (TASK-167): maps every spreadsheet
/// column (from `CustomerImportPreview.headers`) to a `Customer` field,
/// optionally starting from a saved template, and shows a small preview
/// table of the first rows so the gestor can confirm the mapping visually
/// before submitting.
class CustomerImportMappingStep extends StatelessWidget {
  const CustomerImportMappingStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerImportBloc, CustomerImportState>(
      builder: (context, state) {
        final preview = state.preview;
        if (preview == null) return const SizedBox.shrink();

        final columnOptions = <AppDropdownOption<int>>[
          const AppDropdownOption<int>(
            value: _kUnmappedOption,
            label: 'Não mapear',
          ),
          for (var index = 0; index < preview.headers.length; index += 1)
            AppDropdownOption<int>(
              value: index,
              label: preview.headers[index].isEmpty
                  ? 'Coluna ${index + 1}'
                  : preview.headers[index],
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TemplateSelector(state: state),
            const SizedBox(height: AppSpacing.spacing16),
            AppCheckbox(
              value: state.hasHeaderRow,
              onChanged: (value) => context.read<CustomerImportBloc>().add(
                CustomerImportHasHeaderRowChanged(value),
              ),
              label: 'A primeira linha da planilha é um cabeçalho',
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Mapeamento de colunas',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            for (final field in CustomerImportField.values)
              if (field != CustomerImportField.ignored)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                  child: AppDropdown<int>(
                    label: field.label,
                    closeSemanticLabel: 'Fechar seleção',
                    options: columnOptions,
                    selectedValues: <int>{
                      state.columnByField[field] ?? _kUnmappedOption,
                    },
                    errorText: state.mappingFieldErrors[field.code],
                    onChanged: (values) {
                      final selected = values.isEmpty
                          ? _kUnmappedOption
                          : values.first;
                      context.read<CustomerImportBloc>().add(
                        CustomerImportMappingColumnChanged(
                          field: field,
                          column: selected == _kUnmappedOption
                              ? null
                              : selected,
                        ),
                      );
                    },
                  ),
                ),
            if (state.mappingFieldErrors.containsKey('name'))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                child: Text(
                  state.mappingFieldErrors['name']!,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.spacing8),
            _SaveTemplateButton(state: state),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Prévia (${preview.sampleRows.length} de '
              '${preview.totalRowsHint ?? preview.sampleRows.length} linhas)',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: preview.headers
                    .map((header) => DataColumn(label: Text(header)))
                    .toList(growable: false),
                rows: preview.sampleRows
                    .map(
                      (row) => DataRow(
                        cells: row
                            .map((value) => DataCell(Text(value)))
                            .toList(growable: false),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  const _TemplateSelector({required this.state});

  final CustomerImportState state;

  @override
  Widget build(BuildContext context) {
    if (state.templates.isEmpty) return const SizedBox.shrink();

    return AppDropdown<String>(
      label: 'Usar template de mapeamento salvo',
      closeSemanticLabel: 'Fechar seleção',
      options: state.templates
          .map(
            (template) => AppDropdownOption<String>(
              value: template.id,
              label: template.name,
            ),
          )
          .toList(growable: false),
      selectedValues: state.selectedTemplateId == null
          ? const <String>{}
          : <String>{state.selectedTemplateId!},
      onChanged: (values) => context.read<CustomerImportBloc>().add(
        CustomerImportTemplateSelected(values.isEmpty ? null : values.first),
      ),
    );
  }
}

class _SaveTemplateButton extends StatelessWidget {
  const _SaveTemplateButton({required this.state});

  final CustomerImportState state;

  Future<void> _promptAndSave(BuildContext context) async {
    final controller = TextEditingController(
      text: state.templates
          .where((template) => template.id == state.selectedTemplateId)
          .map((template) => template.name)
          .firstOrNull,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salvar template de mapeamento'),
        content: AppTextField(
          controller: controller,
          label: 'Nome do template',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    context.read<CustomerImportBloc>().add(
      CustomerImportTemplateSaveRequested(name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppButton(
        label: 'Salvar como template',
        variant: AppButtonVariant.secondary,
        leadingIcon: Icons.save_outlined,
        onPressed: () => _promptAndSave(context),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
