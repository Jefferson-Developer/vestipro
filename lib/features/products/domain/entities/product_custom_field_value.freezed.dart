// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_custom_field_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductCustomFieldValue {

 String get fieldDefinitionId; Object? get value;
/// Create a copy of ProductCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCustomFieldValueCopyWith<ProductCustomFieldValue> get copyWith => _$ProductCustomFieldValueCopyWithImpl<ProductCustomFieldValue>(this as ProductCustomFieldValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCustomFieldValue&&(identical(other.fieldDefinitionId, fieldDefinitionId) || other.fieldDefinitionId == fieldDefinitionId)&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,fieldDefinitionId,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'ProductCustomFieldValue(fieldDefinitionId: $fieldDefinitionId, value: $value)';
}


}

/// @nodoc
abstract mixin class $ProductCustomFieldValueCopyWith<$Res>  {
  factory $ProductCustomFieldValueCopyWith(ProductCustomFieldValue value, $Res Function(ProductCustomFieldValue) _then) = _$ProductCustomFieldValueCopyWithImpl;
@useResult
$Res call({
 String fieldDefinitionId, Object? value
});




}
/// @nodoc
class _$ProductCustomFieldValueCopyWithImpl<$Res>
    implements $ProductCustomFieldValueCopyWith<$Res> {
  _$ProductCustomFieldValueCopyWithImpl(this._self, this._then);

  final ProductCustomFieldValue _self;
  final $Res Function(ProductCustomFieldValue) _then;

/// Create a copy of ProductCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fieldDefinitionId = null,Object? value = freezed,}) {
  return _then(_self.copyWith(
fieldDefinitionId: null == fieldDefinitionId ? _self.fieldDefinitionId : fieldDefinitionId // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductCustomFieldValue].
extension ProductCustomFieldValuePatterns on ProductCustomFieldValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCustomFieldValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCustomFieldValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCustomFieldValue value)  $default,){
final _that = this;
switch (_that) {
case _ProductCustomFieldValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCustomFieldValue value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCustomFieldValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fieldDefinitionId,  Object? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCustomFieldValue() when $default != null:
return $default(_that.fieldDefinitionId,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fieldDefinitionId,  Object? value)  $default,) {final _that = this;
switch (_that) {
case _ProductCustomFieldValue():
return $default(_that.fieldDefinitionId,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fieldDefinitionId,  Object? value)?  $default,) {final _that = this;
switch (_that) {
case _ProductCustomFieldValue() when $default != null:
return $default(_that.fieldDefinitionId,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _ProductCustomFieldValue implements ProductCustomFieldValue {
  const _ProductCustomFieldValue({required this.fieldDefinitionId, required this.value});
  

@override final  String fieldDefinitionId;
@override final  Object? value;

/// Create a copy of ProductCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCustomFieldValueCopyWith<_ProductCustomFieldValue> get copyWith => __$ProductCustomFieldValueCopyWithImpl<_ProductCustomFieldValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCustomFieldValue&&(identical(other.fieldDefinitionId, fieldDefinitionId) || other.fieldDefinitionId == fieldDefinitionId)&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,fieldDefinitionId,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'ProductCustomFieldValue(fieldDefinitionId: $fieldDefinitionId, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ProductCustomFieldValueCopyWith<$Res> implements $ProductCustomFieldValueCopyWith<$Res> {
  factory _$ProductCustomFieldValueCopyWith(_ProductCustomFieldValue value, $Res Function(_ProductCustomFieldValue) _then) = __$ProductCustomFieldValueCopyWithImpl;
@override @useResult
$Res call({
 String fieldDefinitionId, Object? value
});




}
/// @nodoc
class __$ProductCustomFieldValueCopyWithImpl<$Res>
    implements _$ProductCustomFieldValueCopyWith<$Res> {
  __$ProductCustomFieldValueCopyWithImpl(this._self, this._then);

  final _ProductCustomFieldValue _self;
  final $Res Function(_ProductCustomFieldValue) _then;

/// Create a copy of ProductCustomFieldValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fieldDefinitionId = null,Object? value = freezed,}) {
  return _then(_ProductCustomFieldValue(
fieldDefinitionId: null == fieldDefinitionId ? _self.fieldDefinitionId : fieldDefinitionId // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value ,
  ));
}


}

// dart format on
