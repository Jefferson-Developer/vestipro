// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PriceList {

 String get id; String get organizationId; String get companyId; String get name; String get currency; DateTime get validFrom; DateTime? get validTo; PriceListStatus get status; PriceListScopeType get scope; String? get scopeValue; int get priority; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt; int get version; PriceListSyncStatus get syncStatus;
/// Create a copy of PriceList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceListCopyWith<PriceList> get copyWith => _$PriceListCopyWithImpl<PriceList>(this as PriceList, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceList&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.scopeValue, scopeValue) || other.scopeValue == scopeValue)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,companyId,name,currency,validFrom,validTo,status,scope,scopeValue,priority,createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus);

@override
String toString() {
  return 'PriceList(id: $id, organizationId: $organizationId, companyId: $companyId, name: $name, currency: $currency, validFrom: $validFrom, validTo: $validTo, status: $status, scope: $scope, scopeValue: $scopeValue, priority: $priority, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $PriceListCopyWith<$Res>  {
  factory $PriceListCopyWith(PriceList value, $Res Function(PriceList) _then) = _$PriceListCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, String name, String currency, DateTime validFrom, DateTime? validTo, PriceListStatus status, PriceListScopeType scope, String? scopeValue, int priority, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, PriceListSyncStatus syncStatus
});




}
/// @nodoc
class _$PriceListCopyWithImpl<$Res>
    implements $PriceListCopyWith<$Res> {
  _$PriceListCopyWithImpl(this._self, this._then);

  final PriceList _self;
  final $Res Function(PriceList) _then;

/// Create a copy of PriceList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? name = null,Object? currency = null,Object? validFrom = null,Object? validTo = freezed,Object? status = null,Object? scope = null,Object? scopeValue = freezed,Object? priority = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PriceListStatus,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PriceListScopeType,scopeValue: freezed == scopeValue ? _self.scopeValue : scopeValue // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as PriceListSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceList].
extension PriceListPatterns on PriceList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceList value)  $default,){
final _that = this;
switch (_that) {
case _PriceList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceList value)?  $default,){
final _that = this;
switch (_that) {
case _PriceList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String name,  String currency,  DateTime validFrom,  DateTime? validTo,  PriceListStatus status,  PriceListScopeType scope,  String? scopeValue,  int priority,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  PriceListSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceList() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.name,_that.currency,_that.validFrom,_that.validTo,_that.status,_that.scope,_that.scopeValue,_that.priority,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String name,  String currency,  DateTime validFrom,  DateTime? validTo,  PriceListStatus status,  PriceListScopeType scope,  String? scopeValue,  int priority,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  PriceListSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _PriceList():
return $default(_that.id,_that.organizationId,_that.companyId,_that.name,_that.currency,_that.validFrom,_that.validTo,_that.status,_that.scope,_that.scopeValue,_that.priority,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  String name,  String currency,  DateTime validFrom,  DateTime? validTo,  PriceListStatus status,  PriceListScopeType scope,  String? scopeValue,  int priority,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  PriceListSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _PriceList() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.name,_that.currency,_that.validFrom,_that.validTo,_that.status,_that.scope,_that.scopeValue,_that.priority,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _PriceList extends PriceList {
  const _PriceList({required this.id, required this.organizationId, required this.companyId, required this.name, required this.currency, required this.validFrom, this.validTo, required this.status, required this.scope, this.scopeValue, this.priority = 0, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt, required this.version, required this.syncStatus}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  String name;
@override final  String currency;
@override final  DateTime validFrom;
@override final  DateTime? validTo;
@override final  PriceListStatus status;
@override final  PriceListScopeType scope;
@override final  String? scopeValue;
@override@JsonKey() final  int priority;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;
@override final  int version;
@override final  PriceListSyncStatus syncStatus;

/// Create a copy of PriceList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceListCopyWith<_PriceList> get copyWith => __$PriceListCopyWithImpl<_PriceList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceList&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.scopeValue, scopeValue) || other.scopeValue == scopeValue)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,companyId,name,currency,validFrom,validTo,status,scope,scopeValue,priority,createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus);

@override
String toString() {
  return 'PriceList(id: $id, organizationId: $organizationId, companyId: $companyId, name: $name, currency: $currency, validFrom: $validFrom, validTo: $validTo, status: $status, scope: $scope, scopeValue: $scopeValue, priority: $priority, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$PriceListCopyWith<$Res> implements $PriceListCopyWith<$Res> {
  factory _$PriceListCopyWith(_PriceList value, $Res Function(_PriceList) _then) = __$PriceListCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, String name, String currency, DateTime validFrom, DateTime? validTo, PriceListStatus status, PriceListScopeType scope, String? scopeValue, int priority, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, PriceListSyncStatus syncStatus
});




}
/// @nodoc
class __$PriceListCopyWithImpl<$Res>
    implements _$PriceListCopyWith<$Res> {
  __$PriceListCopyWithImpl(this._self, this._then);

  final _PriceList _self;
  final $Res Function(_PriceList) _then;

/// Create a copy of PriceList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? name = null,Object? currency = null,Object? validFrom = null,Object? validTo = freezed,Object? status = null,Object? scope = null,Object? scopeValue = freezed,Object? priority = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_PriceList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PriceListStatus,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as PriceListScopeType,scopeValue: freezed == scopeValue ? _self.scopeValue : scopeValue // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as PriceListSyncStatus,
  ));
}


}

// dart format on
