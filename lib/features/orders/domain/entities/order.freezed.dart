// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Order {

 String get id; String get organizationId; String get companyId; String get branchId; String get customerId; String get sellerId;// The definitive, sequential order number `submitOrder` (TASK-101)
// generates server-side — `null` until this `Order` has actually been
// submitted (a `draft`/`pendingSync` order never has one). Read-only from
// the client's perspective: nothing in this codebase other than
// `_submitOrder` (`app/bootstrap.dart`), reconciling a successful
// `OrderSubmissionResult`, may ever set it.
 String? get orderNumber; OrderAddress get deliveryAddress; OrderAddress get billingAddress; String get priceListId; String get paymentTermId; String? get carrierId;// "coleção" — the product collection this order was placed against, if
// the seller narrowed the catalog to one (TASK-072 area).
 String? get collectionId;// "tipo de pedido" — free-form categorization code (e.g. normal, sample,
// bonus/gift), intentionally not a closed enum: `tasks.md` seção 9 does
// not fix its possible values, same precedent as `Customer.classification`.
 String? get orderType; List<OrderItem> get items; double get discountAmount; double get surchargeAmount; double get shippingAmount; double? get taxAmount; String? get notes; List<String> get attachmentUrls; OrderStatus get status; List<OrderStatusHistoryEntry> get statusHistory;// Approval metadata: only ever set by the (future) approval flow, never
// inferred from [status] alone.
 String? get approvedBy; DateTime? get approvedAt; String? get rejectionReason; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt; int get version; OrderSyncStatus get syncStatus;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.billingAddress, billingAddress) || other.billingAddress == billingAddress)&&(identical(other.priceListId, priceListId) || other.priceListId == priceListId)&&(identical(other.paymentTermId, paymentTermId) || other.paymentTermId == paymentTermId)&&(identical(other.carrierId, carrierId) || other.carrierId == carrierId)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.surchargeAmount, surchargeAmount) || other.surchargeAmount == surchargeAmount)&&(identical(other.shippingAmount, shippingAmount) || other.shippingAmount == shippingAmount)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.attachmentUrls, attachmentUrls)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.statusHistory, statusHistory)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,branchId,customerId,sellerId,orderNumber,deliveryAddress,billingAddress,priceListId,paymentTermId,carrierId,collectionId,orderType,const DeepCollectionEquality().hash(items),discountAmount,surchargeAmount,shippingAmount,taxAmount,notes,const DeepCollectionEquality().hash(attachmentUrls),status,const DeepCollectionEquality().hash(statusHistory),approvedBy,approvedAt,rejectionReason,createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Order(id: $id, organizationId: $organizationId, companyId: $companyId, branchId: $branchId, customerId: $customerId, sellerId: $sellerId, orderNumber: $orderNumber, deliveryAddress: $deliveryAddress, billingAddress: $billingAddress, priceListId: $priceListId, paymentTermId: $paymentTermId, carrierId: $carrierId, collectionId: $collectionId, orderType: $orderType, items: $items, discountAmount: $discountAmount, surchargeAmount: $surchargeAmount, shippingAmount: $shippingAmount, taxAmount: $taxAmount, notes: $notes, attachmentUrls: $attachmentUrls, status: $status, statusHistory: $statusHistory, approvedBy: $approvedBy, approvedAt: $approvedAt, rejectionReason: $rejectionReason, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, String branchId, String customerId, String sellerId, String? orderNumber, OrderAddress deliveryAddress, OrderAddress billingAddress, String priceListId, String paymentTermId, String? carrierId, String? collectionId, String? orderType, List<OrderItem> items, double discountAmount, double surchargeAmount, double shippingAmount, double? taxAmount, String? notes, List<String> attachmentUrls, OrderStatus status, List<OrderStatusHistoryEntry> statusHistory, String? approvedBy, DateTime? approvedAt, String? rejectionReason, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, OrderSyncStatus syncStatus
});


