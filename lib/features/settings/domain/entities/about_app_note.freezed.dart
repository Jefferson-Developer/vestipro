// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_app_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutAppNote {

 String get id; String get title; String get description;
/// Create a copy of AboutAppNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppNoteCopyWith<AboutAppNote> get copyWith => _$AboutAppNoteCopyWithImpl<AboutAppNote>(this as AboutAppNote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppNote&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description);

@override
String toString() {
  return 'AboutAppNote(id: $id, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class $AboutAppNoteCopyWith<$Res>  {
  factory $AboutAppNoteCopyWith(AboutAppNote value, $Res Function(AboutAppNote) _then) = _$AboutAppNoteCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description
});




}
/// @nodoc
class _$AboutAppNoteCopyWithImpl<$Res>
    implements $AboutAppNoteCopyWith<$Res> {
  _$AboutAppNoteCopyWithImpl(this._self, this._then);

  final AboutAppNote _self;
  final $Res Function(AboutAppNote) _then;

/// Create a copy of AboutAppNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AboutAppNote].
extension AboutAppNotePatterns on AboutAppNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AboutAppNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AboutAppNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AboutAppNote value)  $default,){
final _that = this;
switch (_that) {
case _AboutAppNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AboutAppNote value)?  $default,){
final _that = this;
switch (_that) {
case _AboutAppNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AboutAppNote() when $default != null:
return $default(_that.id,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description)  $default,) {final _that = this;
switch (_that) {
case _AboutAppNote():
return $default(_that.id,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description)?  $default,) {final _that = this;
switch (_that) {
case _AboutAppNote() when $default != null:
return $default(_that.id,_that.title,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _AboutAppNote implements AboutAppNote {
  const _AboutAppNote({required this.id, required this.title, required this.description});


@override final  String id;
@override final  String title;
@override final  String description;

/// Create a copy of AboutAppNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AboutAppNoteCopyWith<_AboutAppNote> get copyWith => __$AboutAppNoteCopyWithImpl<_AboutAppNote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AboutAppNote&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,description);

@override
String toString() {
  return 'AboutAppNote(id: $id, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class _$AboutAppNoteCopyWith<$Res> implements $AboutAppNoteCopyWith<$Res> {
  factory _$AboutAppNoteCopyWith(_AboutAppNote value, $Res Function(_AboutAppNote) _then) = __$AboutAppNoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description
});




}
/// @nodoc
class __$AboutAppNoteCopyWithImpl<$Res>
    implements _$AboutAppNoteCopyWith<$Res> {
  __$AboutAppNoteCopyWithImpl(this._self, this._then);

  final _AboutAppNote _self;
  final $Res Function(_AboutAppNote) _then;

/// Create a copy of AboutAppNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,}) {
  return _then(_AboutAppNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
