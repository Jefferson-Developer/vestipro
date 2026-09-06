// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_import_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerImportTemplate {

 String get id; String get organizationId; String get name; CustomerImportMapping get mapping; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of CustomerImportTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerImportTemplateCopyWith<CustomerImportTemplate> get copyWith => _$CustomerImportTemplateCopyWithImpl<CustomerImportTemplate>(this as CustomerImportTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerImportTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,mapping,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'CustomerImportTemplate(id: $id, organizationId: $organizationId, name: $name, mapping: $mapping, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $CustomerImportTemplateCopyWith<$Res>  {
  factory $CustomerImportTemplateCopyWith(CustomerImportTemplate value, $Res Function(CustomerImportTemplate) _then) = _$CustomerImportTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String name, CustomerImportMapping mapping, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});


$CustomerImportMappingCopyWith<$Res> get mapping;

}
/// @nodoc
class _$CustomerImportTemplateCopyWithImpl<$Res>
    implements $CustomerImportTemplateCopyWith<$Res> {
  _$CustomerImportTemplateCopyWithImpl(this._self, this._then);

  final CustomerImportTemplate _self;
  final $Res Function(CustomerImportTemplate) _then;

/// Create a copy of CustomerImportTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? mapping = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as CustomerImportMapping,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CustomerImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerImportMappingCopyWith<$Res> get mapping {
  
  return $CustomerImportMappingCopyWith<$Res>(_self.mapping, (value) {
    return _then(_self.copyWith(mapping: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerImportTemplate].
extension CustomerImportTemplatePatterns on CustomerImportTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerImportTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerImportTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerImportTemplate value)  $default,){
final _that = this;
switch (_that) {
case _CustomerImportTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerImportTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerImportTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  CustomerImportMapping mapping,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerImportTemplate() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.mapping,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  CustomerImportMapping mapping,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _CustomerImportTemplate():
return $default(_that.id,_that.organizationId,_that.name,_that.mapping,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String name,  CustomerImportMapping mapping,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _CustomerImportTemplate() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.mapping,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerImportTemplate implements CustomerImportTemplate {
  const _CustomerImportTemplate({required this.id, required this.organizationId, required this.name, required this.mapping, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy});
  

@override final  String id;
@override final  String organizationId;
@override final  String name;
@override final  CustomerImportMapping mapping;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of CustomerImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerImportTemplateCopyWith<_CustomerImportTemplate> get copyWith => __$CustomerImportTemplateCopyWithImpl<_CustomerImportTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerImportTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,mapping,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'CustomerImportTemplate(id: $id, organizationId: $organizationId, name: $name, mapping: $mapping, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$CustomerImportTemplateCopyWith<$Res> implements $CustomerImportTemplateCopyWith<$Res> {
  factory _$CustomerImportTemplateCopyWith(_CustomerImportTemplate value, $Res Function(_CustomerImportTemplate) _then) = __$CustomerImportTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String name, CustomerImportMapping mapping, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});


@override $CustomerImportMappingCopyWith<$Res> get mapping;

}
/// @nodoc
class __$CustomerImportTemplateCopyWithImpl<$Res>
    implements _$CustomerImportTemplateCopyWith<$Res> {
  __$CustomerImportTemplateCopyWithImpl(this._self, this._then);

  final _CustomerImportTemplate _self;
  final $Res Function(_CustomerImportTemplate) _then;

/// Create a copy of CustomerImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? mapping = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_CustomerImportTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as CustomerImportMapping,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CustomerImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerImportMappingCopyWith<$Res> get mapping {
  
  return $CustomerImportMappingCopyWith<$Res>(_self.mapping, (value) {
    return _then(_self.copyWith(mapping: value));
  });
}
}

// dart format on
