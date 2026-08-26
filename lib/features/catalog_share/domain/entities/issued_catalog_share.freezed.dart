// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issued_catalog_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IssuedCatalogShare {

 CatalogShare get share; String get token;
/// Create a copy of IssuedCatalogShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedCatalogShareCopyWith<IssuedCatalogShare> get copyWith => _$IssuedCatalogShareCopyWithImpl<IssuedCatalogShare>(this as IssuedCatalogShare, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedCatalogShare&&(identical(other.share, share) || other.share == share)&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,share,token);

@override
String toString() {
  return 'IssuedCatalogShare(share: $share, token: $token)';
}


}

/// @nodoc
abstract mixin class $IssuedCatalogShareCopyWith<$Res>  {
  factory $IssuedCatalogShareCopyWith(IssuedCatalogShare value, $Res Function(IssuedCatalogShare) _then) = _$IssuedCatalogShareCopyWithImpl;
@useResult
$Res call({
 CatalogShare share, String token
});


$CatalogShareCopyWith<$Res> get share;

}
/// @nodoc
class _$IssuedCatalogShareCopyWithImpl<$Res>
    implements $IssuedCatalogShareCopyWith<$Res> {
  _$IssuedCatalogShareCopyWithImpl(this._self, this._then);

  final IssuedCatalogShare _self;
  final $Res Function(IssuedCatalogShare) _then;

/// Create a copy of IssuedCatalogShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? share = null,Object? token = null,}) {
  return _then(_self.copyWith(
share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as CatalogShare,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of IssuedCatalogShare
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogShareCopyWith<$Res> get share {
  
  return $CatalogShareCopyWith<$Res>(_self.share, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssuedCatalogShare].
extension IssuedCatalogSharePatterns on IssuedCatalogShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuedCatalogShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuedCatalogShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuedCatalogShare value)  $default,){
final _that = this;
switch (_that) {
case _IssuedCatalogShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuedCatalogShare value)?  $default,){
final _that = this;
switch (_that) {
case _IssuedCatalogShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogShare share,  String token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedCatalogShare() when $default != null:
return $default(_that.share,_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogShare share,  String token)  $default,) {final _that = this;
switch (_that) {
case _IssuedCatalogShare():
return $default(_that.share,_that.token);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogShare share,  String token)?  $default,) {final _that = this;
switch (_that) {
case _IssuedCatalogShare() when $default != null:
return $default(_that.share,_that.token);case _:
  return null;

}
}

}

/// @nodoc


class _IssuedCatalogShare implements IssuedCatalogShare {
  const _IssuedCatalogShare({required this.share, required this.token});
  

@override final  CatalogShare share;
@override final  String token;

/// Create a copy of IssuedCatalogShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedCatalogShareCopyWith<_IssuedCatalogShare> get copyWith => __$IssuedCatalogShareCopyWithImpl<_IssuedCatalogShare>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedCatalogShare&&(identical(other.share, share) || other.share == share)&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,share,token);

@override
String toString() {
  return 'IssuedCatalogShare(share: $share, token: $token)';
}


}

/// @nodoc
abstract mixin class _$IssuedCatalogShareCopyWith<$Res> implements $IssuedCatalogShareCopyWith<$Res> {
  factory _$IssuedCatalogShareCopyWith(_IssuedCatalogShare value, $Res Function(_IssuedCatalogShare) _then) = __$IssuedCatalogShareCopyWithImpl;
@override @useResult
$Res call({
 CatalogShare share, String token
});


@override $CatalogShareCopyWith<$Res> get share;

}
/// @nodoc
class __$IssuedCatalogShareCopyWithImpl<$Res>
    implements _$IssuedCatalogShareCopyWith<$Res> {
  __$IssuedCatalogShareCopyWithImpl(this._self, this._then);

  final _IssuedCatalogShare _self;
  final $Res Function(_IssuedCatalogShare) _then;

/// Create a copy of IssuedCatalogShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? share = null,Object? token = null,}) {
  return _then(_IssuedCatalogShare(
share: null == share ? _self.share : share // ignore: cast_nullable_to_non_nullable
as CatalogShare,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of IssuedCatalogShare
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogShareCopyWith<$Res> get share {
  
  return $CatalogShareCopyWith<$Res>(_self.share, (value) {
    return _then(_self.copyWith(share: value));
  });
}
}

// dart format on
