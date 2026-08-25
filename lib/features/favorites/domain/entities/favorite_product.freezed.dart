// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FavoriteProduct {

 String get productId; String get userId; String get organizationId; String? get companyId; DateTime get createdAt; FavoriteSyncStatus get syncStatus;
/// Create a copy of FavoriteProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteProductCopyWith<FavoriteProduct> get copyWith => _$FavoriteProductCopyWithImpl<FavoriteProduct>(this as FavoriteProduct, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteProduct&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hash(runtimeType,productId,userId,organizationId,companyId,createdAt,syncStatus);

@override
String toString() {
  return 'FavoriteProduct(productId: $productId, userId: $userId, organizationId: $organizationId, companyId: $companyId, createdAt: $createdAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $FavoriteProductCopyWith<$Res>  {
  factory $FavoriteProductCopyWith(FavoriteProduct value, $Res Function(FavoriteProduct) _then) = _$FavoriteProductCopyWithImpl;
@useResult
$Res call({
 String productId, String userId, String organizationId, String? companyId, DateTime createdAt, FavoriteSyncStatus syncStatus
});




}
/// @nodoc
class _$FavoriteProductCopyWithImpl<$Res>
    implements $FavoriteProductCopyWith<$Res> {
  _$FavoriteProductCopyWithImpl(this._self, this._then);

  final FavoriteProduct _self;
  final $Res Function(FavoriteProduct) _then;

/// Create a copy of FavoriteProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? userId = null,Object? organizationId = null,Object? companyId = freezed,Object? createdAt = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as FavoriteSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteProduct].
extension FavoriteProductPatterns on FavoriteProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteProduct value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteProduct value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String userId,  String organizationId,  String? companyId,  DateTime createdAt,  FavoriteSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteProduct() when $default != null:
return $default(_that.productId,_that.userId,_that.organizationId,_that.companyId,_that.createdAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String userId,  String organizationId,  String? companyId,  DateTime createdAt,  FavoriteSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _FavoriteProduct():
return $default(_that.productId,_that.userId,_that.organizationId,_that.companyId,_that.createdAt,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String userId,  String organizationId,  String? companyId,  DateTime createdAt,  FavoriteSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteProduct() when $default != null:
return $default(_that.productId,_that.userId,_that.organizationId,_that.companyId,_that.createdAt,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _FavoriteProduct implements FavoriteProduct {
  const _FavoriteProduct({required this.productId, required this.userId, required this.organizationId, this.companyId, required this.createdAt, required this.syncStatus});
  

@override final  String productId;
@override final  String userId;
@override final  String organizationId;
@override final  String? companyId;
@override final  DateTime createdAt;
@override final  FavoriteSyncStatus syncStatus;

/// Create a copy of FavoriteProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteProductCopyWith<_FavoriteProduct> get copyWith => __$FavoriteProductCopyWithImpl<_FavoriteProduct>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteProduct&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hash(runtimeType,productId,userId,organizationId,companyId,createdAt,syncStatus);

@override
String toString() {
  return 'FavoriteProduct(productId: $productId, userId: $userId, organizationId: $organizationId, companyId: $companyId, createdAt: $createdAt, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$FavoriteProductCopyWith<$Res> implements $FavoriteProductCopyWith<$Res> {
  factory _$FavoriteProductCopyWith(_FavoriteProduct value, $Res Function(_FavoriteProduct) _then) = __$FavoriteProductCopyWithImpl;
@override @useResult
$Res call({
 String productId, String userId, String organizationId, String? companyId, DateTime createdAt, FavoriteSyncStatus syncStatus
});




}
/// @nodoc
class __$FavoriteProductCopyWithImpl<$Res>
    implements _$FavoriteProductCopyWith<$Res> {
  __$FavoriteProductCopyWithImpl(this._self, this._then);

  final _FavoriteProduct _self;
  final $Res Function(_FavoriteProduct) _then;

/// Create a copy of FavoriteProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? userId = null,Object? organizationId = null,Object? companyId = freezed,Object? createdAt = null,Object? syncStatus = null,}) {
  return _then(_FavoriteProduct(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as FavoriteSyncStatus,
  ));
}


}

// dart format on
