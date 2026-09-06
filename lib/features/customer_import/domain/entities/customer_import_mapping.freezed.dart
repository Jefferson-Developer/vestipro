// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_import_mapping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerImportMapping {

 bool get hasHeaderRow; Map<CustomerImportField, int> get columnByField;
/// Create a copy of CustomerImportMapping
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerImportMappingCopyWith<CustomerImportMapping> get copyWith => _$CustomerImportMappingCopyWithImpl<CustomerImportMapping>(this as CustomerImportMapping, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerImportMapping&&(identical(other.hasHeaderRow, hasHeaderRow) || other.hasHeaderRow == hasHeaderRow)&&const DeepCollectionEquality().equals(other.columnByField, columnByField));
}


@override
int get hashCode => Object.hash(runtimeType,hasHeaderRow,const DeepCollectionEquality().hash(columnByField));

@override
String toString() {
  return 'CustomerImportMapping(hasHeaderRow: $hasHeaderRow, columnByField: $columnByField)';
}


}

/// @nodoc
abstract mixin class $CustomerImportMappingCopyWith<$Res>  {
  factory $CustomerImportMappingCopyWith(CustomerImportMapping value, $Res Function(CustomerImportMapping) _then) = _$CustomerImportMappingCopyWithImpl;
@useResult
$Res call({
 bool hasHeaderRow, Map<CustomerImportField, int> columnByField
});




}
/// @nodoc
class _$CustomerImportMappingCopyWithImpl<$Res>
    implements $CustomerImportMappingCopyWith<$Res> {
  _$CustomerImportMappingCopyWithImpl(this._self, this._then);

  final CustomerImportMapping _self;
  final $Res Function(CustomerImportMapping) _then;

/// Create a copy of CustomerImportMapping
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasHeaderRow = null,Object? columnByField = null,}) {
  return _then(_self.copyWith(
hasHeaderRow: null == hasHeaderRow ? _self.hasHeaderRow : hasHeaderRow // ignore: cast_nullable_to_non_nullable
as bool,columnByField: null == columnByField ? _self.columnByField : columnByField // ignore: cast_nullable_to_non_nullable
as Map<CustomerImportField, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerImportMapping].
extension CustomerImportMappingPatterns on CustomerImportMapping {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerImportMapping value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerImportMapping() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerImportMapping value)  $default,){
final _that = this;
switch (_that) {
case _CustomerImportMapping():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerImportMapping value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerImportMapping() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasHeaderRow,  Map<CustomerImportField, int> columnByField)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerImportMapping() when $default != null:
return $default(_that.hasHeaderRow,_that.columnByField);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasHeaderRow,  Map<CustomerImportField, int> columnByField)  $default,) {final _that = this;
switch (_that) {
case _CustomerImportMapping():
return $default(_that.hasHeaderRow,_that.columnByField);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasHeaderRow,  Map<CustomerImportField, int> columnByField)?  $default,) {final _that = this;
switch (_that) {
case _CustomerImportMapping() when $default != null:
return $default(_that.hasHeaderRow,_that.columnByField);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerImportMapping extends CustomerImportMapping {
  const _CustomerImportMapping({required this.hasHeaderRow, required final  Map<CustomerImportField, int> columnByField}): _columnByField = columnByField,super._();
  

@override final  bool hasHeaderRow;
 final  Map<CustomerImportField, int> _columnByField;
@override Map<CustomerImportField, int> get columnByField {
  if (_columnByField is EqualUnmodifiableMapView) return _columnByField;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_columnByField);
}


/// Create a copy of CustomerImportMapping
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerImportMappingCopyWith<_CustomerImportMapping> get copyWith => __$CustomerImportMappingCopyWithImpl<_CustomerImportMapping>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerImportMapping&&(identical(other.hasHeaderRow, hasHeaderRow) || other.hasHeaderRow == hasHeaderRow)&&const DeepCollectionEquality().equals(other._columnByField, _columnByField));
}


@override
int get hashCode => Object.hash(runtimeType,hasHeaderRow,const DeepCollectionEquality().hash(_columnByField));

@override
String toString() {
  return 'CustomerImportMapping(hasHeaderRow: $hasHeaderRow, columnByField: $columnByField)';
}


}

/// @nodoc
abstract mixin class _$CustomerImportMappingCopyWith<$Res> implements $CustomerImportMappingCopyWith<$Res> {
  factory _$CustomerImportMappingCopyWith(_CustomerImportMapping value, $Res Function(_CustomerImportMapping) _then) = __$CustomerImportMappingCopyWithImpl;
@override @useResult
$Res call({
 bool hasHeaderRow, Map<CustomerImportField, int> columnByField
});




}
/// @nodoc
class __$CustomerImportMappingCopyWithImpl<$Res>
    implements _$CustomerImportMappingCopyWith<$Res> {
  __$CustomerImportMappingCopyWithImpl(this._self, this._then);

  final _CustomerImportMapping _self;
  final $Res Function(_CustomerImportMapping) _then;

/// Create a copy of CustomerImportMapping
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasHeaderRow = null,Object? columnByField = null,}) {
  return _then(_CustomerImportMapping(
hasHeaderRow: null == hasHeaderRow ? _self.hasHeaderRow : hasHeaderRow // ignore: cast_nullable_to_non_nullable
as bool,columnByField: null == columnByField ? _self._columnByField : columnByField // ignore: cast_nullable_to_non_nullable
as Map<CustomerImportField, int>,
  ));
}


}

// dart format on
