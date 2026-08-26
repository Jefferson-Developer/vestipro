// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_share.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogShare {

 String get id; String get organizationId; CatalogShareScope get scope; List<CatalogShareItem> get items; String? get collectionId; String? get collectionName; bool get isRevoked; int get openCount; DateTime? get firstOpenedAt; DateTime? get lastOpenedAt; DateTime get expiresAt; String get createdBy; String get createdByName; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of CatalogShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogShareCopyWith<CatalogShare> get copyWith => _$CatalogShareCopyWithImpl<CatalogShare>(this as CatalogShare, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogShare&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.isRevoked, isRevoked) || other.isRevoked == isRevoked)&&(identical(other.openCount, openCount) || other.openCount == openCount)&&(identical(other.firstOpenedAt, firstOpenedAt) || other.firstOpenedAt == firstOpenedAt)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,scope,const DeepCollectionEquality().hash(items),collectionId,collectionName,isRevoked,openCount,firstOpenedAt,lastOpenedAt,expiresAt,createdBy,createdByName,createdAt,updatedAt);

@override
String toString() {
  return 'CatalogShare(id: $id, organizationId: $organizationId, scope: $scope, items: $items, collectionId: $collectionId, collectionName: $collectionName, isRevoked: $isRevoked, openCount: $openCount, firstOpenedAt: $firstOpenedAt, lastOpenedAt: $lastOpenedAt, expiresAt: $expiresAt, createdBy: $createdBy, createdByName: $createdByName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CatalogShareCopyWith<$Res>  {
  factory $CatalogShareCopyWith(CatalogShare value, $Res Function(CatalogShare) _then) = _$CatalogShareCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, CatalogShareScope scope, List<CatalogShareItem> items, String? collectionId, String? collectionName, bool isRevoked, int openCount, DateTime? firstOpenedAt, DateTime? lastOpenedAt, DateTime expiresAt, String createdBy, String createdByName, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$CatalogShareCopyWithImpl<$Res>
    implements $CatalogShareCopyWith<$Res> {
  _$CatalogShareCopyWithImpl(this._self, this._then);

  final CatalogShare _self;
  final $Res Function(CatalogShare) _then;

/// Create a copy of CatalogShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? scope = null,Object? items = null,Object? collectionId = freezed,Object? collectionName = freezed,Object? isRevoked = null,Object? openCount = null,Object? firstOpenedAt = freezed,Object? lastOpenedAt = freezed,Object? expiresAt = null,Object? createdBy = null,Object? createdByName = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as CatalogShareScope,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogShareItem>,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,collectionName: freezed == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String?,isRevoked: null == isRevoked ? _self.isRevoked : isRevoked // ignore: cast_nullable_to_non_nullable
as bool,openCount: null == openCount ? _self.openCount : openCount // ignore: cast_nullable_to_non_nullable
as int,firstOpenedAt: freezed == firstOpenedAt ? _self.firstOpenedAt : firstOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: null == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogShare].
extension CatalogSharePatterns on CatalogShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogShare value)  $default,){
final _that = this;
switch (_that) {
case _CatalogShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogShare value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  CatalogShareScope scope,  List<CatalogShareItem> items,  String? collectionId,  String? collectionName,  bool isRevoked,  int openCount,  DateTime? firstOpenedAt,  DateTime? lastOpenedAt,  DateTime expiresAt,  String createdBy,  String createdByName,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogShare() when $default != null:
return $default(_that.id,_that.organizationId,_that.scope,_that.items,_that.collectionId,_that.collectionName,_that.isRevoked,_that.openCount,_that.firstOpenedAt,_that.lastOpenedAt,_that.expiresAt,_that.createdBy,_that.createdByName,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  CatalogShareScope scope,  List<CatalogShareItem> items,  String? collectionId,  String? collectionName,  bool isRevoked,  int openCount,  DateTime? firstOpenedAt,  DateTime? lastOpenedAt,  DateTime expiresAt,  String createdBy,  String createdByName,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CatalogShare():
return $default(_that.id,_that.organizationId,_that.scope,_that.items,_that.collectionId,_that.collectionName,_that.isRevoked,_that.openCount,_that.firstOpenedAt,_that.lastOpenedAt,_that.expiresAt,_that.createdBy,_that.createdByName,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  CatalogShareScope scope,  List<CatalogShareItem> items,  String? collectionId,  String? collectionName,  bool isRevoked,  int openCount,  DateTime? firstOpenedAt,  DateTime? lastOpenedAt,  DateTime expiresAt,  String createdBy,  String createdByName,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CatalogShare() when $default != null:
return $default(_that.id,_that.organizationId,_that.scope,_that.items,_that.collectionId,_that.collectionName,_that.isRevoked,_that.openCount,_that.firstOpenedAt,_that.lastOpenedAt,_that.expiresAt,_that.createdBy,_that.createdByName,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogShare extends CatalogShare {
  const _CatalogShare({required this.id, required this.organizationId, required this.scope, required final  List<CatalogShareItem> items, this.collectionId, this.collectionName, required this.isRevoked, required this.openCount, this.firstOpenedAt, this.lastOpenedAt, required this.expiresAt, required this.createdBy, required this.createdByName, required this.createdAt, required this.updatedAt}): _items = items,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  CatalogShareScope scope;
 final  List<CatalogShareItem> _items;
@override List<CatalogShareItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? collectionId;
@override final  String? collectionName;
@override final  bool isRevoked;
@override final  int openCount;
@override final  DateTime? firstOpenedAt;
@override final  DateTime? lastOpenedAt;
@override final  DateTime expiresAt;
@override final  String createdBy;
@override final  String createdByName;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of CatalogShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogShareCopyWith<_CatalogShare> get copyWith => __$CatalogShareCopyWithImpl<_CatalogShare>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogShare&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.isRevoked, isRevoked) || other.isRevoked == isRevoked)&&(identical(other.openCount, openCount) || other.openCount == openCount)&&(identical(other.firstOpenedAt, firstOpenedAt) || other.firstOpenedAt == firstOpenedAt)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,scope,const DeepCollectionEquality().hash(_items),collectionId,collectionName,isRevoked,openCount,firstOpenedAt,lastOpenedAt,expiresAt,createdBy,createdByName,createdAt,updatedAt);

@override
String toString() {
  return 'CatalogShare(id: $id, organizationId: $organizationId, scope: $scope, items: $items, collectionId: $collectionId, collectionName: $collectionName, isRevoked: $isRevoked, openCount: $openCount, firstOpenedAt: $firstOpenedAt, lastOpenedAt: $lastOpenedAt, expiresAt: $expiresAt, createdBy: $createdBy, createdByName: $createdByName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CatalogShareCopyWith<$Res> implements $CatalogShareCopyWith<$Res> {
  factory _$CatalogShareCopyWith(_CatalogShare value, $Res Function(_CatalogShare) _then) = __$CatalogShareCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, CatalogShareScope scope, List<CatalogShareItem> items, String? collectionId, String? collectionName, bool isRevoked, int openCount, DateTime? firstOpenedAt, DateTime? lastOpenedAt, DateTime expiresAt, String createdBy, String createdByName, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$CatalogShareCopyWithImpl<$Res>
    implements _$CatalogShareCopyWith<$Res> {
  __$CatalogShareCopyWithImpl(this._self, this._then);

  final _CatalogShare _self;
  final $Res Function(_CatalogShare) _then;

/// Create a copy of CatalogShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? scope = null,Object? items = null,Object? collectionId = freezed,Object? collectionName = freezed,Object? isRevoked = null,Object? openCount = null,Object? firstOpenedAt = freezed,Object? lastOpenedAt = freezed,Object? expiresAt = null,Object? createdBy = null,Object? createdByName = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_CatalogShare(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as CatalogShareScope,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogShareItem>,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,collectionName: freezed == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String?,isRevoked: null == isRevoked ? _self.isRevoked : isRevoked // ignore: cast_nullable_to_non_nullable
as bool,openCount: null == openCount ? _self.openCount : openCount // ignore: cast_nullable_to_non_nullable
as int,firstOpenedAt: freezed == firstOpenedAt ? _self.firstOpenedAt : firstOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: null == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
