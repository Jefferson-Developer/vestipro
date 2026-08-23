// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent()';
}


}

/// @nodoc
class $OnboardingEventCopyWith<$Res>  {
$OnboardingEventCopyWith(OnboardingEvent _, $Res Function(OnboardingEvent) __);
}


/// Adds pattern-matching-related methods to [OnboardingEvent].
extension OnboardingEventPatterns on OnboardingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OnboardingStarted value)?  started,TResult Function( OnboardingOrganizationNameChanged value)?  organizationNameChanged,TResult Function( OnboardingSegmentSelected value)?  segmentSelected,TResult Function( OnboardingCurrencyChanged value)?  currencyChanged,TResult Function( OnboardingCountryChanged value)?  countryChanged,TResult Function( OnboardingDefaultLanguageChanged value)?  defaultLanguageChanged,TResult Function( OnboardingNextStepRequested value)?  nextStepRequested,TResult Function( OnboardingPreviousStepRequested value)?  previousStepRequested,TResult Function( OnboardingSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OnboardingStarted() when started != null:
return started(_that);case OnboardingOrganizationNameChanged() when organizationNameChanged != null:
return organizationNameChanged(_that);case OnboardingSegmentSelected() when segmentSelected != null:
return segmentSelected(_that);case OnboardingCurrencyChanged() when currencyChanged != null:
return currencyChanged(_that);case OnboardingCountryChanged() when countryChanged != null:
return countryChanged(_that);case OnboardingDefaultLanguageChanged() when defaultLanguageChanged != null:
return defaultLanguageChanged(_that);case OnboardingNextStepRequested() when nextStepRequested != null:
return nextStepRequested(_that);case OnboardingPreviousStepRequested() when previousStepRequested != null:
return previousStepRequested(_that);case OnboardingSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OnboardingStarted value)  started,required TResult Function( OnboardingOrganizationNameChanged value)  organizationNameChanged,required TResult Function( OnboardingSegmentSelected value)  segmentSelected,required TResult Function( OnboardingCurrencyChanged value)  currencyChanged,required TResult Function( OnboardingCountryChanged value)  countryChanged,required TResult Function( OnboardingDefaultLanguageChanged value)  defaultLanguageChanged,required TResult Function( OnboardingNextStepRequested value)  nextStepRequested,required TResult Function( OnboardingPreviousStepRequested value)  previousStepRequested,required TResult Function( OnboardingSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case OnboardingStarted():
return started(_that);case OnboardingOrganizationNameChanged():
return organizationNameChanged(_that);case OnboardingSegmentSelected():
return segmentSelected(_that);case OnboardingCurrencyChanged():
return currencyChanged(_that);case OnboardingCountryChanged():
return countryChanged(_that);case OnboardingDefaultLanguageChanged():
return defaultLanguageChanged(_that);case OnboardingNextStepRequested():
return nextStepRequested(_that);case OnboardingPreviousStepRequested():
return previousStepRequested(_that);case OnboardingSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OnboardingStarted value)?  started,TResult? Function( OnboardingOrganizationNameChanged value)?  organizationNameChanged,TResult? Function( OnboardingSegmentSelected value)?  segmentSelected,TResult? Function( OnboardingCurrencyChanged value)?  currencyChanged,TResult? Function( OnboardingCountryChanged value)?  countryChanged,TResult? Function( OnboardingDefaultLanguageChanged value)?  defaultLanguageChanged,TResult? Function( OnboardingNextStepRequested value)?  nextStepRequested,TResult? Function( OnboardingPreviousStepRequested value)?  previousStepRequested,TResult? Function( OnboardingSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case OnboardingStarted() when started != null:
return started(_that);case OnboardingOrganizationNameChanged() when organizationNameChanged != null:
return organizationNameChanged(_that);case OnboardingSegmentSelected() when segmentSelected != null:
return segmentSelected(_that);case OnboardingCurrencyChanged() when currencyChanged != null:
return currencyChanged(_that);case OnboardingCountryChanged() when countryChanged != null:
return countryChanged(_that);case OnboardingDefaultLanguageChanged() when defaultLanguageChanged != null:
return defaultLanguageChanged(_that);case OnboardingNextStepRequested() when nextStepRequested != null:
return nextStepRequested(_that);case OnboardingPreviousStepRequested() when previousStepRequested != null:
return previousStepRequested(_that);case OnboardingSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( String organizationName)?  organizationNameChanged,TResult Function( OrganizationSegment segment)?  segmentSelected,TResult Function( String currency)?  currencyChanged,TResult Function( String country)?  countryChanged,TResult Function( String defaultLanguage)?  defaultLanguageChanged,TResult Function()?  nextStepRequested,TResult Function()?  previousStepRequested,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OnboardingStarted() when started != null:
return started();case OnboardingOrganizationNameChanged() when organizationNameChanged != null:
return organizationNameChanged(_that.organizationName);case OnboardingSegmentSelected() when segmentSelected != null:
return segmentSelected(_that.segment);case OnboardingCurrencyChanged() when currencyChanged != null:
return currencyChanged(_that.currency);case OnboardingCountryChanged() when countryChanged != null:
return countryChanged(_that.country);case OnboardingDefaultLanguageChanged() when defaultLanguageChanged != null:
return defaultLanguageChanged(_that.defaultLanguage);case OnboardingNextStepRequested() when nextStepRequested != null:
return nextStepRequested();case OnboardingPreviousStepRequested() when previousStepRequested != null:
return previousStepRequested();case OnboardingSubmitted() when submitted != null:
return submitted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( String organizationName)  organizationNameChanged,required TResult Function( OrganizationSegment segment)  segmentSelected,required TResult Function( String currency)  currencyChanged,required TResult Function( String country)  countryChanged,required TResult Function( String defaultLanguage)  defaultLanguageChanged,required TResult Function()  nextStepRequested,required TResult Function()  previousStepRequested,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case OnboardingStarted():
return started();case OnboardingOrganizationNameChanged():
return organizationNameChanged(_that.organizationName);case OnboardingSegmentSelected():
return segmentSelected(_that.segment);case OnboardingCurrencyChanged():
return currencyChanged(_that.currency);case OnboardingCountryChanged():
return countryChanged(_that.country);case OnboardingDefaultLanguageChanged():
return defaultLanguageChanged(_that.defaultLanguage);case OnboardingNextStepRequested():
return nextStepRequested();case OnboardingPreviousStepRequested():
return previousStepRequested();case OnboardingSubmitted():
return submitted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( String organizationName)?  organizationNameChanged,TResult? Function( OrganizationSegment segment)?  segmentSelected,TResult? Function( String currency)?  currencyChanged,TResult? Function( String country)?  countryChanged,TResult? Function( String defaultLanguage)?  defaultLanguageChanged,TResult? Function()?  nextStepRequested,TResult? Function()?  previousStepRequested,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case OnboardingStarted() when started != null:
return started();case OnboardingOrganizationNameChanged() when organizationNameChanged != null:
return organizationNameChanged(_that.organizationName);case OnboardingSegmentSelected() when segmentSelected != null:
return segmentSelected(_that.segment);case OnboardingCurrencyChanged() when currencyChanged != null:
return currencyChanged(_that.currency);case OnboardingCountryChanged() when countryChanged != null:
return countryChanged(_that.country);case OnboardingDefaultLanguageChanged() when defaultLanguageChanged != null:
return defaultLanguageChanged(_that.defaultLanguage);case OnboardingNextStepRequested() when nextStepRequested != null:
return nextStepRequested();case OnboardingPreviousStepRequested() when previousStepRequested != null:
return previousStepRequested();case OnboardingSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class OnboardingStarted implements OnboardingEvent {
  const OnboardingStarted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent.started()';
}


}




