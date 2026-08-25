// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_campaign.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogCampaign {

 String get id; String get organizationId; String get title; String? get subtitle; String? get imageUrl; String? get collectionId; int get order; bool get active; DateTime? get startAt; DateTime? get endAt; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt;
/// Create a copy of CatalogCampaign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogCampaignCopyWith<CatalogCampaign> get copyWith => _$CatalogCampaignCopyWithImpl<CatalogCampaign>(this as CatalogCampaign, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogCampaign&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.order, order) || other.order == order)&&(identical(other.active, active) || other.active == active)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,title,subtitle,imageUrl,collectionId,order,active,startAt,endAt,createdAt,createdBy,updatedAt,updatedBy,deletedAt);

@override
String toString() {
  return 'CatalogCampaign(id: $id, organizationId: $organizationId, title: $title, subtitle: $subtitle, imageUrl: $imageUrl, collectionId: $collectionId, order: $order, active: $active, startAt: $startAt, endAt: $endAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $CatalogCampaignCopyWith<$Res>  {
  factory $CatalogCampaignCopyWith(CatalogCampaign value, $Res Function(CatalogCampaign) _then) = _$CatalogCampaignCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String title, String? subtitle, String? imageUrl, String? collectionId, int order, bool active, DateTime? startAt, DateTime? endAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt
});




}
/// @nodoc
class _$CatalogCampaignCopyWithImpl<$Res>
    implements $CatalogCampaignCopyWith<$Res> {
  _$CatalogCampaignCopyWithImpl(this._self, this._then);

  final CatalogCampaign _self;
  final $Res Function(CatalogCampaign) _then;

/// Create a copy of CatalogCampaign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? title = null,Object? subtitle = freezed,Object? imageUrl = freezed,Object? collectionId = freezed,Object? order = null,Object? active = null,Object? startAt = freezed,Object? endAt = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,startAt: freezed == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogCampaign].
extension CatalogCampaignPatterns on CatalogCampaign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogCampaign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogCampaign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogCampaign value)  $default,){
final _that = this;
switch (_that) {
case _CatalogCampaign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogCampaign value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogCampaign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String title,  String? subtitle,  String? imageUrl,  String? collectionId,  int order,  bool active,  DateTime? startAt,  DateTime? endAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogCampaign() when $default != null:
return $default(_that.id,_that.organizationId,_that.title,_that.subtitle,_that.imageUrl,_that.collectionId,_that.order,_that.active,_that.startAt,_that.endAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String title,  String? subtitle,  String? imageUrl,  String? collectionId,  int order,  bool active,  DateTime? startAt,  DateTime? endAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _CatalogCampaign():
return $default(_that.id,_that.organizationId,_that.title,_that.subtitle,_that.imageUrl,_that.collectionId,_that.order,_that.active,_that.startAt,_that.endAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String title,  String? subtitle,  String? imageUrl,  String? collectionId,  int order,  bool active,  DateTime? startAt,  DateTime? endAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _CatalogCampaign() when $default != null:
return $default(_that.id,_that.organizationId,_that.title,_that.subtitle,_that.imageUrl,_that.collectionId,_that.order,_that.active,_that.startAt,_that.endAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogCampaign extends CatalogCampaign {
  const _CatalogCampaign({required this.id, required this.organizationId, required this.title, this.subtitle, this.imageUrl, this.collectionId, required this.order, required this.active, this.startAt, this.endAt, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String title;
@override final  String? subtitle;
@override final  String? imageUrl;
@override final  String? collectionId;
@override final  int order;
@override final  bool active;
@override final  DateTime? startAt;
@override final  DateTime? endAt;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;

/// Create a copy of CatalogCampaign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogCampaignCopyWith<_CatalogCampaign> get copyWith => __$CatalogCampaignCopyWithImpl<_CatalogCampaign>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogCampaign&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.order, order) || other.order == order)&&(identical(other.active, active) || other.active == active)&&(identical(other.startAt, startAt) || other.startAt == startAt)&&(identical(other.endAt, endAt) || other.endAt == endAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,title,subtitle,imageUrl,collectionId,order,active,startAt,endAt,createdAt,createdBy,updatedAt,updatedBy,deletedAt);

@override
String toString() {
  return 'CatalogCampaign(id: $id, organizationId: $organizationId, title: $title, subtitle: $subtitle, imageUrl: $imageUrl, collectionId: $collectionId, order: $order, active: $active, startAt: $startAt, endAt: $endAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$CatalogCampaignCopyWith<$Res> implements $CatalogCampaignCopyWith<$Res> {
  factory _$CatalogCampaignCopyWith(_CatalogCampaign value, $Res Function(_CatalogCampaign) _then) = __$CatalogCampaignCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String title, String? subtitle, String? imageUrl, String? collectionId, int order, bool active, DateTime? startAt, DateTime? endAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt
});




}
/// @nodoc
class __$CatalogCampaignCopyWithImpl<$Res>
    implements _$CatalogCampaignCopyWith<$Res> {
  __$CatalogCampaignCopyWithImpl(this._self, this._then);

  final _CatalogCampaign _self;
  final $Res Function(_CatalogCampaign) _then;

/// Create a copy of CatalogCampaign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? title = null,Object? subtitle = freezed,Object? imageUrl = freezed,Object? collectionId = freezed,Object? order = null,Object? active = null,Object? startAt = freezed,Object? endAt = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,}) {
  return _then(_CatalogCampaign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,startAt: freezed == startAt ? _self.startAt : startAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endAt: freezed == endAt ? _self.endAt : endAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
