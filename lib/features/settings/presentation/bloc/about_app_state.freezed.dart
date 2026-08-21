// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_app_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutAppState {

 AboutAppDataOrigin get dataOrigin;
/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppStateCopyWith<AboutAppState> get copyWith => _$AboutAppStateCopyWithImpl<AboutAppState>(this as AboutAppState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppState&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin));
}


@override
int get hashCode => Object.hash(runtimeType,dataOrigin);

@override
String toString() {
  return 'AboutAppState(dataOrigin: $dataOrigin)';
}


}

/// @nodoc
abstract mixin class $AboutAppStateCopyWith<$Res>  {
  factory $AboutAppStateCopyWith(AboutAppState value, $Res Function(AboutAppState) _then) = _$AboutAppStateCopyWithImpl;
@useResult
$Res call({
 AboutAppDataOrigin dataOrigin
});




}
/// @nodoc
class _$AboutAppStateCopyWithImpl<$Res>
    implements $AboutAppStateCopyWith<$Res> {
  _$AboutAppStateCopyWithImpl(this._self, this._then);

  final AboutAppState _self;
  final $Res Function(AboutAppState) _then;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dataOrigin = null,}) {
  return _then(_self.copyWith(
dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,
  ));
}

}


/// Adds pattern-matching-related methods to [AboutAppState].
extension AboutAppStatePatterns on AboutAppState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AboutAppInitial value)?  initial,TResult Function( AboutAppLoading value)?  loading,TResult Function( AboutAppReady value)?  ready,TResult Function( AboutAppFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AboutAppInitial() when initial != null:
return initial(_that);case AboutAppLoading() when loading != null:
return loading(_that);case AboutAppReady() when ready != null:
return ready(_that);case AboutAppFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AboutAppInitial value)  initial,required TResult Function( AboutAppLoading value)  loading,required TResult Function( AboutAppReady value)  ready,required TResult Function( AboutAppFailure value)  failure,}){
final _that = this;
switch (_that) {
case AboutAppInitial():
return initial(_that);case AboutAppLoading():
return loading(_that);case AboutAppReady():
return ready(_that);case AboutAppFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AboutAppInitial value)?  initial,TResult? Function( AboutAppLoading value)?  loading,TResult? Function( AboutAppReady value)?  ready,TResult? Function( AboutAppFailure value)?  failure,}){
final _that = this;
switch (_that) {
case AboutAppInitial() when initial != null:
return initial(_that);case AboutAppLoading() when loading != null:
return loading(_that);case AboutAppReady() when ready != null:
return ready(_that);case AboutAppFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( AboutAppDataOrigin dataOrigin)?  initial,TResult Function( AboutApp? aboutApp,  List<AboutAppNote> notes,  String query,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)?  loading,TResult Function( AboutApp aboutApp,  List<AboutAppNote> notes,  int page,  bool hasMore,  String query,  AboutAppDataOrigin dataOrigin,  bool isLoadingNextPage,  AboutAppSubmissionStatus submissionStatus,  Failure? submissionFailure)?  ready,TResult Function( Failure failure,  AboutApp? aboutApp,  List<AboutAppNote> notes,  String query,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AboutAppInitial() when initial != null:
return initial(_that.dataOrigin);case AboutAppLoading() when loading != null:
return loading(_that.aboutApp,_that.notes,_that.query,_that.page,_that.hasMore,_that.dataOrigin);case AboutAppReady() when ready != null:
return ready(_that.aboutApp,_that.notes,_that.page,_that.hasMore,_that.query,_that.dataOrigin,_that.isLoadingNextPage,_that.submissionStatus,_that.submissionFailure);case AboutAppFailure() when failure != null:
return failure(_that.failure,_that.aboutApp,_that.notes,_that.query,_that.page,_that.hasMore,_that.dataOrigin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( AboutAppDataOrigin dataOrigin)  initial,required TResult Function( AboutApp? aboutApp,  List<AboutAppNote> notes,  String query,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)  loading,required TResult Function( AboutApp aboutApp,  List<AboutAppNote> notes,  int page,  bool hasMore,  String query,  AboutAppDataOrigin dataOrigin,  bool isLoadingNextPage,  AboutAppSubmissionStatus submissionStatus,  Failure? submissionFailure)  ready,required TResult Function( Failure failure,  AboutApp? aboutApp,  List<AboutAppNote> notes,  String query,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)  failure,}) {final _that = this;
switch (_that) {
case AboutAppInitial():
return initial(_that.dataOrigin);case AboutAppLoading():
return loading(_that.aboutApp,_that.notes,_that.query,_that.page,_that.hasMore,_that.dataOrigin);case AboutAppReady():
return ready(_that.aboutApp,_that.notes,_that.page,_that.hasMore,_that.query,_that.dataOrigin,_that.isLoadingNextPage,_that.submissionStatus,_that.submissionFailure);case AboutAppFailure():
return failure(_that.failure,_that.aboutApp,_that.notes,_that.query,_that.page,_that.hasMore,_that.dataOrigin);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( AboutAppDataOrigin dataOrigin)?  initial,TResult? Function( AboutApp? aboutApp,  List<AboutAppNote> notes,  String query,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)?  loading,TResult? Function( AboutApp aboutApp,  List<AboutAppNote> notes,  int page,  bool hasMore,  String query,  AboutAppDataOrigin dataOrigin,  bool isLoadingNextPage,  AboutAppSubmissionStatus submissionStatus,  Failure? submissionFailure)?  ready,TResult? Function( Failure failure,  AboutApp? aboutApp,  List<AboutAppNote> notes,  String query,  int page,  bool hasMore,  AboutAppDataOrigin dataOrigin)?  failure,}) {final _that = this;
switch (_that) {
case AboutAppInitial() when initial != null:
return initial(_that.dataOrigin);case AboutAppLoading() when loading != null:
return loading(_that.aboutApp,_that.notes,_that.query,_that.page,_that.hasMore,_that.dataOrigin);case AboutAppReady() when ready != null:
return ready(_that.aboutApp,_that.notes,_that.page,_that.hasMore,_that.query,_that.dataOrigin,_that.isLoadingNextPage,_that.submissionStatus,_that.submissionFailure);case AboutAppFailure() when failure != null:
return failure(_that.failure,_that.aboutApp,_that.notes,_that.query,_that.page,_that.hasMore,_that.dataOrigin);case _:
  return null;

}
}

}

/// @nodoc


class AboutAppInitial implements AboutAppState {
  const AboutAppInitial({this.dataOrigin = AboutAppDataOrigin.localCache});
  

@override@JsonKey() final  AboutAppDataOrigin dataOrigin;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppInitialCopyWith<AboutAppInitial> get copyWith => _$AboutAppInitialCopyWithImpl<AboutAppInitial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppInitial&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin));
}


