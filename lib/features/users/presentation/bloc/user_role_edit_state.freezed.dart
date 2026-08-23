// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_role_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserRoleEditState {

 UserRoleEditLoadStatus get loadStatus; String get organizationId; OrganizationUser? get user; SystemRoleName? get currentRole; SystemRoleName? get selectedRole; List<SystemRoleName> get assignableRoles; String? get roleError; UserRoleEditSubmissionStatus get submissionStatus; Failure? get failure; UserRoleUpdateResult? get result;
/// Create a copy of UserRoleEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRoleEditStateCopyWith<UserRoleEditState> get copyWith => _$UserRoleEditStateCopyWithImpl<UserRoleEditState>(this as UserRoleEditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRoleEditState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.user, user) || other.user == user)&&(identical(other.currentRole, currentRole) || other.currentRole == currentRole)&&(identical(other.selectedRole, selectedRole) || other.selectedRole == selectedRole)&&const DeepCollectionEquality().equals(other.assignableRoles, assignableRoles)&&(identical(other.roleError, roleError) || other.roleError == roleError)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,user,currentRole,selectedRole,const DeepCollectionEquality().hash(assignableRoles),roleError,submissionStatus,failure,result);

@override
String toString() {
  return 'UserRoleEditState(loadStatus: $loadStatus, organizationId: $organizationId, user: $user, currentRole: $currentRole, selectedRole: $selectedRole, assignableRoles: $assignableRoles, roleError: $roleError, submissionStatus: $submissionStatus, failure: $failure, result: $result)';
}


}

