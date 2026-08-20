// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_app_notes_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutAppNotesPage {

 List<AboutAppNote> get items; int get page; bool get hasMore; AboutAppDataOrigin get dataOrigin;
/// Create a copy of AboutAppNotesPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppNotesPageCopyWith<AboutAppNotesPage> get copyWith => _$AboutAppNotesPageCopyWithImpl<AboutAppNotesPage>(this as AboutAppNotesPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppNotesPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),page,hasMore,dataOrigin);

@override
String toString() {
  return 'AboutAppNotesPage(items: $items, page: $page, hasMore: $hasMore, dataOrigin: $dataOrigin)';
}


}

/// @nodoc
abstract mixin class $AboutAppNotesPageCopyWith<$Res>  {
  factory $AboutAppNotesPageCopyWith(AboutAppNotesPage value, $Res Function(AboutAppNotesPage) _then) = _$AboutAppNotesPageCopyWithImpl;
@useResult
$Res call({
 List<AboutAppNote> items, int page, bool hasMore, AboutAppDataOrigin dataOrigin
});




}
/// @nodoc
class _$AboutAppNotesPageCopyWithImpl<$Res>
    implements $AboutAppNotesPageCopyWith<$Res> {
  _$AboutAppNotesPageCopyWithImpl(this._self, this._then);

  final AboutAppNotesPage _self;
  final $Res Function(AboutAppNotesPage) _then;

/// Create a copy of AboutAppNotesPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? page = null,Object? hasMore = null,Object? dataOrigin = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<AboutAppNote>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,
  ));
}

}


/// Adds pattern-matching-related methods to [AboutAppNotesPage].
extension AboutAppNotesPagePatterns on AboutAppNotesPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AboutAppNotesPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AboutAppNotesPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AboutAppNotesPage value)  $default,){
final _that = this;
switch (_that) {
case _AboutAppNotesPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AboutAppNotesPage value)?  $default,){
final _that = this;
switch (_that) {
case _AboutAppNotesPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AboutAppNote> items,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AboutAppNotesPage() when $default != null:
return $default(_that.items,_that.page,_that.hasMore,_that.dataOrigin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AboutAppNote> items,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)  $default,) {final _that = this;
switch (_that) {
case _AboutAppNotesPage():
return $default(_that.items,_that.page,_that.hasMore,_that.dataOrigin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AboutAppNote> items,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)?  $default,) {final _that = this;
switch (_that) {
case _AboutAppNotesPage() when $default != null:
return $default(_that.items,_that.page,_that.hasMore,_that.dataOrigin);case _:
  return null;

}
}

}

/// @nodoc


class _AboutAppNotesPage implements AboutAppNotesPage {
  const _AboutAppNotesPage({required final  List<AboutAppNote> items, required this.page, required this.hasMore, required this.dataOrigin}): _items = items;


 final  List<AboutAppNote> _items;
@override List<AboutAppNote> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int page;
@override final  bool hasMore;
@override final  AboutAppDataOrigin dataOrigin;

/// Create a copy of AboutAppNotesPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AboutAppNotesPageCopyWith<_AboutAppNotesPage> get copyWith => __$AboutAppNotesPageCopyWithImpl<_AboutAppNotesPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AboutAppNotesPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,hasMore,dataOrigin);

@override
String toString() {
  return 'AboutAppNotesPage(items: $items, page: $page, hasMore: $hasMore, dataOrigin: $dataOrigin)';
}


}

/// @nodoc
abstract mixin class _$AboutAppNotesPageCopyWith<$Res> implements $AboutAppNotesPageCopyWith<$Res> {
  factory _$AboutAppNotesPageCopyWith(_AboutAppNotesPage value, $Res Function(_AboutAppNotesPage) _then) = __$AboutAppNotesPageCopyWithImpl;
@override @useResult
$Res call({
 List<AboutAppNote> items, int page, bool hasMore, AboutAppDataOrigin dataOrigin
});




}
/// @nodoc
class __$AboutAppNotesPageCopyWithImpl<$Res>
    implements _$AboutAppNotesPageCopyWith<$Res> {
  __$AboutAppNotesPageCopyWithImpl(this._self, this._then);

  final _AboutAppNotesPage _self;
  final $Res Function(_AboutAppNotesPage) _then;

/// Create a copy of AboutAppNotesPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? hasMore = null,Object? dataOrigin = null,}) {
  return _then(_AboutAppNotesPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<AboutAppNote>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,
  ));
}


}

// dart format on