@override
int get hashCode => Object.hash(runtimeType,dataOrigin);

@override
String toString() {
  return 'AboutAppState.initial(dataOrigin: $dataOrigin)';
}


}

/// @nodoc
abstract mixin class $AboutAppInitialCopyWith<$Res> implements $AboutAppStateCopyWith<$Res> {
  factory $AboutAppInitialCopyWith(AboutAppInitial value, $Res Function(AboutAppInitial) _then) = _$AboutAppInitialCopyWithImpl;
@override @useResult
$Res call({
 AboutAppDataOrigin dataOrigin
});




}
/// @nodoc
class _$AboutAppInitialCopyWithImpl<$Res>
    implements $AboutAppInitialCopyWith<$Res> {
  _$AboutAppInitialCopyWithImpl(this._self, this._then);

  final AboutAppInitial _self;
  final $Res Function(AboutAppInitial) _then;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dataOrigin = null,}) {
  return _then(AboutAppInitial(
dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,
  ));
}


}

/// @nodoc


class AboutAppLoading implements AboutAppState {
  const AboutAppLoading({this.aboutApp, final  List<AboutAppNote> notes = const <AboutAppNote>[], this.query = '', this.page = 0, this.hasMore = true, this.dataOrigin = AboutAppDataOrigin.localCache}): _notes = notes;
  

 final  AboutApp? aboutApp;
 final  List<AboutAppNote> _notes;
@JsonKey() List<AboutAppNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@JsonKey() final  String query;
@JsonKey() final  int page;
@JsonKey() final  bool hasMore;
@override@JsonKey() final  AboutAppDataOrigin dataOrigin;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppLoadingCopyWith<AboutAppLoading> get copyWith => _$AboutAppLoadingCopyWithImpl<AboutAppLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppLoading&&(identical(other.aboutApp, aboutApp) || other.aboutApp == aboutApp)&&const DeepCollectionEquality().equals(other._notes, _notes)&&(identical(other.query, query) || other.query == query)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin));
}


