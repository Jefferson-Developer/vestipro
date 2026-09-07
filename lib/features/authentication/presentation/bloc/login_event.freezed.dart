// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginEvent()';
}


}

/// @nodoc
class $LoginEventCopyWith<$Res>  {
$LoginEventCopyWith(LoginEvent _, $Res Function(LoginEvent) __);
}


/// Adds pattern-matching-related methods to [LoginEvent].
extension LoginEventPatterns on LoginEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LoginEmailChanged value)?  emailChanged,TResult Function( LoginPasswordChanged value)?  passwordChanged,TResult Function( LoginPasswordVisibilityToggled value)?  passwordVisibilityToggled,TResult Function( LoginSubmitted value)?  submitted,TResult Function( LoginCorporateSsoEmailChanged value)?  corporateSsoEmailChanged,TResult Function( LoginCorporateSsoSubmitted value)?  corporateSsoSubmitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LoginEmailChanged() when emailChanged != null:
return emailChanged(_that);case LoginPasswordChanged() when passwordChanged != null:
return passwordChanged(_that);case LoginPasswordVisibilityToggled() when passwordVisibilityToggled != null:
return passwordVisibilityToggled(_that);case LoginSubmitted() when submitted != null:
return submitted(_that);case LoginCorporateSsoEmailChanged() when corporateSsoEmailChanged != null:
return corporateSsoEmailChanged(_that);case LoginCorporateSsoSubmitted() when corporateSsoSubmitted != null:
return corporateSsoSubmitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LoginEmailChanged value)  emailChanged,required TResult Function( LoginPasswordChanged value)  passwordChanged,required TResult Function( LoginPasswordVisibilityToggled value)  passwordVisibilityToggled,required TResult Function( LoginSubmitted value)  submitted,required TResult Function( LoginCorporateSsoEmailChanged value)  corporateSsoEmailChanged,required TResult Function( LoginCorporateSsoSubmitted value)  corporateSsoSubmitted,}){
final _that = this;
switch (_that) {
case LoginEmailChanged():
return emailChanged(_that);case LoginPasswordChanged():
return passwordChanged(_that);case LoginPasswordVisibilityToggled():
return passwordVisibilityToggled(_that);case LoginSubmitted():
return submitted(_that);case LoginCorporateSsoEmailChanged():
return corporateSsoEmailChanged(_that);case LoginCorporateSsoSubmitted():
return corporateSsoSubmitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LoginEmailChanged value)?  emailChanged,TResult? Function( LoginPasswordChanged value)?  passwordChanged,TResult? Function( LoginPasswordVisibilityToggled value)?  passwordVisibilityToggled,TResult? Function( LoginSubmitted value)?  submitted,TResult? Function( LoginCorporateSsoEmailChanged value)?  corporateSsoEmailChanged,TResult? Function( LoginCorporateSsoSubmitted value)?  corporateSsoSubmitted,}){
final _that = this;
switch (_that) {
case LoginEmailChanged() when emailChanged != null:
return emailChanged(_that);case LoginPasswordChanged() when passwordChanged != null:
return passwordChanged(_that);case LoginPasswordVisibilityToggled() when passwordVisibilityToggled != null:
return passwordVisibilityToggled(_that);case LoginSubmitted() when submitted != null:
return submitted(_that);case LoginCorporateSsoEmailChanged() when corporateSsoEmailChanged != null:
return corporateSsoEmailChanged(_that);case LoginCorporateSsoSubmitted() when corporateSsoSubmitted != null:
return corporateSsoSubmitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String email)?  emailChanged,TResult Function( String password)?  passwordChanged,TResult Function()?  passwordVisibilityToggled,TResult Function()?  submitted,TResult Function( String email)?  corporateSsoEmailChanged,TResult Function()?  corporateSsoSubmitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LoginEmailChanged() when emailChanged != null:
return emailChanged(_that.email);case LoginPasswordChanged() when passwordChanged != null:
return passwordChanged(_that.password);case LoginPasswordVisibilityToggled() when passwordVisibilityToggled != null:
return passwordVisibilityToggled();case LoginSubmitted() when submitted != null:
return submitted();case LoginCorporateSsoEmailChanged() when corporateSsoEmailChanged != null:
return corporateSsoEmailChanged(_that.email);case LoginCorporateSsoSubmitted() when corporateSsoSubmitted != null:
return corporateSsoSubmitted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String email)  emailChanged,required TResult Function( String password)  passwordChanged,required TResult Function()  passwordVisibilityToggled,required TResult Function()  submitted,required TResult Function( String email)  corporateSsoEmailChanged,required TResult Function()  corporateSsoSubmitted,}) {final _that = this;
switch (_that) {
case LoginEmailChanged():
return emailChanged(_that.email);case LoginPasswordChanged():
return passwordChanged(_that.password);case LoginPasswordVisibilityToggled():
return passwordVisibilityToggled();case LoginSubmitted():
return submitted();case LoginCorporateSsoEmailChanged():
return corporateSsoEmailChanged(_that.email);case LoginCorporateSsoSubmitted():
return corporateSsoSubmitted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String email)?  emailChanged,TResult? Function( String password)?  passwordChanged,TResult? Function()?  passwordVisibilityToggled,TResult? Function()?  submitted,TResult? Function( String email)?  corporateSsoEmailChanged,TResult? Function()?  corporateSsoSubmitted,}) {final _that = this;
switch (_that) {
case LoginEmailChanged() when emailChanged != null:
return emailChanged(_that.email);case LoginPasswordChanged() when passwordChanged != null:
return passwordChanged(_that.password);case LoginPasswordVisibilityToggled() when passwordVisibilityToggled != null:
return passwordVisibilityToggled();case LoginSubmitted() when submitted != null:
return submitted();case LoginCorporateSsoEmailChanged() when corporateSsoEmailChanged != null:
return corporateSsoEmailChanged(_that.email);case LoginCorporateSsoSubmitted() when corporateSsoSubmitted != null:
return corporateSsoSubmitted();case _:
  return null;

}
}

}

