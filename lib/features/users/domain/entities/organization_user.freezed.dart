// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationUser {

 String get userId;/// Never blank: falls back to [userId] when the denormalized
/// `Membership.name` is missing (e.g. a Membership created before
/// TASK-042 denormalized it) — see [ListOrganizationUsersUseCase].
 String get name;/// Never blank: falls back to an empty string only when the
/// denormalized `Membership.email` is missing; `UserListPage` renders
/// that as an explicit "—", never a raw empty cell.
 String get email;/// The raw system role code (e.g. `'OWNER'`), exactly as stored on
/// `Membership.roleName` — never re-validated here.
 String get roleName; MembershipStatus get status; List<String> get teamIds;/// Resolved [Team.name]s for every id in [teamIds] that still exists
/// (non-deleted) in the organization — shorter than [teamIds] whenever
/// a team was deleted or could not be loaded; never throws for that.
 List<String> get teamNames;
/// Create a copy of OrganizationUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationUserCopyWith<OrganizationUser> get copyWith => _$OrganizationUserCopyWithImpl<OrganizationUser>(this as OrganizationUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationUser&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.teamIds, teamIds)&&const DeepCollectionEquality().equals(other.teamNames, teamNames));
}


@override
int get hashCode => Object.hash(runtimeType,userId,name,email,roleName,status,const DeepCollectionEquality().hash(teamIds),const DeepCollectionEquality().hash(teamNames));

@override
String toString() {
  return 'OrganizationUser(userId: $userId, name: $name, email: $email, roleName: $roleName, status: $status, teamIds: $teamIds, teamNames: $teamNames)';
}


}

/// @nodoc
abstract mixin class $OrganizationUserCopyWith<$Res>  {
  factory $OrganizationUserCopyWith(OrganizationUser value, $Res Function(OrganizationUser) _then) = _$OrganizationUserCopyWithImpl;
@useResult
$Res call({
 String userId, String name, String email, String roleName, MembershipStatus status, List<String> teamIds, List<String> teamNames
});




}
/// @nodoc
class _$OrganizationUserCopyWithImpl<$Res>
    implements $OrganizationUserCopyWith<$Res> {
  _$OrganizationUserCopyWithImpl(this._self, this._then);

  final OrganizationUser _self;
  final $Res Function(OrganizationUser) _then;

/// Create a copy of OrganizationUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? name = null,Object? email = null,Object? roleName = null,Object? status = null,Object? teamIds = null,Object? teamNames = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus,teamIds: null == teamIds ? _self.teamIds : teamIds // ignore: cast_nullable_to_non_nullable
as List<String>,teamNames: null == teamNames ? _self.teamNames : teamNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationUser].
extension OrganizationUserPatterns on OrganizationUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationUser value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationUser value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String name,  String email,  String roleName,  MembershipStatus status,  List<String> teamIds,  List<String> teamNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationUser() when $default != null:
return $default(_that.userId,_that.name,_that.email,_that.roleName,_that.status,_that.teamIds,_that.teamNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String name,  String email,  String roleName,  MembershipStatus status,  List<String> teamIds,  List<String> teamNames)  $default,) {final _that = this;
switch (_that) {
case _OrganizationUser():
return $default(_that.userId,_that.name,_that.email,_that.roleName,_that.status,_that.teamIds,_that.teamNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String name,  String email,  String roleName,  MembershipStatus status,  List<String> teamIds,  List<String> teamNames)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationUser() when $default != null:
return $default(_that.userId,_that.name,_that.email,_that.roleName,_that.status,_that.teamIds,_that.teamNames);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationUser implements OrganizationUser {
  const _OrganizationUser({required this.userId, required this.name, required this.email, required this.roleName, required this.status, final  List<String> teamIds = const <String>[], final  List<String> teamNames = const <String>[]}): _teamIds = teamIds,_teamNames = teamNames;
  

@override final  String userId;
/// Never blank: falls back to [userId] when the denormalized
/// `Membership.name` is missing (e.g. a Membership created before
/// TASK-042 denormalized it) — see [ListOrganizationUsersUseCase].
@override final  String name;
/// Never blank: falls back to an empty string only when the
/// denormalized `Membership.email` is missing; `UserListPage` renders
/// that as an explicit "—", never a raw empty cell.
@override final  String email;
/// The raw system role code (e.g. `'OWNER'`), exactly as stored on
/// `Membership.roleName` — never re-validated here.
@override final  String roleName;
@override final  MembershipStatus status;
 final  List<String> _teamIds;
@override@JsonKey() List<String> get teamIds {
  if (_teamIds is EqualUnmodifiableListView) return _teamIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamIds);
}

/// Resolved [Team.name]s for every id in [teamIds] that still exists
/// (non-deleted) in the organization — shorter than [teamIds] whenever
/// a team was deleted or could not be loaded; never throws for that.
 final  List<String> _teamNames;
/// Resolved [Team.name]s for every id in [teamIds] that still exists
/// (non-deleted) in the organization — shorter than [teamIds] whenever
/// a team was deleted or could not be loaded; never throws for that.
@override@JsonKey() List<String> get teamNames {
  if (_teamNames is EqualUnmodifiableListView) return _teamNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamNames);
}


/// Create a copy of OrganizationUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationUserCopyWith<_OrganizationUser> get copyWith => __$OrganizationUserCopyWithImpl<_OrganizationUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationUser&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._teamIds, _teamIds)&&const DeepCollectionEquality().equals(other._teamNames, _teamNames));
}


@override
int get hashCode => Object.hash(runtimeType,userId,name,email,roleName,status,const DeepCollectionEquality().hash(_teamIds),const DeepCollectionEquality().hash(_teamNames));

@override
String toString() {
  return 'OrganizationUser(userId: $userId, name: $name, email: $email, roleName: $roleName, status: $status, teamIds: $teamIds, teamNames: $teamNames)';
}


}

/// @nodoc
abstract mixin class _$OrganizationUserCopyWith<$Res> implements $OrganizationUserCopyWith<$Res> {
  factory _$OrganizationUserCopyWith(_OrganizationUser value, $Res Function(_OrganizationUser) _then) = __$OrganizationUserCopyWithImpl;
@override @useResult
$Res call({
 String userId, String name, String email, String roleName, MembershipStatus status, List<String> teamIds, List<String> teamNames
});




}
/// @nodoc
class __$OrganizationUserCopyWithImpl<$Res>
    implements _$OrganizationUserCopyWith<$Res> {
  __$OrganizationUserCopyWithImpl(this._self, this._then);

  final _OrganizationUser _self;
  final $Res Function(_OrganizationUser) _then;

/// Create a copy of OrganizationUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? name = null,Object? email = null,Object? roleName = null,Object? status = null,Object? teamIds = null,Object? teamNames = null,}) {
  return _then(_OrganizationUser(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus,teamIds: null == teamIds ? _self._teamIds : teamIds // ignore: cast_nullable_to_non_nullable
as List<String>,teamNames: null == teamNames ? _self._teamNames : teamNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
