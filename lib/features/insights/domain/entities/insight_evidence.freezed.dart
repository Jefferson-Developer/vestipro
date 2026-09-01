// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight_evidence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InsightEvidence {

 String get code; String get label; String get value; double? get numericValue; String? get unit;
/// Create a copy of InsightEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightEvidenceCopyWith<InsightEvidence> get copyWith => _$InsightEvidenceCopyWithImpl<InsightEvidence>(this as InsightEvidence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightEvidence&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.numericValue, numericValue) || other.numericValue == numericValue)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,code,label,value,numericValue,unit);

@override
String toString() {
  return 'InsightEvidence(code: $code, label: $label, value: $value, numericValue: $numericValue, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $InsightEvidenceCopyWith<$Res>  {
  factory $InsightEvidenceCopyWith(InsightEvidence value, $Res Function(InsightEvidence) _then) = _$InsightEvidenceCopyWithImpl;
@useResult
$Res call({
 String code, String label, String value, double? numericValue, String? unit
});




}
/// @nodoc
class _$InsightEvidenceCopyWithImpl<$Res>
    implements $InsightEvidenceCopyWith<$Res> {
  _$InsightEvidenceCopyWithImpl(this._self, this._then);

  final InsightEvidence _self;
  final $Res Function(InsightEvidence) _then;

/// Create a copy of InsightEvidence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? label = null,Object? value = null,Object? numericValue = freezed,Object? unit = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,numericValue: freezed == numericValue ? _self.numericValue : numericValue // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightEvidence].
extension InsightEvidencePatterns on InsightEvidence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightEvidence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightEvidence value)  $default,){
final _that = this;
switch (_that) {
case _InsightEvidence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _InsightEvidence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String label,  String value,  double? numericValue,  String? unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightEvidence() when $default != null:
return $default(_that.code,_that.label,_that.value,_that.numericValue,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String label,  String value,  double? numericValue,  String? unit)  $default,) {final _that = this;
switch (_that) {
case _InsightEvidence():
return $default(_that.code,_that.label,_that.value,_that.numericValue,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String label,  String value,  double? numericValue,  String? unit)?  $default,) {final _that = this;
switch (_that) {
case _InsightEvidence() when $default != null:
return $default(_that.code,_that.label,_that.value,_that.numericValue,_that.unit);case _:
  return null;

}
}

}

/// @nodoc


class _InsightEvidence implements InsightEvidence {
  const _InsightEvidence({required this.code, required this.label, required this.value, this.numericValue, this.unit});
  

@override final  String code;
@override final  String label;
@override final  String value;
@override final  double? numericValue;
@override final  String? unit;

/// Create a copy of InsightEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightEvidenceCopyWith<_InsightEvidence> get copyWith => __$InsightEvidenceCopyWithImpl<_InsightEvidence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightEvidence&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.numericValue, numericValue) || other.numericValue == numericValue)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,code,label,value,numericValue,unit);

@override
String toString() {
  return 'InsightEvidence(code: $code, label: $label, value: $value, numericValue: $numericValue, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$InsightEvidenceCopyWith<$Res> implements $InsightEvidenceCopyWith<$Res> {
  factory _$InsightEvidenceCopyWith(_InsightEvidence value, $Res Function(_InsightEvidence) _then) = __$InsightEvidenceCopyWithImpl;
@override @useResult
$Res call({
 String code, String label, String value, double? numericValue, String? unit
});




}
/// @nodoc
class __$InsightEvidenceCopyWithImpl<$Res>
    implements _$InsightEvidenceCopyWith<$Res> {
  __$InsightEvidenceCopyWithImpl(this._self, this._then);

  final _InsightEvidence _self;
  final $Res Function(_InsightEvidence) _then;

/// Create a copy of InsightEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? label = null,Object? value = null,Object? numericValue = freezed,Object? unit = freezed,}) {
  return _then(_InsightEvidence(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,numericValue: freezed == numericValue ? _self.numericValue : numericValue // ignore: cast_nullable_to_non_nullable
as double?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
