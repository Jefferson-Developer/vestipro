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
 int? get maxTeamsPerUser;/// Extra customer form fields that this Organization requires beyond the
/// hard minimum (document + legal/full name). Stored as stable field codes
/// so the Organization model stays decoupled from the customers feature.
 List<String> get requiredCustomerFields;/// Extra address type codes/labels available in the Customer form, e.g.
/// `showroom|Showroom` or `warehouse|Deposito`.
 List<String> get customerAddressTypes;/// Extra contact type codes/labels available in the Customer form, e.g.
/// `logistics|Logistica`.
 List<String> get customerContactTypes;/// Whether a Product can be associated with more than one `Collection`
/// at once (TASK-066), e.g. a continuous product carried in both a core
/// collection and a seasonal drop. `false` (the default) means
/// `AssociateProductWithCollectionUseCase` replaces any previous
/// association instead of adding a second one.
 bool get allowMultipleCollectionsPerProduct;/// Reservation TTL for TASK-092. Server-side stock reservations must
/// expire automatically, but the timeout is organization-configurable
/// instead of hardcoded in the client.
 int get stockReservationExpiresInMinutes;/// Positivação de carteira (TASK-117, EPIC-15/VESTI-087): reporting
/// cadence used to derive the "current period" window a positivação
/// dashboard/snapshot is computed for. Stored as the raw
/// `TargetPeriodGranularity.name` string (`monthly`/`quarterly`/`yearly`)
/// instead of importing that enum here, same decoupling technique as
/// [customerAddressTypes]/[customerContactTypes] above — the `targets`
/// feature owns decoding/validating it, this settings model only stores
/// the string.
 String get positivacaoPeriodGranularity;/// Which `OrderStatus.name` codes count as "the customer bought" for
/// positivação (TASK-117). Deliberately not every [OrderStatus] — a
/// `draft`/`pendingSync`/`cancelled`/`rejected` order must never count.
/// Stored as raw strings for the same reason as
/// [positivacaoPeriodGranularity]: this settings model never imports the
/// `orders` feature's `OrderStatus` enum, the `targets` feature validates
/// each code against it when parsing `PositivacaoSettings`.
 List<String> get positivacaoEligibleOrderStatuses;/// Minimum order total (in [currency]) for that order to count towards
/// positivação, when the organization wants one — `null` means no
/// minimum (any eligible-status order already counts), same
/// nullable-means-unlimited/disabled convention as [maxTeamsPerUser].
 double? get positivacaoMinOrderValue;/// Ranking comercial visibility rule (TASK-118, EPIC-15): whether a
/// `SALES_REP` sees the full nominal ranking of their peers
/// (`full_ranking`) or only their own relative position (e.g. "você
/// está em 4º de 12", `relative_position_only`). Stored as a raw code
/// (one of [validRankingVisibilityModes]) instead of importing
/// `RankingVisibilityMode` here, same decoupling technique as
/// [positivacaoPeriodGranularity]. Never changes what a
/// `SALES_MANAGER`/`ADMIN`/`OWNER` sees — those roles always get the
/// full ranking of the scope they manage, regardless of this setting;
/// see `RankingCalculationService`'s own docs.
 String get rankingVisibilityMode;
/// Create a copy of OrganizationSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationSettingsCopyWith<OrganizationSettings> get copyWith => _$OrganizationSettingsCopyWithImpl<OrganizationSettings>(this as OrganizationSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationSettings&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.country, country) || other.country == country)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.maxTeamsPerUser, maxTeamsPerUser) || other.maxTeamsPerUser == maxTeamsPerUser)&&const DeepCollectionEquality().equals(other.requiredCustomerFields, requiredCustomerFields)&&const DeepCollectionEquality().equals(other.customerAddressTypes, customerAddressTypes)&&const DeepCollectionEquality().equals(other.customerContactTypes, customerContactTypes)&&(identical(other.allowMultipleCollectionsPerProduct, allowMultipleCollectionsPerProduct) || other.allowMultipleCollectionsPerProduct == allowMultipleCollectionsPerProduct)&&(identical(other.stockReservationExpiresInMinutes, stockReservationExpiresInMinutes) || other.stockReservationExpiresInMinutes == stockReservationExpiresInMinutes)&&(identical(other.positivacaoPeriodGranularity, positivacaoPeriodGranularity) || other.positivacaoPeriodGranularity == positivacaoPeriodGranularity)&&const DeepCollectionEquality().equals(other.positivacaoEligibleOrderStatuses, positivacaoEligibleOrderStatuses)&&(identical(other.positivacaoMinOrderValue, positivacaoMinOrderValue) || other.positivacaoMinOrderValue == positivacaoMinOrderValue)&&(identical(other.rankingVisibilityMode, rankingVisibilityMode) || other.rankingVisibilityMode == rankingVisibilityMode));
}


