// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Product {

 String get id; String get organizationId; String? get companyId; Sku get sku; String get reference; String get name; String? get shortDescription; String? get fullDescription; String? get brand; String? get collectionId; String? get seasonId; String? get line; String? get categoryId; String? get subcategoryId; ProductGender? get gender; TargetAudience? get targetAudience; String? get fabric; String? get composition; String? get supplierId; String? get ncm; Ean? get ean; List<String> get tags; ProductStatus get status; DateTime? get launchDate; String? get seoTitle; String? get seoDescription; String? get seoSlug; List<String> get photoUrls; List<String> get videoUrls; List<ProductCustomFieldValue> get customFieldValues; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt; int get version; ProductSyncStatus get syncStatus;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.fullDescription, fullDescription) || other.fullDescription == fullDescription)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.line, line) || other.line == line)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.targetAudience, targetAudience) || other.targetAudience == targetAudience)&&(identical(other.fabric, fabric) || other.fabric == fabric)&&(identical(other.composition, composition) || other.composition == composition)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.ncm, ncm) || other.ncm == ncm)&&(identical(other.ean, ean) || other.ean == ean)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.status, status) || other.status == status)&&(identical(other.launchDate, launchDate) || other.launchDate == launchDate)&&(identical(other.seoTitle, seoTitle) || other.seoTitle == seoTitle)&&(identical(other.seoDescription, seoDescription) || other.seoDescription == seoDescription)&&(identical(other.seoSlug, seoSlug) || other.seoSlug == seoSlug)&&const DeepCollectionEquality().equals(other.photoUrls, photoUrls)&&const DeepCollectionEquality().equals(other.videoUrls, videoUrls)&&const DeepCollectionEquality().equals(other.customFieldValues, customFieldValues)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,sku,reference,name,shortDescription,fullDescription,brand,collectionId,seasonId,line,categoryId,subcategoryId,gender,targetAudience,fabric,composition,supplierId,ncm,ean,const DeepCollectionEquality().hash(tags),status,launchDate,seoTitle,seoDescription,seoSlug,const DeepCollectionEquality().hash(photoUrls),const DeepCollectionEquality().hash(videoUrls),const DeepCollectionEquality().hash(customFieldValues),createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Product(id: $id, organizationId: $organizationId, companyId: $companyId, sku: $sku, reference: $reference, name: $name, shortDescription: $shortDescription, fullDescription: $fullDescription, brand: $brand, collectionId: $collectionId, seasonId: $seasonId, line: $line, categoryId: $categoryId, subcategoryId: $subcategoryId, gender: $gender, targetAudience: $targetAudience, fabric: $fabric, composition: $composition, supplierId: $supplierId, ncm: $ncm, ean: $ean, tags: $tags, status: $status, launchDate: $launchDate, seoTitle: $seoTitle, seoDescription: $seoDescription, seoSlug: $seoSlug, photoUrls: $photoUrls, videoUrls: $videoUrls, customFieldValues: $customFieldValues, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String? companyId, Sku sku, String reference, String name, String? shortDescription, String? fullDescription, String? brand, String? collectionId, String? seasonId, String? line, String? categoryId, String? subcategoryId, ProductGender? gender, TargetAudience? targetAudience, String? fabric, String? composition, String? supplierId, String? ncm, Ean? ean, List<String> tags, ProductStatus status, DateTime? launchDate, String? seoTitle, String? seoDescription, String? seoSlug, List<String> photoUrls, List<String> videoUrls, List<ProductCustomFieldValue> customFieldValues, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, ProductSyncStatus syncStatus
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? sku = null,Object? reference = null,Object? name = null,Object? shortDescription = freezed,Object? fullDescription = freezed,Object? brand = freezed,Object? collectionId = freezed,Object? seasonId = freezed,Object? line = freezed,Object? categoryId = freezed,Object? subcategoryId = freezed,Object? gender = freezed,Object? targetAudience = freezed,Object? fabric = freezed,Object? composition = freezed,Object? supplierId = freezed,Object? ncm = freezed,Object? ean = freezed,Object? tags = null,Object? status = null,Object? launchDate = freezed,Object? seoTitle = freezed,Object? seoDescription = freezed,Object? seoSlug = freezed,Object? photoUrls = null,Object? videoUrls = null,Object? customFieldValues = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as Sku,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shortDescription: freezed == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String?,fullDescription: freezed == fullDescription ? _self.fullDescription : fullDescription // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,seasonId: freezed == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String?,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,subcategoryId: freezed == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as ProductGender?,targetAudience: freezed == targetAudience ? _self.targetAudience : targetAudience // ignore: cast_nullable_to_non_nullable
as TargetAudience?,fabric: freezed == fabric ? _self.fabric : fabric // ignore: cast_nullable_to_non_nullable
as String?,composition: freezed == composition ? _self.composition : composition // ignore: cast_nullable_to_non_nullable
as String?,supplierId: freezed == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String?,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,ean: freezed == ean ? _self.ean : ean // ignore: cast_nullable_to_non_nullable
as Ean?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductStatus,launchDate: freezed == launchDate ? _self.launchDate : launchDate // ignore: cast_nullable_to_non_nullable
as DateTime?,seoTitle: freezed == seoTitle ? _self.seoTitle : seoTitle // ignore: cast_nullable_to_non_nullable
as String?,seoDescription: freezed == seoDescription ? _self.seoDescription : seoDescription // ignore: cast_nullable_to_non_nullable
as String?,seoSlug: freezed == seoSlug ? _self.seoSlug : seoSlug // ignore: cast_nullable_to_non_nullable
as String?,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrls: null == videoUrls ? _self.videoUrls : videoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,customFieldValues: null == customFieldValues ? _self.customFieldValues : customFieldValues // ignore: cast_nullable_to_non_nullable
as List<ProductCustomFieldValue>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as ProductSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  Sku sku,  String reference,  String name,  String? shortDescription,  String? fullDescription,  String? brand,  String? collectionId,  String? seasonId,  String? line,  String? categoryId,  String? subcategoryId,  ProductGender? gender,  TargetAudience? targetAudience,  String? fabric,  String? composition,  String? supplierId,  String? ncm,  Ean? ean,  List<String> tags,  ProductStatus status,  DateTime? launchDate,  String? seoTitle,  String? seoDescription,  String? seoSlug,  List<String> photoUrls,  List<String> videoUrls,  List<ProductCustomFieldValue> customFieldValues,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  ProductSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.sku,_that.reference,_that.name,_that.shortDescription,_that.fullDescription,_that.brand,_that.collectionId,_that.seasonId,_that.line,_that.categoryId,_that.subcategoryId,_that.gender,_that.targetAudience,_that.fabric,_that.composition,_that.supplierId,_that.ncm,_that.ean,_that.tags,_that.status,_that.launchDate,_that.seoTitle,_that.seoDescription,_that.seoSlug,_that.photoUrls,_that.videoUrls,_that.customFieldValues,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  Sku sku,  String reference,  String name,  String? shortDescription,  String? fullDescription,  String? brand,  String? collectionId,  String? seasonId,  String? line,  String? categoryId,  String? subcategoryId,  ProductGender? gender,  TargetAudience? targetAudience,  String? fabric,  String? composition,  String? supplierId,  String? ncm,  Ean? ean,  List<String> tags,  ProductStatus status,  DateTime? launchDate,  String? seoTitle,  String? seoDescription,  String? seoSlug,  List<String> photoUrls,  List<String> videoUrls,  List<ProductCustomFieldValue> customFieldValues,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  ProductSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.organizationId,_that.companyId,_that.sku,_that.reference,_that.name,_that.shortDescription,_that.fullDescription,_that.brand,_that.collectionId,_that.seasonId,_that.line,_that.categoryId,_that.subcategoryId,_that.gender,_that.targetAudience,_that.fabric,_that.composition,_that.supplierId,_that.ncm,_that.ean,_that.tags,_that.status,_that.launchDate,_that.seoTitle,_that.seoDescription,_that.seoSlug,_that.photoUrls,_that.videoUrls,_that.customFieldValues,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String? companyId,  Sku sku,  String reference,  String name,  String? shortDescription,  String? fullDescription,  String? brand,  String? collectionId,  String? seasonId,  String? line,  String? categoryId,  String? subcategoryId,  ProductGender? gender,  TargetAudience? targetAudience,  String? fabric,  String? composition,  String? supplierId,  String? ncm,  Ean? ean,  List<String> tags,  ProductStatus status,  DateTime? launchDate,  String? seoTitle,  String? seoDescription,  String? seoSlug,  List<String> photoUrls,  List<String> videoUrls,  List<ProductCustomFieldValue> customFieldValues,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  ProductSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.sku,_that.reference,_that.name,_that.shortDescription,_that.fullDescription,_that.brand,_that.collectionId,_that.seasonId,_that.line,_that.categoryId,_that.subcategoryId,_that.gender,_that.targetAudience,_that.fabric,_that.composition,_that.supplierId,_that.ncm,_that.ean,_that.tags,_that.status,_that.launchDate,_that.seoTitle,_that.seoDescription,_that.seoSlug,_that.photoUrls,_that.videoUrls,_that.customFieldValues,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Product extends Product {
  const _Product({required this.id, required this.organizationId, this.companyId, required this.sku, required this.reference, required this.name, this.shortDescription, this.fullDescription, this.brand, this.collectionId, this.seasonId, this.line, this.categoryId, this.subcategoryId, this.gender, this.targetAudience, this.fabric, this.composition, this.supplierId, this.ncm, this.ean, final  List<String> tags = const <String>[], required this.status, this.launchDate, this.seoTitle, this.seoDescription, this.seoSlug, final  List<String> photoUrls = const <String>[], final  List<String> videoUrls = const <String>[], final  List<ProductCustomFieldValue> customFieldValues = const <ProductCustomFieldValue>[], required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt, required this.version, required this.syncStatus}): _tags = tags,_photoUrls = photoUrls,_videoUrls = videoUrls,_customFieldValues = customFieldValues,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String? companyId;
@override final  Sku sku;
@override final  String reference;
@override final  String name;
@override final  String? shortDescription;
@override final  String? fullDescription;
@override final  String? brand;
@override final  String? collectionId;
@override final  String? seasonId;
@override final  String? line;
@override final  String? categoryId;
@override final  String? subcategoryId;
@override final  ProductGender? gender;
@override final  TargetAudience? targetAudience;
@override final  String? fabric;
@override final  String? composition;
@override final  String? supplierId;
@override final  String? ncm;
@override final  Ean? ean;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  ProductStatus status;
@override final  DateTime? launchDate;
@override final  String? seoTitle;
@override final  String? seoDescription;
@override final  String? seoSlug;
 final  List<String> _photoUrls;
@override@JsonKey() List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

 final  List<String> _videoUrls;
@override@JsonKey() List<String> get videoUrls {
  if (_videoUrls is EqualUnmodifiableListView) return _videoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_videoUrls);
}

 final  List<ProductCustomFieldValue> _customFieldValues;
@override@JsonKey() List<ProductCustomFieldValue> get customFieldValues {
  if (_customFieldValues is EqualUnmodifiableListView) return _customFieldValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customFieldValues);
}

