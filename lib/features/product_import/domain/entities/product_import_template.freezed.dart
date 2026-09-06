// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportTemplate {

 String get id; String get organizationId; String get name; ProductImportMapping get mapping; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of ProductImportTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportTemplateCopyWith<ProductImportTemplate> get copyWith => _$ProductImportTemplateCopyWithImpl<ProductImportTemplate>(this as ProductImportTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,mapping,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'ProductImportTemplate(id: $id, organizationId: $organizationId, name: $name, mapping: $mapping, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $ProductImportTemplateCopyWith<$Res>  {
  factory $ProductImportTemplateCopyWith(ProductImportTemplate value, $Res Function(ProductImportTemplate) _then) = _$ProductImportTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String name, ProductImportMapping mapping, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});


$ProductImportMappingCopyWith<$Res> get mapping;

}
/// @nodoc
class _$ProductImportTemplateCopyWithImpl<$Res>
    implements $ProductImportTemplateCopyWith<$Res> {
  _$ProductImportTemplateCopyWithImpl(this._self, this._then);

  final ProductImportTemplate _self;
  final $Res Function(ProductImportTemplate) _then;

/// Create a copy of ProductImportTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? mapping = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as ProductImportMapping,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ProductImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductImportMappingCopyWith<$Res> get mapping {
  
  return $ProductImportMappingCopyWith<$Res>(_self.mapping, (value) {
    return _then(_self.copyWith(mapping: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductImportTemplate].
extension ProductImportTemplatePatterns on ProductImportTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportTemplate value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  ProductImportMapping mapping,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImportTemplate() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String name,  ProductImportMapping mapping,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _ProductImportTemplate():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String name,  ProductImportMapping mapping,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _ProductImportTemplate() when $default != null:
return $default(_that.id,_that.organizationId,_that.name,_that.mapping,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportTemplate implements ProductImportTemplate {
  const _ProductImportTemplate({required this.id, required this.organizationId, required this.name, required this.mapping, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy});
  

@override final  String id;
@override final  String organizationId;
@override final  String name;
@override final  ProductImportMapping mapping;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of ProductImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportTemplateCopyWith<_ProductImportTemplate> get copyWith => __$ProductImportTemplateCopyWithImpl<_ProductImportTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,name,mapping,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'ProductImportTemplate(id: $id, organizationId: $organizationId, name: $name, mapping: $mapping, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$ProductImportTemplateCopyWith<$Res> implements $ProductImportTemplateCopyWith<$Res> {
  factory _$ProductImportTemplateCopyWith(_ProductImportTemplate value, $Res Function(_ProductImportTemplate) _then) = __$ProductImportTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String name, ProductImportMapping mapping, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});


@override $ProductImportMappingCopyWith<$Res> get mapping;

}
/// @nodoc
class __$ProductImportTemplateCopyWithImpl<$Res>
    implements _$ProductImportTemplateCopyWith<$Res> {
  __$ProductImportTemplateCopyWithImpl(this._self, this._then);

  final _ProductImportTemplate _self;
  final $Res Function(_ProductImportTemplate) _then;

/// Create a copy of ProductImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? name = null,Object? mapping = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_ProductImportTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as ProductImportMapping,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ProductImportTemplate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductImportMappingCopyWith<$Res> get mapping {
  
  return $ProductImportMappingCopyWith<$Res>(_self.mapping, (value) {
    return _then(_self.copyWith(mapping: value));
  });
}
}

// dart format on
