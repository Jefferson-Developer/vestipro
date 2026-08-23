// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {

 OnboardingLoadStatus get loadStatus; OnboardingStep get step; String get organizationName;/// `null` until the current step has been submitted at least once (a
/// [OnboardingEvent.nextStepRequested]/[OnboardingEvent.submitted] that
/// found it invalid) or until a fresh edit clears the previous error —
/// same contract as `SignUpState`'s per-field error strings.
 String? get organizationNameError; OrganizationSegment? get segment; String? get segmentError; String get currency; String? get currencyError; String get country; String? get countryError; String get defaultLanguage; String? get defaultLanguageError; OnboardingSubmissionStatus get submissionStatus;/// Only meaningful when [submissionStatus] is
/// [OnboardingSubmissionStatus.failure].
 Failure? get failure;/// Only meaningful when [submissionStatus] is
/// [OnboardingSubmissionStatus.success] — the Organization the wizard
/// just created, consumed by `OnboardingWizardPage` to navigate away
/// with its real id.
 Organization? get createdOrganization;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.step, step) || other.step == step)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.organizationNameError, organizationNameError) || other.organizationNameError == organizationNameError)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.segmentError, segmentError) || other.segmentError == segmentError)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.currencyError, currencyError) || other.currencyError == currencyError)&&(identical(other.country, country) || other.country == country)&&(identical(other.countryError, countryError) || other.countryError == countryError)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.defaultLanguageError, defaultLanguageError) || other.defaultLanguageError == defaultLanguageError)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.createdOrganization, createdOrganization) || other.createdOrganization == createdOrganization));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,step,organizationName,organizationNameError,segment,segmentError,currency,currencyError,country,countryError,defaultLanguage,defaultLanguageError,submissionStatus,failure,createdOrganization);

@override
String toString() {
  return 'OnboardingState(loadStatus: $loadStatus, step: $step, organizationName: $organizationName, organizationNameError: $organizationNameError, segment: $segment, segmentError: $segmentError, currency: $currency, currencyError: $currencyError, country: $country, countryError: $countryError, defaultLanguage: $defaultLanguage, defaultLanguageError: $defaultLanguageError, submissionStatus: $submissionStatus, failure: $failure, createdOrganization: $createdOrganization)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 OnboardingLoadStatus loadStatus, OnboardingStep step, String organizationName, String? organizationNameError, OrganizationSegment? segment, String? segmentError, String currency, String? currencyError, String country, String? countryError, String defaultLanguage, String? defaultLanguageError, OnboardingSubmissionStatus submissionStatus, Failure? failure, Organization? createdOrganization
});