/// @nodoc


class OnboardingOrganizationNameChanged implements OnboardingEvent {
  const OnboardingOrganizationNameChanged(this.organizationName);
  

 final  String organizationName;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingOrganizationNameChangedCopyWith<OnboardingOrganizationNameChanged> get copyWith => _$OnboardingOrganizationNameChangedCopyWithImpl<OnboardingOrganizationNameChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingOrganizationNameChanged&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName));
}


@override
int get hashCode => Object.hash(runtimeType,organizationName);

@override
String toString() {
  return 'OnboardingEvent.organizationNameChanged(organizationName: $organizationName)';
}


}

/// @nodoc
abstract mixin class $OnboardingOrganizationNameChangedCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
  factory $OnboardingOrganizationNameChangedCopyWith(OnboardingOrganizationNameChanged value, $Res Function(OnboardingOrganizationNameChanged) _then) = _$OnboardingOrganizationNameChangedCopyWithImpl;
@useResult
$Res call({
 String organizationName
});




}
/// @nodoc
class _$OnboardingOrganizationNameChangedCopyWithImpl<$Res>
    implements $OnboardingOrganizationNameChangedCopyWith<$Res> {
  _$OnboardingOrganizationNameChangedCopyWithImpl(this._self, this._then);

  final OnboardingOrganizationNameChanged _self;
  final $Res Function(OnboardingOrganizationNameChanged) _then;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationName = null,}) {
  return _then(OnboardingOrganizationNameChanged(
null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OnboardingSegmentSelected implements OnboardingEvent {
  const OnboardingSegmentSelected(this.segment);
  

 final  OrganizationSegment segment;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingSegmentSelectedCopyWith<OnboardingSegmentSelected> get copyWith => _$OnboardingSegmentSelectedCopyWithImpl<OnboardingSegmentSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingSegmentSelected&&(identical(other.segment, segment) || other.segment == segment));
}


@override
int get hashCode => Object.hash(runtimeType,segment);

@override
String toString() {
  return 'OnboardingEvent.segmentSelected(segment: $segment)';
}


}

/// @nodoc
abstract mixin class $OnboardingSegmentSelectedCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
  factory $OnboardingSegmentSelectedCopyWith(OnboardingSegmentSelected value, $Res Function(OnboardingSegmentSelected) _then) = _$OnboardingSegmentSelectedCopyWithImpl;
@useResult
$Res call({
 OrganizationSegment segment
});




}
/// @nodoc
class _$OnboardingSegmentSelectedCopyWithImpl<$Res>
    implements $OnboardingSegmentSelectedCopyWith<$Res> {
  _$OnboardingSegmentSelectedCopyWithImpl(this._self, this._then);

  final OnboardingSegmentSelected _self;
  final $Res Function(OnboardingSegmentSelected) _then;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? segment = null,}) {
  return _then(OnboardingSegmentSelected(
null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as OrganizationSegment,
  ));
}


}

