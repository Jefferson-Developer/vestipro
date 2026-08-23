// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserListState {

 UserListLoadStatus get loadStatus; String get organizationId;/// Every user of the organization, unfiltered and unpaginated — the
/// single result of [ListOrganizationUsersUseCase]. `UserListBloc`
/// applies [searchQuery]/[roleFilter]/[statusFilter] and pagination
/// entirely in memory on top of this list: an internal (not a raw
/// Firestore) roster is the only way to search by name/e-mail at all,
/// since `Membership`/`users/{uid}` cannot be joined by a Firestore
/// query — see `ListOrganizationUsersUseCase`'s own docs.
 List<OrganizationUser> get allUsers;/// Only meaningful when [loadStatus] is [UserListLoadStatus.failure].
 Failure? get loadFailure; String get searchQuery; String? get roleFilter; MembershipStatus? get statusFilter;/// How many of [filteredUsers] are currently revealed
/// (`AppPagination`'s "carregar mais"). Reset to [kUserListPageSize]
/// whenever [searchQuery]/[roleFilter]/[statusFilter] changes.
 int get visibleCount;
/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListStateCopyWith<UserListState> get copyWith => _$UserListStateCopyWithImpl<UserListState>(this as UserListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other.allUsers, allUsers)&&(identical(other.loadFailure, loadFailure) || other.loadFailure == loadFailure)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.roleFilter, roleFilter) || other.roleFilter == roleFilter)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.visibleCount, visibleCount) || other.visibleCount == visibleCount));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,const DeepCollectionEquality().hash(allUsers),loadFailure,searchQuery,roleFilter,statusFilter,visibleCount);

@override
String toString() {
  return 'UserListState(loadStatus: $loadStatus, organizationId: $organizationId, allUsers: $allUsers, loadFailure: $loadFailure, searchQuery: $searchQuery, roleFilter: $roleFilter, statusFilter: $statusFilter, visibleCount: $visibleCount)';
}


}

/// @nodoc
abstract mixin class $UserListStateCopyWith<$Res>  {
  factory $UserListStateCopyWith(UserListState value, $Res Function(UserListState) _then) = _$UserListStateCopyWithImpl;
@useResult
$Res call({
 UserListLoadStatus loadStatus, String organizationId, List<OrganizationUser> allUsers, Failure? loadFailure, String searchQuery, String? roleFilter, MembershipStatus? statusFilter, int visibleCount
});




}
/// @nodoc
class _$UserListStateCopyWithImpl<$Res>
    implements $UserListStateCopyWith<$Res> {
  _$UserListStateCopyWithImpl(this._self, this._then);

  final UserListState _self;
  final $Res Function(UserListState) _then;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadStatus = null,Object? organizationId = null,Object? allUsers = null,Object? loadFailure = freezed,Object? searchQuery = null,Object? roleFilter = freezed,Object? statusFilter = freezed,Object? visibleCount = null,}) {
  return _then(_self.copyWith(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as UserListLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,allUsers: null == allUsers ? _self.allUsers : allUsers // ignore: cast_nullable_to_non_nullable
as List<OrganizationUser>,loadFailure: freezed == loadFailure ? _self.loadFailure : loadFailure // ignore: cast_nullable_to_non_nullable
as Failure?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,roleFilter: freezed == roleFilter ? _self.roleFilter : roleFilter // ignore: cast_nullable_to_non_nullable
as String?,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as MembershipStatus?,visibleCount: null == visibleCount ? _self.visibleCount : visibleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserListState].
extension UserListStatePatterns on UserListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserListState value)  $default,){
final _that = this;
switch (_that) {
case _UserListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserListState value)?  $default,){
final _that = this;
switch (_that) {
case _UserListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserListLoadStatus loadStatus,  String organizationId,  List<OrganizationUser> allUsers,  Failure? loadFailure,  String searchQuery,  String? roleFilter,  MembershipStatus? statusFilter,  int visibleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserListState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.allUsers,_that.loadFailure,_that.searchQuery,_that.roleFilter,_that.statusFilter,_that.visibleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserListLoadStatus loadStatus,  String organizationId,  List<OrganizationUser> allUsers,  Failure? loadFailure,  String searchQuery,  String? roleFilter,  MembershipStatus? statusFilter,  int visibleCount)  $default,) {final _that = this;
switch (_that) {
case _UserListState():
return $default(_that.loadStatus,_that.organizationId,_that.allUsers,_that.loadFailure,_that.searchQuery,_that.roleFilter,_that.statusFilter,_that.visibleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserListLoadStatus loadStatus,  String organizationId,  List<OrganizationUser> allUsers,  Failure? loadFailure,  String searchQuery,  String? roleFilter,  MembershipStatus? statusFilter,  int visibleCount)?  $default,) {final _that = this;
switch (_that) {
case _UserListState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.allUsers,_that.loadFailure,_that.searchQuery,_that.roleFilter,_that.statusFilter,_that.visibleCount);case _:
  return null;

}
}

}

