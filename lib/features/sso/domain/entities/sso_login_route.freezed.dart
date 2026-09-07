// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sso_login_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SsoLoginRoute {

 String get organizationId; String get organizationName; SsoProtocol get protocol; String get providerId;
/// Create a copy of SsoLoginRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SsoLoginRouteCopyWith<SsoLoginRoute> get copyWith => _$SsoLoginRouteCopyWithImpl<SsoLoginRoute>(this as SsoLoginRoute, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SsoLoginRoute&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.providerId, providerId) || other.providerId == providerId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,organizationName,protocol,providerId);

@override
String toString() {
  return 'SsoLoginRoute(organizationId: $organizationId, organizationName: $organizationName, protocol: $protocol, providerId: $providerId)';
}


}

/// @nodoc
abstract mixin class $SsoLoginRouteCopyWith<$Res>  {
  factory $SsoLoginRouteCopyWith(SsoLoginRoute value, $Res Function(SsoLoginRoute) _then) = _$SsoLoginRouteCopyWithImpl;
@useResult
$Res call({
 String organizationId, String organizationName, SsoProtocol protocol, String providerId
});




}
/// @nodoc
class _$SsoLoginRouteCopyWithImpl<$Res>
    implements $SsoLoginRouteCopyWith<$Res> {
  _$SsoLoginRouteCopyWithImpl(this._self, this._then);

  final SsoLoginRoute _self;
  final $Res Function(SsoLoginRoute) _then;

/// Create a copy of SsoLoginRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? organizationName = null,Object? protocol = null,Object? providerId = null,}) {
  return _then(_self.copyWith(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as SsoProtocol,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SsoLoginRoute].
extension SsoLoginRoutePatterns on SsoLoginRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SsoLoginRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SsoLoginRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SsoLoginRoute value)  $default,){
final _that = this;
switch (_that) {
case _SsoLoginRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SsoLoginRoute value)?  $default,){
final _that = this;
switch (_that) {
case _SsoLoginRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String organizationId,  String organizationName,  SsoProtocol protocol,  String providerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SsoLoginRoute() when $default != null:
return $default(_that.organizationId,_that.organizationName,_that.protocol,_that.providerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String organizationId,  String organizationName,  SsoProtocol protocol,  String providerId)  $default,) {final _that = this;
switch (_that) {
case _SsoLoginRoute():
return $default(_that.organizationId,_that.organizationName,_that.protocol,_that.providerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String organizationId,  String organizationName,  SsoProtocol protocol,  String providerId)?  $default,) {final _that = this;
switch (_that) {
case _SsoLoginRoute() when $default != null:
return $default(_that.organizationId,_that.organizationName,_that.protocol,_that.providerId);case _:
  return null;

}
}

}

/// @nodoc


class _SsoLoginRoute implements SsoLoginRoute {
  const _SsoLoginRoute({required this.organizationId, required this.organizationName, required this.protocol, required this.providerId});
  

@override final  String organizationId;
@override final  String organizationName;
@override final  SsoProtocol protocol;
@override final  String providerId;

/// Create a copy of SsoLoginRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SsoLoginRouteCopyWith<_SsoLoginRoute> get copyWith => __$SsoLoginRouteCopyWithImpl<_SsoLoginRoute>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SsoLoginRoute&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.protocol, protocol) || other.protocol == protocol)&&(identical(other.providerId, providerId) || other.providerId == providerId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,organizationName,protocol,providerId);

@override
String toString() {
  return 'SsoLoginRoute(organizationId: $organizationId, organizationName: $organizationName, protocol: $protocol, providerId: $providerId)';
}


}

/// @nodoc
abstract mixin class _$SsoLoginRouteCopyWith<$Res> implements $SsoLoginRouteCopyWith<$Res> {
  factory _$SsoLoginRouteCopyWith(_SsoLoginRoute value, $Res Function(_SsoLoginRoute) _then) = __$SsoLoginRouteCopyWithImpl;
@override @useResult
$Res call({
 String organizationId, String organizationName, SsoProtocol protocol, String providerId
});




}
/// @nodoc
class __$SsoLoginRouteCopyWithImpl<$Res>
    implements _$SsoLoginRouteCopyWith<$Res> {
  __$SsoLoginRouteCopyWithImpl(this._self, this._then);

  final _SsoLoginRoute _self;
  final $Res Function(_SsoLoginRoute) _then;

/// Create a copy of SsoLoginRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? organizationName = null,Object? protocol = null,Object? providerId = null,}) {
  return _then(_SsoLoginRoute(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,protocol: null == protocol ? _self.protocol : protocol // ignore: cast_nullable_to_non_nullable
as SsoProtocol,providerId: null == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