@override
int get hashCode => Object.hash(runtimeType,currency,country,defaultLanguage,segment,maxTeamsPerUser,const DeepCollectionEquality().hash(requiredCustomerFields),const DeepCollectionEquality().hash(customerAddressTypes),const DeepCollectionEquality().hash(customerContactTypes),allowMultipleCollectionsPerProduct,stockReservationExpiresInMinutes,positivacaoPeriodGranularity,const DeepCollectionEquality().hash(positivacaoEligibleOrderStatuses),positivacaoMinOrderValue,rankingVisibilityMode);

@override
String toString() {
  return 'OrganizationSettings(currency: $currency, country: $country, defaultLanguage: $defaultLanguage, segment: $segment, maxTeamsPerUser: $maxTeamsPerUser, requiredCustomerFields: $requiredCustomerFields, customerAddressTypes: $customerAddressTypes, customerContactTypes: $customerContactTypes, allowMultipleCollectionsPerProduct: $allowMultipleCollectionsPerProduct, stockReservationExpiresInMinutes: $stockReservationExpiresInMinutes, positivacaoPeriodGranularity: $positivacaoPeriodGranularity, positivacaoEligibleOrderStatuses: $positivacaoEligibleOrderStatuses, positivacaoMinOrderValue: $positivacaoMinOrderValue, rankingVisibilityMode: $rankingVisibilityMode)';
}


}

