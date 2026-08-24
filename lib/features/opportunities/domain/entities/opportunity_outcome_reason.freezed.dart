// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunity_outcome_reason.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpportunityOutcomeReason {

 String get id; String get organizationId; OpportunityOutcomeType get type; String get description; bool get isActive; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; int get version;
/// Create a copy of OpportunityOutcomeReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpportunityOutcomeReasonCopyWith<OpportunityOutcomeReason> get copyWith => _$OpportunityOutcomeReasonCopyWithImpl<OpportunityOutcomeReason>(this as OpportunityOutcomeReason, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpportunityOutcomeReason&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,type,description,isActive,createdAt,createdBy,updatedAt,updatedBy,version);

@override
String toString() {
  return 'OpportunityOutcomeReason(id: $id, organizationId: $organizationId, type: $type, description: $description, isActive: $isActive, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class $OpportunityOutcomeReasonCopyWith<$Res>  {
  factory $OpportunityOutcomeReasonCopyWith(OpportunityOutcomeReason value, $Res Function(OpportunityOutcomeReason) _then) = _$OpportunityOutcomeReasonCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, OpportunityOutcomeType type, String description, bool isActive, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version
});




}
/// @nodoc
class _$OpportunityOutcomeReasonCopyWithImpl<$Res>
    implements $OpportunityOutcomeReasonCopyWith<$Res> {
  _$OpportunityOutcomeReasonCopyWithImpl(this._self, this._then);

  final OpportunityOutcomeReason _self;
  final $Res Function(OpportunityOutcomeReason) _then;

/// Create a copy of OpportunityOutcomeReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? type = null,Object? description = null,Object? isActive = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OpportunityOutcomeType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OpportunityOutcomeReason].
extension OpportunityOutcomeReasonPatterns on OpportunityOutcomeReason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpportunityOutcomeReason value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpportunityOutcomeReason() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpportunityOutcomeReason value)  $default,){
final _that = this;
switch (_that) {
case _OpportunityOutcomeReason():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpportunityOutcomeReason value)?  $default,){
final _that = this;
switch (_that) {
case _OpportunityOutcomeReason() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  OpportunityOutcomeType type,  String description,  bool isActive,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpportunityOutcomeReason() when $default != null:
return $default(_that.id,_that.organizationId,_that.type,_that.description,_that.isActive,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  OpportunityOutcomeType type,  String description,  bool isActive,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version)  $default,) {final _that = this;
switch (_that) {
case _OpportunityOutcomeReason():
return $default(_that.id,_that.organizationId,_that.type,_that.description,_that.isActive,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  OpportunityOutcomeType type,  String description,  bool isActive,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version)?  $default,) {final _that = this;
switch (_that) {
case _OpportunityOutcomeReason() when $default != null:
return $default(_that.id,_that.organizationId,_that.type,_that.description,_that.isActive,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _OpportunityOutcomeReason extends OpportunityOutcomeReason {
  const _OpportunityOutcomeReason({required this.id, required this.organizationId, required this.type, required this.description, required this.isActive, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, required this.version}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  OpportunityOutcomeType type;
@override final  String description;
@override final  bool isActive;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  int version;

/// Create a copy of OpportunityOutcomeReason
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpportunityOutcomeReasonCopyWith<_OpportunityOutcomeReason> get copyWith => __$OpportunityOutcomeReasonCopyWithImpl<_OpportunityOutcomeReason>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpportunityOutcomeReason&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,type,description,isActive,createdAt,createdBy,updatedAt,updatedBy,version);

@override
String toString() {
  return 'OpportunityOutcomeReason(id: $id, organizationId: $organizationId, type: $type, description: $description, isActive: $isActive, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class _$OpportunityOutcomeReasonCopyWith<$Res> implements $OpportunityOutcomeReasonCopyWith<$Res> {
  factory _$OpportunityOutcomeReasonCopyWith(_OpportunityOutcomeReason value, $Res Function(_OpportunityOutcomeReason) _then) = __$OpportunityOutcomeReasonCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, OpportunityOutcomeType type, String description, bool isActive, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version
});




}
/// @nodoc
class __$OpportunityOutcomeReasonCopyWithImpl<$Res>
    implements _$OpportunityOutcomeReasonCopyWith<$Res> {
  __$OpportunityOutcomeReasonCopyWithImpl(this._self, this._then);

  final _OpportunityOutcomeReason _self;
  final $Res Function(_OpportunityOutcomeReason) _then;

/// Create a copy of OpportunityOutcomeReason
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? type = null,Object? description = null,Object? isActive = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,}) {
  return _then(_OpportunityOutcomeReason(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OpportunityOutcomeType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
