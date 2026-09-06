// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_lookup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportLookup {

 Map<String, String> get categoryIdByName; Map<String, String> get collectionIdByName;/// Never auto-created (`tasks.md` only allows create-or-reject for
/// categoria/coleção, not for cor) — a color name missing here always
/// rejects the row.
 Map<String, String> get colorIdByName;/// Every `SizeGridSize.label` (normalized) -> id of the single
/// `SizeGridTemplate` selected for this import run
/// (`ProductImportMapping.sizeGridTemplateId`) — sent for the exact same
/// reason as the maps above: `SizeGridTemplate` also has no
/// remote/Firestore-backed store yet
/// (`SharedPreferencesSizeGridTemplateRepository`), so
/// `processProductImportJob` has no way to look up "P"/"38" against the
/// chosen grid's sizes itself. A `sizeLabel` cell absent from this map
/// always rejects the row ("grade de tamanho inexistente") — never
/// inferred.
 Map<String, String> get sizeIdByLabel;
/// Create a copy of ProductImportLookup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportLookupCopyWith<ProductImportLookup> get copyWith => _$ProductImportLookupCopyWithImpl<ProductImportLookup>(this as ProductImportLookup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportLookup&&const DeepCollectionEquality().equals(other.categoryIdByName, categoryIdByName)&&const DeepCollectionEquality().equals(other.collectionIdByName, collectionIdByName)&&const DeepCollectionEquality().equals(other.colorIdByName, colorIdByName)&&const DeepCollectionEquality().equals(other.sizeIdByLabel, sizeIdByLabel));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categoryIdByName),const DeepCollectionEquality().hash(collectionIdByName),const DeepCollectionEquality().hash(colorIdByName),const DeepCollectionEquality().hash(sizeIdByLabel));

@override
String toString() {
  return 'ProductImportLookup(categoryIdByName: $categoryIdByName, collectionIdByName: $collectionIdByName, colorIdByName: $colorIdByName, sizeIdByLabel: $sizeIdByLabel)';
}


}

