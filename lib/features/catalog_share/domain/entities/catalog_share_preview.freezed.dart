// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_share_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogSharePreview {

 CatalogShareOutcome get outcome; String? get organizationName; CatalogShareScope? get scope; List<CatalogShareItem> get items; String? get collectionName; DateTime? get expiresAt;
/// Create a copy of CatalogSharePreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogSharePreviewCopyWith<CatalogSharePreview> get copyWith => _$CatalogSharePreviewCopyWithImpl<CatalogSharePreview>(this as CatalogSharePreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogSharePreview&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,outcome,organizationName,scope,const DeepCollectionEquality().hash(items),collectionName,expiresAt);

@override
String toString() {
  return 'CatalogSharePreview(outcome: $outcome, organizationName: $organizationName, scope: $scope, items: $items, collectionName: $collectionName, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $CatalogSharePreviewCopyWith<$Res>  {
  factory $CatalogSharePreviewCopyWith(CatalogSharePreview value, $Res Function(CatalogSharePreview) _then) = _$CatalogSharePreviewCopyWithImpl;
@useResult
$Res call({
 CatalogShareOutcome outcome, String? organizationName, CatalogShareScope? scope, List<CatalogShareItem> items, String? collectionName, DateTime? expiresAt
});




}
/// @nodoc
class _$CatalogSharePreviewCopyWithImpl<$Res>
    implements $CatalogSharePreviewCopyWith<$Res> {
  _$CatalogSharePreviewCopyWithImpl(this._self, this._then);

  final CatalogSharePreview _self;
  final $Res Function(CatalogSharePreview) _then;

/// Create a copy of CatalogSharePreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outcome = null,Object? organizationName = freezed,Object? scope = freezed,Object? items = null,Object? collectionName = freezed,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CatalogShareOutcome,organizationName: freezed == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as CatalogShareScope?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogShareItem>,collectionName: freezed == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogSharePreview].
extension CatalogSharePreviewPatterns on CatalogSharePreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogSharePreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogSharePreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogSharePreview value)  $default,){
final _that = this;
switch (_that) {
case _CatalogSharePreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogSharePreview value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogSharePreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogShareOutcome outcome,  String? organizationName,  CatalogShareScope? scope,  List<CatalogShareItem> items,  String? collectionName,  DateTime? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogSharePreview() when $default != null:
return $default(_that.outcome,_that.organizationName,_that.scope,_that.items,_that.collectionName,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogShareOutcome outcome,  String? organizationName,  CatalogShareScope? scope,  List<CatalogShareItem> items,  String? collectionName,  DateTime? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _CatalogSharePreview():
return $default(_that.outcome,_that.organizationName,_that.scope,_that.items,_that.collectionName,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogShareOutcome outcome,  String? organizationName,  CatalogShareScope? scope,  List<CatalogShareItem> items,  String? collectionName,  DateTime? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CatalogSharePreview() when $default != null:
return $default(_that.outcome,_that.organizationName,_that.scope,_that.items,_that.collectionName,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogSharePreview implements CatalogSharePreview {
  const _CatalogSharePreview({required this.outcome, this.organizationName, this.scope, final  List<CatalogShareItem> items = const <CatalogShareItem>[], this.collectionName, this.expiresAt}): _items = items;
  

@override final  CatalogShareOutcome outcome;
@override final  String? organizationName;
@override final  CatalogShareScope? scope;
 final  List<CatalogShareItem> _items;
@override@JsonKey() List<CatalogShareItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? collectionName;
@override final  DateTime? expiresAt;

/// Create a copy of CatalogSharePreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogSharePreviewCopyWith<_CatalogSharePreview> get copyWith => __$CatalogSharePreviewCopyWithImpl<_CatalogSharePreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogSharePreview&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.scope, scope) || other.scope == scope)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.collectionName, collectionName) || other.collectionName == collectionName)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,outcome,organizationName,scope,const DeepCollectionEquality().hash(_items),collectionName,expiresAt);

@override
String toString() {
  return 'CatalogSharePreview(outcome: $outcome, organizationName: $organizationName, scope: $scope, items: $items, collectionName: $collectionName, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$CatalogSharePreviewCopyWith<$Res> implements $CatalogSharePreviewCopyWith<$Res> {
  factory _$CatalogSharePreviewCopyWith(_CatalogSharePreview value, $Res Function(_CatalogSharePreview) _then) = __$CatalogSharePreviewCopyWithImpl;
@override @useResult
$Res call({
 CatalogShareOutcome outcome, String? organizationName, CatalogShareScope? scope, List<CatalogShareItem> items, String? collectionName, DateTime? expiresAt
});




}
/// @nodoc
class __$CatalogSharePreviewCopyWithImpl<$Res>
    implements _$CatalogSharePreviewCopyWith<$Res> {
  __$CatalogSharePreviewCopyWithImpl(this._self, this._then);

  final _CatalogSharePreview _self;
  final $Res Function(_CatalogSharePreview) _then;

/// Create a copy of CatalogSharePreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? outcome = null,Object? organizationName = freezed,Object? scope = freezed,Object? items = null,Object? collectionName = freezed,Object? expiresAt = freezed,}) {
  return _then(_CatalogSharePreview(
outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CatalogShareOutcome,organizationName: freezed == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String?,scope: freezed == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as CatalogShareScope?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogShareItem>,collectionName: freezed == collectionName ? _self.collectionName : collectionName // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
