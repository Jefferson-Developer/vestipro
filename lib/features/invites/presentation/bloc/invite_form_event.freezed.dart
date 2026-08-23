// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_form_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteFormEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InviteFormEvent()';
}


}

/// @nodoc
class $InviteFormEventCopyWith<$Res>  {
$InviteFormEventCopyWith(InviteFormEvent _, $Res Function(InviteFormEvent) __);
}


/// Adds pattern-matching-related methods to [InviteFormEvent].
extension InviteFormEventPatterns on InviteFormEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InviteFormStarted value)?  started,TResult Function( InviteFormEmailChanged value)?  emailChanged,TResult Function( InviteFormRoleSelected value)?  roleSelected,TResult Function( InviteFormMessageChanged value)?  messageChanged,TResult Function( InviteFormSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InviteFormStarted() when started != null:
return started(_that);case InviteFormEmailChanged() when emailChanged != null:
return emailChanged(_that);case InviteFormRoleSelected() when roleSelected != null:
return roleSelected(_that);case InviteFormMessageChanged() when messageChanged != null:
return messageChanged(_that);case InviteFormSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InviteFormStarted value)  started,required TResult Function( InviteFormEmailChanged value)  emailChanged,required TResult Function( InviteFormRoleSelected value)  roleSelected,required TResult Function( InviteFormMessageChanged value)  messageChanged,required TResult Function( InviteFormSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case InviteFormStarted():
return started(_that);case InviteFormEmailChanged():
return emailChanged(_that);case InviteFormRoleSelected():
return roleSelected(_that);case InviteFormMessageChanged():
return messageChanged(_that);case InviteFormSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InviteFormStarted value)?  started,TResult? Function( InviteFormEmailChanged value)?  emailChanged,TResult? Function( InviteFormRoleSelected value)?  roleSelected,TResult? Function( InviteFormMessageChanged value)?  messageChanged,TResult? Function( InviteFormSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case InviteFormStarted() when started != null:
return started(_that);case InviteFormEmailChanged() when emailChanged != null:
return emailChanged(_that);case InviteFormRoleSelected() when roleSelected != null:
return roleSelected(_that);case InviteFormMessageChanged() when messageChanged != null:
return messageChanged(_that);case InviteFormSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String organizationId)?  started,TResult Function( String email)?  emailChanged,TResult Function( SystemRoleName role)?  roleSelected,TResult Function( String message)?  messageChanged,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InviteFormStarted() when started != null:
return started(_that.organizationId);case InviteFormEmailChanged() when emailChanged != null:
return emailChanged(_that.email);case InviteFormRoleSelected() when roleSelected != null:
return roleSelected(_that.role);case InviteFormMessageChanged() when messageChanged != null:
return messageChanged(_that.message);case InviteFormSubmitted() when submitted != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String organizationId)  started,required TResult Function( String email)  emailChanged,required TResult Function( SystemRoleName role)  roleSelected,required TResult Function( String message)  messageChanged,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case InviteFormStarted():
return started(_that.organizationId);case InviteFormEmailChanged():
return emailChanged(_that.email);case InviteFormRoleSelected():
return roleSelected(_that.role);case InviteFormMessageChanged():
return messageChanged(_that.message);case InviteFormSubmitted():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String organizationId)?  started,TResult? Function( String email)?  emailChanged,TResult? Function( SystemRoleName role)?  roleSelected,TResult? Function( String message)?  messageChanged,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case InviteFormStarted() when started != null:
return started(_that.organizationId);case InviteFormEmailChanged() when emailChanged != null:
return emailChanged(_that.email);case InviteFormRoleSelected() when roleSelected != null:
return roleSelected(_that.role);case InviteFormMessageChanged() when messageChanged != null:
return messageChanged(_that.message);case InviteFormSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class InviteFormStarted implements InviteFormEvent {
  const InviteFormStarted(this.organizationId);
  

 final  String organizationId;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteFormStartedCopyWith<InviteFormStarted> get copyWith => _$InviteFormStartedCopyWithImpl<InviteFormStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormStarted&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId);

