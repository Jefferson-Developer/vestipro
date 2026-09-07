// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_signature.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderSignature {

// Client-generated uuid — doubles as this signature's own idempotency
// key and Firestore document id, same "`Order.id`-as-doc-id" precedent
// `submitOrder` already established for the order itself.
 String get id; String get organizationId; String get companyId; String get orderId;// Denormalized purely for display (receipt/PDF, history screen) — never
// re-derived from it for any business decision.
 String? get orderNumber; OrderSignerRole get signerRole;// The authenticated seller operating the device the canvas was drawn on
// — *not* necessarily who [signerRole]/[signedByName] says physically
// signed (a customer draws on the seller's own device).
 String get signedByUserId; String get signedByName; OrderSignatureMethod get method;// PNG bytes of the canvas capture — kept locally even after a successful
// sync (never purged), so the comprovante/PDF can always be rendered
// offline, on this same device, regardless of connectivity.
 Uint8List get imageBytes; String get contentHash;// `Order.version` at the moment of signing — lets a later reader tell
// apart "the order changed after this signature" from "this signature
// still matches the order's current content" without recomputing
// [contentHash] against historical data it may no longer have.
 int get orderVersionAtSignature; DateTime get signedAt;// Both `null` until `signOrder` confirms the sync — server-authoritative
// metadata, never trusted from (or set by) the client itself.
 String? get deviceInfo; String? get ipAddress; DateTime? get serverReceivedAt; String? get remoteImageStoragePath; OrderSignatureStatus get status; DateTime? get invalidatedAt; String? get invalidatedReason; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; int get version; OrderSignatureSyncStatus get syncStatus;
/// Create a copy of OrderSignature
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderSignatureCopyWith<OrderSignature> get copyWith => _$OrderSignatureCopyWithImpl<OrderSignature>(this as OrderSignature, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderSignature&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.signerRole, signerRole) || other.signerRole == signerRole)&&(identical(other.signedByUserId, signedByUserId) || other.signedByUserId == signedByUserId)&&(identical(other.signedByName, signedByName) || other.signedByName == signedByName)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.imageBytes, imageBytes)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.orderVersionAtSignature, orderVersionAtSignature) || other.orderVersionAtSignature == orderVersionAtSignature)&&(identical(other.signedAt, signedAt) || other.signedAt == signedAt)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.serverReceivedAt, serverReceivedAt) || other.serverReceivedAt == serverReceivedAt)&&(identical(other.remoteImageStoragePath, remoteImageStoragePath) || other.remoteImageStoragePath == remoteImageStoragePath)&&(identical(other.status, status) || other.status == status)&&(identical(other.invalidatedAt, invalidatedAt) || other.invalidatedAt == invalidatedAt)&&(identical(other.invalidatedReason, invalidatedReason) || other.invalidatedReason == invalidatedReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,orderId,orderNumber,signerRole,signedByUserId,signedByName,method,const DeepCollectionEquality().hash(imageBytes),contentHash,orderVersionAtSignature,signedAt,deviceInfo,ipAddress,serverReceivedAt,remoteImageStoragePath,status,invalidatedAt,invalidatedReason,createdAt,createdBy,updatedAt,updatedBy,version,syncStatus]);

