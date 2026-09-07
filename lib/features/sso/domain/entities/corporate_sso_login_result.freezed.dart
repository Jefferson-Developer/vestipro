// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'corporate_sso_login_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CorporateSsoLoginResult {

 SessionUser get sessionUser; String get organizationId; String get organizationName;
/// Create a copy of CorporateSsoLoginResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorporateSsoLoginResultCopyWith<CorporateSsoLoginResult> get copyWith => _$CorporateSsoLoginResultCopyWithImpl<CorporateSsoLoginResult>(this as CorporateSsoLoginResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorporateSsoLoginResult&&(identical(other.sessionUser, sessionUser) || other.sessionUser == sessionUser)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName));
}


@override
int get hashCode => Object.hash(runtimeType,sessionUser,organizationId,organizationName);

@override
String toString() {
  return 'CorporateSsoLoginResult(sessionUser: $sessionUser, organizationId: $organizationId, organizationName: $organizationName)';
}


}

/// @nodoc
abstract mixin class $CorporateSsoLoginResultCopyWith<$Res>  {
  factory $CorporateSsoLoginResultCopyWith(CorporateSsoLoginResult value, $Res Function(CorporateSsoLoginResult) _then) = _$CorporateSsoLoginResultCopyWithImpl;
@useResult
$Res call({
 SessionUser sessionUser, String organizationId, String organizationName
});


$SessionUserCopyWith<$Res> get sessionUser;

}
/// @nodoc
class _$CorporateSsoLoginResultCopyWithImpl<$Res>
    implements $CorporateSsoLoginResultCopyWith<$Res> {
  _$CorporateSsoLoginResultCopyWithImpl(this._self, this._then);

  final CorporateSsoLoginResult _self;
  final $Res Function(CorporateSsoLoginResult) _then;

/// Create a copy of CorporateSsoLoginResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionUser = null,Object? organizationId = null,Object? organizationName = null,}) {
  return _then(_self.copyWith(
sessionUser: null == sessionUser ? _self.sessionUser : sessionUser // ignore: cast_nullable_to_non_nullable
as SessionUser,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CorporateSsoLoginResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionUserCopyWith<$Res> get sessionUser {
  
  return $SessionUserCopyWith<$Res>(_self.sessionUser, (value) {
    return _then(_self.copyWith(sessionUser: value));
  });
}
}


/// Adds pattern-matching-related methods to [CorporateSsoLoginResult].
extension CorporateSsoLoginResultPatterns on CorporateSsoLoginResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CorporateSsoLoginResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CorporateSsoLoginResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CorporateSsoLoginResult value)  $default,){
final _that = this;
switch (_that) {
case _CorporateSsoLoginResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CorporateSsoLoginResult value)?  $default,){
final _that = this;
switch (_that) {
case _CorporateSsoLoginResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionUser sessionUser,  String organizationId,  String organizationName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CorporateSsoLoginResult() when $default != null:
return $default(_that.sessionUser,_that.organizationId,_that.organizationName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionUser sessionUser,  String organizationId,  String organizationName)  $default,) {final _that = this;
switch (_that) {
case _CorporateSsoLoginResult():
return $default(_that.sessionUser,_that.organizationId,_that.organizationName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionUser sessionUser,  String organizationId,  String organizationName)?  $default,) {final _that = this;
switch (_that) {
case _CorporateSsoLoginResult() when $default != null:
return $default(_that.sessionUser,_that.organizationId,_that.organizationName);case _:
  return null;

}
}

}

/// @nodoc


class _CorporateSsoLoginResult implements CorporateSsoLoginResult {
  const _CorporateSsoLoginResult({required this.sessionUser, required this.organizationId, required this.organizationName});
  

@override final  SessionUser sessionUser;
@override final  String organizationId;
@override final  String organizationName;

/// Create a copy of CorporateSsoLoginResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorporateSsoLoginResultCopyWith<_CorporateSsoLoginResult> get copyWith => __$CorporateSsoLoginResultCopyWithImpl<_CorporateSsoLoginResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CorporateSsoLoginResult&&(identical(other.sessionUser, sessionUser) || other.sessionUser == sessionUser)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName));
}


@override
int get hashCode => Object.hash(runtimeType,sessionUser,organizationId,organizationName);

@override
String toString() {
  return 'CorporateSsoLoginResult(sessionUser: $sessionUser, organizationId: $organizationId, organizationName: $organizationName)';
}


}

/// @nodoc
abstract mixin class _$CorporateSsoLoginResultCopyWith<$Res> implements $CorporateSsoLoginResultCopyWith<$Res> {
  factory _$CorporateSsoLoginResultCopyWith(_CorporateSsoLoginResult value, $Res Function(_CorporateSsoLoginResult) _then) = __$CorporateSsoLoginResultCopyWithImpl;
@override @useResult
$Res call({
 SessionUser sessionUser, String organizationId, String organizationName
});


@override $SessionUserCopyWith<$Res> get sessionUser;

}
/// @nodoc
class __$CorporateSsoLoginResultCopyWithImpl<$Res>
    implements _$CorporateSsoLoginResultCopyWith<$Res> {
  __$CorporateSsoLoginResultCopyWithImpl(this._self, this._then);

  final _CorporateSsoLoginResult _self;
  final $Res Function(_CorporateSsoLoginResult) _then;

/// Create a copy of CorporateSsoLoginResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionUser = null,Object? organizationId = null,Object? organizationName = null,}) {
  return _then(_CorporateSsoLoginResult(
sessionUser: null == sessionUser ? _self.sessionUser : sessionUser // ignore: cast_nullable_to_non_nullable
as SessionUser,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CorporateSsoLoginResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionUserCopyWith<$Res> get sessionUser {
  
  return $SessionUserCopyWith<$Res>(_self.sessionUser, (value) {
    return _then(_self.copyWith(sessionUser: value));
  });
}
}

// dart format on
