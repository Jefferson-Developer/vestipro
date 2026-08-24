// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_media.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductMedia {

 String get id; ProductMediaType get type; String get url; String? get thumbnailUrl; int get order; bool get principal; String? get colorId;
/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductMediaCopyWith<ProductMedia> get copyWith => _$ProductMediaCopyWithImpl<ProductMedia>(this as ProductMedia, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.order, order) || other.order == order)&&(identical(other.principal, principal) || other.principal == principal)&&(identical(other.colorId, colorId) || other.colorId == colorId));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,url,thumbnailUrl,order,principal,colorId);

@override
String toString() {
  return 'ProductMedia(id: $id, type: $type, url: $url, thumbnailUrl: $thumbnailUrl, order: $order, principal: $principal, colorId: $colorId)';
}


}

/// @nodoc
abstract mixin class $ProductMediaCopyWith<$Res>  {
  factory $ProductMediaCopyWith(ProductMedia value, $Res Function(ProductMedia) _then) = _$ProductMediaCopyWithImpl;
@useResult
$Res call({
 String id, ProductMediaType type, String url, String? thumbnailUrl, int order, bool principal, String? colorId
});




}
/// @nodoc
class _$ProductMediaCopyWithImpl<$Res>
    implements $ProductMediaCopyWith<$Res> {
  _$ProductMediaCopyWithImpl(this._self, this._then);

  final ProductMedia _self;
  final $Res Function(ProductMedia) _then;

/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? url = null,Object? thumbnailUrl = freezed,Object? order = null,Object? principal = null,Object? colorId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductMediaType,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,principal: null == principal ? _self.principal : principal // ignore: cast_nullable_to_non_nullable
as bool,colorId: freezed == colorId ? _self.colorId : colorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductMedia].
extension ProductMediaPatterns on ProductMedia {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductMedia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductMedia value)  $default,){
final _that = this;
switch (_that) {
case _ProductMedia():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductMedia value)?  $default,){
final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ProductMediaType type,  String url,  String? thumbnailUrl,  int order,  bool principal,  String? colorId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
return $default(_that.id,_that.type,_that.url,_that.thumbnailUrl,_that.order,_that.principal,_that.colorId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ProductMediaType type,  String url,  String? thumbnailUrl,  int order,  bool principal,  String? colorId)  $default,) {final _that = this;
switch (_that) {
case _ProductMedia():
return $default(_that.id,_that.type,_that.url,_that.thumbnailUrl,_that.order,_that.principal,_that.colorId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ProductMediaType type,  String url,  String? thumbnailUrl,  int order,  bool principal,  String? colorId)?  $default,) {final _that = this;
switch (_that) {
case _ProductMedia() when $default != null:
return $default(_that.id,_that.type,_that.url,_that.thumbnailUrl,_that.order,_that.principal,_that.colorId);case _:
  return null;

}
}

}

/// @nodoc


class _ProductMedia implements ProductMedia {
  const _ProductMedia({required this.id, required this.type, required this.url, this.thumbnailUrl, required this.order, this.principal = false, this.colorId});
  

@override final  String id;
@override final  ProductMediaType type;
@override final  String url;
@override final  String? thumbnailUrl;
@override final  int order;
@override@JsonKey() final  bool principal;
@override final  String? colorId;

/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductMediaCopyWith<_ProductMedia> get copyWith => __$ProductMediaCopyWithImpl<_ProductMedia>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductMedia&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.order, order) || other.order == order)&&(identical(other.principal, principal) || other.principal == principal)&&(identical(other.colorId, colorId) || other.colorId == colorId));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,url,thumbnailUrl,order,principal,colorId);

@override
String toString() {
  return 'ProductMedia(id: $id, type: $type, url: $url, thumbnailUrl: $thumbnailUrl, order: $order, principal: $principal, colorId: $colorId)';
}


}

/// @nodoc
abstract mixin class _$ProductMediaCopyWith<$Res> implements $ProductMediaCopyWith<$Res> {
  factory _$ProductMediaCopyWith(_ProductMedia value, $Res Function(_ProductMedia) _then) = __$ProductMediaCopyWithImpl;
@override @useResult
$Res call({
 String id, ProductMediaType type, String url, String? thumbnailUrl, int order, bool principal, String? colorId
});




}
/// @nodoc
class __$ProductMediaCopyWithImpl<$Res>
    implements _$ProductMediaCopyWith<$Res> {
  __$ProductMediaCopyWithImpl(this._self, this._then);

  final _ProductMedia _self;
  final $Res Function(_ProductMedia) _then;

/// Create a copy of ProductMedia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? url = null,Object? thumbnailUrl = freezed,Object? order = null,Object? principal = null,Object? colorId = freezed,}) {
  return _then(_ProductMedia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductMediaType,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,principal: null == principal ? _self.principal : principal // ignore: cast_nullable_to_non_nullable
as bool,colorId: freezed == colorId ? _self.colorId : colorId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
