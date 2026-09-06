// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_import_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerImportPreview {

 String get fileName; bool get isXlsx; List<String> get headers; List<List<String>> get sampleRows;/// Best-effort row count of the whole file (CSV: line count; XLSX:
/// sheet's own reported row count) — `null` when it could not be
/// determined cheaply. Only ever shown to the gestor as an estimate,
/// never relied on for correctness: the Cloud Function counts the real
/// total itself while processing.
 int? get totalRowsHint;
/// Create a copy of CustomerImportPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerImportPreviewCopyWith<CustomerImportPreview> get copyWith => _$CustomerImportPreviewCopyWithImpl<CustomerImportPreview>(this as CustomerImportPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerImportPreview&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.isXlsx, isXlsx) || other.isXlsx == isXlsx)&&const DeepCollectionEquality().equals(other.headers, headers)&&const DeepCollectionEquality().equals(other.sampleRows, sampleRows)&&(identical(other.totalRowsHint, totalRowsHint) || other.totalRowsHint == totalRowsHint));
}


@override
int get hashCode => Object.hash(runtimeType,fileName,isXlsx,const DeepCollectionEquality().hash(headers),const DeepCollectionEquality().hash(sampleRows),totalRowsHint);

@override
String toString() {
  return 'CustomerImportPreview(fileName: $fileName, isXlsx: $isXlsx, headers: $headers, sampleRows: $sampleRows, totalRowsHint: $totalRowsHint)';
}


}

/// @nodoc
abstract mixin class $CustomerImportPreviewCopyWith<$Res>  {
  factory $CustomerImportPreviewCopyWith(CustomerImportPreview value, $Res Function(CustomerImportPreview) _then) = _$CustomerImportPreviewCopyWithImpl;
@useResult
$Res call({
 String fileName, bool isXlsx, List<String> headers, List<List<String>> sampleRows, int? totalRowsHint
});




}
/// @nodoc
class _$CustomerImportPreviewCopyWithImpl<$Res>
    implements $CustomerImportPreviewCopyWith<$Res> {
  _$CustomerImportPreviewCopyWithImpl(this._self, this._then);

  final CustomerImportPreview _self;
  final $Res Function(CustomerImportPreview) _then;

/// Create a copy of CustomerImportPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? isXlsx = null,Object? headers = null,Object? sampleRows = null,Object? totalRowsHint = freezed,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,isXlsx: null == isXlsx ? _self.isXlsx : isXlsx // ignore: cast_nullable_to_non_nullable
as bool,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as List<String>,sampleRows: null == sampleRows ? _self.sampleRows : sampleRows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,totalRowsHint: freezed == totalRowsHint ? _self.totalRowsHint : totalRowsHint // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerImportPreview].
extension CustomerImportPreviewPatterns on CustomerImportPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerImportPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerImportPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerImportPreview value)  $default,){
final _that = this;
switch (_that) {
case _CustomerImportPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerImportPreview value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerImportPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  bool isXlsx,  List<String> headers,  List<List<String>> sampleRows,  int? totalRowsHint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerImportPreview() when $default != null:
return $default(_that.fileName,_that.isXlsx,_that.headers,_that.sampleRows,_that.totalRowsHint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  bool isXlsx,  List<String> headers,  List<List<String>> sampleRows,  int? totalRowsHint)  $default,) {final _that = this;
switch (_that) {
case _CustomerImportPreview():
return $default(_that.fileName,_that.isXlsx,_that.headers,_that.sampleRows,_that.totalRowsHint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  bool isXlsx,  List<String> headers,  List<List<String>> sampleRows,  int? totalRowsHint)?  $default,) {final _that = this;
switch (_that) {
case _CustomerImportPreview() when $default != null:
return $default(_that.fileName,_that.isXlsx,_that.headers,_that.sampleRows,_that.totalRowsHint);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerImportPreview implements CustomerImportPreview {
  const _CustomerImportPreview({required this.fileName, required this.isXlsx, required final  List<String> headers, required final  List<List<String>> sampleRows, this.totalRowsHint}): _headers = headers,_sampleRows = sampleRows;
  

@override final  String fileName;
@override final  bool isXlsx;
 final  List<String> _headers;
@override List<String> get headers {
  if (_headers is EqualUnmodifiableListView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_headers);
}

 final  List<List<String>> _sampleRows;
@override List<List<String>> get sampleRows {
  if (_sampleRows is EqualUnmodifiableListView) return _sampleRows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sampleRows);
}

/// Best-effort row count of the whole file (CSV: line count; XLSX:
/// sheet's own reported row count) — `null` when it could not be
/// determined cheaply. Only ever shown to the gestor as an estimate,
/// never relied on for correctness: the Cloud Function counts the real
/// total itself while processing.
@override final  int? totalRowsHint;

/// Create a copy of CustomerImportPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerImportPreviewCopyWith<_CustomerImportPreview> get copyWith => __$CustomerImportPreviewCopyWithImpl<_CustomerImportPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerImportPreview&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.isXlsx, isXlsx) || other.isXlsx == isXlsx)&&const DeepCollectionEquality().equals(other._headers, _headers)&&const DeepCollectionEquality().equals(other._sampleRows, _sampleRows)&&(identical(other.totalRowsHint, totalRowsHint) || other.totalRowsHint == totalRowsHint));
}


@override
int get hashCode => Object.hash(runtimeType,fileName,isXlsx,const DeepCollectionEquality().hash(_headers),const DeepCollectionEquality().hash(_sampleRows),totalRowsHint);

@override
String toString() {
  return 'CustomerImportPreview(fileName: $fileName, isXlsx: $isXlsx, headers: $headers, sampleRows: $sampleRows, totalRowsHint: $totalRowsHint)';
}


}

/// @nodoc
abstract mixin class _$CustomerImportPreviewCopyWith<$Res> implements $CustomerImportPreviewCopyWith<$Res> {
  factory _$CustomerImportPreviewCopyWith(_CustomerImportPreview value, $Res Function(_CustomerImportPreview) _then) = __$CustomerImportPreviewCopyWithImpl;
@override @useResult
$Res call({
 String fileName, bool isXlsx, List<String> headers, List<List<String>> sampleRows, int? totalRowsHint
});




}
/// @nodoc
class __$CustomerImportPreviewCopyWithImpl<$Res>
    implements _$CustomerImportPreviewCopyWith<$Res> {
  __$CustomerImportPreviewCopyWithImpl(this._self, this._then);

  final _CustomerImportPreview _self;
  final $Res Function(_CustomerImportPreview) _then;

/// Create a copy of CustomerImportPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? isXlsx = null,Object? headers = null,Object? sampleRows = null,Object? totalRowsHint = freezed,}) {
  return _then(_CustomerImportPreview(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,isXlsx: null == isXlsx ? _self.isXlsx : isXlsx // ignore: cast_nullable_to_non_nullable
as bool,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as List<String>,sampleRows: null == sampleRows ? _self._sampleRows : sampleRows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,totalRowsHint: freezed == totalRowsHint ? _self.totalRowsHint : totalRowsHint // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