@override
String toString() {
  return 'InviteFormEvent.started(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class $InviteFormStartedCopyWith<$Res> implements $InviteFormEventCopyWith<$Res> {
  factory $InviteFormStartedCopyWith(InviteFormStarted value, $Res Function(InviteFormStarted) _then) = _$InviteFormStartedCopyWithImpl;
@useResult
$Res call({
 String organizationId
});




}
/// @nodoc
class _$InviteFormStartedCopyWithImpl<$Res>
    implements $InviteFormStartedCopyWith<$Res> {
  _$InviteFormStartedCopyWithImpl(this._self, this._then);

  final InviteFormStarted _self;
  final $Res Function(InviteFormStarted) _then;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = null,}) {
  return _then(InviteFormStarted(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InviteFormEmailChanged implements InviteFormEvent {
  const InviteFormEmailChanged(this.email);
  

 final  String email;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteFormEmailChangedCopyWith<InviteFormEmailChanged> get copyWith => _$InviteFormEmailChangedCopyWithImpl<InviteFormEmailChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormEmailChanged&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'InviteFormEvent.emailChanged(email: $email)';
}


}

/// @nodoc
abstract mixin class $InviteFormEmailChangedCopyWith<$Res> implements $InviteFormEventCopyWith<$Res> {
  factory $InviteFormEmailChangedCopyWith(InviteFormEmailChanged value, $Res Function(InviteFormEmailChanged) _then) = _$InviteFormEmailChangedCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$InviteFormEmailChangedCopyWithImpl<$Res>
    implements $InviteFormEmailChangedCopyWith<$Res> {
  _$InviteFormEmailChangedCopyWithImpl(this._self, this._then);

  final InviteFormEmailChanged _self;
  final $Res Function(InviteFormEmailChanged) _then;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(InviteFormEmailChanged(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InviteFormRoleSelected implements InviteFormEvent {
  const InviteFormRoleSelected(this.role);
  

 final  SystemRoleName role;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteFormRoleSelectedCopyWith<InviteFormRoleSelected> get copyWith => _$InviteFormRoleSelectedCopyWithImpl<InviteFormRoleSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormRoleSelected&&(identical(other.role, role) || other.role == role));
}


@override
int get hashCode => Object.hash(runtimeType,role);

@override
String toString() {
  return 'InviteFormEvent.roleSelected(role: $role)';
}


}

/// @nodoc
abstract mixin class $InviteFormRoleSelectedCopyWith<$Res> implements $InviteFormEventCopyWith<$Res> {
  factory $InviteFormRoleSelectedCopyWith(InviteFormRoleSelected value, $Res Function(InviteFormRoleSelected) _then) = _$InviteFormRoleSelectedCopyWithImpl;
@useResult
$Res call({
 SystemRoleName role
});




}
/// @nodoc
class _$InviteFormRoleSelectedCopyWithImpl<$Res>
    implements $InviteFormRoleSelectedCopyWith<$Res> {
  _$InviteFormRoleSelectedCopyWithImpl(this._self, this._then);

  final InviteFormRoleSelected _self;
  final $Res Function(InviteFormRoleSelected) _then;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = null,}) {
  return _then(InviteFormRoleSelected(
null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as SystemRoleName,
  ));
}


}

/// @nodoc


class InviteFormMessageChanged implements InviteFormEvent {
  const InviteFormMessageChanged(this.message);
  

 final  String message;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteFormMessageChangedCopyWith<InviteFormMessageChanged> get copyWith => _$InviteFormMessageChangedCopyWithImpl<InviteFormMessageChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormMessageChanged&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'InviteFormEvent.messageChanged(message: $message)';
}


}

/// @nodoc
abstract mixin class $InviteFormMessageChangedCopyWith<$Res> implements $InviteFormEventCopyWith<$Res> {
  factory $InviteFormMessageChangedCopyWith(InviteFormMessageChanged value, $Res Function(InviteFormMessageChanged) _then) = _$InviteFormMessageChangedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$InviteFormMessageChangedCopyWithImpl<$Res>
    implements $InviteFormMessageChangedCopyWith<$Res> {
  _$InviteFormMessageChangedCopyWithImpl(this._self, this._then);

  final InviteFormMessageChanged _self;
  final $Res Function(InviteFormMessageChanged) _then;

/// Create a copy of InviteFormEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(InviteFormMessageChanged(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InviteFormSubmitted implements InviteFormEvent {
  const InviteFormSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InviteFormEvent.submitted()';
}


}




// dart format on