@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;
@override final  int version;
@override final  ProductSyncStatus syncStatus;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortDescription, shortDescription) || other.shortDescription == shortDescription)&&(identical(other.fullDescription, fullDescription) || other.fullDescription == fullDescription)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.line, line) || other.line == line)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.targetAudience, targetAudience) || other.targetAudience == targetAudience)&&(identical(other.fabric, fabric) || other.fabric == fabric)&&(identical(other.composition, composition) || other.composition == composition)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.ncm, ncm) || other.ncm == ncm)&&(identical(other.ean, ean) || other.ean == ean)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.status, status) || other.status == status)&&(identical(other.launchDate, launchDate) || other.launchDate == launchDate)&&(identical(other.seoTitle, seoTitle) || other.seoTitle == seoTitle)&&(identical(other.seoDescription, seoDescription) || other.seoDescription == seoDescription)&&(identical(other.seoSlug, seoSlug) || other.seoSlug == seoSlug)&&const DeepCollectionEquality().equals(other._photoUrls, _photoUrls)&&const DeepCollectionEquality().equals(other._videoUrls, _videoUrls)&&const DeepCollectionEquality().equals(other._customFieldValues, _customFieldValues)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,sku,reference,name,shortDescription,fullDescription,brand,collectionId,seasonId,line,categoryId,subcategoryId,gender,targetAudience,fabric,composition,supplierId,ncm,ean,const DeepCollectionEquality().hash(_tags),status,launchDate,seoTitle,seoDescription,seoSlug,const DeepCollectionEquality().hash(_photoUrls),const DeepCollectionEquality().hash(_videoUrls),const DeepCollectionEquality().hash(_customFieldValues),createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Product(id: $id, organizationId: $organizationId, companyId: $companyId, sku: $sku, reference: $reference, name: $name, shortDescription: $shortDescription, fullDescription: $fullDescription, brand: $brand, collectionId: $collectionId, seasonId: $seasonId, line: $line, categoryId: $categoryId, subcategoryId: $subcategoryId, gender: $gender, targetAudience: $targetAudience, fabric: $fabric, composition: $composition, supplierId: $supplierId, ncm: $ncm, ean: $ean, tags: $tags, status: $status, launchDate: $launchDate, seoTitle: $seoTitle, seoDescription: $seoDescription, seoSlug: $seoSlug, photoUrls: $photoUrls, videoUrls: $videoUrls, customFieldValues: $customFieldValues, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String? companyId, Sku sku, String reference, String name, String? shortDescription, String? fullDescription, String? brand, String? collectionId, String? seasonId, String? line, String? categoryId, String? subcategoryId, ProductGender? gender, TargetAudience? targetAudience, String? fabric, String? composition, String? supplierId, String? ncm, Ean? ean, List<String> tags, ProductStatus status, DateTime? launchDate, String? seoTitle, String? seoDescription, String? seoSlug, List<String> photoUrls, List<String> videoUrls, List<ProductCustomFieldValue> customFieldValues, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, ProductSyncStatus syncStatus
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? sku = null,Object? reference = null,Object? name = null,Object? shortDescription = freezed,Object? fullDescription = freezed,Object? brand = freezed,Object? collectionId = freezed,Object? seasonId = freezed,Object? line = freezed,Object? categoryId = freezed,Object? subcategoryId = freezed,Object? gender = freezed,Object? targetAudience = freezed,Object? fabric = freezed,Object? composition = freezed,Object? supplierId = freezed,Object? ncm = freezed,Object? ean = freezed,Object? tags = null,Object? status = null,Object? launchDate = freezed,Object? seoTitle = freezed,Object? seoDescription = freezed,Object? seoSlug = freezed,Object? photoUrls = null,Object? videoUrls = null,Object? customFieldValues = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,sku: null == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as Sku,reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,shortDescription: freezed == shortDescription ? _self.shortDescription : shortDescription // ignore: cast_nullable_to_non_nullable
as String?,fullDescription: freezed == fullDescription ? _self.fullDescription : fullDescription // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,seasonId: freezed == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String?,line: freezed == line ? _self.line : line // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,subcategoryId: freezed == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as ProductGender?,targetAudience: freezed == targetAudience ? _self.targetAudience : targetAudience // ignore: cast_nullable_to_non_nullable
as TargetAudience?,fabric: freezed == fabric ? _self.fabric : fabric // ignore: cast_nullable_to_non_nullable
as String?,composition: freezed == composition ? _self.composition : composition // ignore: cast_nullable_to_non_nullable
as String?,supplierId: freezed == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String?,ncm: freezed == ncm ? _self.ncm : ncm // ignore: cast_nullable_to_non_nullable
as String?,ean: freezed == ean ? _self.ean : ean // ignore: cast_nullable_to_non_nullable
as Ean?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductStatus,launchDate: freezed == launchDate ? _self.launchDate : launchDate // ignore: cast_nullable_to_non_nullable
as DateTime?,seoTitle: freezed == seoTitle ? _self.seoTitle : seoTitle // ignore: cast_nullable_to_non_nullable
as String?,seoDescription: freezed == seoDescription ? _self.seoDescription : seoDescription // ignore: cast_nullable_to_non_nullable
as String?,seoSlug: freezed == seoSlug ? _self.seoSlug : seoSlug // ignore: cast_nullable_to_non_nullable
as String?,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,videoUrls: null == videoUrls ? _self._videoUrls : videoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,customFieldValues: null == customFieldValues ? _self._customFieldValues : customFieldValues // ignore: cast_nullable_to_non_nullable
as List<ProductCustomFieldValue>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as ProductSyncStatus,
  ));
}


}

// dart format on
