// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sign_up_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignUpState {

 String get name; String get email; String get password; String get passwordConfirmation;/// `null` until the field has been validated at least once (first
/// submit attempt) or until a fresh edit clears the previous error.
 String? get nameError; String? get emailError; String? get passwordError; String? get passwordConfirmationError;/// Whether the user checked the Terms of Service/Privacy Policy
/// acceptance box. Kept separate from the text fields because a submit
/// attempt without it still needs a visible validation message instead
/// of a silent disabled button.
 bool get termsAccepted; String? get termsError; bool get obscurePassword; bool get obscurePasswordConfirmation; SignUpSubmissionStatus get status;/// Only meaningful when [status] is [SignUpSubmissionStatus.failure].
/// [Failure.message] is always the amiable, already-in-Portuguese
/// message computed by `firebase_auth_exception_mapper.dart` — never a
/// raw Firebase error code/string.
 Failure? get failure;
/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignUpStateCopyWith<SignUpState> get copyWith => _$SignUpStateCopyWithImpl<SignUpState>(this as SignUpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignUpState&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.passwordConfirmation, passwordConfirmation) || other.passwordConfirmation == passwordConfirmation)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.passwordConfirmationError, passwordConfirmationError) || other.passwordConfirmationError == passwordConfirmationError)&&(identical(other.termsAccepted, termsAccepted) || other.termsAccepted == termsAccepted)&&(identical(other.termsError, termsError) || other.termsError == termsError)&&(identical(other.obscurePassword, obscurePassword) || other.obscurePassword == obscurePassword)&&(identical(other.obscurePasswordConfirmation, obscurePasswordConfirmation) || other.obscurePasswordConfirmation == obscurePasswordConfirmation)&&(identical(other.status, status) || other.status == status)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,name,email,password,passwordConfirmation,nameError,emailError,passwordError,passwordConfirmationError,termsAccepted,termsError,obscurePassword,obscurePasswordConfirmation,status,failure);

@override
String toString() {
  return 'SignUpState(name: $name, email: $email, password: $password, passwordConfirmation: $passwordConfirmation, nameError: $nameError, emailError: $emailError, passwordError: $passwordError, passwordConfirmationError: $passwordConfirmationError, termsAccepted: $termsAccepted, termsError: $termsError, obscurePassword: $obscurePassword, obscurePasswordConfirmation: $obscurePasswordConfirmation, status: $status, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SignUpStateCopyWith<$Res>  {
  factory $SignUpStateCopyWith(SignUpState value, $Res Function(SignUpState) _then) = _$SignUpStateCopyWithImpl;
@useResult
$Res call({
 String name, String email, String password, String passwordConfirmation, String? nameError, String? emailError, String? passwordError, String? passwordConfirmationError, bool termsAccepted, String? termsError, bool obscurePassword, bool obscurePasswordConfirmation, SignUpSubmissionStatus status, Failure? failure
});




}
/// @nodoc
class _$SignUpStateCopyWithImpl<$Res>
    implements $SignUpStateCopyWith<$Res> {
  _$SignUpStateCopyWithImpl(this._self, this._then);

  final SignUpState _self;
  final $Res Function(SignUpState) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? email = null,Object? password = null,Object? passwordConfirmation = null,Object? nameError = freezed,Object? emailError = freezed,Object? passwordError = freezed,Object? passwordConfirmationError = freezed,Object? termsAccepted = null,Object? termsError = freezed,Object? obscurePassword = null,Object? obscurePasswordConfirmation = null,Object? status = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,passwordConfirmation: null == passwordConfirmation ? _self.passwordConfirmation : passwordConfirmation // ignore: cast_nullable_to_non_nullable
as String,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as String?,emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as String?,passwordConfirmationError: freezed == passwordConfirmationError ? _self.passwordConfirmationError : passwordConfirmationError // ignore: cast_nullable_to_non_nullable
as String?,termsAccepted: null == termsAccepted ? _self.termsAccepted : termsAccepted // ignore: cast_nullable_to_non_nullable
as bool,termsError: freezed == termsError ? _self.termsError : termsError // ignore: cast_nullable_to_non_nullable
as String?,obscurePassword: null == obscurePassword ? _self.obscurePassword : obscurePassword // ignore: cast_nullable_to_non_nullable
as bool,obscurePasswordConfirmation: null == obscurePasswordConfirmation ? _self.obscurePasswordConfirmation : obscurePasswordConfirmation // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SignUpSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [SignUpState].
extension SignUpStatePatterns on SignUpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignUpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignUpState value)  $default,){
final _that = this;
switch (_that) {
case _SignUpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignUpState value)?  $default,){
final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String email,  String password,  String passwordConfirmation,  String? nameError,  String? emailError,  String? passwordError,  String? passwordConfirmationError,  bool termsAccepted,  String? termsError,  bool obscurePassword,  bool obscurePasswordConfirmation,  SignUpSubmissionStatus status,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
return $default(_that.name,_that.email,_that.password,_that.passwordConfirmation,_that.nameError,_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.termsAccepted,_that.termsError,_that.obscurePassword,_that.obscurePasswordConfirmation,_that.status,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String email,  String password,  String passwordConfirmation,  String? nameError,  String? emailError,  String? passwordError,  String? passwordConfirmationError,  bool termsAccepted,  String? termsError,  bool obscurePassword,  bool obscurePasswordConfirmation,  SignUpSubmissionStatus status,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _SignUpState():
return $default(_that.name,_that.email,_that.password,_that.passwordConfirmation,_that.nameError,_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.termsAccepted,_that.termsError,_that.obscurePassword,_that.obscurePasswordConfirmation,_that.status,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String email,  String password,  String passwordConfirmation,  String? nameError,  String? emailError,  String? passwordError,  String? passwordConfirmationError,  bool termsAccepted,  String? termsError,  bool obscurePassword,  bool obscurePasswordConfirmation,  SignUpSubmissionStatus status,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _SignUpState() when $default != null:
return $default(_that.name,_that.email,_that.password,_that.passwordConfirmation,_that.nameError,_that.emailError,_that.passwordError,_that.passwordConfirmationError,_that.termsAccepted,_that.termsError,_that.obscurePassword,_that.obscurePasswordConfirmation,_that.status,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _SignUpState implements SignUpState {
  const _SignUpState({this.name = '', this.email = '', this.password = '', this.passwordConfirmation = '', this.nameError, this.emailError, this.passwordError, this.passwordConfirmationError, this.termsAccepted = false, this.termsError, this.obscurePassword = true, this.obscurePasswordConfirmation = true, this.status = SignUpSubmissionStatus.idle, this.failure});
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey() final  String password;
@override@JsonKey() final  String passwordConfirmation;
/// `null` until the field has been validated at least once (first
/// submit attempt) or until a fresh edit clears the previous error.
@override final  String? nameError;
@override final  String? emailError;
@override final  String? passwordError;
@override final  String? passwordConfirmationError;
/// Whether the user checked the Terms of Service/Privacy Policy
/// acceptance box. Kept separate from the text fields because a submit
/// attempt without it still needs a visible validation message instead
/// of a silent disabled button.
@override@JsonKey() final  bool termsAccepted;
@override final  String? termsError;
@override@JsonKey() final  bool obscurePassword;
@override@JsonKey() final  bool obscurePasswordConfirmation;
@override@JsonKey() final  SignUpSubmissionStatus status;
/// Only meaningful when [status] is [SignUpSubmissionStatus.failure].
/// [Failure.message] is always the amiable, already-in-Portuguese
/// message computed by `firebase_auth_exception_mapper.dart` — never a
/// raw Firebase error code/string.
@override final  Failure? failure;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignUpStateCopyWith<_SignUpState> get copyWith => __$SignUpStateCopyWithImpl<_SignUpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignUpState&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.passwordConfirmation, passwordConfirmation) || other.passwordConfirmation == passwordConfirmation)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.passwordConfirmationError, passwordConfirmationError) || other.passwordConfirmationError == passwordConfirmationError)&&(identical(other.termsAccepted, termsAccepted) || other.termsAccepted == termsAccepted)&&(identical(other.termsError, termsError) || other.termsError == termsError)&&(identical(other.obscurePassword, obscurePassword) || other.obscurePassword == obscurePassword)&&(identical(other.obscurePasswordConfirmation, obscurePasswordConfirmation) || other.obscurePasswordConfirmation == obscurePasswordConfirmation)&&(identical(other.status, status) || other.status == status)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,name,email,password,passwordConfirmation,nameError,emailError,passwordError,passwordConfirmationError,termsAccepted,termsError,obscurePassword,obscurePasswordConfirmation,status,failure);

