// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commercial_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommercialPack {

 String get id; String get organizationId; String? get companyId; String get packCode; int get version; String get name; String? get description; CommercialPackType get packType; CommercialPackStatus get status; CommercialPackPricingPolicyType get pricingPolicyType; double? get fixedPrice; double? get discountPercentage; String? get bonusComponentId; CommercialPackStockPolicyType get stockPolicyType; String? get dedicatedWarehouseId; String? get collectionId; String? get campaignId; String? get customerSegment; String? get channel; DateTime get validFrom; DateTime? get validTo; List<PackComponent> get components; List<AssortmentRule> get assortmentRules; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt; String? get supersededByPackId; CommercialPackSyncStatus get syncStatus;
/// Create a copy of CommercialPack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommercialPackCopyWith<CommercialPack> get copyWith => _$CommercialPackCopyWithImpl<CommercialPack>(this as CommercialPack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommercialPack&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.packCode, packCode) || other.packCode == packCode)&&(identical(other.version, version) || other.version == version)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.packType, packType) || other.packType == packType)&&(identical(other.status, status) || other.status == status)&&(identical(other.pricingPolicyType, pricingPolicyType) || other.pricingPolicyType == pricingPolicyType)&&(identical(other.fixedPrice, fixedPrice) || other.fixedPrice == fixedPrice)&&(identical(other.discountPercentage, discountPercentage) || other.discountPercentage == discountPercentage)&&(identical(other.bonusComponentId, bonusComponentId) || other.bonusComponentId == bonusComponentId)&&(identical(other.stockPolicyType, stockPolicyType) || other.stockPolicyType == stockPolicyType)&&(identical(other.dedicatedWarehouseId, dedicatedWarehouseId) || other.dedicatedWarehouseId == dedicatedWarehouseId)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.customerSegment, customerSegment) || other.customerSegment == customerSegment)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&const DeepCollectionEquality().equals(other.components, components)&&const DeepCollectionEquality().equals(other.assortmentRules, assortmentRules)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.supersededByPackId, supersededByPackId) || other.supersededByPackId == supersededByPackId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,packCode,version,name,description,packType,status,pricingPolicyType,fixedPrice,discountPercentage,bonusComponentId,stockPolicyType,dedicatedWarehouseId,collectionId,campaignId,customerSegment,channel,validFrom,validTo,const DeepCollectionEquality().hash(components),const DeepCollectionEquality().hash(assortmentRules),createdAt,createdBy,updatedAt,updatedBy,deletedAt,supersededByPackId,syncStatus]);