/// @nodoc


class _UserListState extends UserListState {
  const _UserListState({this.loadStatus = UserListLoadStatus.loading, this.organizationId = '', final  List<OrganizationUser> allUsers = const <OrganizationUser>[], this.loadFailure, this.searchQuery = '', this.roleFilter, this.statusFilter, this.visibleCount = kUserListPageSize}): _allUsers = allUsers,super._();
  

@override@JsonKey() final  UserListLoadStatus loadStatus;
@override@JsonKey() final  String organizationId;
/// Every user of the organization, unfiltered and unpaginated — the
/// single result of [ListOrganizationUsersUseCase]. `UserListBloc`
/// applies [searchQuery]/[roleFilter]/[statusFilter] and pagination
/// entirely in memory on top of this list: an internal (not a raw
/// Firestore) roster is the only way to search by name/e-mail at all,
/// since `Membership`/`users/{uid}` cannot be joined by a Firestore
/// query — see `ListOrganizationUsersUseCase`'s own docs.
 final  List<OrganizationUser> _allUsers;
/// Every user of the organization, unfiltered and unpaginated — the
/// single result of [ListOrganizationUsersUseCase]. `UserListBloc`
/// applies [searchQuery]/[roleFilter]/[statusFilter] and pagination
/// entirely in memory on top of this list: an internal (not a raw
/// Firestore) roster is the only way to search by name/e-mail at all,
/// since `Membership`/`users/{uid}` cannot be joined by a Firestore
/// query — see `ListOrganizationUsersUseCase`'s own docs.
@override@JsonKey() List<OrganizationUser> get allUsers {
  if (_allUsers is EqualUnmodifiableListView) return _allUsers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allUsers);
}

/// Only meaningful when [loadStatus] is [UserListLoadStatus.failure].
@override final  Failure? loadFailure;
@override@JsonKey() final  String searchQuery;
@override final  String? roleFilter;
@override final  MembershipStatus? statusFilter;
/// How many of [filteredUsers] are currently revealed
/// (`AppPagination`'s "carregar mais"). Reset to [kUserListPageSize]
/// whenever [searchQuery]/[roleFilter]/[statusFilter] changes.
@override@JsonKey() final  int visibleCount;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserListStateCopyWith<_UserListState> get copyWith => __$UserListStateCopyWithImpl<_UserListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserListState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other._allUsers, _allUsers)&&(identical(other.loadFailure, loadFailure) || other.loadFailure == loadFailure)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.roleFilter, roleFilter) || other.roleFilter == roleFilter)&&(identical(other.statusFilter, statusFilter) || other.statusFilter == statusFilter)&&(identical(other.visibleCount, visibleCount) || other.visibleCount == visibleCount));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,const DeepCollectionEquality().hash(_allUsers),loadFailure,searchQuery,roleFilter,statusFilter,visibleCount);

@override
String toString() {
  return 'UserListState(loadStatus: $loadStatus, organizationId: $organizationId, allUsers: $allUsers, loadFailure: $loadFailure, searchQuery: $searchQuery, roleFilter: $roleFilter, statusFilter: $statusFilter, visibleCount: $visibleCount)';
}


}

/// @nodoc
abstract mixin class _$UserListStateCopyWith<$Res> implements $UserListStateCopyWith<$Res> {
  factory _$UserListStateCopyWith(_UserListState value, $Res Function(_UserListState) _then) = __$UserListStateCopyWithImpl;
@override @useResult
$Res call({
 UserListLoadStatus loadStatus, String organizationId, List<OrganizationUser> allUsers, Failure? loadFailure, String searchQuery, String? roleFilter, MembershipStatus? statusFilter, int visibleCount
});




}
/// @nodoc
class __$UserListStateCopyWithImpl<$Res>
    implements _$UserListStateCopyWith<$Res> {
  __$UserListStateCopyWithImpl(this._self, this._then);

  final _UserListState _self;
  final $Res Function(_UserListState) _then;

/// Create a copy of UserListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadStatus = null,Object? organizationId = null,Object? allUsers = null,Object? loadFailure = freezed,Object? searchQuery = null,Object? roleFilter = freezed,Object? statusFilter = freezed,Object? visibleCount = null,}) {
  return _then(_UserListState(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as UserListLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,allUsers: null == allUsers ? _self._allUsers : allUsers // ignore: cast_nullable_to_non_nullable
as List<OrganizationUser>,loadFailure: freezed == loadFailure ? _self.loadFailure : loadFailure // ignore: cast_nullable_to_non_nullable
as Failure?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,roleFilter: freezed == roleFilter ? _self.roleFilter : roleFilter // ignore: cast_nullable_to_non_nullable
as String?,statusFilter: freezed == statusFilter ? _self.statusFilter : statusFilter // ignore: cast_nullable_to_non_nullable
as MembershipStatus?,visibleCount: null == visibleCount ? _self.visibleCount : visibleCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
