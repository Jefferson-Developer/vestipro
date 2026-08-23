// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_list_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InviteListEvent()';
}


}

/// @nodoc
class $InviteListEventCopyWith<$Res>  {
$InviteListEventCopyWith(InviteListEvent _, $Res Function(InviteListEvent) __);
}


/// Adds pattern-matching-related methods to [InviteListEvent].
extension InviteListEventPatterns on InviteListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InviteListStarted value)?  started,TResult Function( InviteListRefreshRequested value)?  refreshRequested,TResult Function( InviteListResendRequested value)?  resendRequested,TResult Function( InviteListRevokeRequested value)?  revokeRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InviteListStarted() when started != null:
return started(_that);case InviteListRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case InviteListResendRequested() when resendRequested != null:
return resendRequested(_that);case InviteListRevokeRequested() when revokeRequested != null:
return revokeRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InviteListStarted value)  started,required TResult Function( InviteListRefreshRequested value)  refreshRequested,required TResult Function( InviteListResendRequested value)  resendRequested,required TResult Function( InviteListRevokeRequested value)  revokeRequested,}){
final _that = this;
switch (_that) {
case InviteListStarted():
return started(_that);case InviteListRefreshRequested():
return refreshRequested(_that);case InviteListResendRequested():
return resendRequested(_that);case InviteListRevokeRequested():
return revokeRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InviteListStarted value)?  started,TResult? Function( InviteListRefreshRequested value)?  refreshRequested,TResult? Function( InviteListResendRequested value)?  resendRequested,TResult? Function( InviteListRevokeRequested value)?  revokeRequested,}){
final _that = this;
switch (_that) {
case InviteListStarted() when started != null:
return started(_that);case InviteListRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case InviteListResendRequested() when resendRequested != null:
return resendRequested(_that);case InviteListRevokeRequested() when revokeRequested != null:
return revokeRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String organizationId)?  started,TResult Function()?  refreshRequested,TResult Function( String inviteId)?  resendRequested,TResult Function( String inviteId)?  revokeRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InviteListStarted() when started != null:
return started(_that.organizationId);case InviteListRefreshRequested() when refreshRequested != null:
return refreshRequested();case InviteListResendRequested() when resendRequested != null:
return resendRequested(_that.inviteId);case InviteListRevokeRequested() when revokeRequested != null:
return revokeRequested(_that.inviteId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String organizationId)  started,required TResult Function()  refreshRequested,required TResult Function( String inviteId)  resendRequested,required TResult Function( String inviteId)  revokeRequested,}) {final _that = this;
switch (_that) {
case InviteListStarted():
return started(_that.organizationId);case InviteListRefreshRequested():
return refreshRequested();case InviteListResendRequested():
return resendRequested(_that.inviteId);case InviteListRevokeRequested():
return revokeRequested(_that.inviteId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String organizationId)?  started,TResult? Function()?  refreshRequested,TResult? Function( String inviteId)?  resendRequested,TResult? Function( String inviteId)?  revokeRequested,}) {final _that = this;
switch (_that) {
case InviteListStarted() when started != null:
return started(_that.organizationId);case InviteListRefreshRequested() when refreshRequested != null:
return refreshRequested();case InviteListResendRequested() when resendRequested != null:
return resendRequested(_that.inviteId);case InviteListRevokeRequested() when revokeRequested != null:
return revokeRequested(_that.inviteId);case _:
  return null;

}
}

}

/// @nodoc


class InviteListStarted implements InviteListEvent {
  const InviteListStarted(this.organizationId);
  

 final  String organizationId;

/// Create a copy of InviteListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteListStartedCopyWith<InviteListStarted> get copyWith => _$InviteListStartedCopyWithImpl<InviteListStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteListStarted&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId));
}


@override
int get hashCode => Object.hash(runtimeType,organizationId);

@override
String toString() {
  return 'InviteListEvent.started(organizationId: $organizationId)';
}


}

