// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completed_sso_login.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompletedSsoLogin {

 String get organizationId; String get organizationName; String get roleName; bool get provisioned;
/// Create a copy of CompletedSsoLogin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletedSsoLoginCopyWith<CompletedSsoLogin> get copyWith => _$CompletedSsoLoginCopyWithImpl<CompletedSsoLogin>(this as CompletedSsoLogin, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletedSsoLogin&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.provisioned, provisioned) || other.provisioned == provisioned));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,organizationName,roleName,provisioned);

@override
String toString() {
  return 'CompletedSsoLogin(organizationId: $organizationId, organizationName: $organizationName, roleName: $roleName, provisioned: $provisioned)';
}


}

/// @nodoc
abstract mixin class $CompletedSsoLoginCopyWith<$Res>  {
  factory $CompletedSsoLoginCopyWith(CompletedSsoLogin value, $Res Function(CompletedSsoLogin) _then) = _$CompletedSsoLoginCopyWithImpl;
@useResult
$Res call({
 String organizationId, String organizationName, String roleName, bool provisioned
});




}
/// @nodoc
class _$CompletedSsoLoginCopyWithImpl<$Res>
    implements $CompletedSsoLoginCopyWith<$Res> {
  _$CompletedSsoLoginCopyWithImpl(this._self, this._then);

  final CompletedSsoLogin _self;
  final $Res Function(CompletedSsoLogin) _then;

/// Create a copy of CompletedSsoLogin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organizationId = null,Object? organizationName = null,Object? roleName = null,Object? provisioned = null,}) {
  return _then(_self.copyWith(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String,provisioned: null == provisioned ? _self.provisioned : provisioned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CompletedSsoLogin].
extension CompletedSsoLoginPatterns on CompletedSsoLogin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletedSsoLogin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletedSsoLogin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletedSsoLogin value)  $default,){
final _that = this;
switch (_that) {
case _CompletedSsoLogin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletedSsoLogin value)?  $default,){
final _that = this;
switch (_that) {
case _CompletedSsoLogin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String organizationId,  String organizationName,  String roleName,  bool provisioned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletedSsoLogin() when $default != null:
return $default(_that.organizationId,_that.organizationName,_that.roleName,_that.provisioned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String organizationId,  String organizationName,  String roleName,  bool provisioned)  $default,) {final _that = this;
switch (_that) {
case _CompletedSsoLogin():
return $default(_that.organizationId,_that.organizationName,_that.roleName,_that.provisioned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String organizationId,  String organizationName,  String roleName,  bool provisioned)?  $default,) {final _that = this;
switch (_that) {
case _CompletedSsoLogin() when $default != null:
return $default(_that.organizationId,_that.organizationName,_that.roleName,_that.provisioned);case _:
  return null;

}
}

}

/// @nodoc


class _CompletedSsoLogin implements CompletedSsoLogin {
  const _CompletedSsoLogin({required this.organizationId, required this.organizationName, required this.roleName, required this.provisioned});
  

@override final  String organizationId;
@override final  String organizationName;
@override final  String roleName;
@override final  bool provisioned;

/// Create a copy of CompletedSsoLogin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletedSsoLoginCopyWith<_CompletedSsoLogin> get copyWith => __$CompletedSsoLoginCopyWithImpl<_CompletedSsoLogin>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletedSsoLogin&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.provisioned, provisioned) || other.provisioned == provisioned));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,organizationName,roleName,provisioned);

@override
String toString() {
  return 'CompletedSsoLogin(organizationId: $organizationId, organizationName: $organizationName, roleName: $roleName, provisioned: $provisioned)';
}


}

/// @nodoc
abstract mixin class _$CompletedSsoLoginCopyWith<$Res> implements $CompletedSsoLoginCopyWith<$Res> {
  factory _$CompletedSsoLoginCopyWith(_CompletedSsoLogin value, $Res Function(_CompletedSsoLogin) _then) = __$CompletedSsoLoginCopyWithImpl;
@override @useResult
$Res call({
 String organizationId, String organizationName, String roleName, bool provisioned
});




}
/// @nodoc
class __$CompletedSsoLoginCopyWithImpl<$Res>
    implements _$CompletedSsoLoginCopyWith<$Res> {
  __$CompletedSsoLoginCopyWithImpl(this._self, this._then);

  final _CompletedSsoLogin _self;
  final $Res Function(_CompletedSsoLogin) _then;

/// Create a copy of CompletedSsoLogin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? organizationName = null,Object? roleName = null,Object? provisioned = null,}) {
  return _then(_CompletedSsoLogin(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String,provisioned: null == provisioned ? _self.provisioned : provisioned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