/// @nodoc
abstract mixin class $ProductImportLookupCopyWith<$Res>  {
  factory $ProductImportLookupCopyWith(ProductImportLookup value, $Res Function(ProductImportLookup) _then) = _$ProductImportLookupCopyWithImpl;
@useResult
$Res call({
 Map<String, String> categoryIdByName, Map<String, String> collectionIdByName, Map<String, String> colorIdByName, Map<String, String> sizeIdByLabel
});




}
/// @nodoc
class _$ProductImportLookupCopyWithImpl<$Res>
    implements $ProductImportLookupCopyWith<$Res> {
  _$ProductImportLookupCopyWithImpl(this._self, this._then);

  final ProductImportLookup _self;
  final $Res Function(ProductImportLookup) _then;

/// Create a copy of ProductImportLookup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryIdByName = null,Object? collectionIdByName = null,Object? colorIdByName = null,Object? sizeIdByLabel = null,}) {
  return _then(_self.copyWith(
categoryIdByName: null == categoryIdByName ? _self.categoryIdByName : categoryIdByName // ignore: cast_nullable_to_non_nullable
as Map<String, String>,collectionIdByName: null == collectionIdByName ? _self.collectionIdByName : collectionIdByName // ignore: cast_nullable_to_non_nullable
as Map<String, String>,colorIdByName: null == colorIdByName ? _self.colorIdByName : colorIdByName // ignore: cast_nullable_to_non_nullable
as Map<String, String>,sizeIdByLabel: null == sizeIdByLabel ? _self.sizeIdByLabel : sizeIdByLabel // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImportLookup].
extension ProductImportLookupPatterns on ProductImportLookup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportLookup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportLookup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportLookup value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportLookup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportLookup value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportLookup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String> categoryIdByName,  Map<String, String> collectionIdByName,  Map<String, String> colorIdByName,  Map<String, String> sizeIdByLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImportLookup() when $default != null:
return $default(_that.categoryIdByName,_that.collectionIdByName,_that.colorIdByName,_that.sizeIdByLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String> categoryIdByName,  Map<String, String> collectionIdByName,  Map<String, String> colorIdByName,  Map<String, String> sizeIdByLabel)  $default,) {final _that = this;
switch (_that) {
case _ProductImportLookup():
return $default(_that.categoryIdByName,_that.collectionIdByName,_that.colorIdByName,_that.sizeIdByLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String> categoryIdByName,  Map<String, String> collectionIdByName,  Map<String, String> colorIdByName,  Map<String, String> sizeIdByLabel)?  $default,) {final _that = this;
switch (_that) {
case _ProductImportLookup() when $default != null:
return $default(_that.categoryIdByName,_that.collectionIdByName,_that.colorIdByName,_that.sizeIdByLabel);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportLookup implements ProductImportLookup {
  const _ProductImportLookup({final  Map<String, String> categoryIdByName = const <String, String>{}, final  Map<String, String> collectionIdByName = const <String, String>{}, final  Map<String, String> colorIdByName = const <String, String>{}, final  Map<String, String> sizeIdByLabel = const <String, String>{}}): _categoryIdByName = categoryIdByName,_collectionIdByName = collectionIdByName,_colorIdByName = colorIdByName,_sizeIdByLabel = sizeIdByLabel;
  

 final  Map<String, String> _categoryIdByName;
@override@JsonKey() Map<String, String> get categoryIdByName {
  if (_categoryIdByName is EqualUnmodifiableMapView) return _categoryIdByName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryIdByName);
}

 final  Map<String, String> _collectionIdByName;
@override@JsonKey() Map<String, String> get collectionIdByName {
  if (_collectionIdByName is EqualUnmodifiableMapView) return _collectionIdByName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collectionIdByName);
}

/// Never auto-created (`tasks.md` only allows create-or-reject for
/// categoria/coleção, not for cor) — a color name missing here always
/// rejects the row.
 final  Map<String, String> _colorIdByName;
/// Never auto-created (`tasks.md` only allows create-or-reject for
/// categoria/coleção, not for cor) — a color name missing here always
/// rejects the row.
@override@JsonKey() Map<String, String> get colorIdByName {
  if (_colorIdByName is EqualUnmodifiableMapView) return _colorIdByName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_colorIdByName);
}

/// Every `SizeGridSize.label` (normalized) -> id of the single
/// `SizeGridTemplate` selected for this import run
/// (`ProductImportMapping.sizeGridTemplateId`) — sent for the exact same
/// reason as the maps above: `SizeGridTemplate` also has no
/// remote/Firestore-backed store yet
/// (`SharedPreferencesSizeGridTemplateRepository`), so
/// `processProductImportJob` has no way to look up "P"/"38" against the
/// chosen grid's sizes itself. A `sizeLabel` cell absent from this map
/// always rejects the row ("grade de tamanho inexistente") — never
/// inferred.
 final  Map<String, String> _sizeIdByLabel;
/// Every `SizeGridSize.label` (normalized) -> id of the single
/// `SizeGridTemplate` selected for this import run
/// (`ProductImportMapping.sizeGridTemplateId`) — sent for the exact same
/// reason as the maps above: `SizeGridTemplate` also has no
/// remote/Firestore-backed store yet
/// (`SharedPreferencesSizeGridTemplateRepository`), so
/// `processProductImportJob` has no way to look up "P"/"38" against the
/// chosen grid's sizes itself. A `sizeLabel` cell absent from this map
/// always rejects the row ("grade de tamanho inexistente") — never
/// inferred.
@override@JsonKey() Map<String, String> get sizeIdByLabel {
  if (_sizeIdByLabel is EqualUnmodifiableMapView) return _sizeIdByLabel;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sizeIdByLabel);
}


/// Create a copy of ProductImportLookup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportLookupCopyWith<_ProductImportLookup> get copyWith => __$ProductImportLookupCopyWithImpl<_ProductImportLookup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportLookup&&const DeepCollectionEquality().equals(other._categoryIdByName, _categoryIdByName)&&const DeepCollectionEquality().equals(other._collectionIdByName, _collectionIdByName)&&const DeepCollectionEquality().equals(other._colorIdByName, _colorIdByName)&&const DeepCollectionEquality().equals(other._sizeIdByLabel, _sizeIdByLabel));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categoryIdByName),const DeepCollectionEquality().hash(_collectionIdByName),const DeepCollectionEquality().hash(_colorIdByName),const DeepCollectionEquality().hash(_sizeIdByLabel));

@override
String toString() {
  return 'ProductImportLookup(categoryIdByName: $categoryIdByName, collectionIdByName: $collectionIdByName, colorIdByName: $colorIdByName, sizeIdByLabel: $sizeIdByLabel)';
}


}

/// @nodoc
abstract mixin class _$ProductImportLookupCopyWith<$Res> implements $ProductImportLookupCopyWith<$Res> {
  factory _$ProductImportLookupCopyWith(_ProductImportLookup value, $Res Function(_ProductImportLookup) _then) = __$ProductImportLookupCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String> categoryIdByName, Map<String, String> collectionIdByName, Map<String, String> colorIdByName, Map<String, String> sizeIdByLabel
});




}
/// @nodoc
class __$ProductImportLookupCopyWithImpl<$Res>
    implements _$ProductImportLookupCopyWith<$Res> {
  __$ProductImportLookupCopyWithImpl(this._self, this._then);

  final _ProductImportLookup _self;
  final $Res Function(_ProductImportLookup) _then;

/// Create a copy of ProductImportLookup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryIdByName = null,Object? collectionIdByName = null,Object? colorIdByName = null,Object? sizeIdByLabel = null,}) {
  return _then(_ProductImportLookup(
categoryIdByName: null == categoryIdByName ? _self._categoryIdByName : categoryIdByName // ignore: cast_nullable_to_non_nullable
as Map<String, String>,collectionIdByName: null == collectionIdByName ? _self._collectionIdByName : collectionIdByName // ignore: cast_nullable_to_non_nullable
as Map<String, String>,colorIdByName: null == colorIdByName ? _self._colorIdByName : colorIdByName // ignore: cast_nullable_to_non_nullable
as Map<String, String>,sizeIdByLabel: null == sizeIdByLabel ? _self._sizeIdByLabel : sizeIdByLabel // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
