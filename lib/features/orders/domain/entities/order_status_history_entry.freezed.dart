// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_status_history_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderStatusHistoryEntry {

 OrderStatus? get previousStatus; OrderStatus get newStatus; DateTime get changedAt; String get actorId; String? get reason;
/// Create a copy of OrderStatusHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStatusHistoryEntryCopyWith<OrderStatusHistoryEntry> get copyWith => _$OrderStatusHistoryEntryCopyWithImpl<OrderStatusHistoryEntry>(this as OrderStatusHistoryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusHistoryEntry&&(identical(other.previousStatus, previousStatus) || other.previousStatus == previousStatus)&&(identical(other.newStatus, newStatus) || other.newStatus == newStatus)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,previousStatus,newStatus,changedAt,actorId,reason);

@override
String toString() {
  return 'OrderStatusHistoryEntry(previousStatus: $previousStatus, newStatus: $newStatus, changedAt: $changedAt, actorId: $actorId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $OrderStatusHistoryEntryCopyWith<$Res>  {
  factory $OrderStatusHistoryEntryCopyWith(OrderStatusHistoryEntry value, $Res Function(OrderStatusHistoryEntry) _then) = _$OrderStatusHistoryEntryCopyWithImpl;
@useResult
$Res call({
 OrderStatus? previousStatus, OrderStatus newStatus, DateTime changedAt, String actorId, String? reason
});




}
/// @nodoc
class _$OrderStatusHistoryEntryCopyWithImpl<$Res>
    implements $OrderStatusHistoryEntryCopyWith<$Res> {
  _$OrderStatusHistoryEntryCopyWithImpl(this._self, this._then);

  final OrderStatusHistoryEntry _self;
  final $Res Function(OrderStatusHistoryEntry) _then;

/// Create a copy of OrderStatusHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? previousStatus = freezed,Object? newStatus = null,Object? changedAt = null,Object? actorId = null,Object? reason = freezed,}) {
  return _then(_self.copyWith(
previousStatus: freezed == previousStatus ? _self.previousStatus : previousStatus // ignore: cast_nullable_to_non_nullable
as OrderStatus?,newStatus: null == newStatus ? _self.newStatus : newStatus // ignore: cast_nullable_to_non_nullable
as OrderStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderStatusHistoryEntry].
extension OrderStatusHistoryEntryPatterns on OrderStatusHistoryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderStatusHistoryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderStatusHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderStatusHistoryEntry value)  $default,){
final _that = this;
switch (_that) {
case _OrderStatusHistoryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderStatusHistoryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OrderStatusHistoryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrderStatus? previousStatus,  OrderStatus newStatus,  DateTime changedAt,  String actorId,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderStatusHistoryEntry() when $default != null:
return $default(_that.previousStatus,_that.newStatus,_that.changedAt,_that.actorId,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrderStatus? previousStatus,  OrderStatus newStatus,  DateTime changedAt,  String actorId,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _OrderStatusHistoryEntry():
return $default(_that.previousStatus,_that.newStatus,_that.changedAt,_that.actorId,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrderStatus? previousStatus,  OrderStatus newStatus,  DateTime changedAt,  String actorId,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _OrderStatusHistoryEntry() when $default != null:
return $default(_that.previousStatus,_that.newStatus,_that.changedAt,_that.actorId,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _OrderStatusHistoryEntry implements OrderStatusHistoryEntry {
  const _OrderStatusHistoryEntry({this.previousStatus, required this.newStatus, required this.changedAt, required this.actorId, this.reason});
  

@override final  OrderStatus? previousStatus;
@override final  OrderStatus newStatus;
@override final  DateTime changedAt;
@override final  String actorId;
@override final  String? reason;

/// Create a copy of OrderStatusHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderStatusHistoryEntryCopyWith<_OrderStatusHistoryEntry> get copyWith => __$OrderStatusHistoryEntryCopyWithImpl<_OrderStatusHistoryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderStatusHistoryEntry&&(identical(other.previousStatus, previousStatus) || other.previousStatus == previousStatus)&&(identical(other.newStatus, newStatus) || other.newStatus == newStatus)&&(identical(other.changedAt, changedAt) || other.changedAt == changedAt)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,previousStatus,newStatus,changedAt,actorId,reason);

@override
String toString() {
  return 'OrderStatusHistoryEntry(previousStatus: $previousStatus, newStatus: $newStatus, changedAt: $changedAt, actorId: $actorId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$OrderStatusHistoryEntryCopyWith<$Res> implements $OrderStatusHistoryEntryCopyWith<$Res> {
  factory _$OrderStatusHistoryEntryCopyWith(_OrderStatusHistoryEntry value, $Res Function(_OrderStatusHistoryEntry) _then) = __$OrderStatusHistoryEntryCopyWithImpl;
@override @useResult
$Res call({
 OrderStatus? previousStatus, OrderStatus newStatus, DateTime changedAt, String actorId, String? reason
});




}
/// @nodoc
class __$OrderStatusHistoryEntryCopyWithImpl<$Res>
    implements _$OrderStatusHistoryEntryCopyWith<$Res> {
  __$OrderStatusHistoryEntryCopyWithImpl(this._self, this._then);

  final _OrderStatusHistoryEntry _self;
  final $Res Function(_OrderStatusHistoryEntry) _then;

/// Create a copy of OrderStatusHistoryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? previousStatus = freezed,Object? newStatus = null,Object? changedAt = null,Object? actorId = null,Object? reason = freezed,}) {
  return _then(_OrderStatusHistoryEntry(
previousStatus: freezed == previousStatus ? _self.previousStatus : previousStatus // ignore: cast_nullable_to_non_nullable
as OrderStatus?,newStatus: null == newStatus ? _self.newStatus : newStatus // ignore: cast_nullable_to_non_nullable
as OrderStatus,changedAt: null == changedAt ? _self.changedAt : changedAt // ignore: cast_nullable_to_non_nullable
as DateTime,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
