// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_home_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogHomeItem {

 String get id; String get title; String? get subtitle; String? get imageUrl; String? get badgeLabel;
/// Create a copy of CatalogHomeItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogHomeItemCopyWith<CatalogHomeItem> get copyWith => _$CatalogHomeItemCopyWithImpl<CatalogHomeItem>(this as CatalogHomeItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogHomeItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.badgeLabel, badgeLabel) || other.badgeLabel == badgeLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,subtitle,imageUrl,badgeLabel);

@override
String toString() {
  return 'CatalogHomeItem(id: $id, title: $title, subtitle: $subtitle, imageUrl: $imageUrl, badgeLabel: $badgeLabel)';
}


}

/// @nodoc
abstract mixin class $CatalogHomeItemCopyWith<$Res>  {
  factory $CatalogHomeItemCopyWith(CatalogHomeItem value, $Res Function(CatalogHomeItem) _then) = _$CatalogHomeItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? subtitle, String? imageUrl, String? badgeLabel
});




}
/// @nodoc
class _$CatalogHomeItemCopyWithImpl<$Res>
    implements $CatalogHomeItemCopyWith<$Res> {
  _$CatalogHomeItemCopyWithImpl(this._self, this._then);

  final CatalogHomeItem _self;
  final $Res Function(CatalogHomeItem) _then;

/// Create a copy of CatalogHomeItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? subtitle = freezed,Object? imageUrl = freezed,Object? badgeLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,badgeLabel: freezed == badgeLabel ? _self.badgeLabel : badgeLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogHomeItem].
extension CatalogHomeItemPatterns on CatalogHomeItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogHomeItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogHomeItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogHomeItem value)  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogHomeItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? subtitle,  String? imageUrl,  String? badgeLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogHomeItem() when $default != null:
return $default(_that.id,_that.title,_that.subtitle,_that.imageUrl,_that.badgeLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? subtitle,  String? imageUrl,  String? badgeLabel)  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeItem():
return $default(_that.id,_that.title,_that.subtitle,_that.imageUrl,_that.badgeLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? subtitle,  String? imageUrl,  String? badgeLabel)?  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeItem() when $default != null:
return $default(_that.id,_that.title,_that.subtitle,_that.imageUrl,_that.badgeLabel);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogHomeItem implements CatalogHomeItem {
  const _CatalogHomeItem({required this.id, required this.title, this.subtitle, this.imageUrl, this.badgeLabel});
  

@override final  String id;
@override final  String title;
@override final  String? subtitle;
@override final  String? imageUrl;
@override final  String? badgeLabel;

/// Create a copy of CatalogHomeItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogHomeItemCopyWith<_CatalogHomeItem> get copyWith => __$CatalogHomeItemCopyWithImpl<_CatalogHomeItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogHomeItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.badgeLabel, badgeLabel) || other.badgeLabel == badgeLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,subtitle,imageUrl,badgeLabel);

@override
String toString() {
  return 'CatalogHomeItem(id: $id, title: $title, subtitle: $subtitle, imageUrl: $imageUrl, badgeLabel: $badgeLabel)';
}


}

/// @nodoc
abstract mixin class _$CatalogHomeItemCopyWith<$Res> implements $CatalogHomeItemCopyWith<$Res> {
  factory _$CatalogHomeItemCopyWith(_CatalogHomeItem value, $Res Function(_CatalogHomeItem) _then) = __$CatalogHomeItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? subtitle, String? imageUrl, String? badgeLabel
});




}
/// @nodoc
class __$CatalogHomeItemCopyWithImpl<$Res>
    implements _$CatalogHomeItemCopyWith<$Res> {
  __$CatalogHomeItemCopyWithImpl(this._self, this._then);

  final _CatalogHomeItem _self;
  final $Res Function(_CatalogHomeItem) _then;

/// Create a copy of CatalogHomeItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? subtitle = freezed,Object? imageUrl = freezed,Object? badgeLabel = freezed,}) {
  return _then(_CatalogHomeItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,badgeLabel: freezed == badgeLabel ? _self.badgeLabel : badgeLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
