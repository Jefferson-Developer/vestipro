// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight_estimated_impact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InsightEstimatedImpact {

 double? get amount; double? get percentage; String get currencyCode;
/// Create a copy of InsightEstimatedImpact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightEstimatedImpactCopyWith<InsightEstimatedImpact> get copyWith => _$InsightEstimatedImpactCopyWithImpl<InsightEstimatedImpact>(this as InsightEstimatedImpact, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InsightEstimatedImpact&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode => Object.hash(runtimeType,amount,percentage,currencyCode);

@override
String toString() {
  return 'InsightEstimatedImpact(amount: $amount, percentage: $percentage, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class $InsightEstimatedImpactCopyWith<$Res>  {
  factory $InsightEstimatedImpactCopyWith(InsightEstimatedImpact value, $Res Function(InsightEstimatedImpact) _then) = _$InsightEstimatedImpactCopyWithImpl;
@useResult
$Res call({
 double? amount, double? percentage, String currencyCode
});




}
/// @nodoc
class _$InsightEstimatedImpactCopyWithImpl<$Res>
    implements $InsightEstimatedImpactCopyWith<$Res> {
  _$InsightEstimatedImpactCopyWithImpl(this._self, this._then);

  final InsightEstimatedImpact _self;
  final $Res Function(InsightEstimatedImpact) _then;

/// Create a copy of InsightEstimatedImpact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? percentage = freezed,Object? currencyCode = null,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,percentage: freezed == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InsightEstimatedImpact].
extension InsightEstimatedImpactPatterns on InsightEstimatedImpact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InsightEstimatedImpact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InsightEstimatedImpact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InsightEstimatedImpact value)  $default,){
final _that = this;
switch (_that) {
case _InsightEstimatedImpact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InsightEstimatedImpact value)?  $default,){
final _that = this;
switch (_that) {
case _InsightEstimatedImpact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? amount,  double? percentage,  String currencyCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InsightEstimatedImpact() when $default != null:
return $default(_that.amount,_that.percentage,_that.currencyCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? amount,  double? percentage,  String currencyCode)  $default,) {final _that = this;
switch (_that) {
case _InsightEstimatedImpact():
return $default(_that.amount,_that.percentage,_that.currencyCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? amount,  double? percentage,  String currencyCode)?  $default,) {final _that = this;
switch (_that) {
case _InsightEstimatedImpact() when $default != null:
return $default(_that.amount,_that.percentage,_that.currencyCode);case _:
  return null;

}
}

}

/// @nodoc


class _InsightEstimatedImpact extends InsightEstimatedImpact {
  const _InsightEstimatedImpact({this.amount, this.percentage, this.currencyCode = 'BRL'}): super._();
  

@override final  double? amount;
@override final  double? percentage;
@override@JsonKey() final  String currencyCode;

/// Create a copy of InsightEstimatedImpact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightEstimatedImpactCopyWith<_InsightEstimatedImpact> get copyWith => __$InsightEstimatedImpactCopyWithImpl<_InsightEstimatedImpact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InsightEstimatedImpact&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode));
}


@override
int get hashCode => Object.hash(runtimeType,amount,percentage,currencyCode);

@override
String toString() {
  return 'InsightEstimatedImpact(amount: $amount, percentage: $percentage, currencyCode: $currencyCode)';
}


}

/// @nodoc
abstract mixin class _$InsightEstimatedImpactCopyWith<$Res> implements $InsightEstimatedImpactCopyWith<$Res> {
  factory _$InsightEstimatedImpactCopyWith(_InsightEstimatedImpact value, $Res Function(_InsightEstimatedImpact) _then) = __$InsightEstimatedImpactCopyWithImpl;
@override @useResult
$Res call({
 double? amount, double? percentage, String currencyCode
});




}
/// @nodoc
class __$InsightEstimatedImpactCopyWithImpl<$Res>
    implements _$InsightEstimatedImpactCopyWith<$Res> {
  __$InsightEstimatedImpactCopyWithImpl(this._self, this._then);

  final _InsightEstimatedImpact _self;
  final $Res Function(_InsightEstimatedImpact) _then;

/// Create a copy of InsightEstimatedImpact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? percentage = freezed,Object? currencyCode = null,}) {
  return _then(_InsightEstimatedImpact(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,percentage: freezed == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