$OrganizationCopyWith<$Res>? get createdOrganization;

}
/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadStatus = null,Object? step = null,Object? organizationName = null,Object? organizationNameError = freezed,Object? segment = freezed,Object? segmentError = freezed,Object? currency = null,Object? currencyError = freezed,Object? country = null,Object? countryError = freezed,Object? defaultLanguage = null,Object? defaultLanguageError = freezed,Object? submissionStatus = null,Object? failure = freezed,Object? createdOrganization = freezed,}) {
  return _then(_self.copyWith(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as OnboardingLoadStatus,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,organizationNameError: freezed == organizationNameError ? _self.organizationNameError : organizationNameError // ignore: cast_nullable_to_non_nullable
as String?,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as OrganizationSegment?,segmentError: freezed == segmentError ? _self.segmentError : segmentError // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,currencyError: freezed == currencyError ? _self.currencyError : currencyError // ignore: cast_nullable_to_non_nullable
as String?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,countryError: freezed == countryError ? _self.countryError : countryError // ignore: cast_nullable_to_non_nullable
as String?,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,defaultLanguageError: freezed == defaultLanguageError ? _self.defaultLanguageError : defaultLanguageError // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as OnboardingSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,createdOrganization: freezed == createdOrganization ? _self.createdOrganization : createdOrganization // ignore: cast_nullable_to_non_nullable
as Organization?,
  ));
}
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get createdOrganization {
    if (_self.createdOrganization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.createdOrganization!, (value) {
    return _then(_self.copyWith(createdOrganization: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingLoadStatus loadStatus,  OnboardingStep step,  String organizationName,  String? organizationNameError,  OrganizationSegment? segment,  String? segmentError,  String currency,  String? currencyError,  String country,  String? countryError,  String defaultLanguage,  String? defaultLanguageError,  OnboardingSubmissionStatus submissionStatus,  Failure? failure,  Organization? createdOrganization)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.loadStatus,_that.step,_that.organizationName,_that.organizationNameError,_that.segment,_that.segmentError,_that.currency,_that.currencyError,_that.country,_that.countryError,_that.defaultLanguage,_that.defaultLanguageError,_that.submissionStatus,_that.failure,_that.createdOrganization);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingLoadStatus loadStatus,  OnboardingStep step,  String organizationName,  String? organizationNameError,  OrganizationSegment? segment,  String? segmentError,  String currency,  String? currencyError,  String country,  String? countryError,  String defaultLanguage,  String? defaultLanguageError,  OnboardingSubmissionStatus submissionStatus,  Failure? failure,  Organization? createdOrganization)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.loadStatus,_that.step,_that.organizationName,_that.organizationNameError,_that.segment,_that.segmentError,_that.currency,_that.currencyError,_that.country,_that.countryError,_that.defaultLanguage,_that.defaultLanguageError,_that.submissionStatus,_that.failure,_that.createdOrganization);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingLoadStatus loadStatus,  OnboardingStep step,  String organizationName,  String? organizationNameError,  OrganizationSegment? segment,  String? segmentError,  String currency,  String? currencyError,  String country,  String? countryError,  String defaultLanguage,  String? defaultLanguageError,  OnboardingSubmissionStatus submissionStatus,  Failure? failure,  Organization? createdOrganization)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.loadStatus,_that.step,_that.organizationName,_that.organizationNameError,_that.segment,_that.segmentError,_that.currency,_that.currencyError,_that.country,_that.countryError,_that.defaultLanguage,_that.defaultLanguageError,_that.submissionStatus,_that.failure,_that.createdOrganization);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState implements OnboardingState {
  const _OnboardingState({this.loadStatus = OnboardingLoadStatus.loading, this.step = OnboardingStep.organizationDetails, this.organizationName = '', this.organizationNameError, this.segment, this.segmentError, this.currency = 'BRL', this.currencyError, this.country = 'BR', this.countryError, this.defaultLanguage = 'pt-BR', this.defaultLanguageError, this.submissionStatus = OnboardingSubmissionStatus.idle, this.failure, this.createdOrganization});
  

@override@JsonKey() final  OnboardingLoadStatus loadStatus;
@override@JsonKey() final  OnboardingStep step;
@override@JsonKey() final  String organizationName;
/// `null` until the current step has been submitted at least once (a
/// [OnboardingEvent.nextStepRequested]/[OnboardingEvent.submitted] that
/// found it invalid) or until a fresh edit clears the previous error —
/// same contract as `SignUpState`'s per-field error strings.
@override final  String? organizationNameError;
@override final  OrganizationSegment? segment;
@override final  String? segmentError;
@override@JsonKey() final  String currency;
@override final  String? currencyError;
@override@JsonKey() final  String country;
@override final  String? countryError;
@override@JsonKey() final  String defaultLanguage;
@override final  String? defaultLanguageError;
@override@JsonKey() final  OnboardingSubmissionStatus submissionStatus;
/// Only meaningful when [submissionStatus] is
/// [OnboardingSubmissionStatus.failure].
@override final  Failure? failure;
/// Only meaningful when [submissionStatus] is
/// [OnboardingSubmissionStatus.success] — the Organization the wizard
/// just created, consumed by `OnboardingWizardPage` to navigate away
/// with its real id.
@override final  Organization? createdOrganization;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingStateCopyWith<_OnboardingState> get copyWith => __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.step, step) || other.step == step)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.organizationNameError, organizationNameError) || other.organizationNameError == organizationNameError)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.segmentError, segmentError) || other.segmentError == segmentError)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.currencyError, currencyError) || other.currencyError == currencyError)&&(identical(other.country, country) || other.country == country)&&(identical(other.countryError, countryError) || other.countryError == countryError)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.defaultLanguageError, defaultLanguageError) || other.defaultLanguageError == defaultLanguageError)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.createdOrganization, createdOrganization) || other.createdOrganization == createdOrganization));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,step,organizationName,organizationNameError,segment,segmentError,currency,currencyError,country,countryError,defaultLanguage,defaultLanguageError,submissionStatus,failure,createdOrganization);

@override
String toString() {
  return 'OnboardingState(loadStatus: $loadStatus, step: $step, organizationName: $organizationName, organizationNameError: $organizationNameError, segment: $segment, segmentError: $segmentError, currency: $currency, currencyError: $currencyError, country: $country, countryError: $countryError, defaultLanguage: $defaultLanguage, defaultLanguageError: $defaultLanguageError, submissionStatus: $submissionStatus, failure: $failure, createdOrganization: $createdOrganization)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 OnboardingLoadStatus loadStatus, OnboardingStep step, String organizationName, String? organizationNameError, OrganizationSegment? segment, String? segmentError, String currency, String? currencyError, String country, String? countryError, String defaultLanguage, String? defaultLanguageError, OnboardingSubmissionStatus submissionStatus, Failure? failure, Organization? createdOrganization
});


@override $OrganizationCopyWith<$Res>? get createdOrganization;

}
/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadStatus = null,Object? step = null,Object? organizationName = null,Object? organizationNameError = freezed,Object? segment = freezed,Object? segmentError = freezed,Object? currency = null,Object? currencyError = freezed,Object? country = null,Object? countryError = freezed,Object? defaultLanguage = null,Object? defaultLanguageError = freezed,Object? submissionStatus = null,Object? failure = freezed,Object? createdOrganization = freezed,}) {
  return _then(_OnboardingState(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as OnboardingLoadStatus,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,organizationNameError: freezed == organizationNameError ? _self.organizationNameError : organizationNameError // ignore: cast_nullable_to_non_nullable
as String?,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as OrganizationSegment?,segmentError: freezed == segmentError ? _self.segmentError : segmentError // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,currencyError: freezed == currencyError ? _self.currencyError : currencyError // ignore: cast_nullable_to_non_nullable
as String?,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,countryError: freezed == countryError ? _self.countryError : countryError // ignore: cast_nullable_to_non_nullable
as String?,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,defaultLanguageError: freezed == defaultLanguageError ? _self.defaultLanguageError : defaultLanguageError // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as OnboardingSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,createdOrganization: freezed == createdOrganization ? _self.createdOrganization : createdOrganization // ignore: cast_nullable_to_non_nullable
as Organization?,
  ));
}

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get createdOrganization {
    if (_self.createdOrganization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.createdOrganization!, (value) {
    return _then(_self.copyWith(createdOrganization: value));
  });
}
}

// dart format on
