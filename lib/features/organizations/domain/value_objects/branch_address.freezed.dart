// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'branch_address.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BranchAddress {

 String get street; String get number; String? get complement; String get neighborhood; String get city; String get state; String get postalCode; String get country;
/// Create a copy of BranchAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchAddressCopyWith<BranchAddress> get copyWith => _$BranchAddressCopyWithImpl<BranchAddress>(this as BranchAddress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchAddress&&(identical(other.street, street) || other.street == street)&&(identical(other.number, number) || other.number == number)&&(identical(other.complement, complement) || other.complement == complement)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,street,number,complement,neighborhood,city,state,postalCode,country);

@override
String toString() {
  return 'BranchAddress(street: $street, number: $number, complement: $complement, neighborhood: $neighborhood, city: $city, state: $state, postalCode: $postalCode, country: $country)';
}


}

/// @nodoc
abstract mixin class $BranchAddressCopyWith<$Res>  {
  factory $BranchAddressCopyWith(BranchAddress value, $Res Function(BranchAddress) _then) = _$BranchAddressCopyWithImpl;
@useResult
$Res call({
 String street, String number, String? complement, String neighborhood, String city, String state, String postalCode, String country
});




}
/// @nodoc
class _$BranchAddressCopyWithImpl<$Res>
    implements $BranchAddressCopyWith<$Res> {
  _$BranchAddressCopyWithImpl(this._self, this._then);

  final BranchAddress _self;
  final $Res Function(BranchAddress) _then;

/// Create a copy of BranchAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? street = null,Object? number = null,Object? complement = freezed,Object? neighborhood = null,Object? city = null,Object? state = null,Object? postalCode = null,Object? country = null,}) {
  return _then(_self.copyWith(
street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,complement: freezed == complement ? _self.complement : complement // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: null == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BranchAddress].
extension BranchAddressPatterns on BranchAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BranchAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BranchAddress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BranchAddress value)  $default,){
final _that = this;
switch (_that) {
case _BranchAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BranchAddress value)?  $default,){
final _that = this;
switch (_that) {
case _BranchAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String street,  String number,  String? complement,  String neighborhood,  String city,  String state,  String postalCode,  String country)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BranchAddress() when $default != null:
return $default(_that.street,_that.number,_that.complement,_that.neighborhood,_that.city,_that.state,_that.postalCode,_that.country);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String street,  String number,  String? complement,  String neighborhood,  String city,  String state,  String postalCode,  String country)  $default,) {final _that = this;
switch (_that) {
case _BranchAddress():
return $default(_that.street,_that.number,_that.complement,_that.neighborhood,_that.city,_that.state,_that.postalCode,_that.country);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String street,  String number,  String? complement,  String neighborhood,  String city,  String state,  String postalCode,  String country)?  $default,) {final _that = this;
switch (_that) {
case _BranchAddress() when $default != null:
return $default(_that.street,_that.number,_that.complement,_that.neighborhood,_that.city,_that.state,_that.postalCode,_that.country);case _:
  return null;

}
}

}

/// @nodoc


class _BranchAddress extends BranchAddress {
  const _BranchAddress({required this.street, required this.number, this.complement, required this.neighborhood, required this.city, required this.state, required this.postalCode, required this.country}): super._();
  

@override final  String street;
@override final  String number;
@override final  String? complement;
@override final  String neighborhood;
@override final  String city;
@override final  String state;
@override final  String postalCode;
@override final  String country;

/// Create a copy of BranchAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BranchAddressCopyWith<_BranchAddress> get copyWith => __$BranchAddressCopyWithImpl<_BranchAddress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BranchAddress&&(identical(other.street, street) || other.street == street)&&(identical(other.number, number) || other.number == number)&&(identical(other.complement, complement) || other.complement == complement)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.country, country) || other.country == country));
}


@override
int get hashCode => Object.hash(runtimeType,street,number,complement,neighborhood,city,state,postalCode,country);

@override
String toString() {
  return 'BranchAddress(street: $street, number: $number, complement: $complement, neighborhood: $neighborhood, city: $city, state: $state, postalCode: $postalCode, country: $country)';
}


}

/// @nodoc
abstract mixin class _$BranchAddressCopyWith<$Res> implements $BranchAddressCopyWith<$Res> {
  factory _$BranchAddressCopyWith(_BranchAddress value, $Res Function(_BranchAddress) _then) = __$BranchAddressCopyWithImpl;
@override @useResult
$Res call({
 String street, String number, String? complement, String neighborhood, String city, String state, String postalCode, String country
});




}
/// @nodoc
class __$BranchAddressCopyWithImpl<$Res>
    implements _$BranchAddressCopyWith<$Res> {
  __$BranchAddressCopyWithImpl(this._self, this._then);

  final _BranchAddress _self;
  final $Res Function(_BranchAddress) _then;

/// Create a copy of BranchAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? street = null,Object? number = null,Object? complement = freezed,Object? neighborhood = null,Object? city = null,Object? state = null,Object? postalCode = null,Object? country = null,}) {
  return _then(_BranchAddress(
street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,complement: freezed == complement ? _self.complement : complement // ignore: cast_nullable_to_non_nullable
as String?,neighborhood: null == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
