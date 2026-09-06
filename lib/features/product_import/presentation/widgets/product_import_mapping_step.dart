import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/product_import_field.dart';
import '../bloc/product_import_bloc.dart';
import '../bloc/product_import_event.dart';
import '../bloc/product_import_state.dart';

/// Sentinel value for "não mapear esta coluna" inside the [AppDropdown]s
/// below — same convention as `CustomerImportMappingStep` (TASK-167).
const int _kUnmappedOption = -1;

/// Step 2 of the product-import wizard (TASK-168): maps every spreadsheet
/// column to a `Product`/`ProductVariant` field, selects the size grid this
/// entire run is validated against, chooses whether an unrecognized
/// categoria/coleção should be created automatically or rejected, and
/// optionally attaches an image package (matched by SKU/referência during
/// processing).
class ProductImportMappingStep extends StatelessWidget {
  const ProductImportMappingStep({super.key});

  Future<void> _pickImages(BuildContext context) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    final bytesByFileName = <String, Uint8List>{};
    for (final file in files) {
      bytesByFileName[file.name] = await file.readAsBytes();
    }
    if (!context.mounted) return;
    context.read<ProductImportBloc>().add(
      ProductImportImagesSelected(bytesByFileName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductImportBloc, ProductImportState>(
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
              onChanged: (value) => context.read<ProductImportBloc>().add(
                ProductImportHasHeaderRowChanged(value),
              ),
              label: 'A primeira linha da planilha é um cabeçalho',
            ),
            const SizedBox(height: AppSpacing.spacing16),
            _SizeGridSelector(state: state),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Mapeamento de colunas',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            for (final field in ProductImportField.values)
              if (field != ProductImportField.ignored)
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
                      context.read<ProductImportBloc>().add(
                        ProductImportMappingColumnChanged(
                          field: field,
                          column: selected == _kUnmappedOption
                              ? null
                              : selected,
                        ),
                      );
                    },
                  ),
                ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Categoria e coleção',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            AppCheckbox(
              value: state.createMissingCategories,
              onChanged: (value) => context.read<ProductImportBloc>().add(
                ProductImportCreateMissingCategoriesChanged(value),
              ),
              label:
                  'Criar automaticamente categorias não cadastradas '
                  '(caso contrário, a linha é rejeitada)',
            ),
            AppCheckbox(
              value: state.createMissingCollections,
              onChanged: (value) => context.read<ProductImportBloc>().add(
                ProductImportCreateMissingCollectionsChanged(value),
              ),
              label:
                  'Criar automaticamente coleções não cadastradas '
                  '(caso contrário, a linha é rejeitada)',
            ),
            Text(
              'Cor precisa já existir na paleta da organização — nunca é '
              'criada automaticamente pela importação.',
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Pacote de imagens (opcional)',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              'Selecione as imagens nomeadas com o SKU ou a referência do '
              'produto (ex.: "12345.jpg"). Uma imagem sem correspondência é '
              'reportada como órfã, sem travar a importação dos demais '
              'produtos.',
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            AppButton(
              label: state.imageBytesByFileName.isEmpty
                  ? 'Selecionar imagens'
                  : '${state.imageBytesByFileName.length} imagem(ns) selecionada(s)',
              variant: AppButtonVariant.secondary,
              leadingIcon: Icons.image_outlined,
              onPressed: () => _pickImages(context),
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

class _SizeGridSelector extends StatelessWidget {
  const _SizeGridSelector({required this.state});

  final ProductImportState state;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<String>(
      label: 'Grade de tamanho desta importação',
      closeSemanticLabel: 'Fechar seleção',
      options: state.sizeGridTemplates
          .map(
            (template) => AppDropdownOption<String>(
              value: template.id,
              label: template.name,
            ),
          )
          .toList(growable: false),
      selectedValues: state.selectedSizeGridTemplateId == null
          ? const <String>{}
          : <String>{state.selectedSizeGridTemplateId!},
      errorText: state.mappingFieldErrors['sizeGridTemplateId'],
      onChanged: (values) => context.read<ProductImportBloc>().add(
        ProductImportSizeGridTemplateSelected(
          values.isEmpty ? null : values.first,
        ),
      ),
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  const _TemplateSelector({required this.state});

  final ProductImportState state;

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
      onChanged: (values) => context.read<ProductImportBloc>().add(
        ProductImportTemplateSelected(values.isEmpty ? null : values.first),
      ),
    );
  }
}

class _SaveTemplateButton extends StatelessWidget {
  const _SaveTemplateButton({required this.state});

  final ProductImportState state;

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
    context.read<ProductImportBloc>().add(
      ProductImportTemplateSaveRequested(name),
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
