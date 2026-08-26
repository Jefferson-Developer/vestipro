// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_share_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogShareItem {

 String get productId; String get name; String? get imageUrl;
/// Create a copy of CatalogShareItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogShareItemCopyWith<CatalogShareItem> get copyWith => _$CatalogShareItemCopyWithImpl<CatalogShareItem>(this as CatalogShareItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogShareItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,productId,name,imageUrl);

@override
String toString() {
  return 'CatalogShareItem(productId: $productId, name: $name, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $CatalogShareItemCopyWith<$Res>  {
  factory $CatalogShareItemCopyWith(CatalogShareItem value, $Res Function(CatalogShareItem) _then) = _$CatalogShareItemCopyWithImpl;
@useResult
$Res call({
 String productId, String name, String? imageUrl
});




}
/// @nodoc
class _$CatalogShareItemCopyWithImpl<$Res>
    implements $CatalogShareItemCopyWith<$Res> {
  _$CatalogShareItemCopyWithImpl(this._self, this._then);

  final CatalogShareItem _self;
  final $Res Function(CatalogShareItem) _then;

/// Create a copy of CatalogShareItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? name = null,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogShareItem].
extension CatalogShareItemPatterns on CatalogShareItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogShareItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogShareItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogShareItem value)  $default,){
final _that = this;
switch (_that) {
case _CatalogShareItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogShareItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogShareItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String name,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogShareItem() when $default != null:
return $default(_that.productId,_that.name,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String name,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _CatalogShareItem():
return $default(_that.productId,_that.name,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String name,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _CatalogShareItem() when $default != null:
return $default(_that.productId,_that.name,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogShareItem implements CatalogShareItem {
  const _CatalogShareItem({required this.productId, required this.name, this.imageUrl});
  

@override final  String productId;
@override final  String name;
@override final  String? imageUrl;

/// Create a copy of CatalogShareItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogShareItemCopyWith<_CatalogShareItem> get copyWith => __$CatalogShareItemCopyWithImpl<_CatalogShareItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogShareItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.name, name) || other.name == name)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,productId,name,imageUrl);

@override
String toString() {
  return 'CatalogShareItem(productId: $productId, name: $name, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$CatalogShareItemCopyWith<$Res> implements $CatalogShareItemCopyWith<$Res> {
  factory _$CatalogShareItemCopyWith(_CatalogShareItem value, $Res Function(_CatalogShareItem) _then) = __$CatalogShareItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String name, String? imageUrl
});




}
/// @nodoc
class __$CatalogShareItemCopyWithImpl<$Res>
    implements _$CatalogShareItemCopyWith<$Res> {
  __$CatalogShareItemCopyWithImpl(this._self, this._then);

  final _CatalogShareItem _self;
  final $Res Function(_CatalogShareItem) _then;

/// Create a copy of CatalogShareItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? name = null,Object? imageUrl = freezed,}) {
  return _then(_CatalogShareItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