@override
String toString() {
  return 'OrderSignature(id: $id, organizationId: $organizationId, companyId: $companyId, orderId: $orderId, orderNumber: $orderNumber, signerRole: $signerRole, signedByUserId: $signedByUserId, signedByName: $signedByName, method: $method, imageBytes: $imageBytes, contentHash: $contentHash, orderVersionAtSignature: $orderVersionAtSignature, signedAt: $signedAt, deviceInfo: $deviceInfo, ipAddress: $ipAddress, serverReceivedAt: $serverReceivedAt, remoteImageStoragePath: $remoteImageStoragePath, status: $status, invalidatedAt: $invalidatedAt, invalidatedReason: $invalidatedReason, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $OrderSignatureCopyWith<$Res>  {
  factory $OrderSignatureCopyWith(OrderSignature value, $Res Function(OrderSignature) _then) = _$OrderSignatureCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, String orderId, String? orderNumber, OrderSignerRole signerRole, String signedByUserId, String signedByName, OrderSignatureMethod method, Uint8List imageBytes, String contentHash, int orderVersionAtSignature, DateTime signedAt, String? deviceInfo, String? ipAddress, DateTime? serverReceivedAt, String? remoteImageStoragePath, OrderSignatureStatus status, DateTime? invalidatedAt, String? invalidatedReason, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version, OrderSignatureSyncStatus syncStatus
});




}
/// @nodoc
class _$OrderSignatureCopyWithImpl<$Res>
    implements $OrderSignatureCopyWith<$Res> {
  _$OrderSignatureCopyWithImpl(this._self, this._then);

  final OrderSignature _self;
  final $Res Function(OrderSignature) _then;

/// Create a copy of OrderSignature
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? orderId = null,Object? orderNumber = freezed,Object? signerRole = null,Object? signedByUserId = null,Object? signedByName = null,Object? method = null,Object? imageBytes = null,Object? contentHash = null,Object? orderVersionAtSignature = null,Object? signedAt = null,Object? deviceInfo = freezed,Object? ipAddress = freezed,Object? serverReceivedAt = freezed,Object? remoteImageStoragePath = freezed,Object? status = null,Object? invalidatedAt = freezed,Object? invalidatedReason = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: freezed == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String?,signerRole: null == signerRole ? _self.signerRole : signerRole // ignore: cast_nullable_to_non_nullable
as OrderSignerRole,signedByUserId: null == signedByUserId ? _self.signedByUserId : signedByUserId // ignore: cast_nullable_to_non_nullable
as String,signedByName: null == signedByName ? _self.signedByName : signedByName // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as OrderSignatureMethod,imageBytes: null == imageBytes ? _self.imageBytes : imageBytes // ignore: cast_nullable_to_non_nullable
as Uint8List,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,orderVersionAtSignature: null == orderVersionAtSignature ? _self.orderVersionAtSignature : orderVersionAtSignature // ignore: cast_nullable_to_non_nullable
as int,signedAt: null == signedAt ? _self.signedAt : signedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,serverReceivedAt: freezed == serverReceivedAt ? _self.serverReceivedAt : serverReceivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,remoteImageStoragePath: freezed == remoteImageStoragePath ? _self.remoteImageStoragePath : remoteImageStoragePath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderSignatureStatus,invalidatedAt: freezed == invalidatedAt ? _self.invalidatedAt : invalidatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,invalidatedReason: freezed == invalidatedReason ? _self.invalidatedReason : invalidatedReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as OrderSignatureSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderSignature].
extension OrderSignaturePatterns on OrderSignature {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderSignature value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderSignature() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderSignature value)  $default,){
final _that = this;
switch (_that) {
case _OrderSignature():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderSignature value)?  $default,){
final _that = this;
switch (_that) {
case _OrderSignature() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String orderId,  String? orderNumber,  OrderSignerRole signerRole,  String signedByUserId,  String signedByName,  OrderSignatureMethod method,  Uint8List imageBytes,  String contentHash,  int orderVersionAtSignature,  DateTime signedAt,  String? deviceInfo,  String? ipAddress,  DateTime? serverReceivedAt,  String? remoteImageStoragePath,  OrderSignatureStatus status,  DateTime? invalidatedAt,  String? invalidatedReason,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  OrderSignatureSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderSignature() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.orderId,_that.orderNumber,_that.signerRole,_that.signedByUserId,_that.signedByName,_that.method,_that.imageBytes,_that.contentHash,_that.orderVersionAtSignature,_that.signedAt,_that.deviceInfo,_that.ipAddress,_that.serverReceivedAt,_that.remoteImageStoragePath,_that.status,_that.invalidatedAt,_that.invalidatedReason,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String orderId,  String? orderNumber,  OrderSignerRole signerRole,  String signedByUserId,  String signedByName,  OrderSignatureMethod method,  Uint8List imageBytes,  String contentHash,  int orderVersionAtSignature,  DateTime signedAt,  String? deviceInfo,  String? ipAddress,  DateTime? serverReceivedAt,  String? remoteImageStoragePath,  OrderSignatureStatus status,  DateTime? invalidatedAt,  String? invalidatedReason,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  OrderSignatureSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _OrderSignature():
return $default(_that.id,_that.organizationId,_that.companyId,_that.orderId,_that.orderNumber,_that.signerRole,_that.signedByUserId,_that.signedByName,_that.method,_that.imageBytes,_that.contentHash,_that.orderVersionAtSignature,_that.signedAt,_that.deviceInfo,_that.ipAddress,_that.serverReceivedAt,_that.remoteImageStoragePath,_that.status,_that.invalidatedAt,_that.invalidatedReason,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  String orderId,  String? orderNumber,  OrderSignerRole signerRole,  String signedByUserId,  String signedByName,  OrderSignatureMethod method,  Uint8List imageBytes,  String contentHash,  int orderVersionAtSignature,  DateTime signedAt,  String? deviceInfo,  String? ipAddress,  DateTime? serverReceivedAt,  String? remoteImageStoragePath,  OrderSignatureStatus status,  DateTime? invalidatedAt,  String? invalidatedReason,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  OrderSignatureSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _OrderSignature() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.orderId,_that.orderNumber,_that.signerRole,_that.signedByUserId,_that.signedByName,_that.method,_that.imageBytes,_that.contentHash,_that.orderVersionAtSignature,_that.signedAt,_that.deviceInfo,_that.ipAddress,_that.serverReceivedAt,_that.remoteImageStoragePath,_that.status,_that.invalidatedAt,_that.invalidatedReason,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _OrderSignature extends OrderSignature {
  const _OrderSignature({required this.id, required this.organizationId, required this.companyId, required this.orderId, this.orderNumber, required this.signerRole, required this.signedByUserId, required this.signedByName, required this.method, required this.imageBytes, required this.contentHash, required this.orderVersionAtSignature, required this.signedAt, this.deviceInfo, this.ipAddress, this.serverReceivedAt, this.remoteImageStoragePath, this.status = OrderSignatureStatus.valid, this.invalidatedAt, this.invalidatedReason, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, required this.version, required this.syncStatus}): super._();
  

// Client-generated uuid — doubles as this signature's own idempotency
// key and Firestore document id, same "`Order.id`-as-doc-id" precedent
// `submitOrder` already established for the order itself.
@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  String orderId;
// Denormalized purely for display (receipt/PDF, history screen) — never
// re-derived from it for any business decision.
@override final  String? orderNumber;
@override final  OrderSignerRole signerRole;
// The authenticated seller operating the device the canvas was drawn on
// — *not* necessarily who [signerRole]/[signedByName] says physically
// signed (a customer draws on the seller's own device).
@override final  String signedByUserId;
@override final  String signedByName;
@override final  OrderSignatureMethod method;
// PNG bytes of the canvas capture — kept locally even after a successful
// sync (never purged), so the comprovante/PDF can always be rendered
// offline, on this same device, regardless of connectivity.
@override final  Uint8List imageBytes;
@override final  String contentHash;
// `Order.version` at the moment of signing — lets a later reader tell
// apart "the order changed after this signature" from "this signature
// still matches the order's current content" without recomputing
// [contentHash] against historical data it may no longer have.
@override final  int orderVersionAtSignature;
@override final  DateTime signedAt;
// Both `null` until `signOrder` confirms the sync — server-authoritative
// metadata, never trusted from (or set by) the client itself.
@override final  String? deviceInfo;
@override final  String? ipAddress;
@override final  DateTime? serverReceivedAt;
@override final  String? remoteImageStoragePath;
@override@JsonKey() final  OrderSignatureStatus status;
@override final  DateTime? invalidatedAt;
@override final  String? invalidatedReason;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  int version;
@override final  OrderSignatureSyncStatus syncStatus;

/// Create a copy of OrderSignature
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderSignatureCopyWith<_OrderSignature> get copyWith => __$OrderSignatureCopyWithImpl<_OrderSignature>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderSignature&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderNumber, orderNumber) || other.orderNumber == orderNumber)&&(identical(other.signerRole, signerRole) || other.signerRole == signerRole)&&(identical(other.signedByUserId, signedByUserId) || other.signedByUserId == signedByUserId)&&(identical(other.signedByName, signedByName) || other.signedByName == signedByName)&&(identical(other.method, method) || other.method == method)&&const DeepCollectionEquality().equals(other.imageBytes, imageBytes)&&(identical(other.contentHash, contentHash) || other.contentHash == contentHash)&&(identical(other.orderVersionAtSignature, orderVersionAtSignature) || other.orderVersionAtSignature == orderVersionAtSignature)&&(identical(other.signedAt, signedAt) || other.signedAt == signedAt)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress)&&(identical(other.serverReceivedAt, serverReceivedAt) || other.serverReceivedAt == serverReceivedAt)&&(identical(other.remoteImageStoragePath, remoteImageStoragePath) || other.remoteImageStoragePath == remoteImageStoragePath)&&(identical(other.status, status) || other.status == status)&&(identical(other.invalidatedAt, invalidatedAt) || other.invalidatedAt == invalidatedAt)&&(identical(other.invalidatedReason, invalidatedReason) || other.invalidatedReason == invalidatedReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,orderId,orderNumber,signerRole,signedByUserId,signedByName,method,const DeepCollectionEquality().hash(imageBytes),contentHash,orderVersionAtSignature,signedAt,deviceInfo,ipAddress,serverReceivedAt,remoteImageStoragePath,status,invalidatedAt,invalidatedReason,createdAt,createdBy,updatedAt,updatedBy,version,syncStatus]);