/// @nodoc
abstract mixin class $UserRoleEditStateCopyWith<$Res>  {
  factory $UserRoleEditStateCopyWith(UserRoleEditState value, $Res Function(UserRoleEditState) _then) = _$UserRoleEditStateCopyWithImpl;
@useResult
$Res call({
 UserRoleEditLoadStatus loadStatus, String organizationId, OrganizationUser? user, SystemRoleName? currentRole, SystemRoleName? selectedRole, List<SystemRoleName> assignableRoles, String? roleError, UserRoleEditSubmissionStatus submissionStatus, Failure? failure, UserRoleUpdateResult? result
});


$OrganizationUserCopyWith<$Res>? get user;

}
/// @nodoc
class _$UserRoleEditStateCopyWithImpl<$Res>
    implements $UserRoleEditStateCopyWith<$Res> {
  _$UserRoleEditStateCopyWithImpl(this._self, this._then);

  final UserRoleEditState _self;
  final $Res Function(UserRoleEditState) _then;

/// Create a copy of UserRoleEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadStatus = null,Object? organizationId = null,Object? user = freezed,Object? currentRole = freezed,Object? selectedRole = freezed,Object? assignableRoles = null,Object? roleError = freezed,Object? submissionStatus = null,Object? failure = freezed,Object? result = freezed,}) {
  return _then(_self.copyWith(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as UserRoleEditLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as OrganizationUser?,currentRole: freezed == currentRole ? _self.currentRole : currentRole // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,selectedRole: freezed == selectedRole ? _self.selectedRole : selectedRole // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,assignableRoles: null == assignableRoles ? _self.assignableRoles : assignableRoles // ignore: cast_nullable_to_non_nullable
as List<SystemRoleName>,roleError: freezed == roleError ? _self.roleError : roleError // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as UserRoleEditSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as UserRoleUpdateResult?,
  ));
}
/// Create a copy of UserRoleEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $OrganizationUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserRoleEditState].
extension UserRoleEditStatePatterns on UserRoleEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserRoleEditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserRoleEditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserRoleEditState value)  $default,){
final _that = this;
switch (_that) {
case _UserRoleEditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserRoleEditState value)?  $default,){
final _that = this;
switch (_that) {
case _UserRoleEditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserRoleEditLoadStatus loadStatus,  String organizationId,  OrganizationUser? user,  SystemRoleName? currentRole,  SystemRoleName? selectedRole,  List<SystemRoleName> assignableRoles,  String? roleError,  UserRoleEditSubmissionStatus submissionStatus,  Failure? failure,  UserRoleUpdateResult? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserRoleEditState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.user,_that.currentRole,_that.selectedRole,_that.assignableRoles,_that.roleError,_that.submissionStatus,_that.failure,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserRoleEditLoadStatus loadStatus,  String organizationId,  OrganizationUser? user,  SystemRoleName? currentRole,  SystemRoleName? selectedRole,  List<SystemRoleName> assignableRoles,  String? roleError,  UserRoleEditSubmissionStatus submissionStatus,  Failure? failure,  UserRoleUpdateResult? result)  $default,) {final _that = this;
switch (_that) {
case _UserRoleEditState():
return $default(_that.loadStatus,_that.organizationId,_that.user,_that.currentRole,_that.selectedRole,_that.assignableRoles,_that.roleError,_that.submissionStatus,_that.failure,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserRoleEditLoadStatus loadStatus,  String organizationId,  OrganizationUser? user,  SystemRoleName? currentRole,  SystemRoleName? selectedRole,  List<SystemRoleName> assignableRoles,  String? roleError,  UserRoleEditSubmissionStatus submissionStatus,  Failure? failure,  UserRoleUpdateResult? result)?  $default,) {final _that = this;
switch (_that) {
case _UserRoleEditState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.user,_that.currentRole,_that.selectedRole,_that.assignableRoles,_that.roleError,_that.submissionStatus,_that.failure,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _UserRoleEditState extends UserRoleEditState {
  const _UserRoleEditState({this.loadStatus = UserRoleEditLoadStatus.loading, this.organizationId = '', this.user, this.currentRole, this.selectedRole, final  List<SystemRoleName> assignableRoles = const <SystemRoleName>[], this.roleError, this.submissionStatus = UserRoleEditSubmissionStatus.idle, this.failure, this.result}): _assignableRoles = assignableRoles,super._();
  

@override@JsonKey() final  UserRoleEditLoadStatus loadStatus;
@override@JsonKey() final  String organizationId;
@override final  OrganizationUser? user;
@override final  SystemRoleName? currentRole;
@override final  SystemRoleName? selectedRole;
 final  List<SystemRoleName> _assignableRoles;
@override@JsonKey() List<SystemRoleName> get assignableRoles {
  if (_assignableRoles is EqualUnmodifiableListView) return _assignableRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignableRoles);
}

@override final  String? roleError;
@override@JsonKey() final  UserRoleEditSubmissionStatus submissionStatus;
@override final  Failure? failure;
@override final  UserRoleUpdateResult? result;

/// Create a copy of UserRoleEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserRoleEditStateCopyWith<_UserRoleEditState> get copyWith => __$UserRoleEditStateCopyWithImpl<_UserRoleEditState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserRoleEditState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.user, user) || other.user == user)&&(identical(other.currentRole, currentRole) || other.currentRole == currentRole)&&(identical(other.selectedRole, selectedRole) || other.selectedRole == selectedRole)&&const DeepCollectionEquality().equals(other._assignableRoles, _assignableRoles)&&(identical(other.roleError, roleError) || other.roleError == roleError)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,user,currentRole,selectedRole,const DeepCollectionEquality().hash(_assignableRoles),roleError,submissionStatus,failure,result);

@override
String toString() {
  return 'UserRoleEditState(loadStatus: $loadStatus, organizationId: $organizationId, user: $user, currentRole: $currentRole, selectedRole: $selectedRole, assignableRoles: $assignableRoles, roleError: $roleError, submissionStatus: $submissionStatus, failure: $failure, result: $result)';
}


}

/// @nodoc
abstract mixin class _$UserRoleEditStateCopyWith<$Res> implements $UserRoleEditStateCopyWith<$Res> {
  factory _$UserRoleEditStateCopyWith(_UserRoleEditState value, $Res Function(_UserRoleEditState) _then) = __$UserRoleEditStateCopyWithImpl;
@override @useResult
$Res call({
 UserRoleEditLoadStatus loadStatus, String organizationId, OrganizationUser? user, SystemRoleName? currentRole, SystemRoleName? selectedRole, List<SystemRoleName> assignableRoles, String? roleError, UserRoleEditSubmissionStatus submissionStatus, Failure? failure, UserRoleUpdateResult? result
});


@override $OrganizationUserCopyWith<$Res>? get user;

}
/// @nodoc
class __$UserRoleEditStateCopyWithImpl<$Res>
    implements _$UserRoleEditStateCopyWith<$Res> {
  __$UserRoleEditStateCopyWithImpl(this._self, this._then);

  final _UserRoleEditState _self;
  final $Res Function(_UserRoleEditState) _then;

/// Create a copy of UserRoleEditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadStatus = null,Object? organizationId = null,Object? user = freezed,Object? currentRole = freezed,Object? selectedRole = freezed,Object? assignableRoles = null,Object? roleError = freezed,Object? submissionStatus = null,Object? failure = freezed,Object? result = freezed,}) {
  return _then(_UserRoleEditState(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as UserRoleEditLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as OrganizationUser?,currentRole: freezed == currentRole ? _self.currentRole : currentRole // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,selectedRole: freezed == selectedRole ? _self.selectedRole : selectedRole // ignore: cast_nullable_to_non_nullable
as SystemRoleName?,assignableRoles: null == assignableRoles ? _self._assignableRoles : assignableRoles // ignore: cast_nullable_to_non_nullable
as List<SystemRoleName>,roleError: freezed == roleError ? _self.roleError : roleError // ignore: cast_nullable_to_non_nullable
as String?,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as UserRoleEditSubmissionStatus,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as UserRoleUpdateResult?,
  ));
}

/// Create a copy of UserRoleEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $OrganizationUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