/// @nodoc
abstract mixin class $OrganizationSettingsCopyWith<$Res>  {
  factory $OrganizationSettingsCopyWith(OrganizationSettings value, $Res Function(OrganizationSettings) _then) = _$OrganizationSettingsCopyWithImpl;
@useResult
$Res call({
 String currency, String country, String defaultLanguage, String? segment, int? maxTeamsPerUser, List<String> requiredCustomerFields, List<String> customerAddressTypes, List<String> customerContactTypes, bool allowMultipleCollectionsPerProduct, int stockReservationExpiresInMinutes, String positivacaoPeriodGranularity, List<String> positivacaoEligibleOrderStatuses, double? positivacaoMinOrderValue, String rankingVisibilityMode
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
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? country = null,Object? defaultLanguage = null,Object? segment = freezed,Object? maxTeamsPerUser = freezed,Object? requiredCustomerFields = null,Object? customerAddressTypes = null,Object? customerContactTypes = null,Object? allowMultipleCollectionsPerProduct = null,Object? stockReservationExpiresInMinutes = null,Object? positivacaoPeriodGranularity = null,Object? positivacaoEligibleOrderStatuses = null,Object? positivacaoMinOrderValue = freezed,Object? rankingVisibilityMode = null,}) {
  return _then(_self.copyWith(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,maxTeamsPerUser: freezed == maxTeamsPerUser ? _self.maxTeamsPerUser : maxTeamsPerUser // ignore: cast_nullable_to_non_nullable
as int?,requiredCustomerFields: null == requiredCustomerFields ? _self.requiredCustomerFields : requiredCustomerFields // ignore: cast_nullable_to_non_nullable
as List<String>,customerAddressTypes: null == customerAddressTypes ? _self.customerAddressTypes : customerAddressTypes // ignore: cast_nullable_to_non_nullable
as List<String>,customerContactTypes: null == customerContactTypes ? _self.customerContactTypes : customerContactTypes // ignore: cast_nullable_to_non_nullable
as List<String>,allowMultipleCollectionsPerProduct: null == allowMultipleCollectionsPerProduct ? _self.allowMultipleCollectionsPerProduct : allowMultipleCollectionsPerProduct // ignore: cast_nullable_to_non_nullable
as bool,stockReservationExpiresInMinutes: null == stockReservationExpiresInMinutes ? _self.stockReservationExpiresInMinutes : stockReservationExpiresInMinutes // ignore: cast_nullable_to_non_nullable
as int,positivacaoPeriodGranularity: null == positivacaoPeriodGranularity ? _self.positivacaoPeriodGranularity : positivacaoPeriodGranularity // ignore: cast_nullable_to_non_nullable
as String,positivacaoEligibleOrderStatuses: null == positivacaoEligibleOrderStatuses ? _self.positivacaoEligibleOrderStatuses : positivacaoEligibleOrderStatuses // ignore: cast_nullable_to_non_nullable
as List<String>,positivacaoMinOrderValue: freezed == positivacaoMinOrderValue ? _self.positivacaoMinOrderValue : positivacaoMinOrderValue // ignore: cast_nullable_to_non_nullable
as double?,rankingVisibilityMode: null == rankingVisibilityMode ? _self.rankingVisibilityMode : rankingVisibilityMode // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  String country,  String defaultLanguage,  String? segment,  int? maxTeamsPerUser,  List<String> requiredCustomerFields,  List<String> customerAddressTypes,  List<String> customerContactTypes,  bool allowMultipleCollectionsPerProduct,  int stockReservationExpiresInMinutes,  String positivacaoPeriodGranularity,  List<String> positivacaoEligibleOrderStatuses,  double? positivacaoMinOrderValue,  String rankingVisibilityMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationSettings() when $default != null:
return $default(_that.currency,_that.country,_that.defaultLanguage,_that.segment,_that.maxTeamsPerUser,_that.requiredCustomerFields,_that.customerAddressTypes,_that.customerContactTypes,_that.allowMultipleCollectionsPerProduct,_that.stockReservationExpiresInMinutes,_that.positivacaoPeriodGranularity,_that.positivacaoEligibleOrderStatuses,_that.positivacaoMinOrderValue,_that.rankingVisibilityMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  String country,  String defaultLanguage,  String? segment,  int? maxTeamsPerUser,  List<String> requiredCustomerFields,  List<String> customerAddressTypes,  List<String> customerContactTypes,  bool allowMultipleCollectionsPerProduct,  int stockReservationExpiresInMinutes,  String positivacaoPeriodGranularity,  List<String> positivacaoEligibleOrderStatuses,  double? positivacaoMinOrderValue,  String rankingVisibilityMode)  $default,) {final _that = this;
switch (_that) {
case _OrganizationSettings():
return $default(_that.currency,_that.country,_that.defaultLanguage,_that.segment,_that.maxTeamsPerUser,_that.requiredCustomerFields,_that.customerAddressTypes,_that.customerContactTypes,_that.allowMultipleCollectionsPerProduct,_that.stockReservationExpiresInMinutes,_that.positivacaoPeriodGranularity,_that.positivacaoEligibleOrderStatuses,_that.positivacaoMinOrderValue,_that.rankingVisibilityMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  String country,  String defaultLanguage,  String? segment,  int? maxTeamsPerUser,  List<String> requiredCustomerFields,  List<String> customerAddressTypes,  List<String> customerContactTypes,  bool allowMultipleCollectionsPerProduct,  int stockReservationExpiresInMinutes,  String positivacaoPeriodGranularity,  List<String> positivacaoEligibleOrderStatuses,  double? positivacaoMinOrderValue,  String rankingVisibilityMode)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationSettings() when $default != null:
return $default(_that.currency,_that.country,_that.defaultLanguage,_that.segment,_that.maxTeamsPerUser,_that.requiredCustomerFields,_that.customerAddressTypes,_that.customerContactTypes,_that.allowMultipleCollectionsPerProduct,_that.stockReservationExpiresInMinutes,_that.positivacaoPeriodGranularity,_that.positivacaoEligibleOrderStatuses,_that.positivacaoMinOrderValue,_that.rankingVisibilityMode);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationSettings extends OrganizationSettings {
  const _OrganizationSettings({required this.currency, required this.country, required this.defaultLanguage, this.segment, this.maxTeamsPerUser, final  List<String> requiredCustomerFields = const <String>[], final  List<String> customerAddressTypes = const <String>[], final  List<String> customerContactTypes = const <String>[], this.allowMultipleCollectionsPerProduct = false, this.stockReservationExpiresInMinutes = 15, this.positivacaoPeriodGranularity = defaultPositivacaoPeriodGranularity, final  List<String> positivacaoEligibleOrderStatuses = defaultPositivacaoEligibleOrderStatuses, this.positivacaoMinOrderValue, this.rankingVisibilityMode = defaultRankingVisibilityMode}): _requiredCustomerFields = requiredCustomerFields,_customerAddressTypes = customerAddressTypes,_customerContactTypes = customerContactTypes,_positivacaoEligibleOrderStatuses = positivacaoEligibleOrderStatuses,super._();
  

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
/// Extra customer form fields that this Organization requires beyond the
/// hard minimum (document + legal/full name). Stored as stable field codes
/// so the Organization model stays decoupled from the customers feature.
 final  List<String> _requiredCustomerFields;
/// Extra customer form fields that this Organization requires beyond the
/// hard minimum (document + legal/full name). Stored as stable field codes
/// so the Organization model stays decoupled from the customers feature.
@override@JsonKey() List<String> get requiredCustomerFields {
  if (_requiredCustomerFields is EqualUnmodifiableListView) return _requiredCustomerFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredCustomerFields);
}

/// Extra address type codes/labels available in the Customer form, e.g.
/// `showroom|Showroom` or `warehouse|Deposito`.
 final  List<String> _customerAddressTypes;
/// Extra address type codes/labels available in the Customer form, e.g.
/// `showroom|Showroom` or `warehouse|Deposito`.
@override@JsonKey() List<String> get customerAddressTypes {
  if (_customerAddressTypes is EqualUnmodifiableListView) return _customerAddressTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customerAddressTypes);
}

/// Extra contact type codes/labels available in the Customer form, e.g.
/// `logistics|Logistica`.
 final  List<String> _customerContactTypes;
/// Extra contact type codes/labels available in the Customer form, e.g.
/// `logistics|Logistica`.
@override@JsonKey() List<String> get customerContactTypes {
  if (_customerContactTypes is EqualUnmodifiableListView) return _customerContactTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customerContactTypes);
}

/// Whether a Product can be associated with more than one `Collection`
/// at once (TASK-066), e.g. a continuous product carried in both a core
/// collection and a seasonal drop. `false` (the default) means
/// `AssociateProductWithCollectionUseCase` replaces any previous
/// association instead of adding a second one.
@override@JsonKey() final  bool allowMultipleCollectionsPerProduct;
/// Reservation TTL for TASK-092. Server-side stock reservations must
/// expire automatically, but the timeout is organization-configurable
/// instead of hardcoded in the client.
@override@JsonKey() final  int stockReservationExpiresInMinutes;
/// Positivação de carteira (TASK-117, EPIC-15/VESTI-087): reporting
/// cadence used to derive the "current period" window a positivação
/// dashboard/snapshot is computed for. Stored as the raw
/// `TargetPeriodGranularity.name` string (`monthly`/`quarterly`/`yearly`)
/// instead of importing that enum here, same decoupling technique as
/// [customerAddressTypes]/[customerContactTypes] above — the `targets`
/// feature owns decoding/validating it, this settings model only stores
/// the string.
@override@JsonKey() final  String positivacaoPeriodGranularity;
/// Which `OrderStatus.name` codes count as "the customer bought" for
/// positivação (TASK-117). Deliberately not every [OrderStatus] — a
/// `draft`/`pendingSync`/`cancelled`/`rejected` order must never count.
/// Stored as raw strings for the same reason as
/// [positivacaoPeriodGranularity]: this settings model never imports the
/// `orders` feature's `OrderStatus` enum, the `targets` feature validates
/// each code against it when parsing `PositivacaoSettings`.
 final  List<String> _positivacaoEligibleOrderStatuses;
/// Which `OrderStatus.name` codes count as "the customer bought" for
/// positivação (TASK-117). Deliberately not every [OrderStatus] — a
/// `draft`/`pendingSync`/`cancelled`/`rejected` order must never count.
/// Stored as raw strings for the same reason as
/// [positivacaoPeriodGranularity]: this settings model never imports the
/// `orders` feature's `OrderStatus` enum, the `targets` feature validates
/// each code against it when parsing `PositivacaoSettings`.
@override@JsonKey() List<String> get positivacaoEligibleOrderStatuses {
  if (_positivacaoEligibleOrderStatuses is EqualUnmodifiableListView) return _positivacaoEligibleOrderStatuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positivacaoEligibleOrderStatuses);
}

/// Minimum order total (in [currency]) for that order to count towards
/// positivação, when the organization wants one — `null` means no
/// minimum (any eligible-status order already counts), same
/// nullable-means-unlimited/disabled convention as [maxTeamsPerUser].
@override final  double? positivacaoMinOrderValue;
/// Ranking comercial visibility rule (TASK-118, EPIC-15): whether a
/// `SALES_REP` sees the full nominal ranking of their peers
/// (`full_ranking`) or only their own relative position (e.g. "você
/// está em 4º de 12", `relative_position_only`). Stored as a raw code
/// (one of [validRankingVisibilityModes]) instead of importing
/// `RankingVisibilityMode` here, same decoupling technique as
/// [positivacaoPeriodGranularity]. Never changes what a
/// `SALES_MANAGER`/`ADMIN`/`OWNER` sees — those roles always get the
/// full ranking of the scope they manage, regardless of this setting;
/// see `RankingCalculationService`'s own docs.
@override@JsonKey() final  String rankingVisibilityMode;

/// Create a copy of OrganizationSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationSettingsCopyWith<_OrganizationSettings> get copyWith => __$OrganizationSettingsCopyWithImpl<_OrganizationSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationSettings&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.country, country) || other.country == country)&&(identical(other.defaultLanguage, defaultLanguage) || other.defaultLanguage == defaultLanguage)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.maxTeamsPerUser, maxTeamsPerUser) || other.maxTeamsPerUser == maxTeamsPerUser)&&const DeepCollectionEquality().equals(other._requiredCustomerFields, _requiredCustomerFields)&&const DeepCollectionEquality().equals(other._customerAddressTypes, _customerAddressTypes)&&const DeepCollectionEquality().equals(other._customerContactTypes, _customerContactTypes)&&(identical(other.allowMultipleCollectionsPerProduct, allowMultipleCollectionsPerProduct) || other.allowMultipleCollectionsPerProduct == allowMultipleCollectionsPerProduct)&&(identical(other.stockReservationExpiresInMinutes, stockReservationExpiresInMinutes) || other.stockReservationExpiresInMinutes == stockReservationExpiresInMinutes)&&(identical(other.positivacaoPeriodGranularity, positivacaoPeriodGranularity) || other.positivacaoPeriodGranularity == positivacaoPeriodGranularity)&&const DeepCollectionEquality().equals(other._positivacaoEligibleOrderStatuses, _positivacaoEligibleOrderStatuses)&&(identical(other.positivacaoMinOrderValue, positivacaoMinOrderValue) || other.positivacaoMinOrderValue == positivacaoMinOrderValue)&&(identical(other.rankingVisibilityMode, rankingVisibilityMode) || other.rankingVisibilityMode == rankingVisibilityMode));
}


@override
int get hashCode => Object.hash(runtimeType,currency,country,defaultLanguage,segment,maxTeamsPerUser,const DeepCollectionEquality().hash(_requiredCustomerFields),const DeepCollectionEquality().hash(_customerAddressTypes),const DeepCollectionEquality().hash(_customerContactTypes),allowMultipleCollectionsPerProduct,stockReservationExpiresInMinutes,positivacaoPeriodGranularity,const DeepCollectionEquality().hash(_positivacaoEligibleOrderStatuses),positivacaoMinOrderValue,rankingVisibilityMode);

@override
String toString() {
  return 'OrganizationSettings(currency: $currency, country: $country, defaultLanguage: $defaultLanguage, segment: $segment, maxTeamsPerUser: $maxTeamsPerUser, requiredCustomerFields: $requiredCustomerFields, customerAddressTypes: $customerAddressTypes, customerContactTypes: $customerContactTypes, allowMultipleCollectionsPerProduct: $allowMultipleCollectionsPerProduct, stockReservationExpiresInMinutes: $stockReservationExpiresInMinutes, positivacaoPeriodGranularity: $positivacaoPeriodGranularity, positivacaoEligibleOrderStatuses: $positivacaoEligibleOrderStatuses, positivacaoMinOrderValue: $positivacaoMinOrderValue, rankingVisibilityMode: $rankingVisibilityMode)';
}


}

