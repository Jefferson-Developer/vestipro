// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_custom_field_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductCustomFieldDefinition {

 String get id; String get organizationId; String get key; String get label; ProductCustomFieldType get type; bool get isRequired; List<String> get options;
/// Create a copy of ProductCustomFieldDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCustomFieldDefinitionCopyWith<ProductCustomFieldDefinition> get copyWith => _$ProductCustomFieldDefinitionCopyWithImpl<ProductCustomFieldDefinition>(this as ProductCustomFieldDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCustomFieldDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&const DeepCollectionEquality().equals(other.options, options));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,key,label,type,isRequired,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'ProductCustomFieldDefinition(id: $id, organizationId: $organizationId, key: $key, label: $label, type: $type, isRequired: $isRequired, options: $options)';
}


}

/// @nodoc
abstract mixin class $ProductCustomFieldDefinitionCopyWith<$Res>  {
  factory $ProductCustomFieldDefinitionCopyWith(ProductCustomFieldDefinition value, $Res Function(ProductCustomFieldDefinition) _then) = _$ProductCustomFieldDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String key, String label, ProductCustomFieldType type, bool isRequired, List<String> options
});




}
/// @nodoc
class _$ProductCustomFieldDefinitionCopyWithImpl<$Res>
    implements $ProductCustomFieldDefinitionCopyWith<$Res> {
  _$ProductCustomFieldDefinitionCopyWithImpl(this._self, this._then);

  final ProductCustomFieldDefinition _self;
  final $Res Function(ProductCustomFieldDefinition) _then;

/// Create a copy of ProductCustomFieldDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? key = null,Object? label = null,Object? type = null,Object? isRequired = null,Object? options = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductCustomFieldType,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductCustomFieldDefinition].
extension ProductCustomFieldDefinitionPatterns on ProductCustomFieldDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCustomFieldDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCustomFieldDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCustomFieldDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ProductCustomFieldDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCustomFieldDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCustomFieldDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String key,  String label,  ProductCustomFieldType type,  bool isRequired,  List<String> options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCustomFieldDefinition() when $default != null:
return $default(_that.id,_that.organizationId,_that.key,_that.label,_that.type,_that.isRequired,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String key,  String label,  ProductCustomFieldType type,  bool isRequired,  List<String> options)  $default,) {final _that = this;
switch (_that) {
case _ProductCustomFieldDefinition():
return $default(_that.id,_that.organizationId,_that.key,_that.label,_that.type,_that.isRequired,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String key,  String label,  ProductCustomFieldType type,  bool isRequired,  List<String> options)?  $default,) {final _that = this;
switch (_that) {
case _ProductCustomFieldDefinition() when $default != null:
return $default(_that.id,_that.organizationId,_that.key,_that.label,_that.type,_that.isRequired,_that.options);case _:
  return null;

}
}

}

/// @nodoc


class _ProductCustomFieldDefinition implements ProductCustomFieldDefinition {
  const _ProductCustomFieldDefinition({required this.id, required this.organizationId, required this.key, required this.label, required this.type, required this.isRequired, final  List<String> options = const <String>[]}): _options = options;
  

@override final  String id;
@override final  String organizationId;
@override final  String key;
@override final  String label;
@override final  ProductCustomFieldType type;
@override final  bool isRequired;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


/// Create a copy of ProductCustomFieldDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCustomFieldDefinitionCopyWith<_ProductCustomFieldDefinition> get copyWith => __$ProductCustomFieldDefinitionCopyWithImpl<_ProductCustomFieldDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCustomFieldDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&const DeepCollectionEquality().equals(other._options, _options));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,key,label,type,isRequired,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'ProductCustomFieldDefinition(id: $id, organizationId: $organizationId, key: $key, label: $label, type: $type, isRequired: $isRequired, options: $options)';
}


}

/// @nodoc
abstract mixin class _$ProductCustomFieldDefinitionCopyWith<$Res> implements $ProductCustomFieldDefinitionCopyWith<$Res> {
  factory _$ProductCustomFieldDefinitionCopyWith(_ProductCustomFieldDefinition value, $Res Function(_ProductCustomFieldDefinition) _then) = __$ProductCustomFieldDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String key, String label, ProductCustomFieldType type, bool isRequired, List<String> options
});




}
/// @nodoc
class __$ProductCustomFieldDefinitionCopyWithImpl<$Res>
    implements _$ProductCustomFieldDefinitionCopyWith<$Res> {
  __$ProductCustomFieldDefinitionCopyWithImpl(this._self, this._then);

  final _ProductCustomFieldDefinition _self;
  final $Res Function(_ProductCustomFieldDefinition) _then;

/// Create a copy of ProductCustomFieldDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? key = null,Object? label = null,Object? type = null,Object? isRequired = null,Object? options = null,}) {
  return _then(_ProductCustomFieldDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductCustomFieldType,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