@override
int get hashCode => Object.hash(runtimeType,aboutApp,const DeepCollectionEquality().hash(_notes),query,page,hasMore,dataOrigin);

@override
String toString() {
  return 'AboutAppState.loading(aboutApp: $aboutApp, notes: $notes, query: $query, page: $page, hasMore: $hasMore, dataOrigin: $dataOrigin)';
}


}

/// @nodoc
abstract mixin class $AboutAppLoadingCopyWith<$Res> implements $AboutAppStateCopyWith<$Res> {
  factory $AboutAppLoadingCopyWith(AboutAppLoading value, $Res Function(AboutAppLoading) _then) = _$AboutAppLoadingCopyWithImpl;
@override @useResult
$Res call({
 AboutApp? aboutApp, List<AboutAppNote> notes, String query, int page, bool hasMore, AboutAppDataOrigin dataOrigin
});


$AboutAppCopyWith<$Res>? get aboutApp;

}
/// @nodoc
class _$AboutAppLoadingCopyWithImpl<$Res>
    implements $AboutAppLoadingCopyWith<$Res> {
  _$AboutAppLoadingCopyWithImpl(this._self, this._then);

  final AboutAppLoading _self;
  final $Res Function(AboutAppLoading) _then;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aboutApp = freezed,Object? notes = null,Object? query = null,Object? page = null,Object? hasMore = null,Object? dataOrigin = null,}) {
  return _then(AboutAppLoading(
aboutApp: freezed == aboutApp ? _self.aboutApp : aboutApp // ignore: cast_nullable_to_non_nullable
as AboutApp?,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<AboutAppNote>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,
  ));
}

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutAppCopyWith<$Res>? get aboutApp {
    if (_self.aboutApp == null) {
    return null;
  }

  return $AboutAppCopyWith<$Res>(_self.aboutApp!, (value) {
    return _then(_self.copyWith(aboutApp: value));
  });
}
}

/// @nodoc


class AboutAppReady implements AboutAppState {
  const AboutAppReady({required this.aboutApp, required final  List<AboutAppNote> notes, required this.page, required this.hasMore, required this.query, required this.dataOrigin, this.isLoadingNextPage = false, this.submissionStatus = AboutAppSubmissionStatus.idle, this.submissionFailure}): _notes = notes;
  

 final  AboutApp aboutApp;
 final  List<AboutAppNote> _notes;
 List<AboutAppNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

 final  int page;
 final  bool hasMore;
 final  String query;
@override final  AboutAppDataOrigin dataOrigin;
@JsonKey() final  bool isLoadingNextPage;
@JsonKey() final  AboutAppSubmissionStatus submissionStatus;
 final  Failure? submissionFailure;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppReadyCopyWith<AboutAppReady> get copyWith => _$AboutAppReadyCopyWithImpl<AboutAppReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppReady&&(identical(other.aboutApp, aboutApp) || other.aboutApp == aboutApp)&&const DeepCollectionEquality().equals(other._notes, _notes)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.query, query) || other.query == query)&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin)&&(identical(other.isLoadingNextPage, isLoadingNextPage) || other.isLoadingNextPage == isLoadingNextPage)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus)&&(identical(other.submissionFailure, submissionFailure) || other.submissionFailure == submissionFailure));
}


@override
int get hashCode => Object.hash(runtimeType,aboutApp,const DeepCollectionEquality().hash(_notes),page,hasMore,query,dataOrigin,isLoadingNextPage,submissionStatus,submissionFailure);

@override
String toString() {
  return 'AboutAppState.ready(aboutApp: $aboutApp, notes: $notes, page: $page, hasMore: $hasMore, query: $query, dataOrigin: $dataOrigin, isLoadingNextPage: $isLoadingNextPage, submissionStatus: $submissionStatus, submissionFailure: $submissionFailure)';
}


}

