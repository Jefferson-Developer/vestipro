// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lead.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Lead {

 String get id; String get organizationId; String? get companyId; String get name; String? get document; LeadSource get source; String get responsibleUserId; LeadStatus get status; int get score; String? get disqualificationReason; String? get convertedCustomerId; String? get convertedOpportunityId; DateTime get createdAt; DateTime? get contactedAt; DateTime? get qualifiedAt; DateTime? get convertedAt; String get createdBy; DateTime get updatedAt; String get updatedBy; int get version; LeadSyncStatus get syncStatus;
/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadCopyWith<Lead> get copyWith => _$LeadCopyWithImpl<Lead>(this as Lead, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lead&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.document, document) || other.document == document)&&(identical(other.source, source) || other.source == source)&&(identical(other.responsibleUserId, responsibleUserId) || other.responsibleUserId == responsibleUserId)&&(identical(other.status, status) || other.status == status)&&(identical(other.score, score) || other.score == score)&&(identical(other.disqualificationReason, disqualificationReason) || other.disqualificationReason == disqualificationReason)&&(identical(other.convertedCustomerId, convertedCustomerId) || other.convertedCustomerId == convertedCustomerId)&&(identical(other.convertedOpportunityId, convertedOpportunityId) || other.convertedOpportunityId == convertedOpportunityId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.contactedAt, contactedAt) || other.contactedAt == contactedAt)&&(identical(other.qualifiedAt, qualifiedAt) || other.qualifiedAt == qualifiedAt)&&(identical(other.convertedAt, convertedAt) || other.convertedAt == convertedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,name,document,source,responsibleUserId,status,score,disqualificationReason,convertedCustomerId,convertedOpportunityId,createdAt,contactedAt,qualifiedAt,convertedAt,createdBy,updatedAt,updatedBy,version,syncStatus]);