/// @nodoc


class OnboardingCurrencyChanged implements OnboardingEvent {
  const OnboardingCurrencyChanged(this.currency);
  

 final  String currency;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingCurrencyChangedCopyWith<OnboardingCurrencyChanged> get copyWith => _$OnboardingCurrencyChangedCopyWithImpl<OnboardingCurrencyChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingCurrencyChanged&&(identical(other.currency, currency) || other.currency == currency));
}


@override
int get hashCode => Object.hash(runtimeType,currency);

@override
String toString() {
  return 'OnboardingEvent.currencyChanged(currency: $currency)';
}


}

/// @nodoc
abstract mixin class $OnboardingCurrencyChangedCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
  factory $OnboardingCurrencyChangedCopyWith(OnboardingCurrencyChanged value, $Res Function(OnboardingCurrencyChanged) _then) = _$OnboardingCurrencyChangedCopyWithImpl;
@useResult
$Res call({
 String currency
});




}
/// @nodoc
class _$OnboardingCurrencyChangedCopyWithImpl<$Res>
    implements $OnboardingCurrencyChangedCopyWith<$Res> {
  _$OnboardingCurrencyChangedCopyWithImpl(this._self, this._then);

  final OnboardingCurrencyChanged _self;
  final $Res Function(OnboardingCurrencyChanged) _then;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? currency = null,}) {
  return _then(OnboardingCurrencyChanged(
null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OnboardingCountryChanged implements OnboardingEvent {
  const OnboardingCountryChanged(this.country);
  

 final  String country;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingCountryChangedCopyWith<OnboardingCountryChanged> get copyWith => _$OnboardingCountryChangedCopyWithImpl<OnboardingCountryChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingCountryChanged&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,country);

@override
String toString() {
  return 'OnboardingEvent.countryChanged(country: $country)';
}


}

/// @nodoc
abstract mixin class $OnboardingCountryChangedCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
  factory $OnboardingCountryChangedCopyWith(OnboardingCountryChanged value, $Res Function(OnboardingCountryChanged) _then) = _$OnboardingCountryChangedCopyWithImpl;
@useResult
$Res call({
 String country
});




}
/// @nodoc
class _$OnboardingCountryChangedCopyWithImpl<$Res>
    implements $OnboardingCountryChangedCopyWith<$Res> {
  _$OnboardingCountryChangedCopyWithImpl(this._self, this._then);

  final OnboardingCountryChanged _self;
  final $Res Function(OnboardingCountryChanged) _then;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? country = null,}) {
  return _then(OnboardingCountryChanged(
null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OnboardingDefaultLanguageChanged implements OnboardingEvent {
  const OnboardingDefaultLanguageChanged(this.defaultLanguage);
  

 final  String defaultLanguage;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingDefaultLanguageChangedCopyWith<OnboardingDefaultLanguageChanged> get copyWith => _$OnboardingDefaultLanguageChangedCopyWithImpl<OnboardingDefaultLanguageChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingDefaultLanguageChanged&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage));
}


@override
int get hashCode => Object.hash(runtimeType,defaultLanguage);

@override
String toString() {
  return 'OnboardingEvent.defaultLanguageChanged(defaultLanguage: $defaultLanguage)';
}


}

/// @nodoc
abstract mixin class $OnboardingDefaultLanguageChangedCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
  factory $OnboardingDefaultLanguageChangedCopyWith(OnboardingDefaultLanguageChanged value, $Res Function(OnboardingDefaultLanguageChanged) _then) = _$OnboardingDefaultLanguageChangedCopyWithImpl;
@useResult
$Res call({
 String defaultLanguage
});




}
/// @nodoc
class _$OnboardingDefaultLanguageChangedCopyWithImpl<$Res>
    implements $OnboardingDefaultLanguageChangedCopyWith<$Res> {
  _$OnboardingDefaultLanguageChangedCopyWithImpl(this._self, this._then);

  final OnboardingDefaultLanguageChanged _self;
  final $Res Function(OnboardingDefaultLanguageChanged) _then;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? defaultLanguage = null,}) {
  return _then(OnboardingDefaultLanguageChanged(
null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OnboardingNextStepRequested implements OnboardingEvent {
  const OnboardingNextStepRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingNextStepRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent.nextStepRequested()';
}


}




/// @nodoc


class OnboardingPreviousStepRequested implements OnboardingEvent {
  const OnboardingPreviousStepRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingPreviousStepRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent.previousStepRequested()';
}


}




/// @nodoc


class OnboardingSubmitted implements OnboardingEvent {
  const OnboardingSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent.submitted()';
}


}




// dart format on