/// @nodoc
abstract mixin class _$OrganizationSettingsCopyWith<$Res> implements $OrganizationSettingsCopyWith<$Res> {
  factory _$OrganizationSettingsCopyWith(_OrganizationSettings value, $Res Function(_OrganizationSettings) _then) = __$OrganizationSettingsCopyWithImpl;
@override @useResult
$Res call({
 String currency, String country, String defaultLanguage, String? segment, int? maxTeamsPerUser, List<String> requiredCustomerFields, List<String> customerAddressTypes, List<String> customerContactTypes, bool allowMultipleCollectionsPerProduct, int stockReservationExpiresInMinutes, String positivacaoPeriodGranularity, List<String> positivacaoEligibleOrderStatuses, double? positivacaoMinOrderValue, String rankingVisibilityMode
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
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? country = null,Object? defaultLanguage = null,Object? segment = freezed,Object? maxTeamsPerUser = freezed,Object? requiredCustomerFields = null,Object? customerAddressTypes = null,Object? customerContactTypes = null,Object? allowMultipleCollectionsPerProduct = null,Object? stockReservationExpiresInMinutes = null,Object? positivacaoPeriodGranularity = null,Object? positivacaoEligibleOrderStatuses = null,Object? positivacaoMinOrderValue = freezed,Object? rankingVisibilityMode = null,}) {
  return _then(_OrganizationSettings(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,defaultLanguage: null == defaultLanguage ? _self.defaultLanguage : defaultLanguage // ignore: cast_nullable_to_non_nullable
as String,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,maxTeamsPerUser: freezed == maxTeamsPerUser ? _self.maxTeamsPerUser : maxTeamsPerUser // ignore: cast_nullable_to_non_nullable
as int?,requiredCustomerFields: null == requiredCustomerFields ? _self._requiredCustomerFields : requiredCustomerFields // ignore: cast_nullable_to_non_nullable
as List<String>,customerAddressTypes: null == customerAddressTypes ? _self._customerAddressTypes : customerAddressTypes // ignore: cast_nullable_to_non_nullable
as List<String>,customerContactTypes: null == customerContactTypes ? _self._customerContactTypes : customerContactTypes // ignore: cast_nullable_to_non_nullable
as List<String>,allowMultipleCollectionsPerProduct: null == allowMultipleCollectionsPerProduct ? _self.allowMultipleCollectionsPerProduct : allowMultipleCollectionsPerProduct // ignore: cast_nullable_to_non_nullable
as bool,stockReservationExpiresInMinutes: null == stockReservationExpiresInMinutes ? _self.stockReservationExpiresInMinutes : stockReservationExpiresInMinutes // ignore: cast_nullable_to_non_nullable
as int,positivacaoPeriodGranularity: null == positivacaoPeriodGranularity ? _self.positivacaoPeriodGranularity : positivacaoPeriodGranularity // ignore: cast_nullable_to_non_nullable
as String,positivacaoEligibleOrderStatuses: null == positivacaoEligibleOrderStatuses ? _self._positivacaoEligibleOrderStatuses : positivacaoEligibleOrderStatuses // ignore: cast_nullable_to_non_nullable
as List<String>,positivacaoMinOrderValue: freezed == positivacaoMinOrderValue ? _self.positivacaoMinOrderValue : positivacaoMinOrderValue // ignore: cast_nullable_to_non_nullable
as double?,rankingVisibilityMode: null == rankingVisibilityMode ? _self.rankingVisibilityMode : rankingVisibilityMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
