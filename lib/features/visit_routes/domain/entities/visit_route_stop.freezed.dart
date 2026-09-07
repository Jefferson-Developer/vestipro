// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visit_route_stop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VisitRouteStop {

 String get customerId; String get displayName; GeoCoordinates get coordinates; int get sequence; VisitRouteStopStatus get status;// Straight-line (haversine) distance/time estimate from the previous
// stop (or from the seller's starting point, for the first stop) — a
// nearest-neighbor heuristic approximation, not a real driving
// distance/duration from a Directions API. `null` only when no
// reference point was available to compute it from (first stop with no
// known origin).
 double? get distanceFromPreviousKm; int? get etaMinutesFromPrevious;
/// Create a copy of VisitRouteStop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitRouteStopCopyWith<VisitRouteStop> get copyWith => _$VisitRouteStopCopyWithImpl<VisitRouteStop>(this as VisitRouteStop, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitRouteStop&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.coordinates, coordinates) || other.coordinates == coordinates)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.status, status) || other.status == status)&&(identical(other.distanceFromPreviousKm, distanceFromPreviousKm) || other.distanceFromPreviousKm == distanceFromPreviousKm)&&(identical(other.etaMinutesFromPrevious, etaMinutesFromPrevious) || other.etaMinutesFromPrevious == etaMinutesFromPrevious));
}


@override
int get hashCode => Object.hash(runtimeType,customerId,displayName,coordinates,sequence,status,distanceFromPreviousKm,etaMinutesFromPrevious);

@override
String toString() {
  return 'VisitRouteStop(customerId: $customerId, displayName: $displayName, coordinates: $coordinates, sequence: $sequence, status: $status, distanceFromPreviousKm: $distanceFromPreviousKm, etaMinutesFromPrevious: $etaMinutesFromPrevious)';
}


}

/// @nodoc
abstract mixin class $VisitRouteStopCopyWith<$Res>  {
  factory $VisitRouteStopCopyWith(VisitRouteStop value, $Res Function(VisitRouteStop) _then) = _$VisitRouteStopCopyWithImpl;
@useResult
$Res call({
 String customerId, String displayName, GeoCoordinates coordinates, int sequence, VisitRouteStopStatus status, double? distanceFromPreviousKm, int? etaMinutesFromPrevious
});




}
/// @nodoc
class _$VisitRouteStopCopyWithImpl<$Res>
    implements $VisitRouteStopCopyWith<$Res> {
  _$VisitRouteStopCopyWithImpl(this._self, this._then);

  final VisitRouteStop _self;
  final $Res Function(VisitRouteStop) _then;

/// Create a copy of VisitRouteStop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? displayName = null,Object? coordinates = null,Object? sequence = null,Object? status = null,Object? distanceFromPreviousKm = freezed,Object? etaMinutesFromPrevious = freezed,}) {
  return _then(_self.copyWith(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,coordinates: null == coordinates ? _self.coordinates : coordinates // ignore: cast_nullable_to_non_nullable
as GeoCoordinates,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VisitRouteStopStatus,distanceFromPreviousKm: freezed == distanceFromPreviousKm ? _self.distanceFromPreviousKm : distanceFromPreviousKm // ignore: cast_nullable_to_non_nullable
as double?,etaMinutesFromPrevious: freezed == etaMinutesFromPrevious ? _self.etaMinutesFromPrevious : etaMinutesFromPrevious // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitRouteStop].
extension VisitRouteStopPatterns on VisitRouteStop {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitRouteStop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitRouteStop() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitRouteStop value)  $default,){
final _that = this;
switch (_that) {
case _VisitRouteStop():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitRouteStop value)?  $default,){
final _that = this;
switch (_that) {
case _VisitRouteStop() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String customerId,  String displayName,  GeoCoordinates coordinates,  int sequence,  VisitRouteStopStatus status,  double? distanceFromPreviousKm,  int? etaMinutesFromPrevious)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitRouteStop() when $default != null:
return $default(_that.customerId,_that.displayName,_that.coordinates,_that.sequence,_that.status,_that.distanceFromPreviousKm,_that.etaMinutesFromPrevious);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String customerId,  String displayName,  GeoCoordinates coordinates,  int sequence,  VisitRouteStopStatus status,  double? distanceFromPreviousKm,  int? etaMinutesFromPrevious)  $default,) {final _that = this;
switch (_that) {
case _VisitRouteStop():
return $default(_that.customerId,_that.displayName,_that.coordinates,_that.sequence,_that.status,_that.distanceFromPreviousKm,_that.etaMinutesFromPrevious);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String customerId,  String displayName,  GeoCoordinates coordinates,  int sequence,  VisitRouteStopStatus status,  double? distanceFromPreviousKm,  int? etaMinutesFromPrevious)?  $default,) {final _that = this;
switch (_that) {
case _VisitRouteStop() when $default != null:
return $default(_that.customerId,_that.displayName,_that.coordinates,_that.sequence,_that.status,_that.distanceFromPreviousKm,_that.etaMinutesFromPrevious);case _:
  return null;

}
}

}

