// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_home_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogHomeSnapshot {

 List<CatalogHomeSection> get sections; DateTime get savedAt;
/// Create a copy of CatalogHomeSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogHomeSnapshotCopyWith<CatalogHomeSnapshot> get copyWith => _$CatalogHomeSnapshotCopyWithImpl<CatalogHomeSnapshot>(this as CatalogHomeSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogHomeSnapshot&&const DeepCollectionEquality().equals(other.sections, sections)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sections),savedAt);

@override
String toString() {
  return 'CatalogHomeSnapshot(sections: $sections, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class $CatalogHomeSnapshotCopyWith<$Res>  {
  factory $CatalogHomeSnapshotCopyWith(CatalogHomeSnapshot value, $Res Function(CatalogHomeSnapshot) _then) = _$CatalogHomeSnapshotCopyWithImpl;
@useResult
$Res call({
 List<CatalogHomeSection> sections, DateTime savedAt
});




}
/// @nodoc
class _$CatalogHomeSnapshotCopyWithImpl<$Res>
    implements $CatalogHomeSnapshotCopyWith<$Res> {
  _$CatalogHomeSnapshotCopyWithImpl(this._self, this._then);

  final CatalogHomeSnapshot _self;
  final $Res Function(CatalogHomeSnapshot) _then;

/// Create a copy of CatalogHomeSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sections = null,Object? savedAt = null,}) {
  return _then(_self.copyWith(
sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<CatalogHomeSection>,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogHomeSnapshot].
extension CatalogHomeSnapshotPatterns on CatalogHomeSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogHomeSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogHomeSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogHomeSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogHomeSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CatalogHomeSection> sections,  DateTime savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogHomeSnapshot() when $default != null:
return $default(_that.sections,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CatalogHomeSection> sections,  DateTime savedAt)  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeSnapshot():
return $default(_that.sections,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CatalogHomeSection> sections,  DateTime savedAt)?  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeSnapshot() when $default != null:
return $default(_that.sections,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogHomeSnapshot implements CatalogHomeSnapshot {
  const _CatalogHomeSnapshot({required final  List<CatalogHomeSection> sections, required this.savedAt}): _sections = sections;
  

 final  List<CatalogHomeSection> _sections;
@override List<CatalogHomeSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

@override final  DateTime savedAt;

/// Create a copy of CatalogHomeSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogHomeSnapshotCopyWith<_CatalogHomeSnapshot> get copyWith => __$CatalogHomeSnapshotCopyWithImpl<_CatalogHomeSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogHomeSnapshot&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sections),savedAt);

@override
String toString() {
  return 'CatalogHomeSnapshot(sections: $sections, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$CatalogHomeSnapshotCopyWith<$Res> implements $CatalogHomeSnapshotCopyWith<$Res> {
  factory _$CatalogHomeSnapshotCopyWith(_CatalogHomeSnapshot value, $Res Function(_CatalogHomeSnapshot) _then) = __$CatalogHomeSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<CatalogHomeSection> sections, DateTime savedAt
});




}
/// @nodoc
class __$CatalogHomeSnapshotCopyWithImpl<$Res>
    implements _$CatalogHomeSnapshotCopyWith<$Res> {
  __$CatalogHomeSnapshotCopyWithImpl(this._self, this._then);

  final _CatalogHomeSnapshot _self;
  final $Res Function(_CatalogHomeSnapshot) _then;

/// Create a copy of CatalogHomeSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sections = null,Object? savedAt = null,}) {
  return _then(_CatalogHomeSnapshot(
sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<CatalogHomeSection>,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
