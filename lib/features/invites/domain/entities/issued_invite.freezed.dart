// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issued_invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IssuedInvite {

 Invite get invite; String get token;
/// Create a copy of IssuedInvite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedInviteCopyWith<IssuedInvite> get copyWith => _$IssuedInviteCopyWithImpl<IssuedInvite>(this as IssuedInvite, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedInvite&&(identical(other.invite, invite) || other.invite == invite)&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,invite,token);

@override
String toString() {
  return 'IssuedInvite(invite: $invite, token: $token)';
}


}

/// @nodoc
abstract mixin class $IssuedInviteCopyWith<$Res>  {
  factory $IssuedInviteCopyWith(IssuedInvite value, $Res Function(IssuedInvite) _then) = _$IssuedInviteCopyWithImpl;
@useResult
$Res call({
 Invite invite, String token
});


$InviteCopyWith<$Res> get invite;

}
/// @nodoc
class _$IssuedInviteCopyWithImpl<$Res>
    implements $IssuedInviteCopyWith<$Res> {
  _$IssuedInviteCopyWithImpl(this._self, this._then);

  final IssuedInvite _self;
  final $Res Function(IssuedInvite) _then;

/// Create a copy of IssuedInvite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invite = null,Object? token = null,}) {
  return _then(_self.copyWith(
invite: null == invite ? _self.invite : invite // ignore: cast_nullable_to_non_nullable
as Invite,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of IssuedInvite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteCopyWith<$Res> get invite {
  
  return $InviteCopyWith<$Res>(_self.invite, (value) {
    return _then(_self.copyWith(invite: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssuedInvite].
extension IssuedInvitePatterns on IssuedInvite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuedInvite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuedInvite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuedInvite value)  $default,){
final _that = this;
switch (_that) {
case _IssuedInvite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuedInvite value)?  $default,){
final _that = this;
switch (_that) {
case _IssuedInvite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Invite invite,  String token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedInvite() when $default != null:
return $default(_that.invite,_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Invite invite,  String token)  $default,) {final _that = this;
switch (_that) {
case _IssuedInvite():
return $default(_that.invite,_that.token);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Invite invite,  String token)?  $default,) {final _that = this;
switch (_that) {
case _IssuedInvite() when $default != null:
return $default(_that.invite,_that.token);case _:
  return null;

}
}

}

/// @nodoc


class _IssuedInvite implements IssuedInvite {
  const _IssuedInvite({required this.invite, required this.token});
  

@override final  Invite invite;
@override final  String token;

/// Create a copy of IssuedInvite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedInviteCopyWith<_IssuedInvite> get copyWith => __$IssuedInviteCopyWithImpl<_IssuedInvite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedInvite&&(identical(other.invite, invite) || other.invite == invite)&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,invite,token);

@override
String toString() {
  return 'IssuedInvite(invite: $invite, token: $token)';
}


}

/// @nodoc
abstract mixin class _$IssuedInviteCopyWith<$Res> implements $IssuedInviteCopyWith<$Res> {
  factory _$IssuedInviteCopyWith(_IssuedInvite value, $Res Function(_IssuedInvite) _then) = __$IssuedInviteCopyWithImpl;
@override @useResult
$Res call({
 Invite invite, String token
});


@override $InviteCopyWith<$Res> get invite;

}
/// @nodoc
class __$IssuedInviteCopyWithImpl<$Res>
    implements _$IssuedInviteCopyWith<$Res> {
  __$IssuedInviteCopyWithImpl(this._self, this._then);

  final _IssuedInvite _self;
  final $Res Function(_IssuedInvite) _then;

/// Create a copy of IssuedInvite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invite = null,Object? token = null,}) {
  return _then(_IssuedInvite(
invite: null == invite ? _self.invite : invite // ignore: cast_nullable_to_non_nullable
as Invite,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of IssuedInvite
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteCopyWith<$Res> get invite {
  
  return $InviteCopyWith<$Res>(_self.invite, (value) {
    return _then(_self.copyWith(invite: value));
  });
}
}

// dart format on
