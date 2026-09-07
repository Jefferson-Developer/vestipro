// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visit_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VisitRoute {

 String get id; String get organizationId; String get companyId; String get salesRepId; DateTime get date; List<VisitRouteStop> get stops; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of VisitRoute
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VisitRouteCopyWith<VisitRoute> get copyWith => _$VisitRouteCopyWithImpl<VisitRoute>(this as VisitRoute, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VisitRoute&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.salesRepId, salesRepId) || other.salesRepId == salesRepId)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.stops, stops)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,companyId,salesRepId,date,const DeepCollectionEquality().hash(stops),createdAt,updatedAt);

@override
String toString() {
  return 'VisitRoute(id: $id, organizationId: $organizationId, companyId: $companyId, salesRepId: $salesRepId, date: $date, stops: $stops, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $VisitRouteCopyWith<$Res>  {
  factory $VisitRouteCopyWith(VisitRoute value, $Res Function(VisitRoute) _then) = _$VisitRouteCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, String salesRepId, DateTime date, List<VisitRouteStop> stops, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$VisitRouteCopyWithImpl<$Res>
    implements $VisitRouteCopyWith<$Res> {
  _$VisitRouteCopyWithImpl(this._self, this._then);

  final VisitRoute _self;
  final $Res Function(VisitRoute) _then;

/// Create a copy of VisitRoute
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? salesRepId = null,Object? date = null,Object? stops = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,salesRepId: null == salesRepId ? _self.salesRepId : salesRepId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,stops: null == stops ? _self.stops : stops // ignore: cast_nullable_to_non_nullable
as List<VisitRouteStop>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VisitRoute].
extension VisitRoutePatterns on VisitRoute {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VisitRoute value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VisitRoute() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VisitRoute value)  $default,){
final _that = this;
switch (_that) {
case _VisitRoute():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VisitRoute value)?  $default,){
final _that = this;
switch (_that) {
case _VisitRoute() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String salesRepId,  DateTime date,  List<VisitRouteStop> stops,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VisitRoute() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.salesRepId,_that.date,_that.stops,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String salesRepId,  DateTime date,  List<VisitRouteStop> stops,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _VisitRoute():
return $default(_that.id,_that.organizationId,_that.companyId,_that.salesRepId,_that.date,_that.stops,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  String salesRepId,  DateTime date,  List<VisitRouteStop> stops,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _VisitRoute() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.salesRepId,_that.date,_that.stops,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _VisitRoute extends VisitRoute {
  const _VisitRoute({required this.id, required this.organizationId, required this.companyId, required this.salesRepId, required this.date, required final  List<VisitRouteStop> stops, required this.createdAt, required this.updatedAt}): _stops = stops,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  String salesRepId;
@override final  DateTime date;
 final  List<VisitRouteStop> _stops;
@override List<VisitRouteStop> get stops {
  if (_stops is EqualUnmodifiableListView) return _stops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stops);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of VisitRoute
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VisitRouteCopyWith<_VisitRoute> get copyWith => __$VisitRouteCopyWithImpl<_VisitRoute>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VisitRoute&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.salesRepId, salesRepId) || other.salesRepId == salesRepId)&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._stops, _stops)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,organizationId,companyId,salesRepId,date,const DeepCollectionEquality().hash(_stops),createdAt,updatedAt);

@override
String toString() {
  return 'VisitRoute(id: $id, organizationId: $organizationId, companyId: $companyId, salesRepId: $salesRepId, date: $date, stops: $stops, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$VisitRouteCopyWith<$Res> implements $VisitRouteCopyWith<$Res> {
  factory _$VisitRouteCopyWith(_VisitRoute value, $Res Function(_VisitRoute) _then) = __$VisitRouteCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, String salesRepId, DateTime date, List<VisitRouteStop> stops, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$VisitRouteCopyWithImpl<$Res>
    implements _$VisitRouteCopyWith<$Res> {
  __$VisitRouteCopyWithImpl(this._self, this._then);

  final _VisitRoute _self;
  final $Res Function(_VisitRoute) _then;

/// Create a copy of VisitRoute
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? salesRepId = null,Object? date = null,Object? stops = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_VisitRoute(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,salesRepId: null == salesRepId ? _self.salesRepId : salesRepId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,stops: null == stops ? _self._stops : stops // ignore: cast_nullable_to_non_nullable
as List<VisitRouteStop>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
