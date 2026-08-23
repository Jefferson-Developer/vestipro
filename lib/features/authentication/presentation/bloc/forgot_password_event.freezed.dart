// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordEvent()';
}


}

/// @nodoc
class $ForgotPasswordEventCopyWith<$Res>  {
$ForgotPasswordEventCopyWith(ForgotPasswordEvent _, $Res Function(ForgotPasswordEvent) __);
}


/// Adds pattern-matching-related methods to [ForgotPasswordEvent].
extension ForgotPasswordEventPatterns on ForgotPasswordEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForgotPasswordEmailChanged value)?  emailChanged,TResult Function( ForgotPasswordSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForgotPasswordEmailChanged() when emailChanged != null:
return emailChanged(_that);case ForgotPasswordSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForgotPasswordEmailChanged value)  emailChanged,required TResult Function( ForgotPasswordSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case ForgotPasswordEmailChanged():
return emailChanged(_that);case ForgotPasswordSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForgotPasswordEmailChanged value)?  emailChanged,TResult? Function( ForgotPasswordSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case ForgotPasswordEmailChanged() when emailChanged != null:
return emailChanged(_that);case ForgotPasswordSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String email)?  emailChanged,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForgotPasswordEmailChanged() when emailChanged != null:
return emailChanged(_that.email);case ForgotPasswordSubmitted() when submitted != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String email)  emailChanged,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case ForgotPasswordEmailChanged():
return emailChanged(_that.email);case ForgotPasswordSubmitted():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String email)?  emailChanged,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case ForgotPasswordEmailChanged() when emailChanged != null:
return emailChanged(_that.email);case ForgotPasswordSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class ForgotPasswordEmailChanged implements ForgotPasswordEvent {
  const ForgotPasswordEmailChanged(this.email);
  

 final  String email;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordEmailChangedCopyWith<ForgotPasswordEmailChanged> get copyWith => _$ForgotPasswordEmailChangedCopyWithImpl<ForgotPasswordEmailChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordEmailChanged&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'ForgotPasswordEvent.emailChanged(email: $email)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordEmailChangedCopyWith<$Res> implements $ForgotPasswordEventCopyWith<$Res> {
  factory $ForgotPasswordEmailChangedCopyWith(ForgotPasswordEmailChanged value, $Res Function(ForgotPasswordEmailChanged) _then) = _$ForgotPasswordEmailChangedCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$ForgotPasswordEmailChangedCopyWithImpl<$Res>
    implements $ForgotPasswordEmailChangedCopyWith<$Res> {
  _$ForgotPasswordEmailChangedCopyWithImpl(this._self, this._then);

  final ForgotPasswordEmailChanged _self;
  final $Res Function(ForgotPasswordEmailChanged) _then;

/// Create a copy of ForgotPasswordEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(ForgotPasswordEmailChanged(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ForgotPasswordSubmitted implements ForgotPasswordEvent {
  const ForgotPasswordSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForgotPasswordEvent.submitted()';
}


}




// dart format on