$OrderAddressCopyWith<$Res> get deliveryAddress;$OrderAddressCopyWith<$Res> get billingAddress;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? branchId = null,Object? customerId = null,Object? sellerId = null,Object? orderNumber = freezed,Object? deliveryAddress = null,Object? billingAddress = null,Object? priceListId = null,Object? paymentTermId = null,Object? carrierId = freezed,Object? collectionId = freezed,Object? orderType = freezed,Object? items = null,Object? discountAmount = null,Object? surchargeAmount = null,Object? shippingAmount = null,Object? taxAmount = freezed,Object? notes = freezed,Object? attachmentUrls = null,Object? status = null,Object? statusHistory = null,Object? approvedBy = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: freezed == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String?,deliveryAddress: null == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as OrderAddress,billingAddress: null == billingAddress ? _self.billingAddress : billingAddress // ignore: cast_nullable_to_non_nullable
as OrderAddress,priceListId: null == priceListId ? _self.priceListId : priceListId // ignore: cast_nullable_to_non_nullable
as String,paymentTermId: null == paymentTermId ? _self.paymentTermId : paymentTermId // ignore: cast_nullable_to_non_nullable
as String,carrierId: freezed == carrierId ? _self.carrierId : carrierId // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,orderType: freezed == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,surchargeAmount: null == surchargeAmount ? _self.surchargeAmount : surchargeAmount // ignore: cast_nullable_to_non_nullable
as double,shippingAmount: null == shippingAmount ? _self.shippingAmount : shippingAmount // ignore: cast_nullable_to_non_nullable
as double,taxAmount: freezed == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrls: null == attachmentUrls ? _self.attachmentUrls : attachmentUrls // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,statusHistory: null == statusHistory ? _self.statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<OrderStatusHistoryEntry>,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as OrderSyncStatus,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderAddressCopyWith<$Res> get deliveryAddress {
  
  return $OrderAddressCopyWith<$Res>(_self.deliveryAddress, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderAddressCopyWith<$Res> get billingAddress {
  
  return $OrderAddressCopyWith<$Res>(_self.billingAddress, (value) {
    return _then(_self.copyWith(billingAddress: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String branchId,  String customerId,  String sellerId,  String? orderNumber,  OrderAddress deliveryAddress,  OrderAddress billingAddress,  String priceListId,  String paymentTermId,  String? carrierId,  String? collectionId,  String? orderType,  List<OrderItem> items,  double discountAmount,  double surchargeAmount,  double shippingAmount,  double? taxAmount,  String? notes,  List<String> attachmentUrls,  OrderStatus status,  List<OrderStatusHistoryEntry> statusHistory,  String? approvedBy,  DateTime? approvedAt,  String? rejectionReason,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  OrderSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.branchId,_that.customerId,_that.sellerId,_that.orderNumber,_that.deliveryAddress,_that.billingAddress,_that.priceListId,_that.paymentTermId,_that.carrierId,_that.collectionId,_that.orderType,_that.items,_that.discountAmount,_that.surchargeAmount,_that.shippingAmount,_that.taxAmount,_that.notes,_that.attachmentUrls,_that.status,_that.statusHistory,_that.approvedBy,_that.approvedAt,_that.rejectionReason,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String branchId,  String customerId,  String sellerId,  String? orderNumber,  OrderAddress deliveryAddress,  OrderAddress billingAddress,  String priceListId,  String paymentTermId,  String? carrierId,  String? collectionId,  String? orderType,  List<OrderItem> items,  double discountAmount,  double surchargeAmount,  double shippingAmount,  double? taxAmount,  String? notes,  List<String> attachmentUrls,  OrderStatus status,  List<OrderStatusHistoryEntry> statusHistory,  String? approvedBy,  DateTime? approvedAt,  String? rejectionReason,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  OrderSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.organizationId,_that.companyId,_that.branchId,_that.customerId,_that.sellerId,_that.orderNumber,_that.deliveryAddress,_that.billingAddress,_that.priceListId,_that.paymentTermId,_that.carrierId,_that.collectionId,_that.orderType,_that.items,_that.discountAmount,_that.surchargeAmount,_that.shippingAmount,_that.taxAmount,_that.notes,_that.attachmentUrls,_that.status,_that.statusHistory,_that.approvedBy,_that.approvedAt,_that.rejectionReason,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  String branchId,  String customerId,  String sellerId,  String? orderNumber,  OrderAddress deliveryAddress,  OrderAddress billingAddress,  String priceListId,  String paymentTermId,  String? carrierId,  String? collectionId,  String? orderType,  List<OrderItem> items,  double discountAmount,  double surchargeAmount,  double shippingAmount,  double? taxAmount,  String? notes,  List<String> attachmentUrls,  OrderStatus status,  List<OrderStatusHistoryEntry> statusHistory,  String? approvedBy,  DateTime? approvedAt,  String? rejectionReason,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  OrderSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.branchId,_that.customerId,_that.sellerId,_that.orderNumber,_that.deliveryAddress,_that.billingAddress,_that.priceListId,_that.paymentTermId,_that.carrierId,_that.collectionId,_that.orderType,_that.items,_that.discountAmount,_that.surchargeAmount,_that.shippingAmount,_that.taxAmount,_that.notes,_that.attachmentUrls,_that.status,_that.statusHistory,_that.approvedBy,_that.approvedAt,_that.rejectionReason,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Order extends Order {
  const _Order({required this.id, required this.organizationId, required this.companyId, required this.branchId, required this.customerId, required this.sellerId, this.orderNumber, required this.deliveryAddress, required this.billingAddress, required this.priceListId, required this.paymentTermId, this.carrierId, this.collectionId, this.orderType, final  List<OrderItem> items = const <OrderItem>[], this.discountAmount = 0, this.surchargeAmount = 0, this.shippingAmount = 0, this.taxAmount, this.notes, final  List<String> attachmentUrls = const <String>[], required this.status, final  List<OrderStatusHistoryEntry> statusHistory = const <OrderStatusHistoryEntry>[], this.approvedBy, this.approvedAt, this.rejectionReason, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt, required this.version, required this.syncStatus}): _items = items,_attachmentUrls = attachmentUrls,_statusHistory = statusHistory,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  String branchId;
@override final  String customerId;
@override final  String sellerId;
// The definitive, sequential order number `submitOrder` (TASK-101)
// generates server-side — `null` until this `Order` has actually been
// submitted (a `draft`/`pendingSync` order never has one). Read-only from
// the client's perspective: nothing in this codebase other than
// `_submitOrder` (`app/bootstrap.dart`), reconciling a successful
// `OrderSubmissionResult`, may ever set it.
@override final  String? orderNumber;
@override final  OrderAddress deliveryAddress;
@override final  OrderAddress billingAddress;
@override final  String priceListId;
@override final  String paymentTermId;
@override final  String? carrierId;
// "coleção" — the product collection this order was placed against, if
// the seller narrowed the catalog to one (TASK-072 area).
@override final  String? collectionId;
// "tipo de pedido" — free-form categorization code (e.g. normal, sample,
// bonus/gift), intentionally not a closed enum: `tasks.md` seção 9 does
// not fix its possible values, same precedent as `Customer.classification`.
@override final  String? orderType;
 final  List<OrderItem> _items;
@override@JsonKey() List<OrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  double discountAmount;
@override@JsonKey() final  double surchargeAmount;
@override@JsonKey() final  double shippingAmount;
@override final  double? taxAmount;
@override final  String? notes;
 final  List<String> _attachmentUrls;
@override@JsonKey() List<String> get attachmentUrls {
  if (_attachmentUrls is EqualUnmodifiableListView) return _attachmentUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachmentUrls);
}

@override final  OrderStatus status;
 final  List<OrderStatusHistoryEntry> _statusHistory;
@override@JsonKey() List<OrderStatusHistoryEntry> get statusHistory {
  if (_statusHistory is EqualUnmodifiableListView) return _statusHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statusHistory);
}

// Approval metadata: only ever set by the (future) approval flow, never
// inferred from [status] alone.
@override final  String? approvedBy;
@override final  DateTime? approvedAt;
@override final  String? rejectionReason;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;
@override final  int version;
@override final  OrderSyncStatus syncStatus;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.billingAddress, billingAddress) || other.billingAddress == billingAddress)&&(identical(other.priceListId, priceListId) || other.priceListId == priceListId)&&(identical(other.paymentTermId, paymentTermId) || other.paymentTermId == paymentTermId)&&(identical(other.carrierId, carrierId) || other.carrierId == carrierId)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.surchargeAmount, surchargeAmount) || other.surchargeAmount == surchargeAmount)&&(identical(other.shippingAmount, shippingAmount) || other.shippingAmount == shippingAmount)&&(identical(other.taxAmount, taxAmount) || other.taxAmount == taxAmount)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other._attachmentUrls, _attachmentUrls)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._statusHistory, _statusHistory)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,branchId,customerId,sellerId,orderNumber,deliveryAddress,billingAddress,priceListId,paymentTermId,carrierId,collectionId,orderType,const DeepCollectionEquality().hash(_items),discountAmount,surchargeAmount,shippingAmount,taxAmount,notes,const DeepCollectionEquality().hash(_attachmentUrls),status,const DeepCollectionEquality().hash(_statusHistory),approvedBy,approvedAt,rejectionReason,createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Order(id: $id, organizationId: $organizationId, companyId: $companyId, branchId: $branchId, customerId: $customerId, sellerId: $sellerId, orderNumber: $orderNumber, deliveryAddress: $deliveryAddress, billingAddress: $billingAddress, priceListId: $priceListId, paymentTermId: $paymentTermId, carrierId: $carrierId, collectionId: $collectionId, orderType: $orderType, items: $items, discountAmount: $discountAmount, surchargeAmount: $surchargeAmount, shippingAmount: $shippingAmount, taxAmount: $taxAmount, notes: $notes, attachmentUrls: $attachmentUrls, status: $status, statusHistory: $statusHistory, approvedBy: $approvedBy, approvedAt: $approvedAt, rejectionReason: $rejectionReason, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, String branchId, String customerId, String sellerId, String? orderNumber, OrderAddress deliveryAddress, OrderAddress billingAddress, String priceListId, String paymentTermId, String? carrierId, String? collectionId, String? orderType, List<OrderItem> items, double discountAmount, double surchargeAmount, double shippingAmount, double? taxAmount, String? notes, List<String> attachmentUrls, OrderStatus status, List<OrderStatusHistoryEntry> statusHistory, String? approvedBy, DateTime? approvedAt, String? rejectionReason, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, OrderSyncStatus syncStatus
});


