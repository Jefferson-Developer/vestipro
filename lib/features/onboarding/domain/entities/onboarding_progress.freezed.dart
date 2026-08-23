// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingProgress {

 OnboardingStep get step; String get organizationName; OrganizationSegment? get segment; String get currency; String get country; String get defaultLanguage;
/// Create a copy of OnboardingProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingProgressCopyWith<OnboardingProgress> get copyWith => _$OnboardingProgressCopyWithImpl<OnboardingProgress>(this as OnboardingProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingProgress&&(identical(other.step, step) || other.step == step)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.country, country) || other.country == country)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,step,organizationName,segment,currency,country,defaultLanguage);

@override
String toString() {
  return 'OnboardingProgress(step: $step, organizationName: $organizationName, segment: $segment, currency: $currency, country: $country, defaultLanguage: $defaultLanguage)';
}


}

/// @nodoc
abstract mixin class $OnboardingProgressCopyWith<$Res>  {
  factory $OnboardingProgressCopyWith(OnboardingProgress value, $Res Function(OnboardingProgress) _then) = _$OnboardingProgressCopyWithImpl;
@useResult
$Res call({
 OnboardingStep step, String organizationName, OrganizationSegment? segment, String currency, String country, String defaultLanguage
});




}
/// @nodoc
class _$OnboardingProgressCopyWithImpl<$Res>
    implements $OnboardingProgressCopyWith<$Res> {
  _$OnboardingProgressCopyWithImpl(this._self, this._then);

  final OnboardingProgress _self;
  final $Res Function(OnboardingProgress) _then;

/// Create a copy of OnboardingProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? organizationName = null,Object? segment = freezed,Object? currency = null,Object? country = null,Object? defaultLanguage = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as OrganizationSegment?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingProgress].
extension OnboardingProgressPatterns on OnboardingProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingProgress value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingProgress value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingStep step,  String organizationName,  OrganizationSegment? segment,  String currency,  String country,  String defaultLanguage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingProgress() when $default != null:
return $default(_that.step,_that.organizationName,_that.segment,_that.currency,_that.country,_that.defaultLanguage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingStep step,  String organizationName,  OrganizationSegment? segment,  String currency,  String country,  String defaultLanguage)  $default,) {final _that = this;
switch (_that) {
case _OnboardingProgress():
return $default(_that.step,_that.organizationName,_that.segment,_that.currency,_that.country,_that.defaultLanguage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingStep step,  String organizationName,  OrganizationSegment? segment,  String currency,  String country,  String defaultLanguage)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingProgress() when $default != null:
return $default(_that.step,_that.organizationName,_that.segment,_that.currency,_that.country,_that.defaultLanguage);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingProgress implements OnboardingProgress {
  const _OnboardingProgress({this.step = OnboardingStep.organizationDetails, this.organizationName = '', this.segment, this.currency = 'BRL', this.country = 'BR', this.defaultLanguage = 'pt-BR'});
  

@override@JsonKey() final  OnboardingStep step;
@override@JsonKey() final  String organizationName;
@override final  OrganizationSegment? segment;
@override@JsonKey() final  String currency;
@override@JsonKey() final  String country;
@override@JsonKey() final  String defaultLanguage;

/// Create a copy of OnboardingProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingProgressCopyWith<_OnboardingProgress> get copyWith => __$OnboardingProgressCopyWithImpl<_OnboardingProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingProgress&&(identical(other.step, step) || other.step == step)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.country, country) || other.country == country)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,step,organizationName,segment,currency,country,defaultLanguage);

@override
String toString() {
  return 'OnboardingProgress(step: $step, organizationName: $organizationName, segment: $segment, currency: $currency, country: $country, defaultLanguage: $defaultLanguage)';
}


}

/// @nodoc
abstract mixin class _$OnboardingProgressCopyWith<$Res> implements $OnboardingProgressCopyWith<$Res> {
  factory _$OnboardingProgressCopyWith(_OnboardingProgress value, $Res Function(_OnboardingProgress) _then) = __$OnboardingProgressCopyWithImpl;
@override @useResult
$Res call({
 OnboardingStep step, String organizationName, OrganizationSegment? segment, String currency, String country, String defaultLanguage
});




}
/// @nodoc
class __$OnboardingProgressCopyWithImpl<$Res>
    implements _$OnboardingProgressCopyWith<$Res> {
  __$OnboardingProgressCopyWithImpl(this._self, this._then);

  final _OnboardingProgress _self;
  final $Res Function(_OnboardingProgress) _then;

/// Create a copy of OnboardingProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? organizationName = null,Object? segment = freezed,Object? currency = null,Object? country = null,Object? defaultLanguage = null,}) {
  return _then(_OnboardingProgress(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as OrganizationSegment?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
