// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_catalog_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductCatalogPage {

 List<Product> get products; bool get hasMore; String? get nextCursor;
/// Create a copy of ProductCatalogPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCatalogPageCopyWith<ProductCatalogPage> get copyWith => _$ProductCatalogPageCopyWithImpl<ProductCatalogPage>(this as ProductCatalogPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCatalogPage&&const DeepCollectionEquality().equals(other.products, products)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(products),hasMore,nextCursor);

@override
String toString() {
  return 'ProductCatalogPage(products: $products, hasMore: $hasMore, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $ProductCatalogPageCopyWith<$Res>  {
  factory $ProductCatalogPageCopyWith(ProductCatalogPage value, $Res Function(ProductCatalogPage) _then) = _$ProductCatalogPageCopyWithImpl;
@useResult
$Res call({
 List<Product> products, bool hasMore, String? nextCursor
});




}
/// @nodoc
class _$ProductCatalogPageCopyWithImpl<$Res>
    implements $ProductCatalogPageCopyWith<$Res> {
  _$ProductCatalogPageCopyWithImpl(this._self, this._then);

  final ProductCatalogPage _self;
  final $Res Function(ProductCatalogPage) _then;

/// Create a copy of ProductCatalogPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? products = null,Object? hasMore = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<Product>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductCatalogPage].
extension ProductCatalogPagePatterns on ProductCatalogPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCatalogPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCatalogPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCatalogPage value)  $default,){
final _that = this;
switch (_that) {
case _ProductCatalogPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCatalogPage value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCatalogPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Product> products,  bool hasMore,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCatalogPage() when $default != null:
return $default(_that.products,_that.hasMore,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Product> products,  bool hasMore,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ProductCatalogPage():
return $default(_that.products,_that.hasMore,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Product> products,  bool hasMore,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ProductCatalogPage() when $default != null:
return $default(_that.products,_that.hasMore,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc


class _ProductCatalogPage implements ProductCatalogPage {
  const _ProductCatalogPage({required final  List<Product> products, required this.hasMore, this.nextCursor}): _products = products;
  

 final  List<Product> _products;
@override List<Product> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}

@override final  bool hasMore;
@override final  String? nextCursor;

/// Create a copy of ProductCatalogPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCatalogPageCopyWith<_ProductCatalogPage> get copyWith => __$ProductCatalogPageCopyWithImpl<_ProductCatalogPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCatalogPage&&const DeepCollectionEquality().equals(other._products, _products)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_products),hasMore,nextCursor);

@override
String toString() {
  return 'ProductCatalogPage(products: $products, hasMore: $hasMore, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ProductCatalogPageCopyWith<$Res> implements $ProductCatalogPageCopyWith<$Res> {
  factory _$ProductCatalogPageCopyWith(_ProductCatalogPage value, $Res Function(_ProductCatalogPage) _then) = __$ProductCatalogPageCopyWithImpl;
@override @useResult
$Res call({
 List<Product> products, bool hasMore, String? nextCursor
});




}
/// @nodoc
class __$ProductCatalogPageCopyWithImpl<$Res>
    implements _$ProductCatalogPageCopyWith<$Res> {
  __$ProductCatalogPageCopyWithImpl(this._self, this._then);

  final _ProductCatalogPage _self;
  final $Res Function(_ProductCatalogPage) _then;

/// Create a copy of ProductCatalogPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? products = null,Object? hasMore = null,Object? nextCursor = freezed,}) {
  return _then(_ProductCatalogPage(
products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<Product>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
