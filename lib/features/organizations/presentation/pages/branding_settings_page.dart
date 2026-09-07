import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../cubit/branding_settings_cubit.dart';
import '../cubit/branding_settings_state.dart';

/// Admin screen for the organization's catalog white-label branding
/// (TASK-179, EPIC-25): logo and primary color applied to every
/// customer-facing catalog surface (today, the catalog share public link,
/// TASK-081; in the future, the customer B2B portal, TASK-182) — always the
/// *same* Design System components the vendor's own catalog already uses,
/// never a duplicated screen per organization.
///
/// Gated behind [Capability.organizationSettingsManage] — the same
/// capability that already governs the rest of `OrganizationSettings`
/// (currency, positivação rule, etc., TASK-117), only ever granted to
/// OWNER/ADMIN.
class BrandingSettingsPage extends StatelessWidget {
  const BrandingSettingsPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final BrandingSettingsCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.organizationSettingsManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<BrandingSettingsCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(organizationId: organizationId, updatedBy: userId),
            );
            return cubit;
          },
          child: const _BrandingSettingsView(),
        );
      },
    );
  }
}

class _BrandingSettingsView extends StatefulWidget {
  const _BrandingSettingsView();

  @override
  State<_BrandingSettingsView> createState() => _BrandingSettingsViewState();
}

class _BrandingSettingsViewState extends State<_BrandingSettingsView> {
  final _logoUrlController = TextEditingController();
  final _primaryColorHexController = TextEditingController();

  @override
  void dispose() {
    _logoUrlController.dispose();
    _primaryColorHexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BrandingSettingsCubit, BrandingSettingsState>(
      listenWhen: (previous, current) =>
          previous.logoUrlInput != current.logoUrlInput ||
          previous.primaryColorHexInput != current.primaryColorHexInput ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (_logoUrlController.text != state.logoUrlInput) {
          _logoUrlController.text = state.logoUrlInput;
        }
        if (_primaryColorHexController.text != state.primaryColorHexInput) {
          _primaryColorHexController.text = state.primaryColorHexInput;
        }
        if (state.saveStatus == BrandingSettingsSaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Marca do catálogo salva com sucesso.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == BrandingSettingsSaveStatus.failure &&
            state.failureMessage != null &&
            state.fieldErrors.isEmpty) {
          AppSnackbar.show(
            context,
            message: state.failureMessage!,
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        if (_logoUrlController.text != state.logoUrlInput) {
          _logoUrlController.text = state.logoUrlInput;
        }
        if (_primaryColorHexController.text != state.primaryColorHexInput) {
          _primaryColorHexController.text = state.primaryColorHexInput;
        }
        final cubit = context.read<BrandingSettingsCubit>();

        if (state.loadStatus == BrandingSettingsLoadStatus.loading ||
            state.loadStatus == BrandingSettingsLoadStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.loadStatus == BrandingSettingsLoadStatus.failure) {
          return Scaffold(
            body: AppErrorState(
              title: 'Não foi possível carregar a configuração de marca',
              message: state.failureMessage ?? 'Tente novamente em breve.',
            ),
          );
        }

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Marca do catálogo (white-label)',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Personalize o logo e a cor principal do catálogo '
                    'exibido a clientes finais. A pré-visualização abaixo '
                    'mostra exatamente como o catálogo ficará antes de '
                    'salvar.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppTextField(
                    controller: _logoUrlController,
                    label: 'URL do logo (opcional)',
                    semanticLabel: 'URL do logo do catálogo',
                    hintText: 'https://...',
                    errorText: state.fieldErrors['brandingLogoUrl'],
                    onChanged: (value) =>
                        cubit.updateDraft(logoUrlInput: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppTextField(
                    controller: _primaryColorHexController,
                    label: 'Cor principal (opcional)',
                    semanticLabel: 'Cor principal do catálogo',
                    hintText: '#1F5364',
                    errorText: state.fieldErrors['brandingPrimaryColorHex'],
                    onChanged: (value) =>
                        cubit.updateDraft(primaryColorHexInput: value),
                  ),
                  if (state.usesContrastFallback) ...<Widget>[
                    const SizedBox(height: AppSpacing.spacing8),
                    _ContrastFallbackNotice(),
                  ],
                  const SizedBox(height: AppSpacing.spacing24),
                  Text(
                    'Pré-visualização do catálogo',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  _BrandedCatalogPreview(
                    logoUrl: state.logoUrlInput.trim(),
                    primaryColorHex: state.primaryColorHexInput.trim(),
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Salvar marca',
                      leadingIcon: Icons.save_outlined,
                      isLoading:
                          state.saveStatus ==
                          BrandingSettingsSaveStatus.submitting,
                      onPressed: state.isBusy ? null : cubit.submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Never blocks saving — the Design System already applies a safe
/// accessibility fallback automatically (`AppBrandTheme
/// .needsContrastFallback`); this is purely informational, so the
/// organization understands *why* the preview's text color may differ from
/// what they typed.
class _ContrastFallbackNotice extends StatelessWidget {
  const _ContrastFallbackNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.info_outline, size: AppIconSizes.sm, color: colors.warning),
        const SizedBox(width: AppSpacing.spacing4),
        Expanded(
          child: Text(
            'Esta cor não atinge o contraste mínimo de acessibilidade. Um '
            'ajuste automático de cor de texto será aplicado para manter o '
            'catálogo legível.',
            style: AppTypography.bodySmall.copyWith(color: colors.warning),
          ),
        ),
      ],
    );
  }
}

/// Renders the exact same catalog components a customer sees
/// (`AppProductGrid`/`AppProductCard`) with a handful of sample products,
/// wrapped in the branded [ThemeData] `AppBrandTheme.resolveTheme` derives
/// from the draft input as the organization types it — never waiting for a
/// save, and never a second, catalog-specific preview widget tree.
class _BrandedCatalogPreview extends StatelessWidget {
  const _BrandedCatalogPreview({
    required this.logoUrl,
    required this.primaryColorHex,
  });

  final String logoUrl;
  final String primaryColorHex;

  static const List<AppProductCardData> _sampleProducts = <AppProductCardData>[
    AppProductCardData(id: 'sample-1', name: 'Camisa Linho'),
    AppProductCardData(id: 'sample-2', name: 'Vestido Verão'),
    AppProductCardData(id: 'sample-3', name: 'Calça Alfaiataria'),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final brandTheme = AppBrandTheme.resolveTheme(
      brightness: brightness,
      primaryColorHex: primaryColorHex.isEmpty ? null : primaryColorHex,
    );

    return Theme(
      data: brandTheme,
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          return Container(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.radius12),
              border: Border.all(color: colors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (logoUrl.isNotEmpty) ...<Widget>[
                  SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        height: 40,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SizedBox.shrink(),
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                ],
                AppProductGrid(
                  products: _sampleProducts,
                  onProductTap: (_) {},
                  crossAxisCount: 3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
