// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_home_section_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogHomeSectionConfig {

 CatalogHomeSectionType get type; String get title; int get order; int get priority; bool get enabled; int get itemLimit;
/// Create a copy of CatalogHomeSectionConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogHomeSectionConfigCopyWith<CatalogHomeSectionConfig> get copyWith => _$CatalogHomeSectionConfigCopyWithImpl<CatalogHomeSectionConfig>(this as CatalogHomeSectionConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogHomeSectionConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.itemLimit, itemLimit) || other.itemLimit == itemLimit));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,order,priority,enabled,itemLimit);

@override
String toString() {
  return 'CatalogHomeSectionConfig(type: $type, title: $title, order: $order, priority: $priority, enabled: $enabled, itemLimit: $itemLimit)';
}


}

/// @nodoc
abstract mixin class $CatalogHomeSectionConfigCopyWith<$Res>  {
  factory $CatalogHomeSectionConfigCopyWith(CatalogHomeSectionConfig value, $Res Function(CatalogHomeSectionConfig) _then) = _$CatalogHomeSectionConfigCopyWithImpl;
@useResult
$Res call({
 CatalogHomeSectionType type, String title, int order, int priority, bool enabled, int itemLimit
});




}
/// @nodoc
class _$CatalogHomeSectionConfigCopyWithImpl<$Res>
    implements $CatalogHomeSectionConfigCopyWith<$Res> {
  _$CatalogHomeSectionConfigCopyWithImpl(this._self, this._then);

  final CatalogHomeSectionConfig _self;
  final $Res Function(CatalogHomeSectionConfig) _then;

/// Create a copy of CatalogHomeSectionConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? order = null,Object? priority = null,Object? enabled = null,Object? itemLimit = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CatalogHomeSectionType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,itemLimit: null == itemLimit ? _self.itemLimit : itemLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogHomeSectionConfig].
extension CatalogHomeSectionConfigPatterns on CatalogHomeSectionConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogHomeSectionConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogHomeSectionConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogHomeSectionConfig value)  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeSectionConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogHomeSectionConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeSectionConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogHomeSectionType type,  String title,  int order,  int priority,  bool enabled,  int itemLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogHomeSectionConfig() when $default != null:
return $default(_that.type,_that.title,_that.order,_that.priority,_that.enabled,_that.itemLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogHomeSectionType type,  String title,  int order,  int priority,  bool enabled,  int itemLimit)  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeSectionConfig():
return $default(_that.type,_that.title,_that.order,_that.priority,_that.enabled,_that.itemLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogHomeSectionType type,  String title,  int order,  int priority,  bool enabled,  int itemLimit)?  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeSectionConfig() when $default != null:
return $default(_that.type,_that.title,_that.order,_that.priority,_that.enabled,_that.itemLimit);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogHomeSectionConfig implements CatalogHomeSectionConfig {
  const _CatalogHomeSectionConfig({required this.type, required this.title, required this.order, required this.priority, this.enabled = true, this.itemLimit = 12});
  

@override final  CatalogHomeSectionType type;
@override final  String title;
@override final  int order;
@override final  int priority;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int itemLimit;

/// Create a copy of CatalogHomeSectionConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogHomeSectionConfigCopyWith<_CatalogHomeSectionConfig> get copyWith => __$CatalogHomeSectionConfigCopyWithImpl<_CatalogHomeSectionConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogHomeSectionConfig&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.itemLimit, itemLimit) || other.itemLimit == itemLimit));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,order,priority,enabled,itemLimit);

@override
String toString() {
  return 'CatalogHomeSectionConfig(type: $type, title: $title, order: $order, priority: $priority, enabled: $enabled, itemLimit: $itemLimit)';
}


}

/// @nodoc
abstract mixin class _$CatalogHomeSectionConfigCopyWith<$Res> implements $CatalogHomeSectionConfigCopyWith<$Res> {
  factory _$CatalogHomeSectionConfigCopyWith(_CatalogHomeSectionConfig value, $Res Function(_CatalogHomeSectionConfig) _then) = __$CatalogHomeSectionConfigCopyWithImpl;
@override @useResult
$Res call({
 CatalogHomeSectionType type, String title, int order, int priority, bool enabled, int itemLimit
});




}
/// @nodoc
class __$CatalogHomeSectionConfigCopyWithImpl<$Res>
    implements _$CatalogHomeSectionConfigCopyWith<$Res> {
  __$CatalogHomeSectionConfigCopyWithImpl(this._self, this._then);

  final _CatalogHomeSectionConfig _self;
  final $Res Function(_CatalogHomeSectionConfig) _then;

/// Create a copy of CatalogHomeSectionConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? order = null,Object? priority = null,Object? enabled = null,Object? itemLimit = null,}) {
  return _then(_CatalogHomeSectionConfig(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CatalogHomeSectionType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,itemLimit: null == itemLimit ? _self.itemLimit : itemLimit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
