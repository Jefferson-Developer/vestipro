// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteListState {

 InviteListLoadStatus get loadStatus; String get organizationId; List<Invite> get invites;/// Only meaningful when [loadStatus] is [InviteListLoadStatus.failure].
 Failure? get loadFailure;/// The id of the invite currently being resent/revoked, so its row can
/// show a busy state while every other row stays interactive. `null`
/// when no resend/revoke is in flight.
 String? get processingInviteId;/// The result of the last successful resend — `InviteListPage` shows
/// its one-time [IssuedInvite.token] right after (see [IssuedInvite]'s
/// own docs for why it can never be retrieved again afterwards). Reset
/// to `null` on the next list load/resend/revoke.
 IssuedInvite? get lastResendResult;/// A resend/revoke that failed — shown once (e.g. a snackbar), then
/// expected to be cleared by the caller.
 Failure? get actionFailure;
/// Create a copy of InviteListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteListStateCopyWith<InviteListState> get copyWith => _$InviteListStateCopyWithImpl<InviteListState>(this as InviteListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteListState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other.invites, invites)&&(identical(other.loadFailure, loadFailure) || other.loadFailure == loadFailure)&&(identical(other.processingInviteId, processingInviteId) || other.processingInviteId == processingInviteId)&&(identical(other.lastResendResult, lastResendResult) || other.lastResendResult == lastResendResult)&&(identical(other.actionFailure, actionFailure) || other.actionFailure == actionFailure));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,const DeepCollectionEquality().hash(invites),loadFailure,processingInviteId,lastResendResult,actionFailure);

@override
String toString() {
  return 'InviteListState(loadStatus: $loadStatus, organizationId: $organizationId, invites: $invites, loadFailure: $loadFailure, processingInviteId: $processingInviteId, lastResendResult: $lastResendResult, actionFailure: $actionFailure)';
}


}

