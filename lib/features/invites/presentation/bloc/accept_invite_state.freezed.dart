// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accept_invite_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AcceptInviteState {

 String get token; AcceptInviteValidationStatus get validationStatus;/// Only meaningful once [validationStatus] is
/// [AcceptInviteValidationStatus.ready].
 InviteAcceptanceOutcome get outcome; String? get organizationId; String? get organizationName; String? get invitedEmail; SystemRoleName? get roleName;/// Whether someone is already signed in, resolved once, right when
/// [validationStatus] becomes [AcceptInviteValidationStatus.ready] with
/// a [InviteAcceptanceOutcome.valid] outcome. `false` after
/// [AcceptInviteEvent.signOutRequested] succeeds.
 bool get hasActiveSession;/// Only meaningful while [hasActiveSession] is `true`: whether the
/// signed-in user's e-mail diverges from [invitedEmail]
/// (case-insensitively) — the documented TASK-040 rule is to **block**
/// this case client-side (steering the user to sign out) on top of the
/// server-side `permission-denied` `acceptInvite` would return anyway.
 bool get sessionEmailMismatch; AcceptInviteAcceptanceStatus get acceptanceStatus;/// Only meaningful when [acceptanceStatus] is
/// [AcceptInviteAcceptanceStatus.success] — where `AcceptInvitePage`
/// navigates to next.
 String? get acceptedOrganizationId;/// Meaningful when [validationStatus] is
/// [AcceptInviteValidationStatus.error] or [acceptanceStatus] is
/// [AcceptInviteAcceptanceStatus.failure].
 Failure? get failure;
/// Create a copy of AcceptInviteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcceptInviteStateCopyWith<AcceptInviteState> get copyWith => _$AcceptInviteStateCopyWithImpl<AcceptInviteState>(this as AcceptInviteState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcceptInviteState&&(identical(other.token, token) || other.token == token)&&(identical(other.validationStatus, validationStatus) || other.validationStatus == validationStatus)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.invitedEmail, invitedEmail) || other.invitedEmail == invitedEmail)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.hasActiveSession, hasActiveSession) || other.hasActiveSession == hasActiveSession)&&(identical(other.sessionEmailMismatch, sessionEmailMismatch) || other.sessionEmailMismatch == sessionEmailMismatch)&&(identical(other.acceptanceStatus, acceptanceStatus) || other.acceptanceStatus == acceptanceStatus)&&(identical(other.acceptedOrganizationId, acceptedOrganizationId) || other.acceptedOrganizationId == acceptedOrganizationId)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,token,validationStatus,outcome,organizationId,organizationName,invitedEmail,roleName,hasActiveSession,sessionEmailMismatch,acceptanceStatus,acceptedOrganizationId,failure);

