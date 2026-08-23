// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_list_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListEvent()';
}


}

/// @nodoc
class $UserListEventCopyWith<$Res>  {
$UserListEventCopyWith(UserListEvent _, $Res Function(UserListEvent) __);
}


/// Adds pattern-matching-related methods to [UserListEvent].
extension UserListEventPatterns on UserListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserListStarted value)?  started,TResult Function( UserListRefreshRequested value)?  refreshRequested,TResult Function( UserListSearchChanged value)?  searchChanged,TResult Function( UserListRoleFilterChanged value)?  roleFilterChanged,TResult Function( UserListStatusFilterChanged value)?  statusFilterChanged,TResult Function( UserListLoadMoreRequested value)?  loadMoreRequested,TResult Function( UserListAccessStatusChangeRequested value)?  accessStatusChangeRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserListStarted() when started != null:
return started(_that);case UserListRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case UserListSearchChanged() when searchChanged != null:
return searchChanged(_that);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case UserListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested(_that);case UserListAccessStatusChangeRequested() when accessStatusChangeRequested != null:
return accessStatusChangeRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserListStarted value)  started,required TResult Function( UserListRefreshRequested value)  refreshRequested,required TResult Function( UserListSearchChanged value)  searchChanged,required TResult Function( UserListRoleFilterChanged value)  roleFilterChanged,required TResult Function( UserListStatusFilterChanged value)  statusFilterChanged,required TResult Function( UserListLoadMoreRequested value)  loadMoreRequested,required TResult Function( UserListAccessStatusChangeRequested value)  accessStatusChangeRequested,}){
final _that = this;
switch (_that) {
case UserListStarted():
return started(_that);case UserListRefreshRequested():
return refreshRequested(_that);case UserListSearchChanged():
return searchChanged(_that);case UserListRoleFilterChanged():
return roleFilterChanged(_that);case UserListStatusFilterChanged():
return statusFilterChanged(_that);case UserListLoadMoreRequested():
return loadMoreRequested(_that);case UserListAccessStatusChangeRequested():
return accessStatusChangeRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserListStarted value)?  started,TResult? Function( UserListRefreshRequested value)?  refreshRequested,TResult? Function( UserListSearchChanged value)?  searchChanged,TResult? Function( UserListRoleFilterChanged value)?  roleFilterChanged,TResult? Function( UserListStatusFilterChanged value)?  statusFilterChanged,TResult? Function( UserListLoadMoreRequested value)?  loadMoreRequested,TResult? Function( UserListAccessStatusChangeRequested value)?  accessStatusChangeRequested,}){
final _that = this;
switch (_that) {
case UserListStarted() when started != null:
return started(_that);case UserListRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case UserListSearchChanged() when searchChanged != null:
return searchChanged(_that);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case UserListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested(_that);case UserListAccessStatusChangeRequested() when accessStatusChangeRequested != null:
return accessStatusChangeRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String organizationId)?  started,TResult Function()?  refreshRequested,TResult Function( String query)?  searchChanged,TResult Function( String? roleName)?  roleFilterChanged,TResult Function( MembershipStatus? status)?  statusFilterChanged,TResult Function()?  loadMoreRequested,TResult Function( OrganizationUser user)?  accessStatusChangeRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserListStarted() when started != null:
return started(_that.organizationId);case UserListRefreshRequested() when refreshRequested != null:
return refreshRequested();case UserListSearchChanged() when searchChanged != null:
return searchChanged(_that.query);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that.roleName);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case UserListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested();case UserListAccessStatusChangeRequested() when accessStatusChangeRequested != null:
return accessStatusChangeRequested(_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String organizationId)  started,required TResult Function()  refreshRequested,required TResult Function( String query)  searchChanged,required TResult Function( String? roleName)  roleFilterChanged,required TResult Function( MembershipStatus? status)  statusFilterChanged,required TResult Function()  loadMoreRequested,required TResult Function( OrganizationUser user)  accessStatusChangeRequested,}) {final _that = this;
switch (_that) {
case UserListStarted():
return started(_that.organizationId);case UserListRefreshRequested():
return refreshRequested();case UserListSearchChanged():
return searchChanged(_that.query);case UserListRoleFilterChanged():
return roleFilterChanged(_that.roleName);case UserListStatusFilterChanged():
return statusFilterChanged(_that.status);case UserListLoadMoreRequested():
return loadMoreRequested();case UserListAccessStatusChangeRequested():
return accessStatusChangeRequested(_that.user);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String organizationId)?  started,TResult? Function()?  refreshRequested,TResult? Function( String query)?  searchChanged,TResult? Function( String? roleName)?  roleFilterChanged,TResult? Function( MembershipStatus? status)?  statusFilterChanged,TResult? Function()?  loadMoreRequested,TResult? Function( OrganizationUser user)?  accessStatusChangeRequested,}) {final _that = this;
switch (_that) {
case UserListStarted() when started != null:
return started(_that.organizationId);case UserListRefreshRequested() when refreshRequested != null:
return refreshRequested();case UserListSearchChanged() when searchChanged != null:
return searchChanged(_that.query);case UserListRoleFilterChanged() when roleFilterChanged != null:
return roleFilterChanged(_that.roleName);case UserListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case UserListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested();case UserListAccessStatusChangeRequested() when accessStatusChangeRequested != null:
return accessStatusChangeRequested(_that.user);case _:
  return null;

}
}

}

/// @nodoc


class UserListStarted implements UserListEvent {
  const UserListStarted(this.organizationId);


 final  String organizationId;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListStartedCopyWith<UserListStarted> get copyWith => _$UserListStartedCopyWithImpl<UserListStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListStarted&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId);

