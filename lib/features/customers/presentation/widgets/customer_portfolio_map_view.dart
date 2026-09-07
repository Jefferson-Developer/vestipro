import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_map_pin.dart';
import '../../domain/services/customer_map_clusterer.dart';
import '../../domain/services/customer_map_pin_builder.dart';
import '../../domain/value_objects/customer_status.dart';

/// Map visualization of the customer carteira (TASK-176): one pin per
/// customer with a geocoded address, clustered together at low zoom levels.
///
/// Receives [customers] already filtered/paginated by whichever
/// `CustomerPortfolioBloc` instance the caller owns — the exact same source
/// the list view (`_PortfolioContent`) reads, so the two views can never
/// disagree on which customers are visible (`tasks.md`/TASK-176: "os mesmos
/// filtros... sem divergência de regra entre as duas visualizações").
class CustomerPortfolioMapView extends StatefulWidget {
  const CustomerPortfolioMapView({
    required this.customers,
    this.onCustomerSelected,
    super.key,
  });

  final List<Customer> customers;
  final ValueChanged<Customer>? onCustomerSelected;

  @override
  State<CustomerPortfolioMapView> createState() =>
      _CustomerPortfolioMapViewState();
}

class _CustomerPortfolioMapViewState extends State<CustomerPortfolioMapView> {
  static const _pinBuilder = CustomerMapPinBuilder();
  static const _clusterer = CustomerMapClusterer();

  /// Geographic center of Brazil — only used when no customer has a usable
  /// pin yet, so the map never opens on the ocean off the coast of Africa
  /// (the raw `LatLng(0, 0)` default).
  static const _fallbackCenter = LatLng(-14.2350, -51.9253);
  static const _fallbackZoom = 4.0;

  GoogleMapController? _controller;
  double _zoom = _fallbackZoom;
  bool _hasCenteredOnData = false;

  @override
  Widget build(BuildContext context) {
    final pins = _pinBuilder.build(widget.customers);
    final customersWithoutLocation = _pinBuilder.customersWithoutLocationCount(
      widget.customers,
    );
    final customersById = <String, Customer>{
      for (final customer in widget.customers) customer.id: customer,
    };
    final clusters = _clusterer.cluster(pins: pins, zoom: _zoom);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (customersWithoutLocation > 0)
          _CustomersWithoutLocationBanner(count: customersWithoutLocation),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: pins.isEmpty
                    ? _fallbackCenter
                    : LatLng(
                        pins.first.coordinates.latitude,
                        pins.first.coordinates.longitude,
                      ),
                zoom: _fallbackZoom,
              ),
              onMapCreated: (controller) => _controller = controller,
              onCameraMove: (position) => _zoom = position.zoom,
              onCameraIdle: () => setState(() {}),
              markers: <Marker>{
                for (final cluster in clusters)
                  _buildMarker(cluster: cluster, customersById: customersById),
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant CustomerPortfolioMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasCenteredOnData || widget.customers.isEmpty) return;
    final pins = _pinBuilder.build(widget.customers);
    if (pins.isEmpty) return;
    _hasCenteredOnData = true;
    final controller = _controller;
    if (controller != null) {
      unawaited(
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              pins.first.coordinates.latitude,
              pins.first.coordinates.longitude,
            ),
            10,
          ),
        ),
      );
    }
  }

  Marker _buildMarker({
    required MapCluster cluster,
    required Map<String, Customer> customersById,
  }) {
    final position = LatLng(cluster.latitude, cluster.longitude);
    if (cluster.isCluster) {
      return Marker(
        markerId: MarkerId('cluster_${cluster.latitude}_${cluster.longitude}'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: '${cluster.pins.length} clientes'),
        onTap: () {
          final controller = _controller;
          if (controller == null) return;
          unawaited(
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(position, (_zoom + 2).clamp(0, 20)),
            ),
          );
        },
      );
    }

    final pin = cluster.singlePin;
    final customer = customersById[pin.customerId];
    return Marker(
      markerId: MarkerId(pin.customerId),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(_hueForStatus(pin.status)),
      infoWindow: InfoWindow(title: pin.displayName),
      onTap: customer == null
          ? null
          : () => _showCustomerCard(context, pin, customer),
    );
  }

  double _hueForStatus(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => BitmapDescriptor.hueGreen,
      CustomerStatus.prospect => BitmapDescriptor.hueAzure,
      CustomerStatus.inactive => BitmapDescriptor.hueYellow,
      CustomerStatus.blocked => BitmapDescriptor.hueRed,
    };
  }

  void _showCustomerCard(
    BuildContext context,
    CustomerMapPin pin,
    Customer customer,
  ) {
    unawaited(
      AppBottomSheet.show<void>(
        context: context,
        title: pin.displayName,
        builder: (sheetContext) => _CustomerMapPinCard(
          pin: pin,
          onViewDetails: widget.onCustomerSelected == null
              ? null
              : () {
                  Navigator.of(sheetContext).pop();
                  widget.onCustomerSelected!(customer);
                },
        ),
      ),
    );
  }
}

class _CustomerMapPinCard extends StatelessWidget {
  const _CustomerMapPinCard({required this.pin, this.onViewDetails});

  final CustomerMapPin pin;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            AppStatusBadge(
              label: _statusLabel(pin.status),
              variant: _statusVariant(pin.status),
            ),
            AppStatusBadge(
              label: pin.potential?.trim().isEmpty ?? true
                  ? 'Potencial nao informado'
                  : 'Potencial ${pin.potential}',
              variant: AppStatusBadgeVariant.info,
              icon: Icons.trending_up,
            ),
            AppStatusBadge(
              label: _lastPurchaseLabel(pin.lastPurchaseAt),
              variant: AppStatusBadgeVariant.neutral,
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        ),
        if (onViewDetails != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Ver detalhes',
            leadingIcon: Icons.person_search_outlined,
            onPressed: onViewDetails,
          ),
        ],
      ],
    );
  }

  String _statusLabel(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => 'Ativo',
      CustomerStatus.inactive => 'Inativo',
      CustomerStatus.prospect => 'Prospect',
      CustomerStatus.blocked => 'Bloqueado',
    };
  }

  AppStatusBadgeVariant _statusVariant(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => AppStatusBadgeVariant.success,
      CustomerStatus.inactive => AppStatusBadgeVariant.neutral,
      CustomerStatus.prospect => AppStatusBadgeVariant.info,
      CustomerStatus.blocked => AppStatusBadgeVariant.error,
    };
  }

  String _lastPurchaseLabel(DateTime? date) {
    if (date == null) return 'Sem compra';
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    return 'Ultima compra $day/$month/${localDate.year}';
  }
}

class _CustomersWithoutLocationBanner extends StatelessWidget {
  const _CustomersWithoutLocationBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.warning.withValues(alpha: 0.14),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.warning.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.location_off_outlined, color: colors.warning),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              count == 1
                  ? '1 cliente sem localizacao nao aparece no mapa.'
                  : '$count clientes sem localizacao nao aparecem no mapa.',
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
