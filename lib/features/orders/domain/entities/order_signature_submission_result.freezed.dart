// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_signature_submission_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderSignatureSubmissionResult {

 String get signatureId; String get remoteImageStoragePath; DateTime get serverReceivedAt;// Resolved server-side from the callable's own `_meta` (app
// version/platform) — advisory metadata, never used for authorization,
// same status every other Function already treats `_meta` with.
 String? get deviceInfo;// Resolved server-side from the request's own IP — never trusted from
// (or even sent by) the client, unlike every other field this callable
// receives.
 String? get ipAddress;
/// Create a copy of OrderSignatureSubmissionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderSignatureSubmissionResultCopyWith<OrderSignatureSubmissionResult> get copyWith => _$OrderSignatureSubmissionResultCopyWithImpl<OrderSignatureSubmissionResult>(this as OrderSignatureSubmissionResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderSignatureSubmissionResult&&(identical(other.signatureId, signatureId) || other.signatureId == signatureId)&&(identical(other.remoteImageStoragePath, remoteImageStoragePath) || other.remoteImageStoragePath == remoteImageStoragePath)&&(identical(other.serverReceivedAt, serverReceivedAt) || other.serverReceivedAt == serverReceivedAt)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress));
}


@override
int get hashCode => Object.hash(runtimeType,signatureId,remoteImageStoragePath,serverReceivedAt,deviceInfo,ipAddress);

@override
String toString() {
  return 'OrderSignatureSubmissionResult(signatureId: $signatureId, remoteImageStoragePath: $remoteImageStoragePath, serverReceivedAt: $serverReceivedAt, deviceInfo: $deviceInfo, ipAddress: $ipAddress)';
}


}

/// @nodoc
abstract mixin class $OrderSignatureSubmissionResultCopyWith<$Res>  {
  factory $OrderSignatureSubmissionResultCopyWith(OrderSignatureSubmissionResult value, $Res Function(OrderSignatureSubmissionResult) _then) = _$OrderSignatureSubmissionResultCopyWithImpl;
@useResult
$Res call({
 String signatureId, String remoteImageStoragePath, DateTime serverReceivedAt, String? deviceInfo, String? ipAddress
});




}
/// @nodoc
class _$OrderSignatureSubmissionResultCopyWithImpl<$Res>
    implements $OrderSignatureSubmissionResultCopyWith<$Res> {
  _$OrderSignatureSubmissionResultCopyWithImpl(this._self, this._then);

  final OrderSignatureSubmissionResult _self;
  final $Res Function(OrderSignatureSubmissionResult) _then;

/// Create a copy of OrderSignatureSubmissionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? signatureId = null,Object? remoteImageStoragePath = null,Object? serverReceivedAt = null,Object? deviceInfo = freezed,Object? ipAddress = freezed,}) {
  return _then(_self.copyWith(
signatureId: null == signatureId ? _self.signatureId : signatureId // ignore: cast_nullable_to_non_nullable
as String,remoteImageStoragePath: null == remoteImageStoragePath ? _self.remoteImageStoragePath : remoteImageStoragePath // ignore: cast_nullable_to_non_nullable
as String,serverReceivedAt: null == serverReceivedAt ? _self.serverReceivedAt : serverReceivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderSignatureSubmissionResult].
extension OrderSignatureSubmissionResultPatterns on OrderSignatureSubmissionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderSignatureSubmissionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderSignatureSubmissionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderSignatureSubmissionResult value)  $default,){
final _that = this;
switch (_that) {
case _OrderSignatureSubmissionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderSignatureSubmissionResult value)?  $default,){
final _that = this;
switch (_that) {
case _OrderSignatureSubmissionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String signatureId,  String remoteImageStoragePath,  DateTime serverReceivedAt,  String? deviceInfo,  String? ipAddress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderSignatureSubmissionResult() when $default != null:
return $default(_that.signatureId,_that.remoteImageStoragePath,_that.serverReceivedAt,_that.deviceInfo,_that.ipAddress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String signatureId,  String remoteImageStoragePath,  DateTime serverReceivedAt,  String? deviceInfo,  String? ipAddress)  $default,) {final _that = this;
switch (_that) {
case _OrderSignatureSubmissionResult():
return $default(_that.signatureId,_that.remoteImageStoragePath,_that.serverReceivedAt,_that.deviceInfo,_that.ipAddress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String signatureId,  String remoteImageStoragePath,  DateTime serverReceivedAt,  String? deviceInfo,  String? ipAddress)?  $default,) {final _that = this;
switch (_that) {
case _OrderSignatureSubmissionResult() when $default != null:
return $default(_that.signatureId,_that.remoteImageStoragePath,_that.serverReceivedAt,_that.deviceInfo,_that.ipAddress);case _:
  return null;

}
}

}

/// @nodoc


class _OrderSignatureSubmissionResult implements OrderSignatureSubmissionResult {
  const _OrderSignatureSubmissionResult({required this.signatureId, required this.remoteImageStoragePath, required this.serverReceivedAt, this.deviceInfo, this.ipAddress});
  

@override final  String signatureId;
@override final  String remoteImageStoragePath;
@override final  DateTime serverReceivedAt;
// Resolved server-side from the callable's own `_meta` (app
// version/platform) — advisory metadata, never used for authorization,
// same status every other Function already treats `_meta` with.
@override final  String? deviceInfo;
// Resolved server-side from the request's own IP — never trusted from
// (or even sent by) the client, unlike every other field this callable
// receives.
@override final  String? ipAddress;

/// Create a copy of OrderSignatureSubmissionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderSignatureSubmissionResultCopyWith<_OrderSignatureSubmissionResult> get copyWith => __$OrderSignatureSubmissionResultCopyWithImpl<_OrderSignatureSubmissionResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderSignatureSubmissionResult&&(identical(other.signatureId, signatureId) || other.signatureId == signatureId)&&(identical(other.remoteImageStoragePath, remoteImageStoragePath) || other.remoteImageStoragePath == remoteImageStoragePath)&&(identical(other.serverReceivedAt, serverReceivedAt) || other.serverReceivedAt == serverReceivedAt)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo)&&(identical(other.ipAddress, ipAddress) || other.ipAddress == ipAddress));
}


@override
int get hashCode => Object.hash(runtimeType,signatureId,remoteImageStoragePath,serverReceivedAt,deviceInfo,ipAddress);

@override
String toString() {
  return 'OrderSignatureSubmissionResult(signatureId: $signatureId, remoteImageStoragePath: $remoteImageStoragePath, serverReceivedAt: $serverReceivedAt, deviceInfo: $deviceInfo, ipAddress: $ipAddress)';
}


}

