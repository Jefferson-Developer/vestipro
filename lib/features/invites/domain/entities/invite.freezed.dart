// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Invite {

 String get id; String get organizationId; String get email; SystemRoleName get roleName; InviteStatus get status; String get invitedByUserId; String get invitedByName; String? get message; DateTime get expiresAt; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy;
/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCopyWith<Invite> get copyWith => _$InviteCopyWithImpl<Invite>(this as Invite, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.status, status) || other.status == status)&&(identical(other.invitedByUserId, invitedByUserId) || other.invitedByUserId == invitedByUserId)&&(identical(other.invitedByName, invitedByName) || other.invitedByName == invitedByName)&&(identical(other.message, message) || other.message == message)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,email,roleName,status,invitedByUserId,invitedByName,message,expiresAt,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'Invite(id: $id, organizationId: $organizationId, email: $email, roleName: $roleName, status: $status, invitedByUserId: $invitedByUserId, invitedByName: $invitedByName, message: $message, expiresAt: $expiresAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $InviteCopyWith<$Res>  {
  factory $InviteCopyWith(Invite value, $Res Function(Invite) _then) = _$InviteCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String email, SystemRoleName roleName, InviteStatus status, String invitedByUserId, String invitedByName, String? message, DateTime expiresAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class _$InviteCopyWithImpl<$Res>
    implements $InviteCopyWith<$Res> {
  _$InviteCopyWithImpl(this._self, this._then);

  final Invite _self;
  final $Res Function(Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? email = null,Object? roleName = null,Object? status = null,Object? invitedByUserId = null,Object? invitedByName = null,Object? message = freezed,Object? expiresAt = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as SystemRoleName,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,invitedByUserId: null == invitedByUserId ? _self.invitedByUserId : invitedByUserId // ignore: cast_nullable_to_non_nullable
as String,invitedByName: null == invitedByName ? _self.invitedByName : invitedByName // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Invite].
extension InvitePatterns on Invite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invite value)  $default,){
final _that = this;
switch (_that) {
case _Invite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invite value)?  $default,){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String email,  SystemRoleName roleName,  InviteStatus status,  String invitedByUserId,  String invitedByName,  String? message,  DateTime expiresAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.organizationId,_that.email,_that.roleName,_that.status,_that.invitedByUserId,_that.invitedByName,_that.message,_that.expiresAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String email,  SystemRoleName roleName,  InviteStatus status,  String invitedByUserId,  String invitedByName,  String? message,  DateTime expiresAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)  $default,) {final _that = this;
switch (_that) {
case _Invite():
return $default(_that.id,_that.organizationId,_that.email,_that.roleName,_that.status,_that.invitedByUserId,_that.invitedByName,_that.message,_that.expiresAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String email,  SystemRoleName roleName,  InviteStatus status,  String invitedByUserId,  String invitedByName,  String? message,  DateTime expiresAt,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.organizationId,_that.email,_that.roleName,_that.status,_that.invitedByUserId,_that.invitedByName,_that.message,_that.expiresAt,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc


class _Invite implements Invite {
  const _Invite({required this.id, required this.organizationId, required this.email, required this.roleName, required this.status, required this.invitedByUserId, required this.invitedByName, this.message, required this.expiresAt, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy});
  

@override final  String id;
@override final  String organizationId;
@override final  String email;
@override final  SystemRoleName roleName;
@override final  InviteStatus status;
@override final  String invitedByUserId;
@override final  String invitedByName;
@override final  String? message;
@override final  DateTime expiresAt;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCopyWith<_Invite> get copyWith => __$InviteCopyWithImpl<_Invite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.email, email) || other.email == email)&&(identical(other.roleName, roleName) || other.roleName == roleName)&&(identical(other.status, status) || other.status == status)&&(identical(other.invitedByUserId, invitedByUserId) || other.invitedByUserId == invitedByUserId)&&(identical(other.invitedByName, invitedByName) || other.invitedByName == invitedByName)&&(identical(other.message, message) || other.message == message)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,email,roleName,status,invitedByUserId,invitedByName,message,expiresAt,createdAt,createdBy,updatedAt,updatedBy);

@override
String toString() {
  return 'Invite(id: $id, organizationId: $organizationId, email: $email, roleName: $roleName, status: $status, invitedByUserId: $invitedByUserId, invitedByName: $invitedByName, message: $message, expiresAt: $expiresAt, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$InviteCopyWith<$Res> implements $InviteCopyWith<$Res> {
  factory _$InviteCopyWith(_Invite value, $Res Function(_Invite) _then) = __$InviteCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String email, SystemRoleName roleName, InviteStatus status, String invitedByUserId, String invitedByName, String? message, DateTime expiresAt, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy
});




}
/// @nodoc
class __$InviteCopyWithImpl<$Res>
    implements _$InviteCopyWith<$Res> {
  __$InviteCopyWithImpl(this._self, this._then);

  final _Invite _self;
  final $Res Function(_Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? email = null,Object? roleName = null,Object? status = null,Object? invitedByUserId = null,Object? invitedByName = null,Object? message = freezed,Object? expiresAt = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,}) {
  return _then(_Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roleName: null == roleName ? _self.roleName : roleName // ignore: cast_nullable_to_non_nullable
as SystemRoleName,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InviteStatus,invitedByUserId: null == invitedByUserId ? _self.invitedByUserId : invitedByUserId // ignore: cast_nullable_to_non_nullable
as String,invitedByName: null == invitedByName ? _self.invitedByName : invitedByName // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