/// @nodoc
abstract mixin class $AboutAppReadyCopyWith<$Res> implements $AboutAppStateCopyWith<$Res> {
  factory $AboutAppReadyCopyWith(AboutAppReady value, $Res Function(AboutAppReady) _then) = _$AboutAppReadyCopyWithImpl;
@override @useResult
$Res call({
 AboutApp aboutApp, List<AboutAppNote> notes, int page, bool hasMore, String query, AboutAppDataOrigin dataOrigin, bool isLoadingNextPage, AboutAppSubmissionStatus submissionStatus, Failure? submissionFailure
});


$AboutAppCopyWith<$Res> get aboutApp;

}
/// @nodoc
class _$AboutAppReadyCopyWithImpl<$Res>
    implements $AboutAppReadyCopyWith<$Res> {
  _$AboutAppReadyCopyWithImpl(this._self, this._then);

  final AboutAppReady _self;
  final $Res Function(AboutAppReady) _then;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aboutApp = null,Object? notes = null,Object? page = null,Object? hasMore = null,Object? query = null,Object? dataOrigin = null,Object? isLoadingNextPage = null,Object? submissionStatus = null,Object? submissionFailure = freezed,}) {
  return _then(AboutAppReady(
aboutApp: null == aboutApp ? _self.aboutApp : aboutApp // ignore: cast_nullable_to_non_nullable
as AboutApp,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<AboutAppNote>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,isLoadingNextPage: null == isLoadingNextPage ? _self.isLoadingNextPage : isLoadingNextPage // ignore: cast_nullable_to_non_nullable
as bool,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as AboutAppSubmissionStatus,submissionFailure: freezed == submissionFailure ? _self.submissionFailure : submissionFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutAppCopyWith<$Res> get aboutApp {
  
  return $AboutAppCopyWith<$Res>(_self.aboutApp, (value) {
    return _then(_self.copyWith(aboutApp: value));
  });
}
}

/// @nodoc


class AboutAppFailure implements AboutAppState {
  const AboutAppFailure({required this.failure, this.aboutApp, final  List<AboutAppNote> notes = const <AboutAppNote>[], this.query = '', this.page = 0, this.hasMore = false, this.dataOrigin = AboutAppDataOrigin.localCache}): _notes = notes;
  

 final  Failure failure;
 final  AboutApp? aboutApp;
 final  List<AboutAppNote> _notes;
@JsonKey() List<AboutAppNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

@JsonKey() final  String query;
@JsonKey() final  int page;
@JsonKey() final  bool hasMore;
@override@JsonKey() final  AboutAppDataOrigin dataOrigin;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutAppFailureCopyWith<AboutAppFailure> get copyWith => _$AboutAppFailureCopyWithImpl<AboutAppFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutAppFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.aboutApp, aboutApp) || other.aboutApp == aboutApp)&&const DeepCollectionEquality().equals(other._notes, _notes)&&(identical(other.query, query) || other.query == query)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.dataOrigin, dataOrigin) || other.dataOrigin == dataOrigin));
}


@override
int get hashCode => Object.hash(runtimeType,failure,aboutApp,const DeepCollectionEquality().hash(_notes),query,page,hasMore,dataOrigin);

@override
String toString() {
  return 'AboutAppState.failure(failure: $failure, aboutApp: $aboutApp, notes: $notes, query: $query, page: $page, hasMore: $hasMore, dataOrigin: $dataOrigin)';
}


}

/// @nodoc
abstract mixin class $AboutAppFailureCopyWith<$Res> implements $AboutAppStateCopyWith<$Res> {
  factory $AboutAppFailureCopyWith(AboutAppFailure value, $Res Function(AboutAppFailure) _then) = _$AboutAppFailureCopyWithImpl;
@override @useResult
$Res call({
 Failure failure, AboutApp? aboutApp, List<AboutAppNote> notes, String query, int page, bool hasMore, AboutAppDataOrigin dataOrigin
});


$AboutAppCopyWith<$Res>? get aboutApp;

}
/// @nodoc
class _$AboutAppFailureCopyWithImpl<$Res>
    implements $AboutAppFailureCopyWith<$Res> {
  _$AboutAppFailureCopyWithImpl(this._self, this._then);

  final AboutAppFailure _self;
  final $Res Function(AboutAppFailure) _then;

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? aboutApp = freezed,Object? notes = null,Object? query = null,Object? page = null,Object? hasMore = null,Object? dataOrigin = null,}) {
  return _then(AboutAppFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,aboutApp: freezed == aboutApp ? _self.aboutApp : aboutApp // ignore: cast_nullable_to_non_nullable
as AboutApp?,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<AboutAppNote>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,dataOrigin: null == dataOrigin ? _self.dataOrigin : dataOrigin // ignore: cast_nullable_to_non_nullable
as AboutAppDataOrigin,
  ));
}

/// Create a copy of AboutAppState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutAppCopyWith<$Res>? get aboutApp {
    if (_self.aboutApp == null) {
    return null;
  }

  return $AboutAppCopyWith<$Res>(_self.aboutApp!, (value) {
    return _then(_self.copyWith(aboutApp: value));
  });
}
}

// dart format on
