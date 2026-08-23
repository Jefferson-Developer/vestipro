// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accepted_invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AcceptedInvite {

 String get organizationId; String get organizationName; SystemRoleName get roleName;
/// Create a copy of AcceptedInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcceptedInviteCopyWith<AcceptedInvite> get copyWith => _$AcceptedInviteCopyWithImpl<AcceptedInvite>(this as AcceptedInvite, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcceptedInvite&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.roleName, roleName) || other.roleName == roleName));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,organizationName,roleName);

@override
String toString() {
  return 'AcceptedInvite(organizationId: $organizationId, organizationName: $organizationName, roleName: $roleName)';
}


}

/// @nodoc
abstract mixin class $AcceptedInviteCopyWith<$Res>  {
  factory $AcceptedInviteCopyWith(AcceptedInvite value, $Res Function(AcceptedInvite) _then) = _$AcceptedInviteCopyWithImpl;
@useResult
$Res call({
 String organizationId, String organizationName, SystemRoleName roleName
});




}
/// @nodoc
class _$AcceptedInviteCopyWithImpl<$Res>
    implements $AcceptedInviteCopyWith<$Res> {
  _$AcceptedInviteCopyWithImpl(this._self, this._then);

  final AcceptedInvite _self;
  final $Res Function(AcceptedInvite) _then;

/// Create a copy of AcceptedInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? organizationName = null,Object? roleName = null,}) {
  return _then(_self.copyWith(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as SystemRoleName,
  ));
}

}


/// Adds pattern-matching-related methods to [AcceptedInvite].
extension AcceptedInvitePatterns on AcceptedInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcceptedInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcceptedInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcceptedInvite value)  $default,){
final _that = this;
switch (_that) {
case _AcceptedInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcceptedInvite value)?  $default,){
final _that = this;
switch (_that) {
case _AcceptedInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String organizationId,  String organizationName,  SystemRoleName roleName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcceptedInvite() when $default != null:
return $default(_that.organizationId,_that.organizationName,_that.roleName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String organizationId,  String organizationName,  SystemRoleName roleName)  $default,) {final _that = this;
switch (_that) {
case _AcceptedInvite():
return $default(_that.organizationId,_that.organizationName,_that.roleName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String organizationId,  String organizationName,  SystemRoleName roleName)?  $default,) {final _that = this;
switch (_that) {
case _AcceptedInvite() when $default != null:
return $default(_that.organizationId,_that.organizationName,_that.roleName);case _:
  return null;

}
}

}

/// @nodoc


class _AcceptedInvite implements AcceptedInvite {
  const _AcceptedInvite({required this.organizationId, required this.organizationName, required this.roleName});
  

@override final  String organizationId;
@override final  String organizationName;
@override final  SystemRoleName roleName;

/// Create a copy of AcceptedInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcceptedInviteCopyWith<_AcceptedInvite> get copyWith => __$AcceptedInviteCopyWithImpl<_AcceptedInvite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcceptedInvite&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.roleName, roleName) || other.roleName == roleName));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,organizationName,roleName);

@override
String toString() {
  return 'AcceptedInvite(organizationId: $organizationId, organizationName: $organizationName, roleName: $roleName)';
}


}

/// @nodoc
abstract mixin class _$AcceptedInviteCopyWith<$Res> implements $AcceptedInviteCopyWith<$Res> {
  factory _$AcceptedInviteCopyWith(_AcceptedInvite value, $Res Function(_AcceptedInvite) _then) = __$AcceptedInviteCopyWithImpl;
@override @useResult
$Res call({
 String organizationId, String organizationName, SystemRoleName roleName
});




}
/// @nodoc
class __$AcceptedInviteCopyWithImpl<$Res>
    implements _$AcceptedInviteCopyWith<$Res> {
  __$AcceptedInviteCopyWithImpl(this._self, this._then);

  final _AcceptedInvite _self;
  final $Res Function(_AcceptedInvite) _then;

/// Create a copy of AcceptedInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? organizationName = null,Object? roleName = null,}) {
  return _then(_AcceptedInvite(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as SystemRoleName,
  ));
}


}

// dart format on
