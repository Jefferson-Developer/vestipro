// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_contact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerContact {

 String get id; CustomerContactType get type; String get name; String? get role; String? get phone; String? get email; bool get isPrimary;
/// Create a copy of CustomerContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerContactCopyWith<CustomerContact> get copyWith => _$CustomerContactCopyWithImpl<CustomerContact>(this as CustomerContact, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerContact&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,name,role,phone,email,isPrimary);

@override
String toString() {
  return 'CustomerContact(id: $id, type: $type, name: $name, role: $role, phone: $phone, email: $email, isPrimary: $isPrimary)';
}


}

/// @nodoc
abstract mixin class $CustomerContactCopyWith<$Res>  {
  factory $CustomerContactCopyWith(CustomerContact value, $Res Function(CustomerContact) _then) = _$CustomerContactCopyWithImpl;
@useResult
$Res call({
 String id, CustomerContactType type, String name, String? role, String? phone, String? email, bool isPrimary
});




}
/// @nodoc
class _$CustomerContactCopyWithImpl<$Res>
    implements $CustomerContactCopyWith<$Res> {
  _$CustomerContactCopyWithImpl(this._self, this._then);

  final CustomerContact _self;
  final $Res Function(CustomerContact) _then;

/// Create a copy of CustomerContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? role = freezed,Object? phone = freezed,Object? email = freezed,Object? isPrimary = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CustomerContactType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerContact].
extension CustomerContactPatterns on CustomerContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerContact value)  $default,){
final _that = this;
switch (_that) {
case _CustomerContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerContact value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CustomerContactType type,  String name,  String? role,  String? phone,  String? email,  bool isPrimary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerContact() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.role,_that.phone,_that.email,_that.isPrimary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CustomerContactType type,  String name,  String? role,  String? phone,  String? email,  bool isPrimary)  $default,) {final _that = this;
switch (_that) {
case _CustomerContact():
return $default(_that.id,_that.type,_that.name,_that.role,_that.phone,_that.email,_that.isPrimary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CustomerContactType type,  String name,  String? role,  String? phone,  String? email,  bool isPrimary)?  $default,) {final _that = this;
switch (_that) {
case _CustomerContact() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.role,_that.phone,_that.email,_that.isPrimary);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerContact extends CustomerContact {
  const _CustomerContact({required this.id, required this.type, required this.name, this.role, this.phone, this.email, this.isPrimary = false}): super._();
  

@override final  String id;
@override final  CustomerContactType type;
@override final  String name;
@override final  String? role;
@override final  String? phone;
@override final  String? email;
@override@JsonKey() final  bool isPrimary;

/// Create a copy of CustomerContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerContactCopyWith<_CustomerContact> get copyWith => __$CustomerContactCopyWithImpl<_CustomerContact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerContact&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.role, role) || other.role == role)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,name,role,phone,email,isPrimary);

@override
String toString() {
  return 'CustomerContact(id: $id, type: $type, name: $name, role: $role, phone: $phone, email: $email, isPrimary: $isPrimary)';
}


}

/// @nodoc
abstract mixin class _$CustomerContactCopyWith<$Res> implements $CustomerContactCopyWith<$Res> {
  factory _$CustomerContactCopyWith(_CustomerContact value, $Res Function(_CustomerContact) _then) = __$CustomerContactCopyWithImpl;
@override @useResult
$Res call({
 String id, CustomerContactType type, String name, String? role, String? phone, String? email, bool isPrimary
});




}
/// @nodoc
class __$CustomerContactCopyWithImpl<$Res>
    implements _$CustomerContactCopyWith<$Res> {
  __$CustomerContactCopyWithImpl(this._self, this._then);

  final _CustomerContact _self;
  final $Res Function(_CustomerContact) _then;

/// Create a copy of CustomerContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? role = freezed,Object? phone = freezed,Object? email = freezed,Object? isPrimary = null,}) {
  return _then(_CustomerContact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CustomerContactType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
