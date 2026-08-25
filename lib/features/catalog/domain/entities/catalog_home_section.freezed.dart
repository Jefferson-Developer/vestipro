// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_home_section.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatalogHomeSection {

 CatalogHomeSectionType get type; String get title; int get order; int get priority; List<CatalogHomeItem> get items;
/// Create a copy of CatalogHomeSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogHomeSectionCopyWith<CatalogHomeSection> get copyWith => _$CatalogHomeSectionCopyWithImpl<CatalogHomeSection>(this as CatalogHomeSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogHomeSection&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,order,priority,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'CatalogHomeSection(type: $type, title: $title, order: $order, priority: $priority, items: $items)';
}


}

/// @nodoc
abstract mixin class $CatalogHomeSectionCopyWith<$Res>  {
  factory $CatalogHomeSectionCopyWith(CatalogHomeSection value, $Res Function(CatalogHomeSection) _then) = _$CatalogHomeSectionCopyWithImpl;
@useResult
$Res call({
 CatalogHomeSectionType type, String title, int order, int priority, List<CatalogHomeItem> items
});




}
/// @nodoc
class _$CatalogHomeSectionCopyWithImpl<$Res>
    implements $CatalogHomeSectionCopyWith<$Res> {
  _$CatalogHomeSectionCopyWithImpl(this._self, this._then);

  final CatalogHomeSection _self;
  final $Res Function(CatalogHomeSection) _then;

/// Create a copy of CatalogHomeSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? title = null,Object? order = null,Object? priority = null,Object? items = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CatalogHomeSectionType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogHomeItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogHomeSection].
extension CatalogHomeSectionPatterns on CatalogHomeSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogHomeSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogHomeSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogHomeSection value)  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogHomeSection value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogHomeSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogHomeSectionType type,  String title,  int order,  int priority,  List<CatalogHomeItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogHomeSection() when $default != null:
return $default(_that.type,_that.title,_that.order,_that.priority,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogHomeSectionType type,  String title,  int order,  int priority,  List<CatalogHomeItem> items)  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeSection():
return $default(_that.type,_that.title,_that.order,_that.priority,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogHomeSectionType type,  String title,  int order,  int priority,  List<CatalogHomeItem> items)?  $default,) {final _that = this;
switch (_that) {
case _CatalogHomeSection() when $default != null:
return $default(_that.type,_that.title,_that.order,_that.priority,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogHomeSection extends CatalogHomeSection {
  const _CatalogHomeSection({required this.type, required this.title, required this.order, required this.priority, final  List<CatalogHomeItem> items = const <CatalogHomeItem>[]}): _items = items,super._();
  

@override final  CatalogHomeSectionType type;
@override final  String title;
@override final  int order;
@override final  int priority;
 final  List<CatalogHomeItem> _items;
@override@JsonKey() List<CatalogHomeItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of CatalogHomeSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogHomeSectionCopyWith<_CatalogHomeSection> get copyWith => __$CatalogHomeSectionCopyWithImpl<_CatalogHomeSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogHomeSection&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,type,title,order,priority,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'CatalogHomeSection(type: $type, title: $title, order: $order, priority: $priority, items: $items)';
}


}

/// @nodoc
abstract mixin class _$CatalogHomeSectionCopyWith<$Res> implements $CatalogHomeSectionCopyWith<$Res> {
  factory _$CatalogHomeSectionCopyWith(_CatalogHomeSection value, $Res Function(_CatalogHomeSection) _then) = __$CatalogHomeSectionCopyWithImpl;
@override @useResult
$Res call({
 CatalogHomeSectionType type, String title, int order, int priority, List<CatalogHomeItem> items
});




}
/// @nodoc
class __$CatalogHomeSectionCopyWithImpl<$Res>
    implements _$CatalogHomeSectionCopyWith<$Res> {
  __$CatalogHomeSectionCopyWithImpl(this._self, this._then);

  final _CatalogHomeSection _self;
  final $Res Function(_CatalogHomeSection) _then;

/// Create a copy of CatalogHomeSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? title = null,Object? order = null,Object? priority = null,Object? items = null,}) {
  return _then(_CatalogHomeSection(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CatalogHomeSectionType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogHomeItem>,
  ));
}


}

// dart format on
