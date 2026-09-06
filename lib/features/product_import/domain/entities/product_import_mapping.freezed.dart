// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_mapping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportMapping {

 bool get hasHeaderRow; Map<ProductImportField, int> get columnByField; String get sizeGridTemplateId;
/// Create a copy of ProductImportMapping
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportMappingCopyWith<ProductImportMapping> get copyWith => _$ProductImportMappingCopyWithImpl<ProductImportMapping>(this as ProductImportMapping, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportMapping&&(identical(other.hasHeaderRow, hasHeaderRow) || other.hasHeaderRow == hasHeaderRow)&&const DeepCollectionEquality().equals(other.columnByField, columnByField)&&(identical(other.sizeGridTemplateId, sizeGridTemplateId) || other.sizeGridTemplateId == sizeGridTemplateId));
}


@override
int get hashCode => Object.hash(runtimeType,hasHeaderRow,const DeepCollectionEquality().hash(columnByField),sizeGridTemplateId);

@override
String toString() {
  return 'ProductImportMapping(hasHeaderRow: $hasHeaderRow, columnByField: $columnByField, sizeGridTemplateId: $sizeGridTemplateId)';
}


}

/// @nodoc
abstract mixin class $ProductImportMappingCopyWith<$Res>  {
  factory $ProductImportMappingCopyWith(ProductImportMapping value, $Res Function(ProductImportMapping) _then) = _$ProductImportMappingCopyWithImpl;
@useResult
$Res call({
 bool hasHeaderRow, Map<ProductImportField, int> columnByField, String sizeGridTemplateId
});




}
/// @nodoc
class _$ProductImportMappingCopyWithImpl<$Res>
    implements $ProductImportMappingCopyWith<$Res> {
  _$ProductImportMappingCopyWithImpl(this._self, this._then);

  final ProductImportMapping _self;
  final $Res Function(ProductImportMapping) _then;

/// Create a copy of ProductImportMapping
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasHeaderRow = null,Object? columnByField = null,Object? sizeGridTemplateId = null,}) {
  return _then(_self.copyWith(
hasHeaderRow: null == hasHeaderRow ? _self.hasHeaderRow : hasHeaderRow // ignore: cast_nullable_to_non_nullable
as bool,columnByField: null == columnByField ? _self.columnByField : columnByField // ignore: cast_nullable_to_non_nullable
as Map<ProductImportField, int>,sizeGridTemplateId: null == sizeGridTemplateId ? _self.sizeGridTemplateId : sizeGridTemplateId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImportMapping].
extension ProductImportMappingPatterns on ProductImportMapping {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportMapping value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportMapping() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportMapping value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportMapping():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportMapping value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportMapping() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasHeaderRow,  Map<ProductImportField, int> columnByField,  String sizeGridTemplateId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImportMapping() when $default != null:
return $default(_that.hasHeaderRow,_that.columnByField,_that.sizeGridTemplateId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasHeaderRow,  Map<ProductImportField, int> columnByField,  String sizeGridTemplateId)  $default,) {final _that = this;
switch (_that) {
case _ProductImportMapping():
return $default(_that.hasHeaderRow,_that.columnByField,_that.sizeGridTemplateId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasHeaderRow,  Map<ProductImportField, int> columnByField,  String sizeGridTemplateId)?  $default,) {final _that = this;
switch (_that) {
case _ProductImportMapping() when $default != null:
return $default(_that.hasHeaderRow,_that.columnByField,_that.sizeGridTemplateId);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportMapping implements ProductImportMapping {
  const _ProductImportMapping({required this.hasHeaderRow, required final  Map<ProductImportField, int> columnByField, required this.sizeGridTemplateId}): _columnByField = columnByField;
  

@override final  bool hasHeaderRow;
 final  Map<ProductImportField, int> _columnByField;
@override Map<ProductImportField, int> get columnByField {
  if (_columnByField is EqualUnmodifiableMapView) return _columnByField;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_columnByField);
}

@override final  String sizeGridTemplateId;

/// Create a copy of ProductImportMapping
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportMappingCopyWith<_ProductImportMapping> get copyWith => __$ProductImportMappingCopyWithImpl<_ProductImportMapping>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportMapping&&(identical(other.hasHeaderRow, hasHeaderRow) || other.hasHeaderRow == hasHeaderRow)&&const DeepCollectionEquality().equals(other._columnByField, _columnByField)&&(identical(other.sizeGridTemplateId, sizeGridTemplateId) || other.sizeGridTemplateId == sizeGridTemplateId));
}


@override
int get hashCode => Object.hash(runtimeType,hasHeaderRow,const DeepCollectionEquality().hash(_columnByField),sizeGridTemplateId);

@override
String toString() {
  return 'ProductImportMapping(hasHeaderRow: $hasHeaderRow, columnByField: $columnByField, sizeGridTemplateId: $sizeGridTemplateId)';
}


}

/// @nodoc
abstract mixin class _$ProductImportMappingCopyWith<$Res> implements $ProductImportMappingCopyWith<$Res> {
  factory _$ProductImportMappingCopyWith(_ProductImportMapping value, $Res Function(_ProductImportMapping) _then) = __$ProductImportMappingCopyWithImpl;
@override @useResult
$Res call({
 bool hasHeaderRow, Map<ProductImportField, int> columnByField, String sizeGridTemplateId
});




}
/// @nodoc
class __$ProductImportMappingCopyWithImpl<$Res>
    implements _$ProductImportMappingCopyWith<$Res> {
  __$ProductImportMappingCopyWithImpl(this._self, this._then);

  final _ProductImportMapping _self;
  final $Res Function(_ProductImportMapping) _then;

/// Create a copy of ProductImportMapping
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasHeaderRow = null,Object? columnByField = null,Object? sizeGridTemplateId = null,}) {
  return _then(_ProductImportMapping(
hasHeaderRow: null == hasHeaderRow ? _self.hasHeaderRow : hasHeaderRow // ignore: cast_nullable_to_non_nullable
as bool,columnByField: null == columnByField ? _self._columnByField : columnByField // ignore: cast_nullable_to_non_nullable
as Map<ProductImportField, int>,sizeGridTemplateId: null == sizeGridTemplateId ? _self.sizeGridTemplateId : sizeGridTemplateId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
