// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationSettings {

 String get currency; String get country; String get defaultLanguage;/// The fashion segment the Organization operates in (`apparel`,
/// `footwear`, `accessories`, `multi_brand` — see
/// `OrganizationSegment.code`), collected by the onboarding wizard
/// (TASK-038). Nullable — and never validated here — because, unlike
/// [currency]/[country]/[defaultLanguage], not every caller of this
/// type sets it (e.g. a future settings update that only changes
/// [currency] has no reason to also resend it); the wizard enforces its
/// own "segment is required to finish onboarding" rule independently
/// (`CompleteOnboardingUseCase`).
 String? get segment;/// Optional commercial governance limit: when set, one active member
/// cannot be assigned to more than this many Teams in the Organization.
/// `null` means unlimited.
 int? get maxTeamsPerUser;
/// Create a copy of OrganizationSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationSettingsCopyWith<OrganizationSettings> get copyWith => _$OrganizationSettingsCopyWithImpl<OrganizationSettings>(this as OrganizationSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationSettings&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.country, country) || other.country == country)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.maxTeamsPerUser, maxTeamsPerUser) || other.maxTeamsPerUser == maxTeamsPerUser));
}


@override
int get hashCode => Object.hash(runtimeType,currency,country,defaultLanguage,segment,maxTeamsPerUser);

@override
String toString() {
  return 'OrganizationSettings(currency: $currency, country: $country, defaultLanguage: $defaultLanguage, segment: $segment, maxTeamsPerUser: $maxTeamsPerUser)';
}


}

/// @nodoc
abstract mixin class $OrganizationSettingsCopyWith<$Res>  {
  factory $OrganizationSettingsCopyWith(OrganizationSettings value, $Res Function(OrganizationSettings) _then) = _$OrganizationSettingsCopyWithImpl;
@useResult
$Res call({
 String currency, String country, String defaultLanguage, String? segment, int? maxTeamsPerUser
});




}
/// @nodoc
class _$OrganizationSettingsCopyWithImpl<$Res>
    implements $OrganizationSettingsCopyWith<$Res> {
  _$OrganizationSettingsCopyWithImpl(this._self, this._then);

  final OrganizationSettings _self;
  final $Res Function(OrganizationSettings) _then;

/// Create a copy of OrganizationSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? country = null,Object? defaultLanguage = null,Object? segment = freezed,Object? maxTeamsPerUser = freezed,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,maxTeamsPerUser: freezed == maxTeamsPerUser ? _self.maxTeamsPerUser : maxTeamsPerUser // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationSettings].
extension OrganizationSettingsPatterns on OrganizationSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationSettings value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationSettings value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  String country,  String defaultLanguage,  String? segment,  int? maxTeamsPerUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationSettings() when $default != null:
return $default(_that.currency,_that.country,_that.defaultLanguage,_that.segment,_that.maxTeamsPerUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  String country,  String defaultLanguage,  String? segment,  int? maxTeamsPerUser)  $default,) {final _that = this;
switch (_that) {
case _OrganizationSettings():
return $default(_that.currency,_that.country,_that.defaultLanguage,_that.segment,_that.maxTeamsPerUser);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  String country,  String defaultLanguage,  String? segment,  int? maxTeamsPerUser)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationSettings() when $default != null:
return $default(_that.currency,_that.country,_that.defaultLanguage,_that.segment,_that.maxTeamsPerUser);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationSettings extends OrganizationSettings {
  const _OrganizationSettings({required this.currency, required this.country, required this.defaultLanguage, this.segment, this.maxTeamsPerUser}): super._();
  

@override final  String currency;
@override final  String country;
@override final  String defaultLanguage;
/// The fashion segment the Organization operates in (`apparel`,
/// `footwear`, `accessories`, `multi_brand` — see
/// `OrganizationSegment.code`), collected by the onboarding wizard
/// (TASK-038). Nullable — and never validated here — because, unlike
/// [currency]/[country]/[defaultLanguage], not every caller of this
/// type sets it (e.g. a future settings update that only changes
/// [currency] has no reason to also resend it); the wizard enforces its
/// own "segment is required to finish onboarding" rule independently
/// (`CompleteOnboardingUseCase`).
@override final  String? segment;
/// Optional commercial governance limit: when set, one active member
/// cannot be assigned to more than this many Teams in the Organization.
/// `null` means unlimited.
@override final  int? maxTeamsPerUser;

/// Create a copy of OrganizationSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationSettingsCopyWith<_OrganizationSettings> get copyWith => __$OrganizationSettingsCopyWithImpl<_OrganizationSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationSettings&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.country, country) || other.country == country)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.maxTeamsPerUser, maxTeamsPerUser) || other.maxTeamsPerUser == maxTeamsPerUser));
}


@override
int get hashCode => Object.hash(runtimeType,currency,country,defaultLanguage,segment,maxTeamsPerUser);

@override
String toString() {
  return 'OrganizationSettings(currency: $currency, country: $country, defaultLanguage: $defaultLanguage, segment: $segment, maxTeamsPerUser: $maxTeamsPerUser)';
}


}

/// @nodoc
abstract mixin class _$OrganizationSettingsCopyWith<$Res> implements $OrganizationSettingsCopyWith<$Res> {
  factory _$OrganizationSettingsCopyWith(_OrganizationSettings value, $Res Function(_OrganizationSettings) _then) = __$OrganizationSettingsCopyWithImpl;
@override @useResult
$Res call({
 String currency, String country, String defaultLanguage, String? segment, int? maxTeamsPerUser
});




}
/// @nodoc
class __$OrganizationSettingsCopyWithImpl<$Res>
    implements _$OrganizationSettingsCopyWith<$Res> {
  __$OrganizationSettingsCopyWithImpl(this._self, this._then);

  final _OrganizationSettings _self;
  final $Res Function(_OrganizationSettings) _then;

/// Create a copy of OrganizationSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? country = null,Object? defaultLanguage = null,Object? segment = freezed,Object? maxTeamsPerUser = freezed,}) {
  return _then(_OrganizationSettings(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,maxTeamsPerUser: freezed == maxTeamsPerUser ? _self.maxTeamsPerUser : maxTeamsPerUser // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
