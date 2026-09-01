// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InsightAction {

 InsightActionType get type; String get label; String? get route; String? get customerId; String? get productId; String? get sellerId; Map<String, Object?> get payload;
/// Create a copy of InsightAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightActionCopyWith<InsightAction> get copyWith => _$InsightActionCopyWithImpl<InsightAction>(this as InsightAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightAction&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.route, route) || other.route == route)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&const DeepCollectionEquality().equals(other.payload, payload));
}


@override
int get hashCode => Object.hash(runtimeType,type,label,route,customerId,productId,sellerId,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'InsightAction(type: $type, label: $label, route: $route, customerId: $customerId, productId: $productId, sellerId: $sellerId, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $InsightActionCopyWith<$Res>  {
  factory $InsightActionCopyWith(InsightAction value, $Res Function(InsightAction) _then) = _$InsightActionCopyWithImpl;
@useResult
$Res call({
 InsightActionType type, String label, String? route, String? customerId, String? productId, String? sellerId, Map<String, Object?> payload
});




}
/// @nodoc
class _$InsightActionCopyWithImpl<$Res>
    implements $InsightActionCopyWith<$Res> {
  _$InsightActionCopyWithImpl(this._self, this._then);

  final InsightAction _self;
  final $Res Function(InsightAction) _then;

/// Create a copy of InsightAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? label = null,Object? route = freezed,Object? customerId = freezed,Object? productId = freezed,Object? sellerId = freezed,Object? payload = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InsightActionType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightAction].
extension InsightActionPatterns on InsightAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightAction value)  $default,){
final _that = this;
switch (_that) {
case _InsightAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightAction value)?  $default,){
final _that = this;
switch (_that) {
case _InsightAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InsightActionType type,  String label,  String? route,  String? customerId,  String? productId,  String? sellerId,  Map<String, Object?> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightAction() when $default != null:
return $default(_that.type,_that.label,_that.route,_that.customerId,_that.productId,_that.sellerId,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InsightActionType type,  String label,  String? route,  String? customerId,  String? productId,  String? sellerId,  Map<String, Object?> payload)  $default,) {final _that = this;
switch (_that) {
case _InsightAction():
return $default(_that.type,_that.label,_that.route,_that.customerId,_that.productId,_that.sellerId,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InsightActionType type,  String label,  String? route,  String? customerId,  String? productId,  String? sellerId,  Map<String, Object?> payload)?  $default,) {final _that = this;
switch (_that) {
case _InsightAction() when $default != null:
return $default(_that.type,_that.label,_that.route,_that.customerId,_that.productId,_that.sellerId,_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class _InsightAction implements InsightAction {
  const _InsightAction({required this.type, required this.label, this.route, this.customerId, this.productId, this.sellerId, final  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload;
  

@override final  InsightActionType type;
@override final  String label;
@override final  String? route;
@override final  String? customerId;
@override final  String? productId;
@override final  String? sellerId;
 final  Map<String, Object?> _payload;
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of InsightAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightActionCopyWith<_InsightAction> get copyWith => __$InsightActionCopyWithImpl<_InsightAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightAction&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.route, route) || other.route == route)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&const DeepCollectionEquality().equals(other._payload, _payload));
}


@override
int get hashCode => Object.hash(runtimeType,type,label,route,customerId,productId,sellerId,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'InsightAction(type: $type, label: $label, route: $route, customerId: $customerId, productId: $productId, sellerId: $sellerId, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$InsightActionCopyWith<$Res> implements $InsightActionCopyWith<$Res> {
  factory _$InsightActionCopyWith(_InsightAction value, $Res Function(_InsightAction) _then) = __$InsightActionCopyWithImpl;
@override @useResult
$Res call({
 InsightActionType type, String label, String? route, String? customerId, String? productId, String? sellerId, Map<String, Object?> payload
});




}
/// @nodoc
class __$InsightActionCopyWithImpl<$Res>
    implements _$InsightActionCopyWith<$Res> {
  __$InsightActionCopyWithImpl(this._self, this._then);

  final _InsightAction _self;
  final $Res Function(_InsightAction) _then;

/// Create a copy of InsightAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? label = null,Object? route = freezed,Object? customerId = freezed,Object? productId = freezed,Object? sellerId = freezed,Object? payload = null,}) {
  return _then(_InsightAction(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InsightActionType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