/// @nodoc


class _VisitRouteStop extends VisitRouteStop {
  const _VisitRouteStop({required this.customerId, required this.displayName, required this.coordinates, required this.sequence, this.status = VisitRouteStopStatus.pending, this.distanceFromPreviousKm, this.etaMinutesFromPrevious}): super._();
  

@override final  String customerId;
@override final  String displayName;
@override final  GeoCoordinates coordinates;
@override final  int sequence;
@override@JsonKey() final  VisitRouteStopStatus status;
// Straight-line (haversine) distance/time estimate from the previous
// stop (or from the seller's starting point, for the first stop) — a
// nearest-neighbor heuristic approximation, not a real driving
// distance/duration from a Directions API. `null` only when no
// reference point was available to compute it from (first stop with no
// known origin).
@override final  double? distanceFromPreviousKm;
@override final  int? etaMinutesFromPrevious;

/// Create a copy of VisitRouteStop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitRouteStopCopyWith<_VisitRouteStop> get copyWith => __$VisitRouteStopCopyWithImpl<_VisitRouteStop>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitRouteStop&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.coordinates, coordinates) || other.coordinates == coordinates)&&(identical(other.sequence, sequence) || other.sequence == sequence)&&(identical(other.status, status) || other.status == status)&&(identical(other.distanceFromPreviousKm, distanceFromPreviousKm) || other.distanceFromPreviousKm == distanceFromPreviousKm)&&(identical(other.etaMinutesFromPrevious, etaMinutesFromPrevious) || other.etaMinutesFromPrevious == etaMinutesFromPrevious));
}


@override
int get hashCode => Object.hash(runtimeType,customerId,displayName,coordinates,sequence,status,distanceFromPreviousKm,etaMinutesFromPrevious);

@override
String toString() {
  return 'VisitRouteStop(customerId: $customerId, displayName: $displayName, coordinates: $coordinates, sequence: $sequence, status: $status, distanceFromPreviousKm: $distanceFromPreviousKm, etaMinutesFromPrevious: $etaMinutesFromPrevious)';
}


}

/// @nodoc
abstract mixin class _$VisitRouteStopCopyWith<$Res> implements $VisitRouteStopCopyWith<$Res> {
  factory _$VisitRouteStopCopyWith(_VisitRouteStop value, $Res Function(_VisitRouteStop) _then) = __$VisitRouteStopCopyWithImpl;
@override @useResult
$Res call({
 String customerId, String displayName, GeoCoordinates coordinates, int sequence, VisitRouteStopStatus status, double? distanceFromPreviousKm, int? etaMinutesFromPrevious
});




}
/// @nodoc
class __$VisitRouteStopCopyWithImpl<$Res>
    implements _$VisitRouteStopCopyWith<$Res> {
  __$VisitRouteStopCopyWithImpl(this._self, this._then);

  final _VisitRouteStop _self;
  final $Res Function(_VisitRouteStop) _then;

/// Create a copy of VisitRouteStop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? displayName = null,Object? coordinates = null,Object? sequence = null,Object? status = null,Object? distanceFromPreviousKm = freezed,Object? etaMinutesFromPrevious = freezed,}) {
  return _then(_VisitRouteStop(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,coordinates: null == coordinates ? _self.coordinates : coordinates // ignore: cast_nullable_to_non_nullable
as GeoCoordinates,sequence: null == sequence ? _self.sequence : sequence // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VisitRouteStopStatus,distanceFromPreviousKm: freezed == distanceFromPreviousKm ? _self.distanceFromPreviousKm : distanceFromPreviousKm // ignore: cast_nullable_to_non_nullable
as double?,etaMinutesFromPrevious: freezed == etaMinutesFromPrevious ? _self.etaMinutesFromPrevious : etaMinutesFromPrevious // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
