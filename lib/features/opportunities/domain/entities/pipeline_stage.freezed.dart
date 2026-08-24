// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pipeline_stage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PipelineStage {

 String get id; String get organizationId; String get name; int get order; String get colorHex; PipelineStageTerminalType get terminalType; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; int get version;
/// Create a copy of PipelineStage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PipelineStageCopyWith<PipelineStage> get copyWith => _$PipelineStageCopyWithImpl<PipelineStage>(this as PipelineStage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PipelineStage&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.terminalType, terminalType) || other.terminalType == terminalType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,order,colorHex,terminalType,createdAt,createdBy,updatedAt,updatedBy,version);

@override
String toString() {
  return 'PipelineStage(id: $id, organizationId: $organizationId, name: $name, order: $order, colorHex: $colorHex, terminalType: $terminalType, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class $PipelineStageCopyWith<$Res>  {
  factory $PipelineStageCopyWith(PipelineStage value, $Res Function(PipelineStage) _then) = _$PipelineStageCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String name, int order, String colorHex, PipelineStageTerminalType terminalType, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version
});




}
/// @nodoc
class _$PipelineStageCopyWithImpl<$Res>
    implements $PipelineStageCopyWith<$Res> {
  _$PipelineStageCopyWithImpl(this._self, this._then);

  final PipelineStage _self;
  final $Res Function(PipelineStage) _then;

/// Create a copy of PipelineStage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? order = null,Object? colorHex = null,Object? terminalType = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,colorHex: null == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String,terminalType: null == terminalType ? _self.terminalType : terminalType // ignore: cast_nullable_to_non_nullable
as PipelineStageTerminalType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PipelineStage].
extension PipelineStagePatterns on PipelineStage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PipelineStage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PipelineStage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PipelineStage value)  $default,){
final _that = this;
switch (_that) {
case _PipelineStage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PipelineStage value)?  $default,){
final _that = this;
switch (_that) {
case _PipelineStage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  int order,  String colorHex,  PipelineStageTerminalType terminalType,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PipelineStage() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.order,_that.colorHex,_that.terminalType,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  int order,  String colorHex,  PipelineStageTerminalType terminalType,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version)  $default,) {final _that = this;
switch (_that) {
case _PipelineStage():
return $default(_that.id,_that.organizationId,_that.name,_that.order,_that.colorHex,_that.terminalType,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String name,  int order,  String colorHex,  PipelineStageTerminalType terminalType,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  int version)?  $default,) {final _that = this;
switch (_that) {
case _PipelineStage() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.order,_that.colorHex,_that.terminalType,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.version);case _:
  return null;

}
}

}

/// @nodoc


class _PipelineStage extends PipelineStage {
  const _PipelineStage({required this.id, required this.organizationId, required this.name, required this.order, required this.colorHex, required this.terminalType, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, required this.version}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String name;
@override final  int order;
@override final  String colorHex;
@override final  PipelineStageTerminalType terminalType;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  int version;

/// Create a copy of PipelineStage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PipelineStageCopyWith<_PipelineStage> get copyWith => __$PipelineStageCopyWithImpl<_PipelineStage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PipelineStage&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.terminalType, terminalType) || other.terminalType == terminalType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.version, version) || other.version == version));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,order,colorHex,terminalType,createdAt,createdBy,updatedAt,updatedBy,version);

@override
String toString() {
  return 'PipelineStage(id: $id, organizationId: $organizationId, name: $name, order: $order, colorHex: $colorHex, terminalType: $terminalType, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, version: $version)';
}


}

/// @nodoc
abstract mixin class _$PipelineStageCopyWith<$Res> implements $PipelineStageCopyWith<$Res> {
  factory _$PipelineStageCopyWith(_PipelineStage value, $Res Function(_PipelineStage) _then) = __$PipelineStageCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String name, int order, String colorHex, PipelineStageTerminalType terminalType, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, int version
});




}
/// @nodoc
class __$PipelineStageCopyWithImpl<$Res>
    implements _$PipelineStageCopyWith<$Res> {
  __$PipelineStageCopyWithImpl(this._self, this._then);

  final _PipelineStage _self;
  final $Res Function(_PipelineStage) _then;

/// Create a copy of PipelineStage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? order = null,Object? colorHex = null,Object? terminalType = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? version = null,}) {
  return _then(_PipelineStage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,colorHex: null == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String,terminalType: null == terminalType ? _self.terminalType : terminalType // ignore: cast_nullable_to_non_nullable
as PipelineStageTerminalType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