@override
String toString() {
  return 'AcceptInviteState(token: $token, validationStatus: $validationStatus, outcome: $outcome, organizationId: $organizationId, organizationName: $organizationName, invitedEmail: $invitedEmail, roleName: $roleName, hasActiveSession: $hasActiveSession, sessionEmailMismatch: $sessionEmailMismatch, acceptanceStatus: $acceptanceStatus, acceptedOrganizationId: $acceptedOrganizationId, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AcceptInviteStateCopyWith<$Res>  {
  factory $AcceptInviteStateCopyWith(AcceptInviteState value, $Res Function(AcceptInviteState) _then) = _$AcceptInviteStateCopyWithImpl;
@useResult
$Res call({
 String token, AcceptInviteValidationStatus validationStatus, InviteAcceptanceOutcome outcome, String? organizationId, String? organizationName, String? invitedEmail, SystemRoleName? roleName, bool hasActiveSession, bool sessionEmailMismatch, AcceptInviteAcceptanceStatus acceptanceStatus, String? acceptedOrganizationId, Failure? failure
});




}
/// @nodoc
class _$AcceptInviteStateCopyWithImpl<$Res>
    implements $AcceptInviteStateCopyWith<$Res> {
  _$AcceptInviteStateCopyWithImpl(this._self, this._then);

  final AcceptInviteState _self;
  final $Res Function(AcceptInviteState) _then;

/// Create a copy of AcceptInviteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? validationStatus = null,Object? outcome = null,Object? organizationId = freezed,Object? organizationName = freezed,Object? invitedEmail = freezed,Object? roleName = freezed,Object? hasActiveSession = null,Object? sessionEmailMismatch = null,Object? acceptanceStatus = null,Object? acceptedOrganizationId = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,validationStatus: null == validationStatus ? _self.validationStatus : validationStatus // ignore: cast_nullable_to_non_nullable
as AcceptInviteValidationStatus,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as InviteAcceptanceOutcome,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,organizationName: freezed == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String?,invitedEmail: freezed == invitedEmail ? _self.invitedEmail : invitedEmail // ignore: cast_nullable_to_non_nullable
as String?,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,hasActiveSession: null == hasActiveSession ? _self.hasActiveSession : hasActiveSession // ignore: cast_nullable_to_non_nullable
as bool,sessionEmailMismatch: null == sessionEmailMismatch ? _self.sessionEmailMismatch : sessionEmailMismatch // ignore: cast_nullable_to_non_nullable
as bool,acceptanceStatus: null == acceptanceStatus ? _self.acceptanceStatus : acceptanceStatus // ignore: cast_nullable_to_non_nullable
as AcceptInviteAcceptanceStatus,acceptedOrganizationId: freezed == acceptedOrganizationId ? _self.acceptedOrganizationId : acceptedOrganizationId // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [AcceptInviteState].
extension AcceptInviteStatePatterns on AcceptInviteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcceptInviteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcceptInviteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcceptInviteState value)  $default,){
final _that = this;
switch (_that) {
case _AcceptInviteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcceptInviteState value)?  $default,){
final _that = this;
switch (_that) {
case _AcceptInviteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  AcceptInviteValidationStatus validationStatus,  InviteAcceptanceOutcome outcome,  String? organizationId,  String? organizationName,  String? invitedEmail,  SystemRoleName? roleName,  bool hasActiveSession,  bool sessionEmailMismatch,  AcceptInviteAcceptanceStatus acceptanceStatus,  String? acceptedOrganizationId,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcceptInviteState() when $default != null:
return $default(_that.token,_that.validationStatus,_that.outcome,_that.organizationId,_that.organizationName,_that.invitedEmail,_that.roleName,_that.hasActiveSession,_that.sessionEmailMismatch,_that.acceptanceStatus,_that.acceptedOrganizationId,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  AcceptInviteValidationStatus validationStatus,  InviteAcceptanceOutcome outcome,  String? organizationId,  String? organizationName,  String? invitedEmail,  SystemRoleName? roleName,  bool hasActiveSession,  bool sessionEmailMismatch,  AcceptInviteAcceptanceStatus acceptanceStatus,  String? acceptedOrganizationId,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _AcceptInviteState():
return $default(_that.token,_that.validationStatus,_that.outcome,_that.organizationId,_that.organizationName,_that.invitedEmail,_that.roleName,_that.hasActiveSession,_that.sessionEmailMismatch,_that.acceptanceStatus,_that.acceptedOrganizationId,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  AcceptInviteValidationStatus validationStatus,  InviteAcceptanceOutcome outcome,  String? organizationId,  String? organizationName,  String? invitedEmail,  SystemRoleName? roleName,  bool hasActiveSession,  bool sessionEmailMismatch,  AcceptInviteAcceptanceStatus acceptanceStatus,  String? acceptedOrganizationId,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _AcceptInviteState() when $default != null:
return $default(_that.token,_that.validationStatus,_that.outcome,_that.organizationId,_that.organizationName,_that.invitedEmail,_that.roleName,_that.hasActiveSession,_that.sessionEmailMismatch,_that.acceptanceStatus,_that.acceptedOrganizationId,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _AcceptInviteState implements AcceptInviteState {
  const _AcceptInviteState({this.token = '', this.validationStatus = AcceptInviteValidationStatus.loading, this.outcome = InviteAcceptanceOutcome.notFound, this.organizationId, this.organizationName, this.invitedEmail, this.roleName, this.hasActiveSession = false, this.sessionEmailMismatch = false, this.acceptanceStatus = AcceptInviteAcceptanceStatus.idle, this.acceptedOrganizationId, this.failure});
  

@override@JsonKey() final  String token;
@override@JsonKey() final  AcceptInviteValidationStatus validationStatus;
/// Only meaningful once [validationStatus] is
/// [AcceptInviteValidationStatus.ready].
@override@JsonKey() final  InviteAcceptanceOutcome outcome;
@override final  String? organizationId;
@override final  String? organizationName;
@override final  String? invitedEmail;
@override final  SystemRoleName? roleName;
/// Whether someone is already signed in, resolved once, right when
/// [validationStatus] becomes [AcceptInviteValidationStatus.ready] with
/// a [InviteAcceptanceOutcome.valid] outcome. `false` after
/// [AcceptInviteEvent.signOutRequested] succeeds.
@override@JsonKey() final  bool hasActiveSession;
/// Only meaningful while [hasActiveSession] is `true`: whether the
/// signed-in user's e-mail diverges from [invitedEmail]
/// (case-insensitively) — the documented TASK-040 rule is to **block**
/// this case client-side (steering the user to sign out) on top of the
/// server-side `permission-denied` `acceptInvite` would return anyway.
@override@JsonKey() final  bool sessionEmailMismatch;
@override@JsonKey() final  AcceptInviteAcceptanceStatus acceptanceStatus;
/// Only meaningful when [acceptanceStatus] is
/// [AcceptInviteAcceptanceStatus.success] — where `AcceptInvitePage`
/// navigates to next.
@override final  String? acceptedOrganizationId;
/// Meaningful when [validationStatus] is
/// [AcceptInviteValidationStatus.error] or [acceptanceStatus] is
/// [AcceptInviteAcceptanceStatus.failure].
@override final  Failure? failure;

/// Create a copy of AcceptInviteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcceptInviteStateCopyWith<_AcceptInviteState> get copyWith => __$AcceptInviteStateCopyWithImpl<_AcceptInviteState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcceptInviteState&&(identical(other.token, token) || other.token == token)&&(identical(other.validationStatus, validationStatus) || other.validationStatus == validationStatus)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.invitedEmail, invitedEmail) || other.invitedEmail == invitedEmail)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.hasActiveSession, hasActiveSession) || other.hasActiveSession == hasActiveSession)&&(identical(other.sessionEmailMismatch, sessionEmailMismatch) || other.sessionEmailMismatch == sessionEmailMismatch)&&(identical(other.acceptanceStatus, acceptanceStatus) || other.acceptanceStatus == acceptanceStatus)&&(identical(other.acceptedOrganizationId, acceptedOrganizationId) || other.acceptedOrganizationId == acceptedOrganizationId)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,token,validationStatus,outcome,organizationId,organizationName,invitedEmail,roleName,hasActiveSession,sessionEmailMismatch,acceptanceStatus,acceptedOrganizationId,failure);

@override
String toString() {
  return 'AcceptInviteState(token: $token, validationStatus: $validationStatus, outcome: $outcome, organizationId: $organizationId, organizationName: $organizationName, invitedEmail: $invitedEmail, roleName: $roleName, hasActiveSession: $hasActiveSession, sessionEmailMismatch: $sessionEmailMismatch, acceptanceStatus: $acceptanceStatus, acceptedOrganizationId: $acceptedOrganizationId, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$AcceptInviteStateCopyWith<$Res> implements $AcceptInviteStateCopyWith<$Res> {
  factory _$AcceptInviteStateCopyWith(_AcceptInviteState value, $Res Function(_AcceptInviteState) _then) = __$AcceptInviteStateCopyWithImpl;
@override @useResult
$Res call({
 String token, AcceptInviteValidationStatus validationStatus, InviteAcceptanceOutcome outcome, String? organizationId, String? organizationName, String? invitedEmail, SystemRoleName? roleName, bool hasActiveSession, bool sessionEmailMismatch, AcceptInviteAcceptanceStatus acceptanceStatus, String? acceptedOrganizationId, Failure? failure
});




}
/// @nodoc
class __$AcceptInviteStateCopyWithImpl<$Res>
    implements _$AcceptInviteStateCopyWith<$Res> {
  __$AcceptInviteStateCopyWithImpl(this._self, this._then);

  final _AcceptInviteState _self;
  final $Res Function(_AcceptInviteState) _then;

/// Create a copy of AcceptInviteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? validationStatus = null,Object? outcome = null,Object? organizationId = freezed,Object? organizationName = freezed,Object? invitedEmail = freezed,Object? roleName = freezed,Object? hasActiveSession = null,Object? sessionEmailMismatch = null,Object? acceptanceStatus = null,Object? acceptedOrganizationId = freezed,Object? failure = freezed,}) {
  return _then(_AcceptInviteState(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,validationStatus: null == validationStatus ? _self.validationStatus : validationStatus // ignore: cast_nullable_to_non_nullable
as AcceptInviteValidationStatus,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as InviteAcceptanceOutcome,organizationId: freezed == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String?,organizationName: freezed == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String?,invitedEmail: freezed == invitedEmail ? _self.invitedEmail : invitedEmail // ignore: cast_nullable_to_non_nullable
as String?,roleName: freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,hasActiveSession: null == hasActiveSession ? _self.hasActiveSession : hasActiveSession // ignore: cast_nullable_to_non_nullable
as bool,sessionEmailMismatch: null == sessionEmailMismatch ? _self.sessionEmailMismatch : sessionEmailMismatch // ignore: cast_nullable_to_non_nullable
as bool,acceptanceStatus: null == acceptanceStatus ? _self.acceptanceStatus : acceptanceStatus // ignore: cast_nullable_to_non_nullable
as AcceptInviteAcceptanceStatus,acceptedOrganizationId: freezed == acceptedOrganizationId ? _self.acceptedOrganizationId : acceptedOrganizationId // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