@override
String toString() {
  return 'CommercialPack(id: $id, organizationId: $organizationId, companyId: $companyId, packCode: $packCode, version: $version, name: $name, description: $description, packType: $packType, status: $status, pricingPolicyType: $pricingPolicyType, fixedPrice: $fixedPrice, discountPercentage: $discountPercentage, bonusComponentId: $bonusComponentId, stockPolicyType: $stockPolicyType, dedicatedWarehouseId: $dedicatedWarehouseId, collectionId: $collectionId, campaignId: $campaignId, customerSegment: $customerSegment, channel: $channel, validFrom: $validFrom, validTo: $validTo, components: $components, assortmentRules: $assortmentRules, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, supersededByPackId: $supersededByPackId, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $CommercialPackCopyWith<$Res>  {
  factory $CommercialPackCopyWith(CommercialPack value, $Res Function(CommercialPack) _then) = _$CommercialPackCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String? companyId, String packCode, int version, String name, String? description, CommercialPackType packType, CommercialPackStatus status, CommercialPackPricingPolicyType pricingPolicyType, double? fixedPrice, double? discountPercentage, String? bonusComponentId, CommercialPackStockPolicyType stockPolicyType, String? dedicatedWarehouseId, String? collectionId, String? campaignId, String? customerSegment, String? channel, DateTime validFrom, DateTime? validTo, List<PackComponent> components, List<AssortmentRule> assortmentRules, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, String? supersededByPackId, CommercialPackSyncStatus syncStatus
});




}
/// @nodoc
class _$CommercialPackCopyWithImpl<$Res>
    implements $CommercialPackCopyWith<$Res> {
  _$CommercialPackCopyWithImpl(this._self, this._then);

  final CommercialPack _self;
  final $Res Function(CommercialPack) _then;

/// Create a copy of CommercialPack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? packCode = null,Object? version = null,Object? name = null,Object? description = freezed,Object? packType = null,Object? status = null,Object? pricingPolicyType = null,Object? fixedPrice = freezed,Object? discountPercentage = freezed,Object? bonusComponentId = freezed,Object? stockPolicyType = null,Object? dedicatedWarehouseId = freezed,Object? collectionId = freezed,Object? campaignId = freezed,Object? customerSegment = freezed,Object? channel = freezed,Object? validFrom = null,Object? validTo = freezed,Object? components = null,Object? assortmentRules = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? supersededByPackId = freezed,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,packCode: null == packCode ? _self.packCode : packCode // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,packType: null == packType ? _self.packType : packType // ignore: cast_nullable_to_non_nullable
as CommercialPackType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommercialPackStatus,pricingPolicyType: null == pricingPolicyType ? _self.pricingPolicyType : pricingPolicyType // ignore: cast_nullable_to_non_nullable
as CommercialPackPricingPolicyType,fixedPrice: freezed == fixedPrice ? _self.fixedPrice : fixedPrice // ignore: cast_nullable_to_non_nullable
as double?,discountPercentage: freezed == discountPercentage ? _self.discountPercentage : discountPercentage // ignore: cast_nullable_to_non_nullable
as double?,bonusComponentId: freezed == bonusComponentId ? _self.bonusComponentId : bonusComponentId // ignore: cast_nullable_to_non_nullable
as String?,stockPolicyType: null == stockPolicyType ? _self.stockPolicyType : stockPolicyType // ignore: cast_nullable_to_non_nullable
as CommercialPackStockPolicyType,dedicatedWarehouseId: freezed == dedicatedWarehouseId ? _self.dedicatedWarehouseId : dedicatedWarehouseId // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,campaignId: freezed == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String?,customerSegment: freezed == customerSegment ? _self.customerSegment : customerSegment // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as List<PackComponent>,assortmentRules: null == assortmentRules ? _self.assortmentRules : assortmentRules // ignore: cast_nullable_to_non_nullable
as List<AssortmentRule>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,supersededByPackId: freezed == supersededByPackId ? _self.supersededByPackId : supersededByPackId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as CommercialPackSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [CommercialPack].
extension CommercialPackPatterns on CommercialPack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommercialPack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommercialPack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommercialPack value)  $default,){
final _that = this;
switch (_that) {
case _CommercialPack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommercialPack value)?  $default,){
final _that = this;
switch (_that) {
case _CommercialPack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  String packCode,  int version,  String name,  String? description,  CommercialPackType packType,  CommercialPackStatus status,  CommercialPackPricingPolicyType pricingPolicyType,  double? fixedPrice,  double? discountPercentage,  String? bonusComponentId,  CommercialPackStockPolicyType stockPolicyType,  String? dedicatedWarehouseId,  String? collectionId,  String? campaignId,  String? customerSegment,  String? channel,  DateTime validFrom,  DateTime? validTo,  List<PackComponent> components,  List<AssortmentRule> assortmentRules,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  String? supersededByPackId,  CommercialPackSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommercialPack() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.packCode,_that.version,_that.name,_that.description,_that.packType,_that.status,_that.pricingPolicyType,_that.fixedPrice,_that.discountPercentage,_that.bonusComponentId,_that.stockPolicyType,_that.dedicatedWarehouseId,_that.collectionId,_that.campaignId,_that.customerSegment,_that.channel,_that.validFrom,_that.validTo,_that.components,_that.assortmentRules,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.supersededByPackId,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  String packCode,  int version,  String name,  String? description,  CommercialPackType packType,  CommercialPackStatus status,  CommercialPackPricingPolicyType pricingPolicyType,  double? fixedPrice,  double? discountPercentage,  String? bonusComponentId,  CommercialPackStockPolicyType stockPolicyType,  String? dedicatedWarehouseId,  String? collectionId,  String? campaignId,  String? customerSegment,  String? channel,  DateTime validFrom,  DateTime? validTo,  List<PackComponent> components,  List<AssortmentRule> assortmentRules,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  String? supersededByPackId,  CommercialPackSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _CommercialPack():
return $default(_that.id,_that.organizationId,_that.companyId,_that.packCode,_that.version,_that.name,_that.description,_that.packType,_that.status,_that.pricingPolicyType,_that.fixedPrice,_that.discountPercentage,_that.bonusComponentId,_that.stockPolicyType,_that.dedicatedWarehouseId,_that.collectionId,_that.campaignId,_that.customerSegment,_that.channel,_that.validFrom,_that.validTo,_that.components,_that.assortmentRules,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.supersededByPackId,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String? companyId,  String packCode,  int version,  String name,  String? description,  CommercialPackType packType,  CommercialPackStatus status,  CommercialPackPricingPolicyType pricingPolicyType,  double? fixedPrice,  double? discountPercentage,  String? bonusComponentId,  CommercialPackStockPolicyType stockPolicyType,  String? dedicatedWarehouseId,  String? collectionId,  String? campaignId,  String? customerSegment,  String? channel,  DateTime validFrom,  DateTime? validTo,  List<PackComponent> components,  List<AssortmentRule> assortmentRules,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  String? supersededByPackId,  CommercialPackSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _CommercialPack() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.packCode,_that.version,_that.name,_that.description,_that.packType,_that.status,_that.pricingPolicyType,_that.fixedPrice,_that.discountPercentage,_that.bonusComponentId,_that.stockPolicyType,_that.dedicatedWarehouseId,_that.collectionId,_that.campaignId,_that.customerSegment,_that.channel,_that.validFrom,_that.validTo,_that.components,_that.assortmentRules,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.supersededByPackId,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _CommercialPack extends CommercialPack {
  const _CommercialPack({required this.id, required this.organizationId, this.companyId, required this.packCode, required this.version, required this.name, this.description, required this.packType, required this.status, required this.pricingPolicyType, this.fixedPrice, this.discountPercentage, this.bonusComponentId, required this.stockPolicyType, this.dedicatedWarehouseId, this.collectionId, this.campaignId, this.customerSegment, this.channel, required this.validFrom, this.validTo, final  List<PackComponent> components = const <PackComponent>[], final  List<AssortmentRule> assortmentRules = const <AssortmentRule>[], required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt, this.supersededByPackId, required this.syncStatus}): _components = components,_assortmentRules = assortmentRules,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String? companyId;
@override final  String packCode;
@override final  int version;
@override final  String name;
@override final  String? description;
@override final  CommercialPackType packType;
@override final  CommercialPackStatus status;
@override final  CommercialPackPricingPolicyType pricingPolicyType;
@override final  double? fixedPrice;
@override final  double? discountPercentage;
@override final  String? bonusComponentId;
@override final  CommercialPackStockPolicyType stockPolicyType;
@override final  String? dedicatedWarehouseId;
@override final  String? collectionId;
@override final  String? campaignId;
@override final  String? customerSegment;
@override final  String? channel;
@override final  DateTime validFrom;
@override final  DateTime? validTo;
 final  List<PackComponent> _components;
@override@JsonKey() List<PackComponent> get components {
  if (_components is EqualUnmodifiableListView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_components);
}

 final  List<AssortmentRule> _assortmentRules;
@override@JsonKey() List<AssortmentRule> get assortmentRules {
  if (_assortmentRules is EqualUnmodifiableListView) return _assortmentRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assortmentRules);
}

@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;
@override final  String? supersededByPackId;
@override final  CommercialPackSyncStatus syncStatus;

/// Create a copy of CommercialPack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommercialPackCopyWith<_CommercialPack> get copyWith => __$CommercialPackCopyWithImpl<_CommercialPack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommercialPack&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.packCode, packCode) || other.packCode == packCode)&&(identical(other.version, version) || other.version == version)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.packType, packType) || other.packType == packType)&&(identical(other.status, status) || other.status == status)&&(identical(other.pricingPolicyType, pricingPolicyType) || other.pricingPolicyType == pricingPolicyType)&&(identical(other.fixedPrice, fixedPrice) || other.fixedPrice == fixedPrice)&&(identical(other.discountPercentage, discountPercentage) || other.discountPercentage == discountPercentage)&&(identical(other.bonusComponentId, bonusComponentId) || other.bonusComponentId == bonusComponentId)&&(identical(other.stockPolicyType, stockPolicyType) || other.stockPolicyType == stockPolicyType)&&(identical(other.dedicatedWarehouseId, dedicatedWarehouseId) || other.dedicatedWarehouseId == dedicatedWarehouseId)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.campaignId, campaignId) || other.campaignId == campaignId)&&(identical(other.customerSegment, customerSegment) || other.customerSegment == customerSegment)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&const DeepCollectionEquality().equals(other._components, _components)&&const DeepCollectionEquality().equals(other._assortmentRules, _assortmentRules)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.supersededByPackId, supersededByPackId) || other.supersededByPackId == supersededByPackId)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,packCode,version,name,description,packType,status,pricingPolicyType,fixedPrice,discountPercentage,bonusComponentId,stockPolicyType,dedicatedWarehouseId,collectionId,campaignId,customerSegment,channel,validFrom,validTo,const DeepCollectionEquality().hash(_components),const DeepCollectionEquality().hash(_assortmentRules),createdAt,createdBy,updatedAt,updatedBy,deletedAt,supersededByPackId,syncStatus]);

@override
String toString() {
  return 'CommercialPack(id: $id, organizationId: $organizationId, companyId: $companyId, packCode: $packCode, version: $version, name: $name, description: $description, packType: $packType, status: $status, pricingPolicyType: $pricingPolicyType, fixedPrice: $fixedPrice, discountPercentage: $discountPercentage, bonusComponentId: $bonusComponentId, stockPolicyType: $stockPolicyType, dedicatedWarehouseId: $dedicatedWarehouseId, collectionId: $collectionId, campaignId: $campaignId, customerSegment: $customerSegment, channel: $channel, validFrom: $validFrom, validTo: $validTo, components: $components, assortmentRules: $assortmentRules, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, supersededByPackId: $supersededByPackId, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$CommercialPackCopyWith<$Res> implements $CommercialPackCopyWith<$Res> {
  factory _$CommercialPackCopyWith(_CommercialPack value, $Res Function(_CommercialPack) _then) = __$CommercialPackCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String? companyId, String packCode, int version, String name, String? description, CommercialPackType packType, CommercialPackStatus status, CommercialPackPricingPolicyType pricingPolicyType, double? fixedPrice, double? discountPercentage, String? bonusComponentId, CommercialPackStockPolicyType stockPolicyType, String? dedicatedWarehouseId, String? collectionId, String? campaignId, String? customerSegment, String? channel, DateTime validFrom, DateTime? validTo, List<PackComponent> components, List<AssortmentRule> assortmentRules, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, String? supersededByPackId, CommercialPackSyncStatus syncStatus
});




}
/// @nodoc
class __$CommercialPackCopyWithImpl<$Res>
    implements _$CommercialPackCopyWith<$Res> {
  __$CommercialPackCopyWithImpl(this._self, this._then);

  final _CommercialPack _self;
  final $Res Function(_CommercialPack) _then;

/// Create a copy of CommercialPack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? packCode = null,Object? version = null,Object? name = null,Object? description = freezed,Object? packType = null,Object? status = null,Object? pricingPolicyType = null,Object? fixedPrice = freezed,Object? discountPercentage = freezed,Object? bonusComponentId = freezed,Object? stockPolicyType = null,Object? dedicatedWarehouseId = freezed,Object? collectionId = freezed,Object? campaignId = freezed,Object? customerSegment = freezed,Object? channel = freezed,Object? validFrom = null,Object? validTo = freezed,Object? components = null,Object? assortmentRules = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? supersededByPackId = freezed,Object? syncStatus = null,}) {
  return _then(_CommercialPack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,packCode: null == packCode ? _self.packCode : packCode // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,packType: null == packType ? _self.packType : packType // ignore: cast_nullable_to_non_nullable
as CommercialPackType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CommercialPackStatus,pricingPolicyType: null == pricingPolicyType ? _self.pricingPolicyType : pricingPolicyType // ignore: cast_nullable_to_non_nullable
as CommercialPackPricingPolicyType,fixedPrice: freezed == fixedPrice ? _self.fixedPrice : fixedPrice // ignore: cast_nullable_to_non_nullable
as double?,discountPercentage: freezed == discountPercentage ? _self.discountPercentage : discountPercentage // ignore: cast_nullable_to_non_nullable
as double?,bonusComponentId: freezed == bonusComponentId ? _self.bonusComponentId : bonusComponentId // ignore: cast_nullable_to_non_nullable
as String?,stockPolicyType: null == stockPolicyType ? _self.stockPolicyType : stockPolicyType // ignore: cast_nullable_to_non_nullable
as CommercialPackStockPolicyType,dedicatedWarehouseId: freezed == dedicatedWarehouseId ? _self.dedicatedWarehouseId : dedicatedWarehouseId // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,campaignId: freezed == campaignId ? _self.campaignId : campaignId // ignore: cast_nullable_to_non_nullable
as String?,customerSegment: freezed == customerSegment ? _self.customerSegment : customerSegment // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as List<PackComponent>,assortmentRules: null == assortmentRules ? _self._assortmentRules : assortmentRules // ignore: cast_nullable_to_non_nullable
as List<AssortmentRule>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,supersededByPackId: freezed == supersededByPackId ? _self.supersededByPackId : supersededByPackId // ignore: cast_nullable_to_non_nullable
as String?,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as CommercialPackSyncStatus,
  ));
}


}

// dart format on
