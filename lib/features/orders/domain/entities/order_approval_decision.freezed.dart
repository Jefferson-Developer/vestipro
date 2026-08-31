// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_approval_decision.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderApprovalDecision {

 String get approverId; OrderApprovalDecisionValue get decision; String? get reason; DateTime get decidedAt;
/// Create a copy of OrderApprovalDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderApprovalDecisionCopyWith<OrderApprovalDecision> get copyWith => _$OrderApprovalDecisionCopyWithImpl<OrderApprovalDecision>(this as OrderApprovalDecision, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderApprovalDecision&&(identical(other.approverId, approverId) || other.approverId == approverId)&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}


@override
int get hashCode => Object.hash(runtimeType,approverId,decision,reason,decidedAt);

@override
String toString() {
  return 'OrderApprovalDecision(approverId: $approverId, decision: $decision, reason: $reason, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class $OrderApprovalDecisionCopyWith<$Res>  {
  factory $OrderApprovalDecisionCopyWith(OrderApprovalDecision value, $Res Function(OrderApprovalDecision) _then) = _$OrderApprovalDecisionCopyWithImpl;
@useResult
$Res call({
 String approverId, OrderApprovalDecisionValue decision, String? reason, DateTime decidedAt
});




}
/// @nodoc
class _$OrderApprovalDecisionCopyWithImpl<$Res>
    implements $OrderApprovalDecisionCopyWith<$Res> {
  _$OrderApprovalDecisionCopyWithImpl(this._self, this._then);

  final OrderApprovalDecision _self;
  final $Res Function(OrderApprovalDecision) _then;

/// Create a copy of OrderApprovalDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? approverId = null,Object? decision = null,Object? reason = freezed,Object? decidedAt = null,}) {
  return _then(_self.copyWith(
approverId: null == approverId ? _self.approverId : approverId // ignore: cast_nullable_to_non_nullable
as String,decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as OrderApprovalDecisionValue,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: null == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderApprovalDecision].
extension OrderApprovalDecisionPatterns on OrderApprovalDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderApprovalDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderApprovalDecision() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderApprovalDecision value)  $default,){
final _that = this;
switch (_that) {
case _OrderApprovalDecision():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderApprovalDecision value)?  $default,){
final _that = this;
switch (_that) {
case _OrderApprovalDecision() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String approverId,  OrderApprovalDecisionValue decision,  String? reason,  DateTime decidedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderApprovalDecision() when $default != null:
return $default(_that.approverId,_that.decision,_that.reason,_that.decidedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String approverId,  OrderApprovalDecisionValue decision,  String? reason,  DateTime decidedAt)  $default,) {final _that = this;
switch (_that) {
case _OrderApprovalDecision():
return $default(_that.approverId,_that.decision,_that.reason,_that.decidedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String approverId,  OrderApprovalDecisionValue decision,  String? reason,  DateTime decidedAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderApprovalDecision() when $default != null:
return $default(_that.approverId,_that.decision,_that.reason,_that.decidedAt);case _:
  return null;

}
}

}

/// @nodoc


class _OrderApprovalDecision extends OrderApprovalDecision {
  const _OrderApprovalDecision({required this.approverId, required this.decision, this.reason, required this.decidedAt}): super._();
  

@override final  String approverId;
@override final  OrderApprovalDecisionValue decision;
@override final  String? reason;
@override final  DateTime decidedAt;

/// Create a copy of OrderApprovalDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderApprovalDecisionCopyWith<_OrderApprovalDecision> get copyWith => __$OrderApprovalDecisionCopyWithImpl<_OrderApprovalDecision>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderApprovalDecision&&(identical(other.approverId, approverId) || other.approverId == approverId)&&(identical(other.decision, decision) || other.decision == decision)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt));
}


@override
int get hashCode => Object.hash(runtimeType,approverId,decision,reason,decidedAt);

@override
String toString() {
  return 'OrderApprovalDecision(approverId: $approverId, decision: $decision, reason: $reason, decidedAt: $decidedAt)';
}


}

/// @nodoc
abstract mixin class _$OrderApprovalDecisionCopyWith<$Res> implements $OrderApprovalDecisionCopyWith<$Res> {
  factory _$OrderApprovalDecisionCopyWith(_OrderApprovalDecision value, $Res Function(_OrderApprovalDecision) _then) = __$OrderApprovalDecisionCopyWithImpl;
@override @useResult
$Res call({
 String approverId, OrderApprovalDecisionValue decision, String? reason, DateTime decidedAt
});




}
/// @nodoc
class __$OrderApprovalDecisionCopyWithImpl<$Res>
    implements _$OrderApprovalDecisionCopyWith<$Res> {
  __$OrderApprovalDecisionCopyWithImpl(this._self, this._then);

  final _OrderApprovalDecision _self;
  final $Res Function(_OrderApprovalDecision) _then;

/// Create a copy of OrderApprovalDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? approverId = null,Object? decision = null,Object? reason = freezed,Object? decidedAt = null,}) {
  return _then(_OrderApprovalDecision(
approverId: null == approverId ? _self.approverId : approverId // ignore: cast_nullable_to_non_nullable
as String,decision: null == decision ? _self.decision : decision // ignore: cast_nullable_to_non_nullable
as OrderApprovalDecisionValue,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,decidedAt: null == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
