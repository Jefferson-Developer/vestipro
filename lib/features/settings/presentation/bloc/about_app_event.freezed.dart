// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_app_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutAppEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutAppEvent()';
}


}

/// @nodoc
class $AboutAppEventCopyWith<$Res>  {
$AboutAppEventCopyWith(AboutAppEvent _, $Res Function(AboutAppEvent) __);
}


/// Adds pattern-matching-related methods to [AboutAppEvent].
extension AboutAppEventPatterns on AboutAppEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AboutAppStarted value)?  started,TResult Function( AboutAppSearchQueryChanged value)?  searchQueryChanged,TResult Function( AboutAppNextPageRequested value)?  nextPageRequested,TResult Function( AboutAppDiagnosticsSubmitted value)?  diagnosticsSubmitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AboutAppStarted() when started != null:
return started(_that);case AboutAppSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that);case AboutAppNextPageRequested() when nextPageRequested != null:
return nextPageRequested(_that);case AboutAppDiagnosticsSubmitted() when diagnosticsSubmitted != null:
return diagnosticsSubmitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AboutAppStarted value)  started,required TResult Function( AboutAppSearchQueryChanged value)  searchQueryChanged,required TResult Function( AboutAppNextPageRequested value)  nextPageRequested,required TResult Function( AboutAppDiagnosticsSubmitted value)  diagnosticsSubmitted,}){
final _that = this;
switch (_that) {
case AboutAppStarted():
return started(_that);case AboutAppSearchQueryChanged():
return searchQueryChanged(_that);case AboutAppNextPageRequested():
return nextPageRequested(_that);case AboutAppDiagnosticsSubmitted():
return diagnosticsSubmitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AboutAppStarted value)?  started,TResult? Function( AboutAppSearchQueryChanged value)?  searchQueryChanged,TResult? Function( AboutAppNextPageRequested value)?  nextPageRequested,TResult? Function( AboutAppDiagnosticsSubmitted value)?  diagnosticsSubmitted,}){
final _that = this;
switch (_that) {
case AboutAppStarted() when started != null:
return started(_that);case AboutAppSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that);case AboutAppNextPageRequested() when nextPageRequested != null:
return nextPageRequested(_that);case AboutAppDiagnosticsSubmitted() when diagnosticsSubmitted != null:
return diagnosticsSubmitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( String query)?  searchQueryChanged,TResult Function()?  nextPageRequested,TResult Function()?  diagnosticsSubmitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AboutAppStarted() when started != null:
return started();case AboutAppSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that.query);case AboutAppNextPageRequested() when nextPageRequested != null:
return nextPageRequested();case AboutAppDiagnosticsSubmitted() when diagnosticsSubmitted != null:
return diagnosticsSubmitted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( String query)  searchQueryChanged,required TResult Function()  nextPageRequested,required TResult Function()  diagnosticsSubmitted,}) {final _that = this;
switch (_that) {
case AboutAppStarted():
return started();case AboutAppSearchQueryChanged():
return searchQueryChanged(_that.query);case AboutAppNextPageRequested():
return nextPageRequested();case AboutAppDiagnosticsSubmitted():
return diagnosticsSubmitted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( String query)?  searchQueryChanged,TResult? Function()?  nextPageRequested,TResult? Function()?  diagnosticsSubmitted,}) {final _that = this;
switch (_that) {
case AboutAppStarted() when started != null:
return started();case AboutAppSearchQueryChanged() when searchQueryChanged != null:
return searchQueryChanged(_that.query);case AboutAppNextPageRequested() when nextPageRequested != null:
return nextPageRequested();case AboutAppDiagnosticsSubmitted() when diagnosticsSubmitted != null:
return diagnosticsSubmitted();case _:
  return null;

}
}

}

/// @nodoc


class AboutAppStarted implements AboutAppEvent {
  const AboutAppStarted();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutAppEvent.started()';
}


}




/// @nodoc


class AboutAppSearchQueryChanged implements AboutAppEvent {
  const AboutAppSearchQueryChanged(this.query);


 final  String query;

/// Create a copy of AboutAppEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppSearchQueryChangedCopyWith<AboutAppSearchQueryChanged> get copyWith => _$AboutAppSearchQueryChangedCopyWithImpl<AboutAppSearchQueryChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppSearchQueryChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'AboutAppEvent.searchQueryChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class $AboutAppSearchQueryChangedCopyWith<$Res> implements $AboutAppEventCopyWith<$Res> {
  factory $AboutAppSearchQueryChangedCopyWith(AboutAppSearchQueryChanged value, $Res Function(AboutAppSearchQueryChanged) _then) = _$AboutAppSearchQueryChangedCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$AboutAppSearchQueryChangedCopyWithImpl<$Res>
    implements $AboutAppSearchQueryChangedCopyWith<$Res> {
  _$AboutAppSearchQueryChangedCopyWithImpl(this._self, this._then);

  final AboutAppSearchQueryChanged _self;
  final $Res Function(AboutAppSearchQueryChanged) _then;

/// Create a copy of AboutAppEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(AboutAppSearchQueryChanged(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AboutAppNextPageRequested implements AboutAppEvent {
  const AboutAppNextPageRequested();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppNextPageRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutAppEvent.nextPageRequested()';
}


}




/// @nodoc


class AboutAppDiagnosticsSubmitted implements AboutAppEvent {
  const AboutAppDiagnosticsSubmitted();







@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppDiagnosticsSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AboutAppEvent.diagnosticsSubmitted()';
}


}




// dart format on