/// @nodoc
abstract mixin class $InviteListStateCopyWith<$Res>  {
  factory $InviteListStateCopyWith(InviteListState value, $Res Function(InviteListState) _then) = _$InviteListStateCopyWithImpl;
@useResult
$Res call({
 InviteListLoadStatus loadStatus, String organizationId, List<Invite> invites, Failure? loadFailure, String? processingInviteId, IssuedInvite? lastResendResult, Failure? actionFailure
});


$IssuedInviteCopyWith<$Res>? get lastResendResult;

}
/// @nodoc
class _$InviteListStateCopyWithImpl<$Res>
    implements $InviteListStateCopyWith<$Res> {
  _$InviteListStateCopyWithImpl(this._self, this._then);

  final InviteListState _self;
  final $Res Function(InviteListState) _then;

/// Create a copy of InviteListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadStatus = null,Object? organizationId = null,Object? invites = null,Object? loadFailure = freezed,Object? processingInviteId = freezed,Object? lastResendResult = freezed,Object? actionFailure = freezed,}) {
  return _then(_self.copyWith(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as InviteListLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,invites: null == invites ? _self.invites : invites // ignore: cast_nullable_to_non_nullable
as List<Invite>,loadFailure: freezed == loadFailure ? _self.loadFailure : loadFailure // ignore: cast_nullable_to_non_nullable
as Failure?,processingInviteId: freezed == processingInviteId ? _self.processingInviteId : processingInviteId // ignore: cast_nullable_to_non_nullable
as String?,lastResendResult: freezed == lastResendResult ? _self.lastResendResult : lastResendResult // ignore: cast_nullable_to_non_nullable
as IssuedInvite?,actionFailure: freezed == actionFailure ? _self.actionFailure : actionFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of InviteListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedInviteCopyWith<$Res>? get lastResendResult {
    if (_self.lastResendResult == null) {
    return null;
  }

  return $IssuedInviteCopyWith<$Res>(_self.lastResendResult!, (value) {
    return _then(_self.copyWith(lastResendResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [InviteListState].
extension InviteListStatePatterns on InviteListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteListState value)  $default,){
final _that = this;
switch (_that) {
case _InviteListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteListState value)?  $default,){
final _that = this;
switch (_that) {
case _InviteListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InviteListLoadStatus loadStatus,  String organizationId,  List<Invite> invites,  Failure? loadFailure,  String? processingInviteId,  IssuedInvite? lastResendResult,  Failure? actionFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteListState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.invites,_that.loadFailure,_that.processingInviteId,_that.lastResendResult,_that.actionFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InviteListLoadStatus loadStatus,  String organizationId,  List<Invite> invites,  Failure? loadFailure,  String? processingInviteId,  IssuedInvite? lastResendResult,  Failure? actionFailure)  $default,) {final _that = this;
switch (_that) {
case _InviteListState():
return $default(_that.loadStatus,_that.organizationId,_that.invites,_that.loadFailure,_that.processingInviteId,_that.lastResendResult,_that.actionFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InviteListLoadStatus loadStatus,  String organizationId,  List<Invite> invites,  Failure? loadFailure,  String? processingInviteId,  IssuedInvite? lastResendResult,  Failure? actionFailure)?  $default,) {final _that = this;
switch (_that) {
case _InviteListState() when $default != null:
return $default(_that.loadStatus,_that.organizationId,_that.invites,_that.loadFailure,_that.processingInviteId,_that.lastResendResult,_that.actionFailure);case _:
  return null;

}
}

}

/// @nodoc


class _InviteListState implements InviteListState {
  const _InviteListState({this.loadStatus = InviteListLoadStatus.loading, this.organizationId = '', final  List<Invite> invites = const <Invite>[], this.loadFailure, this.processingInviteId, this.lastResendResult, this.actionFailure}): _invites = invites;
  

@override@JsonKey() final  InviteListLoadStatus loadStatus;
@override@JsonKey() final  String organizationId;
 final  List<Invite> _invites;
@override@JsonKey() List<Invite> get invites {
  if (_invites is EqualUnmodifiableListView) return _invites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invites);
}

/// Only meaningful when [loadStatus] is [InviteListLoadStatus.failure].
@override final  Failure? loadFailure;
/// The id of the invite currently being resent/revoked, so its row can
/// show a busy state while every other row stays interactive. `null`
/// when no resend/revoke is in flight.
@override final  String? processingInviteId;
/// The result of the last successful resend — `InviteListPage` shows
/// its one-time [IssuedInvite.token] right after (see [IssuedInvite]'s
/// own docs for why it can never be retrieved again afterwards). Reset
/// to `null` on the next list load/resend/revoke.
@override final  IssuedInvite? lastResendResult;
/// A resend/revoke that failed — shown once (e.g. a snackbar), then
/// expected to be cleared by the caller.
@override final  Failure? actionFailure;

/// Create a copy of InviteListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteListStateCopyWith<_InviteListState> get copyWith => __$InviteListStateCopyWithImpl<_InviteListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteListState&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&const DeepCollectionEquality().equals(other._invites, _invites)&&(identical(other.loadFailure, loadFailure) || other.loadFailure == loadFailure)&&(identical(other.processingInviteId, processingInviteId) || other.processingInviteId == processingInviteId)&&(identical(other.lastResendResult, lastResendResult) || other.lastResendResult == lastResendResult)&&(identical(other.actionFailure, actionFailure) || other.actionFailure == actionFailure));
}


@override
int get hashCode => Object.hash(runtimeType,loadStatus,organizationId,const DeepCollectionEquality().hash(_invites),loadFailure,processingInviteId,lastResendResult,actionFailure);

@override
String toString() {
  return 'InviteListState(loadStatus: $loadStatus, organizationId: $organizationId, invites: $invites, loadFailure: $loadFailure, processingInviteId: $processingInviteId, lastResendResult: $lastResendResult, actionFailure: $actionFailure)';
}


}

/// @nodoc
abstract mixin class _$InviteListStateCopyWith<$Res> implements $InviteListStateCopyWith<$Res> {
  factory _$InviteListStateCopyWith(_InviteListState value, $Res Function(_InviteListState) _then) = __$InviteListStateCopyWithImpl;
@override @useResult
$Res call({
 InviteListLoadStatus loadStatus, String organizationId, List<Invite> invites, Failure? loadFailure, String? processingInviteId, IssuedInvite? lastResendResult, Failure? actionFailure
});


@override $IssuedInviteCopyWith<$Res>? get lastResendResult;

}
/// @nodoc
class __$InviteListStateCopyWithImpl<$Res>
    implements _$InviteListStateCopyWith<$Res> {
  __$InviteListStateCopyWithImpl(this._self, this._then);

  final _InviteListState _self;
  final $Res Function(_InviteListState) _then;

/// Create a copy of InviteListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadStatus = null,Object? organizationId = null,Object? invites = null,Object? loadFailure = freezed,Object? processingInviteId = freezed,Object? lastResendResult = freezed,Object? actionFailure = freezed,}) {
  return _then(_InviteListState(
loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as InviteListLoadStatus,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,invites: null == invites ? _self._invites : invites // ignore: cast_nullable_to_non_nullable
as List<Invite>,loadFailure: freezed == loadFailure ? _self.loadFailure : loadFailure // ignore: cast_nullable_to_non_nullable
as Failure?,processingInviteId: freezed == processingInviteId ? _self.processingInviteId : processingInviteId // ignore: cast_nullable_to_non_nullable
as String?,lastResendResult: freezed == lastResendResult ? _self.lastResendResult : lastResendResult // ignore: cast_nullable_to_non_nullable
as IssuedInvite?,actionFailure: freezed == actionFailure ? _self.actionFailure : actionFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of InviteListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedInviteCopyWith<$Res>? get lastResendResult {
    if (_self.lastResendResult == null) {
    return null;
  }

  return $IssuedInviteCopyWith<$Res>(_self.lastResendResult!, (value) {
    return _then(_self.copyWith(lastResendResult: value));
  });
}
}

// dart format on
