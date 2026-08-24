// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_collection_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductCollectionLink {

 String get id; String get organizationId; String get productId; String get collectionId; DateTime get createdAt; String get createdBy;
/// Create a copy of ProductCollectionLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCollectionLinkCopyWith<ProductCollectionLink> get copyWith => _$ProductCollectionLinkCopyWithImpl<ProductCollectionLink>(this as ProductCollectionLink, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCollectionLink&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,productId,collectionId,createdAt,createdBy);

@override
String toString() {
  return 'ProductCollectionLink(id: $id, organizationId: $organizationId, productId: $productId, collectionId: $collectionId, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ProductCollectionLinkCopyWith<$Res>  {
  factory $ProductCollectionLinkCopyWith(ProductCollectionLink value, $Res Function(ProductCollectionLink) _then) = _$ProductCollectionLinkCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String productId, String collectionId, DateTime createdAt, String createdBy
});




}
/// @nodoc
class _$ProductCollectionLinkCopyWithImpl<$Res>
    implements $ProductCollectionLinkCopyWith<$Res> {
  _$ProductCollectionLinkCopyWithImpl(this._self, this._then);

  final ProductCollectionLink _self;
  final $Res Function(ProductCollectionLink) _then;

/// Create a copy of ProductCollectionLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? productId = null,Object? collectionId = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,collectionId: null == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductCollectionLink].
extension ProductCollectionLinkPatterns on ProductCollectionLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCollectionLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCollectionLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCollectionLink value)  $default,){
final _that = this;
switch (_that) {
case _ProductCollectionLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCollectionLink value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCollectionLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String productId,  String collectionId,  DateTime createdAt,  String createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCollectionLink() when $default != null:
return $default(_that.id,_that.organizationId,_that.productId,_that.collectionId,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String productId,  String collectionId,  DateTime createdAt,  String createdBy)  $default,) {final _that = this;
switch (_that) {
case _ProductCollectionLink():
return $default(_that.id,_that.organizationId,_that.productId,_that.collectionId,_that.createdAt,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String productId,  String collectionId,  DateTime createdAt,  String createdBy)?  $default,) {final _that = this;
switch (_that) {
case _ProductCollectionLink() when $default != null:
return $default(_that.id,_that.organizationId,_that.productId,_that.collectionId,_that.createdAt,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc


class _ProductCollectionLink implements ProductCollectionLink {
  const _ProductCollectionLink({required this.id, required this.organizationId, required this.productId, required this.collectionId, required this.createdAt, required this.createdBy});
  

@override final  String id;
@override final  String organizationId;
@override final  String productId;
@override final  String collectionId;
@override final  DateTime createdAt;
@override final  String createdBy;

/// Create a copy of ProductCollectionLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCollectionLinkCopyWith<_ProductCollectionLink> get copyWith => __$ProductCollectionLinkCopyWithImpl<_ProductCollectionLink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCollectionLink&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,productId,collectionId,createdAt,createdBy);

@override
String toString() {
  return 'ProductCollectionLink(id: $id, organizationId: $organizationId, productId: $productId, collectionId: $collectionId, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ProductCollectionLinkCopyWith<$Res> implements $ProductCollectionLinkCopyWith<$Res> {
  factory _$ProductCollectionLinkCopyWith(_ProductCollectionLink value, $Res Function(_ProductCollectionLink) _then) = __$ProductCollectionLinkCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String productId, String collectionId, DateTime createdAt, String createdBy
});




}
/// @nodoc
class __$ProductCollectionLinkCopyWithImpl<$Res>
    implements _$ProductCollectionLinkCopyWith<$Res> {
  __$ProductCollectionLinkCopyWithImpl(this._self, this._then);

  final _ProductCollectionLink _self;
  final $Res Function(_ProductCollectionLink) _then;

/// Create a copy of ProductCollectionLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? productId = null,Object? collectionId = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_ProductCollectionLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,collectionId: null == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