@override
String toString() {
  return 'SignUpState(name: $name, email: $email, password: $password, passwordConfirmation: $passwordConfirmation, nameError: $nameError, emailError: $emailError, passwordError: $passwordError, passwordConfirmationError: $passwordConfirmationError, termsAccepted: $termsAccepted, termsError: $termsError, obscurePassword: $obscurePassword, obscurePasswordConfirmation: $obscurePasswordConfirmation, status: $status, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$SignUpStateCopyWith<$Res> implements $SignUpStateCopyWith<$Res> {
  factory _$SignUpStateCopyWith(_SignUpState value, $Res Function(_SignUpState) _then) = __$SignUpStateCopyWithImpl;
@override @useResult
$Res call({
 String name, String email, String password, String passwordConfirmation, String? nameError, String? emailError, String? passwordError, String? passwordConfirmationError, bool termsAccepted, String? termsError, bool obscurePassword, bool obscurePasswordConfirmation, SignUpSubmissionStatus status, Failure? failure
});




}
/// @nodoc
class __$SignUpStateCopyWithImpl<$Res>
    implements _$SignUpStateCopyWith<$Res> {
  __$SignUpStateCopyWithImpl(this._self, this._then);

  final _SignUpState _self;
  final $Res Function(_SignUpState) _then;

/// Create a copy of SignUpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? email = null,Object? password = null,Object? passwordConfirmation = null,Object? nameError = freezed,Object? emailError = freezed,Object? passwordError = freezed,Object? passwordConfirmationError = freezed,Object? termsAccepted = null,Object? termsError = freezed,Object? obscurePassword = null,Object? obscurePasswordConfirmation = null,Object? status = null,Object? failure = freezed,}) {
  return _then(_SignUpState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,passwordConfirmation: null == passwordConfirmation ? _self.passwordConfirmation : passwordConfirmation // ignore: cast_nullable_to_non_nullable
as String,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as String?,emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String?,passwordError: freezed == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as String?,passwordConfirmationError: freezed == passwordConfirmationError ? _self.passwordConfirmationError : passwordConfirmationError // ignore: cast_nullable_to_non_nullable
as String?,termsAccepted: null == termsAccepted ? _self.termsAccepted : termsAccepted // ignore: cast_nullable_to_non_nullable
as bool,termsError: freezed == termsError ? _self.termsError : termsError // ignore: cast_nullable_to_non_nullable
as String?,obscurePassword: null == obscurePassword ? _self.obscurePassword : obscurePassword // ignore: cast_nullable_to_non_nullable
as bool,obscurePasswordConfirmation: null == obscurePasswordConfirmation ? _self.obscurePasswordConfirmation : obscurePasswordConfirmation // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SignUpSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