/// @nodoc
abstract mixin class _$OrderSignatureSubmissionResultCopyWith<$Res> implements $OrderSignatureSubmissionResultCopyWith<$Res> {
  factory _$OrderSignatureSubmissionResultCopyWith(_OrderSignatureSubmissionResult value, $Res Function(_OrderSignatureSubmissionResult) _then) = __$OrderSignatureSubmissionResultCopyWithImpl;
@override @useResult
$Res call({
 String signatureId, String remoteImageStoragePath, DateTime serverReceivedAt, String? deviceInfo, String? ipAddress
});




}
/// @nodoc
class __$OrderSignatureSubmissionResultCopyWithImpl<$Res>
    implements _$OrderSignatureSubmissionResultCopyWith<$Res> {
  __$OrderSignatureSubmissionResultCopyWithImpl(this._self, this._then);

  final _OrderSignatureSubmissionResult _self;
  final $Res Function(_OrderSignatureSubmissionResult) _then;

/// Create a copy of OrderSignatureSubmissionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? signatureId = null,Object? remoteImageStoragePath = null,Object? serverReceivedAt = null,Object? deviceInfo = freezed,Object? ipAddress = freezed,}) {
  return _then(_OrderSignatureSubmissionResult(
signatureId: null == signatureId ? _self.signatureId : signatureId // ignore: cast_nullable_to_non_nullable
as String,remoteImageStoragePath: null == remoteImageStoragePath ? _self.remoteImageStoragePath : remoteImageStoragePath // ignore: cast_nullable_to_non_nullable
as String,serverReceivedAt: null == serverReceivedAt ? _self.serverReceivedAt : serverReceivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as String?,ipAddress: freezed == ipAddress ? _self.ipAddress : ipAddress // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