/// @nodoc
abstract mixin class $InviteListStartedCopyWith<$Res> implements $InviteListEventCopyWith<$Res> {
  factory $InviteListStartedCopyWith(InviteListStarted value, $Res Function(InviteListStarted) _then) = _$InviteListStartedCopyWithImpl;
@useResult
$Res call({
 String organizationId
});




}
/// @nodoc
class _$InviteListStartedCopyWithImpl<$Res>
    implements $InviteListStartedCopyWith<$Res> {
  _$InviteListStartedCopyWithImpl(this._self, this._then);

  final InviteListStarted _self;
  final $Res Function(InviteListStarted) _then;

/// Create a copy of InviteListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationId = null,}) {
  return _then(InviteListStarted(
null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InviteListRefreshRequested implements InviteListEvent {
  const InviteListRefreshRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteListRefreshRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InviteListEvent.refreshRequested()';
}


}




/// @nodoc


class InviteListResendRequested implements InviteListEvent {
  const InviteListResendRequested(this.inviteId);
  

 final  String inviteId;

/// Create a copy of InviteListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteListResendRequestedCopyWith<InviteListResendRequested> get copyWith => _$InviteListResendRequestedCopyWithImpl<InviteListResendRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteListResendRequested&&(identical(other.inviteId, inviteId) || other.inviteId == inviteId));
}


@override
int get hashCode => Object.hash(runtimeType,inviteId);

@override
String toString() {
  return 'InviteListEvent.resendRequested(inviteId: $inviteId)';
}


}

/// @nodoc
abstract mixin class $InviteListResendRequestedCopyWith<$Res> implements $InviteListEventCopyWith<$Res> {
  factory $InviteListResendRequestedCopyWith(InviteListResendRequested value, $Res Function(InviteListResendRequested) _then) = _$InviteListResendRequestedCopyWithImpl;
@useResult
$Res call({
 String inviteId
});




}
/// @nodoc
class _$InviteListResendRequestedCopyWithImpl<$Res>
    implements $InviteListResendRequestedCopyWith<$Res> {
  _$InviteListResendRequestedCopyWithImpl(this._self, this._then);

  final InviteListResendRequested _self;
  final $Res Function(InviteListResendRequested) _then;

/// Create a copy of InviteListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? inviteId = null,}) {
  return _then(InviteListResendRequested(
null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InviteListRevokeRequested implements InviteListEvent {
  const InviteListRevokeRequested(this.inviteId);
  

 final  String inviteId;

/// Create a copy of InviteListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteListRevokeRequestedCopyWith<InviteListRevokeRequested> get copyWith => _$InviteListRevokeRequestedCopyWithImpl<InviteListRevokeRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteListRevokeRequested&&(identical(other.inviteId, inviteId) || other.inviteId == inviteId));
}


@override
int get hashCode => Object.hash(runtimeType,inviteId);

@override
String toString() {
  return 'InviteListEvent.revokeRequested(inviteId: $inviteId)';
}


}

/// @nodoc
abstract mixin class $InviteListRevokeRequestedCopyWith<$Res> implements $InviteListEventCopyWith<$Res> {
  factory $InviteListRevokeRequestedCopyWith(InviteListRevokeRequested value, $Res Function(InviteListRevokeRequested) _then) = _$InviteListRevokeRequestedCopyWithImpl;
@useResult
$Res call({
 String inviteId
});




}
/// @nodoc
class _$InviteListRevokeRequestedCopyWithImpl<$Res>
    implements $InviteListRevokeRequestedCopyWith<$Res> {
  _$InviteListRevokeRequestedCopyWithImpl(this._self, this._then);

  final InviteListRevokeRequested _self;
  final $Res Function(InviteListRevokeRequested) _then;

/// Create a copy of InviteListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? inviteId = null,}) {
  return _then(InviteListRevokeRequested(
null == inviteId ? _self.inviteId : inviteId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