@override $OrderAddressCopyWith<$Res> get deliveryAddress;@override $OrderAddressCopyWith<$Res> get billingAddress;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? branchId = null,Object? customerId = null,Object? sellerId = null,Object? orderNumber = freezed,Object? deliveryAddress = null,Object? billingAddress = null,Object? priceListId = null,Object? paymentTermId = null,Object? carrierId = freezed,Object? collectionId = freezed,Object? orderType = freezed,Object? items = null,Object? discountAmount = null,Object? surchargeAmount = null,Object? shippingAmount = null,Object? taxAmount = freezed,Object? notes = freezed,Object? attachmentUrls = null,Object? status = null,Object? statusHistory = null,Object? approvedBy = freezed,Object? approvedAt = freezed,Object? rejectionReason = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,sellerId: null == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: freezed == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String?,deliveryAddress: null == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as OrderAddress,billingAddress: null == billingAddress ? _self.billingAddress : billingAddress // ignore: cast_nullable_to_non_nullable
as OrderAddress,priceListId: null == priceListId ? _self.priceListId : priceListId // ignore: cast_nullable_to_non_nullable
as String,paymentTermId: null == paymentTermId ? _self.paymentTermId : paymentTermId // ignore: cast_nullable_to_non_nullable
as String,carrierId: freezed == carrierId ? _self.carrierId : carrierId // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,orderType: freezed == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as double,surchargeAmount: null == surchargeAmount ? _self.surchargeAmount : surchargeAmount // ignore: cast_nullable_to_non_nullable
as double,shippingAmount: null == shippingAmount ? _self.shippingAmount : shippingAmount // ignore: cast_nullable_to_non_nullable
as double,taxAmount: freezed == taxAmount ? _self.taxAmount : taxAmount // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,attachmentUrls: null == attachmentUrls ? _self._attachmentUrls : attachmentUrls // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,statusHistory: null == statusHistory ? _self._statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<OrderStatusHistoryEntry>,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as OrderSyncStatus,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderAddressCopyWith<$Res> get deliveryAddress {
  
  return $OrderAddressCopyWith<$Res>(_self.deliveryAddress, (value) {
    return _then(_self.copyWith(deliveryAddress: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderAddressCopyWith<$Res> get billingAddress {
  
  return $OrderAddressCopyWith<$Res>(_self.billingAddress, (value) {
    return _then(_self.copyWith(billingAddress: value));
  });
}
}

// dart format on