@override
String toString() {
  return 'OrderSignature(id: $id, organizationId: $organizationId, companyId: $companyId, orderId: $orderId, orderNumber: $orderNumber, signerRole: $signerRole, signedByUserId: $signedByUserId, signedByName: $signedByName, method: $method, imageBytes: $imageBytes, contentHash: $contentHash, orderVersionAtSignature: $orderVersionAtSignature, signedAt: $signedAt, deviceInfo: $deviceInfo, ipAddress: $ipAddress, serverReceivedAt: $serverReceivedAt, remoteImageStoragePath: $remoteImageStoragePath, status: $status, invalidatedAt: $invalidatedAt, invalidatedReason: $invalidatedReason, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$OrderSignatureCopyWith<$Res> implements $OrderSignatureCopyWith<$Res> {
  factory _$OrderSignatureCopyWith(_OrderSignature value, $Res Function(_OrderSignature) _then) = __$OrderSignatureCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, String orderId, String? orderNumber, OrderSignerRole signerRole, String signedByUserId, String signedByName, OrderSignatureMethod method, Uint8List imageBytes, String contentHash, int orderVersionAtSignature, DateTime signedAt, String? deviceInfo, String? ipAddress, DateTime? serverReceivedAt, String? remoteImageStoragePath, OrderSignatureStatus status, DateTime? invalidatedAt, String? invalidatedReason, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version, OrderSignatureSyncStatus syncStatus
});




}
/// @nodoc
class __$OrderSignatureCopyWithImpl<$Res>
    implements _$OrderSignatureCopyWith<$Res> {
  __$OrderSignatureCopyWithImpl(this._self, this._then);

  final _OrderSignature _self;
  final $Res Function(_OrderSignature) _then;

/// Create a copy of OrderSignature
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? orderId = null,Object? orderNumber = freezed,Object? signerRole = null,Object? signedByUserId = null,Object? signedByName = null,Object? method = null,Object? imageBytes = null,Object? contentHash = null,Object? orderVersionAtSignature = null,Object? signedAt = null,Object? deviceInfo = freezed,Object? ipAddress = freezed,Object? serverReceivedAt = freezed,Object? remoteImageStoragePath = freezed,Object? status = null,Object? invalidatedAt = freezed,Object? invalidatedReason = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,Object? syncStatus = null,}) {
  return _then(_OrderSignature(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,orderNumber: freezed == orderNumber ? _self.orderNumber : orderNumber // ignore: cast_nullable_to_non_nullable
as String?,signerRole: null == signerRole ? _self.signerRole : signerRole // ignore: cast_nullable_to_non_nullable
as OrderSignerRole,signedByUserId: null == signedByUserId ? _self.signedByUserId : signedByUserId // ignore: cast_nullable_to_non_nullable
as String,signedByName: null == signedByName ? _self.signedByName : signedByName // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as OrderSignatureMethod,imageBytes: null == imageBytes ? _self.imageBytes : imageBytes // ignore: cast_nullable_to_non_nullable
as Uint8List,contentHash: null == contentHash ? _self.contentHash : contentHash // ignore: cast_nullable_to_non_nullable
as String,orderVersionAtSignature: null == orderVersionAtSignature ? _self.orderVersionAtSignature : orderVersionAtSignature // ignore: cast_nullable_to_non_nullable
as int,signedAt: null == signedAt ? _self.signedAt : signedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,serverReceivedAt: freezed == serverReceivedAt ? _self.serverReceivedAt : serverReceivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,remoteImageStoragePath: freezed == remoteImageStoragePath ? _self.remoteImageStoragePath : remoteImageStoragePath // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderSignatureStatus,invalidatedAt: freezed == invalidatedAt ? _self.invalidatedAt : invalidatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,invalidatedReason: freezed == invalidatedReason ? _self.invalidatedReason : invalidatedReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as OrderSignatureSyncStatus,
  ));
}


}

// dart format on