/// @nodoc


class LoginEmailChanged implements LoginEvent {
  const LoginEmailChanged(this.email);
  

 final  String email;

/// Create a copy of LoginEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginEmailChangedCopyWith<LoginEmailChanged> get copyWith => _$LoginEmailChangedCopyWithImpl<LoginEmailChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginEmailChanged&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'LoginEvent.emailChanged(email: $email)';
}


}

/// @nodoc
abstract mixin class $LoginEmailChangedCopyWith<$Res> implements $LoginEventCopyWith<$Res> {
  factory $LoginEmailChangedCopyWith(LoginEmailChanged value, $Res Function(LoginEmailChanged) _then) = _$LoginEmailChangedCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$LoginEmailChangedCopyWithImpl<$Res>
    implements $LoginEmailChangedCopyWith<$Res> {
  _$LoginEmailChangedCopyWithImpl(this._self, this._then);

  final LoginEmailChanged _self;
  final $Res Function(LoginEmailChanged) _then;

/// Create a copy of LoginEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(LoginEmailChanged(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LoginPasswordChanged implements LoginEvent {
  const LoginPasswordChanged(this.password);
  

 final  String password;

/// Create a copy of LoginEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginPasswordChangedCopyWith<LoginPasswordChanged> get copyWith => _$LoginPasswordChangedCopyWithImpl<LoginPasswordChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginPasswordChanged&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,password);

@override
String toString() {
  return 'LoginEvent.passwordChanged(password: $password)';
}


}

/// @nodoc
abstract mixin class $LoginPasswordChangedCopyWith<$Res> implements $LoginEventCopyWith<$Res> {
  factory $LoginPasswordChangedCopyWith(LoginPasswordChanged value, $Res Function(LoginPasswordChanged) _then) = _$LoginPasswordChangedCopyWithImpl;
@useResult
$Res call({
 String password
});




}
/// @nodoc
class _$LoginPasswordChangedCopyWithImpl<$Res>
    implements $LoginPasswordChangedCopyWith<$Res> {
  _$LoginPasswordChangedCopyWithImpl(this._self, this._then);

  final LoginPasswordChanged _self;
  final $Res Function(LoginPasswordChanged) _then;

/// Create a copy of LoginEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? password = null,}) {
  return _then(LoginPasswordChanged(
null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LoginPasswordVisibilityToggled implements LoginEvent {
  const LoginPasswordVisibilityToggled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginPasswordVisibilityToggled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginEvent.passwordVisibilityToggled()';
}


}




/// @nodoc


class LoginSubmitted implements LoginEvent {
  const LoginSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginEvent.submitted()';
}


}




/// @nodoc


class LoginCorporateSsoEmailChanged implements LoginEvent {
  const LoginCorporateSsoEmailChanged(this.email);
  

 final  String email;

/// Create a copy of LoginEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginCorporateSsoEmailChangedCopyWith<LoginCorporateSsoEmailChanged> get copyWith => _$LoginCorporateSsoEmailChangedCopyWithImpl<LoginCorporateSsoEmailChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginCorporateSsoEmailChanged&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'LoginEvent.corporateSsoEmailChanged(email: $email)';
}


}

/// @nodoc
abstract mixin class $LoginCorporateSsoEmailChangedCopyWith<$Res> implements $LoginEventCopyWith<$Res> {
  factory $LoginCorporateSsoEmailChangedCopyWith(LoginCorporateSsoEmailChanged value, $Res Function(LoginCorporateSsoEmailChanged) _then) = _$LoginCorporateSsoEmailChangedCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$LoginCorporateSsoEmailChangedCopyWithImpl<$Res>
    implements $LoginCorporateSsoEmailChangedCopyWith<$Res> {
  _$LoginCorporateSsoEmailChangedCopyWithImpl(this._self, this._then);

  final LoginCorporateSsoEmailChanged _self;
  final $Res Function(LoginCorporateSsoEmailChanged) _then;

/// Create a copy of LoginEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(LoginCorporateSsoEmailChanged(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LoginCorporateSsoSubmitted implements LoginEvent {
  const LoginCorporateSsoSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginCorporateSsoSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LoginEvent.corporateSsoSubmitted()';
}


}




// dart format on
