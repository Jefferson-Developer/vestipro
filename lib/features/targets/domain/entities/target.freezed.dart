// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'target.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Target {

 String get id; String get organizationId; String get companyId; TargetDimensionType get dimensionType; String get dimensionId; TargetPeriodGranularity get periodGranularity; DateTime get startDate; DateTime get endDate; TargetMetricType get metricType; double get targetValue; String get currency; TargetStatus get status; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt; int get version; TargetSyncStatus get syncStatus;
/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TargetCopyWith<Target> get copyWith => _$TargetCopyWithImpl<Target>(this as Target, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Target&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.dimensionType, dimensionType) || other.dimensionType == dimensionType)&&(identical(other.dimensionId, dimensionId) || other.dimensionId == dimensionId)&&(identical(other.periodGranularity, periodGranularity) || other.periodGranularity == periodGranularity)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.metricType, metricType) || other.metricType == metricType)&&(identical(other.targetValue, targetValue) || other.targetValue == targetValue)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,dimensionType,dimensionId,periodGranularity,startDate,endDate,metricType,targetValue,currency,status,createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Target(id: $id, organizationId: $organizationId, companyId: $companyId, dimensionType: $dimensionType, dimensionId: $dimensionId, periodGranularity: $periodGranularity, startDate: $startDate, endDate: $endDate, metricType: $metricType, targetValue: $targetValue, currency: $currency, status: $status, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $TargetCopyWith<$Res>  {
  factory $TargetCopyWith(Target value, $Res Function(Target) _then) = _$TargetCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, TargetDimensionType dimensionType, String dimensionId, TargetPeriodGranularity periodGranularity, DateTime startDate, DateTime endDate, TargetMetricType metricType, double targetValue, String currency, TargetStatus status, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, TargetSyncStatus syncStatus
});




}
/// @nodoc
class _$TargetCopyWithImpl<$Res>
    implements $TargetCopyWith<$Res> {
  _$TargetCopyWithImpl(this._self, this._then);

  final Target _self;
  final $Res Function(Target) _then;

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? dimensionType = null,Object? dimensionId = null,Object? periodGranularity = null,Object? startDate = null,Object? endDate = null,Object? metricType = null,Object? targetValue = null,Object? currency = null,Object? status = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,dimensionType: null == dimensionType ? _self.dimensionType : dimensionType // ignore: cast_nullable_to_non_nullable
as TargetDimensionType,dimensionId: null == dimensionId ? _self.dimensionId : dimensionId // ignore: cast_nullable_to_non_nullable
as String,periodGranularity: null == periodGranularity ? _self.periodGranularity : periodGranularity // ignore: cast_nullable_to_non_nullable
as TargetPeriodGranularity,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,metricType: null == metricType ? _self.metricType : metricType // ignore: cast_nullable_to_non_nullable
as TargetMetricType,targetValue: null == targetValue ? _self.targetValue : targetValue // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TargetStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as TargetSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Target].
extension TargetPatterns on Target {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Target value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Target() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Target value)  $default,){
final _that = this;
switch (_that) {
case _Target():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Target value)?  $default,){
final _that = this;
switch (_that) {
case _Target() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  TargetDimensionType dimensionType,  String dimensionId,  TargetPeriodGranularity periodGranularity,  DateTime startDate,  DateTime endDate,  TargetMetricType metricType,  double targetValue,  String currency,  TargetStatus status,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  TargetSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Target() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.dimensionType,_that.dimensionId,_that.periodGranularity,_that.startDate,_that.endDate,_that.metricType,_that.targetValue,_that.currency,_that.status,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  TargetDimensionType dimensionType,  String dimensionId,  TargetPeriodGranularity periodGranularity,  DateTime startDate,  DateTime endDate,  TargetMetricType metricType,  double targetValue,  String currency,  TargetStatus status,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  TargetSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Target():
return $default(_that.id,_that.organizationId,_that.companyId,_that.dimensionType,_that.dimensionId,_that.periodGranularity,_that.startDate,_that.endDate,_that.metricType,_that.targetValue,_that.currency,_that.status,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  TargetDimensionType dimensionType,  String dimensionId,  TargetPeriodGranularity periodGranularity,  DateTime startDate,  DateTime endDate,  TargetMetricType metricType,  double targetValue,  String currency,  TargetStatus status,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  TargetSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Target() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.dimensionType,_that.dimensionId,_that.periodGranularity,_that.startDate,_that.endDate,_that.metricType,_that.targetValue,_that.currency,_that.status,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Target extends Target {
  const _Target({required this.id, required this.organizationId, required this.companyId, required this.dimensionType, required this.dimensionId, required this.periodGranularity, required this.startDate, required this.endDate, required this.metricType, required this.targetValue, required this.currency, required this.status, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt, required this.version, required this.syncStatus}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  TargetDimensionType dimensionType;
@override final  String dimensionId;
@override final  TargetPeriodGranularity periodGranularity;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  TargetMetricType metricType;
@override final  double targetValue;
@override final  String currency;
@override final  TargetStatus status;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;
@override final  int version;
@override final  TargetSyncStatus syncStatus;

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TargetCopyWith<_Target> get copyWith => __$TargetCopyWithImpl<_Target>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Target&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.dimensionType, dimensionType) || other.dimensionType == dimensionType)&&(identical(other.dimensionId, dimensionId) || other.dimensionId == dimensionId)&&(identical(other.periodGranularity, periodGranularity) || other.periodGranularity == periodGranularity)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.metricType, metricType) || other.metricType == metricType)&&(identical(other.targetValue, targetValue) || other.targetValue == targetValue)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,dimensionType,dimensionId,periodGranularity,startDate,endDate,metricType,targetValue,currency,status,createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Target(id: $id, organizationId: $organizationId, companyId: $companyId, dimensionType: $dimensionType, dimensionId: $dimensionId, periodGranularity: $periodGranularity, startDate: $startDate, endDate: $endDate, metricType: $metricType, targetValue: $targetValue, currency: $currency, status: $status, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$TargetCopyWith<$Res> implements $TargetCopyWith<$Res> {
  factory _$TargetCopyWith(_Target value, $Res Function(_Target) _then) = __$TargetCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, TargetDimensionType dimensionType, String dimensionId, TargetPeriodGranularity periodGranularity, DateTime startDate, DateTime endDate, TargetMetricType metricType, double targetValue, String currency, TargetStatus status, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, TargetSyncStatus syncStatus
});




}
/// @nodoc
class __$TargetCopyWithImpl<$Res>
    implements _$TargetCopyWith<$Res> {
  __$TargetCopyWithImpl(this._self, this._then);

  final _Target _self;
  final $Res Function(_Target) _then;

/// Create a copy of Target
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? dimensionType = null,Object? dimensionId = null,Object? periodGranularity = null,Object? startDate = null,Object? endDate = null,Object? metricType = null,Object? targetValue = null,Object? currency = null,Object? status = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_Target(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,dimensionType: null == dimensionType ? _self.dimensionType : dimensionType // ignore: cast_nullable_to_non_nullable
as TargetDimensionType,dimensionId: null == dimensionId ? _self.dimensionId : dimensionId // ignore: cast_nullable_to_non_nullable
as String,periodGranularity: null == periodGranularity ? _self.periodGranularity : periodGranularity // ignore: cast_nullable_to_non_nullable
as TargetPeriodGranularity,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,metricType: null == metricType ? _self.metricType : metricType // ignore: cast_nullable_to_non_nullable
as TargetMetricType,targetValue: null == targetValue ? _self.targetValue : targetValue // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TargetStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as TargetSyncStatus,
  ));
}


}

// dart format on
