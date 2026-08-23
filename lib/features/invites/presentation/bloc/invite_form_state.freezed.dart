// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteFormState {

 InviteFormLoadStatus get loadStatus; String get organizationId;/// The roles the signed-in user is allowed to assign, resolved from
/// their real Membership (`assignableRolesFor`) — never all 7 system
/// roles unconditionally. Empty while [loadStatus] is
/// [InviteFormLoadStatus.loading], or if their Membership could not be
/// resolved at all (fails closed, same as [PermissionService]).
 List<SystemRoleName> get assignableRoles; String get email; String? get emailError; SystemRoleName? get role; String? get roleError; String get message; InviteFormSubmissionStatus get submissionStatus;/// Only meaningful when [submissionStatus] is
/// [InviteFormSubmissionStatus.failure].
 Failure? get failure;/// Only meaningful when [submissionStatus] is
/// [InviteFormSubmissionStatus.success] — the invite just issued,
/// including the one-time [IssuedInvite.token] `InviteUserPage` shows so
/// it can be copied/shared right now (see [IssuedInvite]'s own docs for
/// why it can never be retrieved again afterwards).
 IssuedInvite? get issuedInvite;
/// Create a copy of InviteFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteFormStateCopyWith<InviteFormState> get copyWith => _$InviteFormStateCopyWithImpl<InviteFormState>(this as InviteFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteFormState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other.assignableRoles, assignableRoles)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.role, role) || other.role == role)&&(identical(other.roleError, roleError) || other.roleError == roleError)&&(identical(other.message, message) || other.message == message)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.issuedInvite, issuedInvite) || other.issuedInvite == issuedInvite));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,const DeepCollectionEquality().hash(assignableRoles),email,emailError,role,roleError,message,submissionStatus,failure,issuedInvite);

@override
String toString() {
  return 'InviteFormState(loadStatus: $loadStatus, organizationId: $organizationId, assignableRoles: $assignableRoles, email: $email, emailError: $emailError, role: $role, roleError: $roleError, message: $message, submissionStatus: $submissionStatus, failure: $failure, issuedInvite: $issuedInvite)';
}


}

/// @nodoc
abstract mixin class $InviteFormStateCopyWith<$Res>  {
  factory $InviteFormStateCopyWith(InviteFormState value, $Res Function(InviteFormState) _then) = _$InviteFormStateCopyWithImpl;
@useResult
$Res call({
 InviteFormLoadStatus loadStatus, String organizationId, List<SystemRoleName> assignableRoles, String email, String? emailError, SystemRoleName? role, String? roleError, String message, InviteFormSubmissionStatus submissionStatus, Failure? failure, IssuedInvite? issuedInvite
});


$IssuedInviteCopyWith<$Res>? get issuedInvite;

}
/// @nodoc
class _$InviteFormStateCopyWithImpl<$Res>
    implements $InviteFormStateCopyWith<$Res> {
  _$InviteFormStateCopyWithImpl(this._self, this._then);

  final InviteFormState _self;
  final $Res Function(InviteFormState) _then;

/// Create a copy of InviteFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadStatus = null,Object? organizationId = null,Object? assignableRoles = null,Object? email = null,Object? emailError = freezed,Object? role = freezed,Object? roleError = freezed,Object? message = null,Object? submissionStatus = null,Object? failure = freezed,Object? issuedInvite = freezed,}) {
  return _then(_self.copyWith(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as InviteFormLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,assignableRoles: null == assignableRoles ? _self.assignableRoles : assignableRoles // ignore: cast_nullable_to_non_nullable
as List<SystemRoleName>,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,roleError: freezed == roleError ? _self.roleError : roleError // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as InviteFormSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,issuedInvite: freezed == issuedInvite ? _self.issuedInvite : issuedInvite // ignore: cast_nullable_to_non_nullable
as IssuedInvite?,
  ));
}
/// Create a copy of InviteFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedInviteCopyWith<$Res>? get issuedInvite {
    if (_self.issuedInvite == null) {
    return null;
  }

  return $IssuedInviteCopyWith<$Res>(_self.issuedInvite!, (value) {
    return _then(_self.copyWith(issuedInvite: value));
  });
}
}


/// Adds pattern-matching-related methods to [InviteFormState].
extension InviteFormStatePatterns on InviteFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteFormState value)  $default,){
final _that = this;
switch (_that) {
case _InviteFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteFormState value)?  $default,){
final _that = this;
switch (_that) {
case _InviteFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InviteFormLoadStatus loadStatus,  String organizationId,  List<SystemRoleName> assignableRoles,  String email,  String? emailError,  SystemRoleName? role,  String? roleError,  String message,  InviteFormSubmissionStatus submissionStatus,  Failure? failure,  IssuedInvite? issuedInvite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteFormState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.assignableRoles,_that.email,_that.emailError,_that.role,_that.roleError,_that.message,_that.submissionStatus,_that.failure,_that.issuedInvite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InviteFormLoadStatus loadStatus,  String organizationId,  List<SystemRoleName> assignableRoles,  String email,  String? emailError,  SystemRoleName? role,  String? roleError,  String message,  InviteFormSubmissionStatus submissionStatus,  Failure? failure,  IssuedInvite? issuedInvite)  $default,) {final _that = this;
switch (_that) {
case _InviteFormState():
return $default(_that.loadStatus,_that.organizationId,_that.assignableRoles,_that.email,_that.emailError,_that.role,_that.roleError,_that.message,_that.submissionStatus,_that.failure,_that.issuedInvite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InviteFormLoadStatus loadStatus,  String organizationId,  List<SystemRoleName> assignableRoles,  String email,  String? emailError,  SystemRoleName? role,  String? roleError,  String message,  InviteFormSubmissionStatus submissionStatus,  Failure? failure,  IssuedInvite? issuedInvite)?  $default,) {final _that = this;
switch (_that) {
case _InviteFormState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.assignableRoles,_that.email,_that.emailError,_that.role,_that.roleError,_that.message,_that.submissionStatus,_that.failure,_that.issuedInvite);case _:
  return null;

}
}

}