@override
String toString() {
  return 'UserListEvent.started(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class $UserListStartedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListStartedCopyWith(UserListStarted value, $Res Function(UserListStarted) _then) = _$UserListStartedCopyWithImpl;
@useResult
$Res call({
 String organizationId
});




}
/// @nodoc
class _$UserListStartedCopyWithImpl<$Res>
    implements $UserListStartedCopyWith<$Res> {
  _$UserListStartedCopyWithImpl(this._self, this._then);

  final UserListStarted _self;
  final $Res Function(UserListStarted) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = null,}) {
  return _then(UserListStarted(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UserListRefreshRequested implements UserListEvent {
  const UserListRefreshRequested();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListRefreshRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListEvent.refreshRequested()';
}


}




/// @nodoc


class UserListSearchChanged implements UserListEvent {
  const UserListSearchChanged(this.query);
  

 final  String query;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListSearchChangedCopyWith<UserListSearchChanged> get copyWith => _$UserListSearchChangedCopyWithImpl<UserListSearchChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListSearchChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'UserListEvent.searchChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class $UserListSearchChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListSearchChangedCopyWith(UserListSearchChanged value, $Res Function(UserListSearchChanged) _then) = _$UserListSearchChangedCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$UserListSearchChangedCopyWithImpl<$Res>
    implements $UserListSearchChangedCopyWith<$Res> {
  _$UserListSearchChangedCopyWithImpl(this._self, this._then);

  final UserListSearchChanged _self;
  final $Res Function(UserListSearchChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(UserListSearchChanged(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UserListRoleFilterChanged implements UserListEvent {
  const UserListRoleFilterChanged(this.roleName);
  

 final  String? roleName;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListRoleFilterChangedCopyWith<UserListRoleFilterChanged> get copyWith => _$UserListRoleFilterChangedCopyWithImpl<UserListRoleFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListRoleFilterChanged&&(identical(other.roleName, roleName) || other.roleName == roleName));
}


@override
int get hashCode => Object.hash(runtimeType,roleName);

@override
String toString() {
  return 'UserListEvent.roleFilterChanged(roleName: $roleName)';
}


}

/// @nodoc
abstract mixin class $UserListRoleFilterChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListRoleFilterChangedCopyWith(UserListRoleFilterChanged value, $Res Function(UserListRoleFilterChanged) _then) = _$UserListRoleFilterChangedCopyWithImpl;
@useResult
$Res call({
 String? roleName
});




}
/// @nodoc
class _$UserListRoleFilterChangedCopyWithImpl<$Res>
    implements $UserListRoleFilterChangedCopyWith<$Res> {
  _$UserListRoleFilterChangedCopyWithImpl(this._self, this._then);

  final UserListRoleFilterChanged _self;
  final $Res Function(UserListRoleFilterChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roleName = freezed,}) {
  return _then(UserListRoleFilterChanged(
freezed == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UserListStatusFilterChanged implements UserListEvent {
  const UserListStatusFilterChanged(this.status);
  

 final  MembershipStatus? status;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListStatusFilterChangedCopyWith<UserListStatusFilterChanged> get copyWith => _$UserListStatusFilterChangedCopyWithImpl<UserListStatusFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListStatusFilterChanged&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'UserListEvent.statusFilterChanged(status: $status)';
}


}

/// @nodoc
abstract mixin class $UserListStatusFilterChangedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListStatusFilterChangedCopyWith(UserListStatusFilterChanged value, $Res Function(UserListStatusFilterChanged) _then) = _$UserListStatusFilterChangedCopyWithImpl;
@useResult
$Res call({
 MembershipStatus? status
});




}
/// @nodoc
class _$UserListStatusFilterChangedCopyWithImpl<$Res>
    implements $UserListStatusFilterChangedCopyWith<$Res> {
  _$UserListStatusFilterChangedCopyWithImpl(this._self, this._then);

  final UserListStatusFilterChanged _self;
  final $Res Function(UserListStatusFilterChanged) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(UserListStatusFilterChanged(
freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MembershipStatus?,
  ));
}


}

/// @nodoc


class UserListLoadMoreRequested implements UserListEvent {
  const UserListLoadMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListLoadMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserListEvent.loadMoreRequested()';
}


}




/// @nodoc


class UserListAccessStatusChangeRequested implements UserListEvent {
  const UserListAccessStatusChangeRequested(this.user);


 final  OrganizationUser user;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserListAccessStatusChangeRequestedCopyWith<UserListAccessStatusChangeRequested> get copyWith => _$UserListAccessStatusChangeRequestedCopyWithImpl<UserListAccessStatusChangeRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserListAccessStatusChangeRequested&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'UserListEvent.accessStatusChangeRequested(user: $user)';
}


}

/// @nodoc
abstract mixin class $UserListAccessStatusChangeRequestedCopyWith<$Res> implements $UserListEventCopyWith<$Res> {
  factory $UserListAccessStatusChangeRequestedCopyWith(UserListAccessStatusChangeRequested value, $Res Function(UserListAccessStatusChangeRequested) _then) = _$UserListAccessStatusChangeRequestedCopyWithImpl;
@useResult
$Res call({
 OrganizationUser user
});


$OrganizationUserCopyWith<$Res> get user;

}
/// @nodoc
class _$UserListAccessStatusChangeRequestedCopyWithImpl<$Res>
    implements $UserListAccessStatusChangeRequestedCopyWith<$Res> {
  _$UserListAccessStatusChangeRequestedCopyWithImpl(this._self, this._then);

  final UserListAccessStatusChangeRequested _self;
  final $Res Function(UserListAccessStatusChangeRequested) _then;

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(UserListAccessStatusChangeRequested(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as OrganizationUser,
  ));
}

/// Create a copy of UserListEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationUserCopyWith<$Res> get user {

  return $OrganizationUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
