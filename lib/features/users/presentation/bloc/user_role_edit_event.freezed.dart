// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_role_edit_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserRoleEditEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRoleEditEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserRoleEditEvent()';
}


}

/// @nodoc
class $UserRoleEditEventCopyWith<$Res>  {
$UserRoleEditEventCopyWith(UserRoleEditEvent _, $Res Function(UserRoleEditEvent) __);
}


/// Adds pattern-matching-related methods to [UserRoleEditEvent].
extension UserRoleEditEventPatterns on UserRoleEditEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserRoleEditStarted value)?  started,TResult Function( UserRoleEditRoleSelected value)?  roleSelected,TResult Function( UserRoleEditSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserRoleEditStarted() when started != null:
return started(_that);case UserRoleEditRoleSelected() when roleSelected != null:
return roleSelected(_that);case UserRoleEditSubmitted() when submitted != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserRoleEditStarted value)  started,required TResult Function( UserRoleEditRoleSelected value)  roleSelected,required TResult Function( UserRoleEditSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case UserRoleEditStarted():
return started(_that);case UserRoleEditRoleSelected():
return roleSelected(_that);case UserRoleEditSubmitted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserRoleEditStarted value)?  started,TResult? Function( UserRoleEditRoleSelected value)?  roleSelected,TResult? Function( UserRoleEditSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case UserRoleEditStarted() when started != null:
return started(_that);case UserRoleEditRoleSelected() when roleSelected != null:
return roleSelected(_that);case UserRoleEditSubmitted() when submitted != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String organizationId,  OrganizationUser user)?  started,TResult Function( SystemRoleName role)?  roleSelected,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserRoleEditStarted() when started != null:
return started(_that.organizationId,_that.user);case UserRoleEditRoleSelected() when roleSelected != null:
return roleSelected(_that.role);case UserRoleEditSubmitted() when submitted != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String organizationId,  OrganizationUser user)  started,required TResult Function( SystemRoleName role)  roleSelected,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case UserRoleEditStarted():
return started(_that.organizationId,_that.user);case UserRoleEditRoleSelected():
return roleSelected(_that.role);case UserRoleEditSubmitted():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String organizationId,  OrganizationUser user)?  started,TResult? Function( SystemRoleName role)?  roleSelected,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case UserRoleEditStarted() when started != null:
return started(_that.organizationId,_that.user);case UserRoleEditRoleSelected() when roleSelected != null:
return roleSelected(_that.role);case UserRoleEditSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class UserRoleEditStarted implements UserRoleEditEvent {
  const UserRoleEditStarted({required this.organizationId, required this.user});
  

 final  String organizationId;
 final  OrganizationUser user;

/// Create a copy of UserRoleEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRoleEditStartedCopyWith<UserRoleEditStarted> get copyWith => _$UserRoleEditStartedCopyWithImpl<UserRoleEditStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRoleEditStarted&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId,user);

@override
String toString() {
  return 'UserRoleEditEvent.started(organizationId: $organizationId, user: $user)';
}


}

/// @nodoc
abstract mixin class $UserRoleEditStartedCopyWith<$Res> implements $UserRoleEditEventCopyWith<$Res> {
  factory $UserRoleEditStartedCopyWith(UserRoleEditStarted value, $Res Function(UserRoleEditStarted) _then) = _$UserRoleEditStartedCopyWithImpl;
@useResult
$Res call({
 String organizationId, OrganizationUser user
});


$OrganizationUserCopyWith<$Res> get user;

}
/// @nodoc
class _$UserRoleEditStartedCopyWithImpl<$Res>
    implements $UserRoleEditStartedCopyWith<$Res> {
  _$UserRoleEditStartedCopyWithImpl(this._self, this._then);

  final UserRoleEditStarted _self;
  final $Res Function(UserRoleEditStarted) _then;

/// Create a copy of UserRoleEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = null,Object? user = null,}) {
  return _then(UserRoleEditStarted(
organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as OrganizationUser,
  ));
}

/// Create a copy of UserRoleEditEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationUserCopyWith<$Res> get user {
  
  return $OrganizationUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class UserRoleEditRoleSelected implements UserRoleEditEvent {
  const UserRoleEditRoleSelected(this.role);
  

 final  SystemRoleName role;

/// Create a copy of UserRoleEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRoleEditRoleSelectedCopyWith<UserRoleEditRoleSelected> get copyWith => _$UserRoleEditRoleSelectedCopyWithImpl<UserRoleEditRoleSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRoleEditRoleSelected&&(identical(other.role, role) || other.role == role));
}


@override
int get hashCode => Object.hash(runtimeType,role);

@override
String toString() {
  return 'UserRoleEditEvent.roleSelected(role: $role)';
}


}

/// @nodoc
abstract mixin class $UserRoleEditRoleSelectedCopyWith<$Res> implements $UserRoleEditEventCopyWith<$Res> {
  factory $UserRoleEditRoleSelectedCopyWith(UserRoleEditRoleSelected value, $Res Function(UserRoleEditRoleSelected) _then) = _$UserRoleEditRoleSelectedCopyWithImpl;
@useResult
$Res call({
 SystemRoleName role
});




}
/// @nodoc
class _$UserRoleEditRoleSelectedCopyWithImpl<$Res>
    implements $UserRoleEditRoleSelectedCopyWith<$Res> {
  _$UserRoleEditRoleSelectedCopyWithImpl(this._self, this._then);

  final UserRoleEditRoleSelected _self;
  final $Res Function(UserRoleEditRoleSelected) _then;

/// Create a copy of UserRoleEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = null,}) {
  return _then(UserRoleEditRoleSelected(
null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as SystemRoleName,
  ));
}


}

/// @nodoc


class UserRoleEditSubmitted implements UserRoleEditEvent {
  const UserRoleEditSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRoleEditSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserRoleEditEvent.submitted()';
}


}




// dart format on
