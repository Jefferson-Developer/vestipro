// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Collection {

 String get id; String get organizationId; String get name; String? get seasonId; int? get year; DateTime? get startDate; DateTime? get endDate; CollectionStatus get status; int get version; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt;
/// Create a copy of Collection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionCopyWith<Collection> get copyWith => _$CollectionCopyWithImpl<Collection>(this as Collection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Collection&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.year, year) || other.year == year)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,seasonId,year,startDate,endDate,status,version,createdAt,createdBy,updatedAt,updatedBy,deletedAt);

@override
String toString() {
  return 'Collection(id: $id, organizationId: $organizationId, name: $name, seasonId: $seasonId, year: $year, startDate: $startDate, endDate: $endDate, status: $status, version: $version, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $CollectionCopyWith<$Res>  {
  factory $CollectionCopyWith(Collection value, $Res Function(Collection) _then) = _$CollectionCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String name, String? seasonId, int? year, DateTime? startDate, DateTime? endDate, CollectionStatus status, int version, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt
});




}
/// @nodoc
class _$CollectionCopyWithImpl<$Res>
    implements $CollectionCopyWith<$Res> {
  _$CollectionCopyWithImpl(this._self, this._then);

  final Collection _self;
  final $Res Function(Collection) _then;

/// Create a copy of Collection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? seasonId = freezed,Object? year = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? status = null,Object? version = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,seasonId: freezed == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CollectionStatus,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Collection].
extension CollectionPatterns on Collection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Collection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Collection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Collection value)  $default,){
final _that = this;
switch (_that) {
case _Collection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Collection value)?  $default,){
final _that = this;
switch (_that) {
case _Collection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  String? seasonId,  int? year,  DateTime? startDate,  DateTime? endDate,  CollectionStatus status,  int version,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Collection() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.seasonId,_that.year,_that.startDate,_that.endDate,_that.status,_that.version,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  String? seasonId,  int? year,  DateTime? startDate,  DateTime? endDate,  CollectionStatus status,  int version,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Collection():
return $default(_that.id,_that.organizationId,_that.name,_that.seasonId,_that.year,_that.startDate,_that.endDate,_that.status,_that.version,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String name,  String? seasonId,  int? year,  DateTime? startDate,  DateTime? endDate,  CollectionStatus status,  int version,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Collection() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.seasonId,_that.year,_that.startDate,_that.endDate,_that.status,_that.version,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Collection extends Collection {
  const _Collection({required this.id, required this.organizationId, required this.name, this.seasonId, this.year, this.startDate, this.endDate, required this.status, required this.version, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String name;
@override final  String? seasonId;
@override final  int? year;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  CollectionStatus status;
@override final  int version;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;

/// Create a copy of Collection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CollectionCopyWith<_Collection> get copyWith => __$CollectionCopyWithImpl<_Collection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Collection&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.year, year) || other.year == year)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.version, version) || other.version == version)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,seasonId,year,startDate,endDate,status,version,createdAt,createdBy,updatedAt,updatedBy,deletedAt);

@override
String toString() {
  return 'Collection(id: $id, organizationId: $organizationId, name: $name, seasonId: $seasonId, year: $year, startDate: $startDate, endDate: $endDate, status: $status, version: $version, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$CollectionCopyWith<$Res> implements $CollectionCopyWith<$Res> {
  factory _$CollectionCopyWith(_Collection value, $Res Function(_Collection) _then) = __$CollectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String name, String? seasonId, int? year, DateTime? startDate, DateTime? endDate, CollectionStatus status, int version, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt
});




}
/// @nodoc
class __$CollectionCopyWithImpl<$Res>
    implements _$CollectionCopyWith<$Res> {
  __$CollectionCopyWithImpl(this._self, this._then);

  final _Collection _self;
  final $Res Function(_Collection) _then;

/// Create a copy of Collection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? seasonId = freezed,Object? year = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? status = null,Object? version = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,}) {
  return _then(_Collection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,seasonId: freezed == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CollectionStatus,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
