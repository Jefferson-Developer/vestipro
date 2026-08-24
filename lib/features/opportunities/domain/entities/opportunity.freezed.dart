// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Opportunity {

 String get id; String get organizationId; String? get companyId; String get title; String? get description; String? get customerId; String? get leadId; double get estimatedValue; int get probability; double get revenueForecast; String get responsibleUserId; String get stageId; OpportunityStatus get status; DateTime get expectedCloseDate; String? get wonReason; String? get lostReason; DateTime? get closedAt; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; int get version; OpportunitySyncStatus get syncStatus;
/// Create a copy of Opportunity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpportunityCopyWith<Opportunity> get copyWith => _$OpportunityCopyWithImpl<Opportunity>(this as Opportunity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Opportunity&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.leadId, leadId) || other.leadId == leadId)&&(identical(other.estimatedValue, estimatedValue) || other.estimatedValue == estimatedValue)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.revenueForecast, revenueForecast) || other.revenueForecast == revenueForecast)&&(identical(other.responsibleUserId, responsibleUserId) || other.responsibleUserId == responsibleUserId)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.status, status) || other.status == status)&&(identical(other.expectedCloseDate, expectedCloseDate) || other.expectedCloseDate == expectedCloseDate)&&(identical(other.wonReason, wonReason) || other.wonReason == wonReason)&&(identical(other.lostReason, lostReason) || other.lostReason == lostReason)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,title,description,customerId,leadId,estimatedValue,probability,revenueForecast,responsibleUserId,stageId,status,expectedCloseDate,wonReason,lostReason,closedAt,createdAt,createdBy,updatedAt,updatedBy,version,syncStatus]);