/// @nodoc


class _InviteFormState implements InviteFormState {
  const _InviteFormState({this.loadStatus = InviteFormLoadStatus.loading, this.organizationId = '', final  List<SystemRoleName> assignableRoles = const <SystemRoleName>[], this.email = '', this.emailError, this.role, this.roleError, this.message = '', this.submissionStatus = InviteFormSubmissionStatus.idle, this.failure, this.issuedInvite}): _assignableRoles = assignableRoles;
  

@override@JsonKey() final  InviteFormLoadStatus loadStatus;
@override@JsonKey() final  String organizationId;
/// The roles the signed-in user is allowed to assign, resolved from
/// their real Membership (`assignableRolesFor`) — never all 7 system
/// roles unconditionally. Empty while [loadStatus] is
/// [InviteFormLoadStatus.loading], or if their Membership could not be
/// resolved at all (fails closed, same as [PermissionService]).
 final  List<SystemRoleName> _assignableRoles;
/// The roles the signed-in user is allowed to assign, resolved from
/// their real Membership (`assignableRolesFor`) — never all 7 system
/// roles unconditionally. Empty while [loadStatus] is
/// [InviteFormLoadStatus.loading], or if their Membership could not be
/// resolved at all (fails closed, same as [PermissionService]).
@override@JsonKey() List<SystemRoleName> get assignableRoles {
  if (_assignableRoles is EqualUnmodifiableListView) return _assignableRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignableRoles);
}

@override@JsonKey() final  String email;
@override final  String? emailError;
@override final  SystemRoleName? role;
@override final  String? roleError;
@override@JsonKey() final  String message;
@override@JsonKey() final  InviteFormSubmissionStatus submissionStatus;
/// Only meaningful when [submissionStatus] is
/// [InviteFormSubmissionStatus.failure].
@override final  Failure? failure;
/// Only meaningful when [submissionStatus] is
/// [InviteFormSubmissionStatus.success] — the invite just issued,
/// including the one-time [IssuedInvite.token] `InviteUserPage` shows so
/// it can be copied/shared right now (see [IssuedInvite]'s own docs for
/// why it can never be retrieved again afterwards).
@override final  IssuedInvite? issuedInvite;

/// Create a copy of InviteFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteFormStateCopyWith<_InviteFormState> get copyWith => __$InviteFormStateCopyWithImpl<_InviteFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteFormState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other._assignableRoles, _assignableRoles)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailError, emailError) || other.emailError == emailError)&&(identical(other.role, role) || other.role == role)&&(identical(other.roleError, roleError) || other.roleError == roleError)&&(identical(other.message, message) || other.message == message)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.issuedInvite, issuedInvite) || other.issuedInvite == issuedInvite));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,const DeepCollectionEquality().hash(_assignableRoles),email,emailError,role,roleError,message,submissionStatus,failure,issuedInvite);

@override
String toString() {
  return 'InviteFormState(loadStatus: $loadStatus, organizationId: $organizationId, assignableRoles: $assignableRoles, email: $email, emailError: $emailError, role: $role, roleError: $roleError, message: $message, submissionStatus: $submissionStatus, failure: $failure, issuedInvite: $issuedInvite)';
}


}

/// @nodoc
abstract mixin class _$InviteFormStateCopyWith<$Res> implements $InviteFormStateCopyWith<$Res> {
  factory _$InviteFormStateCopyWith(_InviteFormState value, $Res Function(_InviteFormState) _then) = __$InviteFormStateCopyWithImpl;
@override @useResult
$Res call({
 InviteFormLoadStatus loadStatus, String organizationId, List<SystemRoleName> assignableRoles, String email, String? emailError, SystemRoleName? role, String? roleError, String message, InviteFormSubmissionStatus submissionStatus, Failure? failure, IssuedInvite? issuedInvite
});


@override $IssuedInviteCopyWith<$Res>? get issuedInvite;

}
/// @nodoc
class __$InviteFormStateCopyWithImpl<$Res>
    implements _$InviteFormStateCopyWith<$Res> {
  __$InviteFormStateCopyWithImpl(this._self, this._then);

  final _InviteFormState _self;
  final $Res Function(_InviteFormState) _then;

/// Create a copy of InviteFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadStatus = null,Object? organizationId = null,Object? assignableRoles = null,Object? email = null,Object? emailError = freezed,Object? role = freezed,Object? roleError = freezed,Object? message = null,Object? submissionStatus = null,Object? failure = freezed,Object? issuedInvite = freezed,}) {
  return _then(_InviteFormState(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as InviteFormLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,assignableRoles: null == assignableRoles ? _self._assignableRoles : assignableRoles // ignore: cast_nullable_to_non_nullable
as List<SystemRoleName>,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,emailError: freezed == emailError ? _self.emailError : emailError // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,roleError: freezed == roleError ? _self.roleError : roleError // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as InviteFormSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,issuedInvite: freezed == issuedInvite ? _self.issuedInvite : issuedInvite // ignore: cast_nullable_to_non_nullable
as IssuedInvite?,
  ));
}

/// Create a copy of InviteFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedInviteCopyWith<$Res>? get issuedInvite {
    if (_self.issuedInvite == null) {
    return null;
  }

  return $IssuedInviteCopyWith<$Res>(_self.issuedInvite!, (value) {
    return _then(_self.copyWith(issuedInvite: value));
  });
}
}

// dart format on