@override
String toString() {
  return 'Lead(id: $id, organizationId: $organizationId, companyId: $companyId, name: $name, document: $document, source: $source, responsibleUserId: $responsibleUserId, status: $status, score: $score, disqualificationReason: $disqualificationReason, convertedCustomerId: $convertedCustomerId, convertedOpportunityId: $convertedOpportunityId, createdAt: $createdAt, contactedAt: $contactedAt, qualifiedAt: $qualifiedAt, convertedAt: $convertedAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $LeadCopyWith<$Res>  {
  factory $LeadCopyWith(Lead value, $Res Function(Lead) _then) = _$LeadCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String? companyId, String name, String? document, LeadSource source, String responsibleUserId, LeadStatus status, int score, String? disqualificationReason, String? convertedCustomerId, String? convertedOpportunityId, DateTime createdAt, DateTime? contactedAt, DateTime? qualifiedAt, DateTime? convertedAt, String createdBy, DateTime updatedAt, String updatedBy, int version, LeadSyncStatus syncStatus
});




}
/// @nodoc
class _$LeadCopyWithImpl<$Res>
    implements $LeadCopyWith<$Res> {
  _$LeadCopyWithImpl(this._self, this._then);

  final Lead _self;
  final $Res Function(Lead) _then;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? name = null,Object? document = freezed,Object? source = null,Object? responsibleUserId = null,Object? status = null,Object? score = null,Object? disqualificationReason = freezed,Object? convertedCustomerId = freezed,Object? convertedOpportunityId = freezed,Object? createdAt = null,Object? contactedAt = freezed,Object? qualifiedAt = freezed,Object? convertedAt = freezed,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource,responsibleUserId: null == responsibleUserId ? _self.responsibleUserId : responsibleUserId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeadStatus,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,disqualificationReason: freezed == disqualificationReason ? _self.disqualificationReason : disqualificationReason // ignore: cast_nullable_to_non_nullable
as String?,convertedCustomerId: freezed == convertedCustomerId ? _self.convertedCustomerId : convertedCustomerId // ignore: cast_nullable_to_non_nullable
as String?,convertedOpportunityId: freezed == convertedOpportunityId ? _self.convertedOpportunityId : convertedOpportunityId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,contactedAt: freezed == contactedAt ? _self.contactedAt : contactedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,qualifiedAt: freezed == qualifiedAt ? _self.qualifiedAt : qualifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,convertedAt: freezed == convertedAt ? _self.convertedAt : convertedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as LeadSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Lead].
extension LeadPatterns on Lead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lead value)  $default,){
final _that = this;
switch (_that) {
case _Lead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lead value)?  $default,){
final _that = this;
switch (_that) {
case _Lead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  String name,  String? document,  LeadSource source,  String responsibleUserId,  LeadStatus status,  int score,  String? disqualificationReason,  String? convertedCustomerId,  String? convertedOpportunityId,  DateTime createdAt,  DateTime? contactedAt,  DateTime? qualifiedAt,  DateTime? convertedAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  LeadSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lead() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.name,_that.document,_that.source,_that.responsibleUserId,_that.status,_that.score,_that.disqualificationReason,_that.convertedCustomerId,_that.convertedOpportunityId,_that.createdAt,_that.contactedAt,_that.qualifiedAt,_that.convertedAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String? companyId,  String name,  String? document,  LeadSource source,  String responsibleUserId,  LeadStatus status,  int score,  String? disqualificationReason,  String? convertedCustomerId,  String? convertedOpportunityId,  DateTime createdAt,  DateTime? contactedAt,  DateTime? qualifiedAt,  DateTime? convertedAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  LeadSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Lead():
return $default(_that.id,_that.organizationId,_that.companyId,_that.name,_that.document,_that.source,_that.responsibleUserId,_that.status,_that.score,_that.disqualificationReason,_that.convertedCustomerId,_that.convertedOpportunityId,_that.createdAt,_that.contactedAt,_that.qualifiedAt,_that.convertedAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String? companyId,  String name,  String? document,  LeadSource source,  String responsibleUserId,  LeadStatus status,  int score,  String? disqualificationReason,  String? convertedCustomerId,  String? convertedOpportunityId,  DateTime createdAt,  DateTime? contactedAt,  DateTime? qualifiedAt,  DateTime? convertedAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version,  LeadSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Lead() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.name,_that.document,_that.source,_that.responsibleUserId,_that.status,_that.score,_that.disqualificationReason,_that.convertedCustomerId,_that.convertedOpportunityId,_that.createdAt,_that.contactedAt,_that.qualifiedAt,_that.convertedAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Lead extends Lead {
  const _Lead({required this.id, required this.organizationId, this.companyId, required this.name, this.document, required this.source, required this.responsibleUserId, required this.status, this.score = 0, this.disqualificationReason, this.convertedCustomerId, this.convertedOpportunityId, required this.createdAt, this.contactedAt, this.qualifiedAt, this.convertedAt, required this.createdBy, required this.updatedAt, required this.updatedBy, required this.version, required this.syncStatus}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String? companyId;
@override final  String name;
@override final  String? document;
@override final  LeadSource source;
@override final  String responsibleUserId;
@override final  LeadStatus status;
@override@JsonKey() final  int score;
@override final  String? disqualificationReason;
@override final  String? convertedCustomerId;
@override final  String? convertedOpportunityId;
@override final  DateTime createdAt;
@override final  DateTime? contactedAt;
@override final  DateTime? qualifiedAt;
@override final  DateTime? convertedAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  int version;
@override final  LeadSyncStatus syncStatus;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadCopyWith<_Lead> get copyWith => __$LeadCopyWithImpl<_Lead>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lead&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.document, document) || other.document == document)&&(identical(other.source, source) || other.source == source)&&(identical(other.responsibleUserId, responsibleUserId) || other.responsibleUserId == responsibleUserId)&&(identical(other.status, status) || other.status == status)&&(identical(other.score, score) || other.score == score)&&(identical(other.disqualificationReason, disqualificationReason) || other.disqualificationReason == disqualificationReason)&&(identical(other.convertedCustomerId, convertedCustomerId) || other.convertedCustomerId == convertedCustomerId)&&(identical(other.convertedOpportunityId, convertedOpportunityId) || other.convertedOpportunityId == convertedOpportunityId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.contactedAt, contactedAt) || other.contactedAt == contactedAt)&&(identical(other.qualifiedAt, qualifiedAt) || other.qualifiedAt == qualifiedAt)&&(identical(other.convertedAt, convertedAt) || other.convertedAt == convertedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,name,document,source,responsibleUserId,status,score,disqualificationReason,convertedCustomerId,convertedOpportunityId,createdAt,contactedAt,qualifiedAt,convertedAt,createdBy,updatedAt,updatedBy,version,syncStatus]);

@override
String toString() {
  return 'Lead(id: $id, organizationId: $organizationId, companyId: $companyId, name: $name, document: $document, source: $source, responsibleUserId: $responsibleUserId, status: $status, score: $score, disqualificationReason: $disqualificationReason, convertedCustomerId: $convertedCustomerId, convertedOpportunityId: $convertedOpportunityId, createdAt: $createdAt, contactedAt: $contactedAt, qualifiedAt: $qualifiedAt, convertedAt: $convertedAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$LeadCopyWith<$Res> implements $LeadCopyWith<$Res> {
  factory _$LeadCopyWith(_Lead value, $Res Function(_Lead) _then) = __$LeadCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String? companyId, String name, String? document, LeadSource source, String responsibleUserId, LeadStatus status, int score, String? disqualificationReason, String? convertedCustomerId, String? convertedOpportunityId, DateTime createdAt, DateTime? contactedAt, DateTime? qualifiedAt, DateTime? convertedAt, String createdBy, DateTime updatedAt, String updatedBy, int version, LeadSyncStatus syncStatus
});




}
/// @nodoc
class __$LeadCopyWithImpl<$Res>
    implements _$LeadCopyWith<$Res> {
  __$LeadCopyWithImpl(this._self, this._then);

  final _Lead _self;
  final $Res Function(_Lead) _then;

/// Create a copy of Lead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = freezed,Object? name = null,Object? document = freezed,Object? source = null,Object? responsibleUserId = null,Object? status = null,Object? score = null,Object? disqualificationReason = freezed,Object? convertedCustomerId = freezed,Object? convertedOpportunityId = freezed,Object? createdAt = null,Object? contactedAt = freezed,Object? qualifiedAt = freezed,Object? convertedAt = freezed,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,Object? syncStatus = null,}) {
  return _then(_Lead(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: freezed == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LeadSource,responsibleUserId: null == responsibleUserId ? _self.responsibleUserId : responsibleUserId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeadStatus,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,disqualificationReason: freezed == disqualificationReason ? _self.disqualificationReason : disqualificationReason // ignore: cast_nullable_to_non_nullable
as String?,convertedCustomerId: freezed == convertedCustomerId ? _self.convertedCustomerId : convertedCustomerId // ignore: cast_nullable_to_non_nullable
as String?,convertedOpportunityId: freezed == convertedOpportunityId ? _self.convertedOpportunityId : convertedOpportunityId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,contactedAt: freezed == contactedAt ? _self.contactedAt : contactedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,qualifiedAt: freezed == qualifiedAt ? _self.qualifiedAt : qualifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,convertedAt: freezed == convertedAt ? _self.convertedAt : convertedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as LeadSyncStatus,
  ));
}


}

// dart format on
