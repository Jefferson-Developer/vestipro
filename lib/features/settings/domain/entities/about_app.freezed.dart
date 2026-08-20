// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_app.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutApp {

 String get name; AppVersion get version; String get environmentLabel; DateTime get updatedAt;
/// Create a copy of AboutApp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppCopyWith<AboutApp> get copyWith => _$AboutAppCopyWithImpl<AboutApp>(this as AboutApp, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutApp&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.environmentLabel, environmentLabel) || other.environmentLabel == environmentLabel)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,name,version,environmentLabel,updatedAt);

@override
String toString() {
  return 'AboutApp(name: $name, version: $version, environmentLabel: $environmentLabel, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AboutAppCopyWith<$Res>  {
  factory $AboutAppCopyWith(AboutApp value, $Res Function(AboutApp) _then) = _$AboutAppCopyWithImpl;
@useResult
$Res call({
 String name, AppVersion version, String environmentLabel, DateTime updatedAt
});


$AppVersionCopyWith<$Res> get version;

}
/// @nodoc
class _$AboutAppCopyWithImpl<$Res>
    implements $AboutAppCopyWith<$Res> {
  _$AboutAppCopyWithImpl(this._self, this._then);

  final AboutApp _self;
  final $Res Function(AboutApp) _then;

/// Create a copy of AboutApp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? version = null,Object? environmentLabel = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as AppVersion,environmentLabel: null == environmentLabel ? _self.environmentLabel : environmentLabel // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of AboutApp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppVersionCopyWith<$Res> get version {
  
  return $AppVersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}


/// Adds pattern-matching-related methods to [AboutApp].
extension AboutAppPatterns on AboutApp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AboutApp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AboutApp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AboutApp value)  $default,){
final _that = this;
switch (_that) {
case _AboutApp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AboutApp value)?  $default,){
final _that = this;
switch (_that) {
case _AboutApp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  AppVersion version,  String environmentLabel,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AboutApp() when $default != null:
return $default(_that.name,_that.version,_that.environmentLabel,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  AppVersion version,  String environmentLabel,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AboutApp():
return $default(_that.name,_that.version,_that.environmentLabel,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  AppVersion version,  String environmentLabel,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AboutApp() when $default != null:
return $default(_that.name,_that.version,_that.environmentLabel,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AboutApp implements AboutApp {
  const _AboutApp({required this.name, required this.version, required this.environmentLabel, required this.updatedAt});
  

@override final  String name;
@override final  AppVersion version;
@override final  String environmentLabel;
@override final  DateTime updatedAt;

/// Create a copy of AboutApp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AboutAppCopyWith<_AboutApp> get copyWith => __$AboutAppCopyWithImpl<_AboutApp>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AboutApp&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.environmentLabel, environmentLabel) || other.environmentLabel == environmentLabel)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,name,version,environmentLabel,updatedAt);

@override
String toString() {
  return 'AboutApp(name: $name, version: $version, environmentLabel: $environmentLabel, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AboutAppCopyWith<$Res> implements $AboutAppCopyWith<$Res> {
  factory _$AboutAppCopyWith(_AboutApp value, $Res Function(_AboutApp) _then) = __$AboutAppCopyWithImpl;
@override @useResult
$Res call({
 String name, AppVersion version, String environmentLabel, DateTime updatedAt
});


@override $AppVersionCopyWith<$Res> get version;

}
/// @nodoc
class __$AboutAppCopyWithImpl<$Res>
    implements _$AboutAppCopyWith<$Res> {
  __$AboutAppCopyWithImpl(this._self, this._then);

  final _AboutApp _self;
  final $Res Function(_AboutApp) _then;

/// Create a copy of AboutApp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? version = null,Object? environmentLabel = null,Object? updatedAt = null,}) {
  return _then(_AboutApp(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as AppVersion,environmentLabel: null == environmentLabel ? _self.environmentLabel : environmentLabel // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of AboutApp
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppVersionCopyWith<$Res> get version {
  
  return $AppVersionCopyWith<$Res>(_self.version, (value) {
    return _then(_self.copyWith(version: value));
  });
}
}

// dart format on