@override
String toString() {
  return 'Opportunity(id: $id, organizationId: $organizationId, companyId: $companyId, title: $title, description: $description, customerId: $customerId, leadId: $leadId, estimatedValue: $estimatedValue, probability: $probability, revenueForecast: $revenueForecast, responsibleUserId: $responsibleUserId, stageId: $stageId, status: $status, expectedCloseDate: $expectedCloseDate, wonReason: $wonReason, lostReason: $lostReason, closedAt: $closedAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $OpportunityCopyWith<$Res>  {
  factory $OpportunityCopyWith(Opportunity value, $Res Function(Opportunity) _then) = _$OpportunityCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String? companyId, String title, String? description, String? customerId, String? leadId, double estimatedValue, int probability, double revenueForecast, String responsibleUserId, String stageId, OpportunityStatus status, DateTime expectedCloseDate, String? wonReason, String? lostReason, DateTime? closedAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version, OpportunitySyncStatus syncStatus
});




}
/// @nodoc
class _$OpportunityCopyWithImpl<$Res>
    implements $OpportunityCopyWith<$Res> {
  _$OpportunityCopyWithImpl(this._self, this._then);

  final Opportunity _self;
  final $Res Function(Opportunity) _then;

/// Create a copy of Opportunity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? title = null,Object? description = freezed,Object? customerId = freezed,Object? leadId = freezed,Object? estimatedValue = null,Object? probability = null,Object? revenueForecast = null,Object? responsibleUserId = null,Object? stageId = null,Object? status = null,Object? expectedCloseDate = null,Object? wonReason = freezed,Object? lostReason = freezed,Object? closedAt = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,leadId: freezed == leadId ? _self.leadId : leadId // ignore: cast_nullable_to_non_nullable
as String?,estimatedValue: null == estimatedValue ? _self.estimatedValue : estimatedValue // ignore: cast_nullable_to_non_nullable
as double,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as int,revenueForecast: null == revenueForecast ? _self.revenueForecast : revenueForecast // ignore: cast_nullable_to_non_nullable
as double,responsibleUserId: null == responsibleUserId ? _self.responsibleUserId : responsibleUserId // ignore: cast_nullable_to_non_nullable
as String,stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OpportunityStatus,expectedCloseDate: null == expectedCloseDate ? _self.expectedCloseDate : expectedCloseDate // ignore: cast_nullable_to_non_nullable
as DateTime,wonReason: freezed == wonReason ? _self.wonReason : wonReason // ignore: cast_nullable_to_non_nullable
as String?,lostReason: freezed == lostReason ? _self.lostReason : lostReason // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as OpportunitySyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Opportunity].
extension OpportunityPatterns on Opportunity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Opportunity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Opportunity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Opportunity value)  $default,){
final _that = this;
switch (_that) {
case _Opportunity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Opportunity value)?  $default,){
final _that = this;
switch (_that) {
case _Opportunity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  String title,  String? description,  String? customerId,  String? leadId,  double estimatedValue,  int probability,  double revenueForecast,  String responsibleUserId,  String stageId,  OpportunityStatus status,  DateTime expectedCloseDate,  String? wonReason,  String? lostReason,  DateTime? closedAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  OpportunitySyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Opportunity() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.title,_that.description,_that.customerId,_that.leadId,_that.estimatedValue,_that.probability,_that.revenueForecast,_that.responsibleUserId,_that.stageId,_that.status,_that.expectedCloseDate,_that.wonReason,_that.lostReason,_that.closedAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  String title,  String? description,  String? customerId,  String? leadId,  double estimatedValue,  int probability,  double revenueForecast,  String responsibleUserId,  String stageId,  OpportunityStatus status,  DateTime expectedCloseDate,  String? wonReason,  String? lostReason,  DateTime? closedAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  OpportunitySyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Opportunity():
return $default(_that.id,_that.organizationId,_that.companyId,_that.title,_that.description,_that.customerId,_that.leadId,_that.estimatedValue,_that.probability,_that.revenueForecast,_that.responsibleUserId,_that.stageId,_that.status,_that.expectedCloseDate,_that.wonReason,_that.lostReason,_that.closedAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String? companyId,  String title,  String? description,  String? customerId,  String? leadId,  double estimatedValue,  int probability,  double revenueForecast,  String responsibleUserId,  String stageId,  OpportunityStatus status,  DateTime expectedCloseDate,  String? wonReason,  String? lostReason,  DateTime? closedAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  OpportunitySyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Opportunity() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.title,_that.description,_that.customerId,_that.leadId,_that.estimatedValue,_that.probability,_that.revenueForecast,_that.responsibleUserId,_that.stageId,_that.status,_that.expectedCloseDate,_that.wonReason,_that.lostReason,_that.closedAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Opportunity extends Opportunity {
  const _Opportunity({required this.id, required this.organizationId, this.companyId, required this.title, this.description, this.customerId, this.leadId, required this.estimatedValue, required this.probability, required this.revenueForecast, required this.responsibleUserId, required this.stageId, required this.status, required this.expectedCloseDate, this.wonReason, this.lostReason, this.closedAt, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, required this.version, required this.syncStatus}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String? companyId;
@override final  String title;
@override final  String? description;
@override final  String? customerId;
@override final  String? leadId;
@override final  double estimatedValue;
@override final  int probability;
@override final  double revenueForecast;
@override final  String responsibleUserId;
@override final  String stageId;
@override final  OpportunityStatus status;
@override final  DateTime expectedCloseDate;
@override final  String? wonReason;
@override final  String? lostReason;
@override final  DateTime? closedAt;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  int version;
@override final  OpportunitySyncStatus syncStatus;

/// Create a copy of Opportunity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpportunityCopyWith<_Opportunity> get copyWith => __$OpportunityCopyWithImpl<_Opportunity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Opportunity&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.leadId, leadId) || other.leadId == leadId)&&(identical(other.estimatedValue, estimatedValue) || other.estimatedValue == estimatedValue)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.revenueForecast, revenueForecast) || other.revenueForecast == revenueForecast)&&(identical(other.responsibleUserId, responsibleUserId) || other.responsibleUserId == responsibleUserId)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.status, status) || other.status == status)&&(identical(other.expectedCloseDate, expectedCloseDate) || other.expectedCloseDate == expectedCloseDate)&&(identical(other.wonReason, wonReason) || other.wonReason == wonReason)&&(identical(other.lostReason, lostReason) || other.lostReason == lostReason)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,title,description,customerId,leadId,estimatedValue,probability,revenueForecast,responsibleUserId,stageId,status,expectedCloseDate,wonReason,lostReason,closedAt,createdAt,createdBy,updatedAt,updatedBy,version,syncStatus]);

@override
String toString() {
  return 'Opportunity(id: $id, organizationId: $organizationId, companyId: $companyId, title: $title, description: $description, customerId: $customerId, leadId: $leadId, estimatedValue: $estimatedValue, probability: $probability, revenueForecast: $revenueForecast, responsibleUserId: $responsibleUserId, stageId: $stageId, status: $status, expectedCloseDate: $expectedCloseDate, wonReason: $wonReason, lostReason: $lostReason, closedAt: $closedAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$OpportunityCopyWith<$Res> implements $OpportunityCopyWith<$Res> {
  factory _$OpportunityCopyWith(_Opportunity value, $Res Function(_Opportunity) _then) = __$OpportunityCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String? companyId, String title, String? description, String? customerId, String? leadId, double estimatedValue, int probability, double revenueForecast, String responsibleUserId, String stageId, OpportunityStatus status, DateTime expectedCloseDate, String? wonReason, String? lostReason, DateTime? closedAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version, OpportunitySyncStatus syncStatus
});




}
/// @nodoc
class __$OpportunityCopyWithImpl<$Res>
    implements _$OpportunityCopyWith<$Res> {
  __$OpportunityCopyWithImpl(this._self, this._then);

  final _Opportunity _self;
  final $Res Function(_Opportunity) _then;

/// Create a copy of Opportunity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? title = null,Object? description = freezed,Object? customerId = freezed,Object? leadId = freezed,Object? estimatedValue = null,Object? probability = null,Object? revenueForecast = null,Object? responsibleUserId = null,Object? stageId = null,Object? status = null,Object? expectedCloseDate = null,Object? wonReason = freezed,Object? lostReason = freezed,Object? closedAt = freezed,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,Object? syncStatus = null,}) {
  return _then(_Opportunity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,leadId: freezed == leadId ? _self.leadId : leadId // ignore: cast_nullable_to_non_nullable
as String?,estimatedValue: null == estimatedValue ? _self.estimatedValue : estimatedValue // ignore: cast_nullable_to_non_nullable
as double,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as int,revenueForecast: null == revenueForecast ? _self.revenueForecast : revenueForecast // ignore: cast_nullable_to_non_nullable
as double,responsibleUserId: null == responsibleUserId ? _self.responsibleUserId : responsibleUserId // ignore: cast_nullable_to_non_nullable
as String,stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OpportunityStatus,expectedCloseDate: null == expectedCloseDate ? _self.expectedCloseDate : expectedCloseDate // ignore: cast_nullable_to_non_nullable
as DateTime,wonReason: freezed == wonReason ? _self.wonReason : wonReason // ignore: cast_nullable_to_non_nullable
as String?,lostReason: freezed == lostReason ? _self.lostReason : lostReason // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as OpportunitySyncStatus,
  ));
}


}

// dart format on
