// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportPreview {

 String get fileName; bool get isXlsx; List<String> get headers; List<List<String>> get sampleRows; int? get totalRowsHint;
/// Create a copy of ProductImportPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportPreviewCopyWith<ProductImportPreview> get copyWith => _$ProductImportPreviewCopyWithImpl<ProductImportPreview>(this as ProductImportPreview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportPreview&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.isXlsx, isXlsx) || other.isXlsx == isXlsx)&&const DeepCollectionEquality().equals(other.headers, headers)&&const DeepCollectionEquality().equals(other.sampleRows, sampleRows)&&(identical(other.totalRowsHint, totalRowsHint) || other.totalRowsHint == totalRowsHint));
}


@override
int get hashCode => Object.hash(runtimeType,fileName,isXlsx,const DeepCollectionEquality().hash(headers),const DeepCollectionEquality().hash(sampleRows),totalRowsHint);

@override
String toString() {
  return 'ProductImportPreview(fileName: $fileName, isXlsx: $isXlsx, headers: $headers, sampleRows: $sampleRows, totalRowsHint: $totalRowsHint)';
}


}

/// @nodoc
abstract mixin class $ProductImportPreviewCopyWith<$Res>  {
  factory $ProductImportPreviewCopyWith(ProductImportPreview value, $Res Function(ProductImportPreview) _then) = _$ProductImportPreviewCopyWithImpl;
@useResult
$Res call({
 String fileName, bool isXlsx, List<String> headers, List<List<String>> sampleRows, int? totalRowsHint
});




}
/// @nodoc
class _$ProductImportPreviewCopyWithImpl<$Res>
    implements $ProductImportPreviewCopyWith<$Res> {
  _$ProductImportPreviewCopyWithImpl(this._self, this._then);

  final ProductImportPreview _self;
  final $Res Function(ProductImportPreview) _then;

/// Create a copy of ProductImportPreview
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


/// Adds pattern-matching-related methods to [ProductImportPreview].
extension ProductImportPreviewPatterns on ProductImportPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportPreview value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportPreview value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportPreview() when $default != null:
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
case _ProductImportPreview() when $default != null:
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
case _ProductImportPreview():
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
case _ProductImportPreview() when $default != null:
return $default(_that.fileName,_that.isXlsx,_that.headers,_that.sampleRows,_that.totalRowsHint);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportPreview implements ProductImportPreview {
  const _ProductImportPreview({required this.fileName, required this.isXlsx, required final  List<String> headers, required final  List<List<String>> sampleRows, this.totalRowsHint}): _headers = headers,_sampleRows = sampleRows;
  

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

@override final  int? totalRowsHint;

/// Create a copy of ProductImportPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportPreviewCopyWith<_ProductImportPreview> get copyWith => __$ProductImportPreviewCopyWithImpl<_ProductImportPreview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportPreview&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.isXlsx, isXlsx) || other.isXlsx == isXlsx)&&const DeepCollectionEquality().equals(other._headers, _headers)&&const DeepCollectionEquality().equals(other._sampleRows, _sampleRows)&&(identical(other.totalRowsHint, totalRowsHint) || other.totalRowsHint == totalRowsHint));
}


@override
int get hashCode => Object.hash(runtimeType,fileName,isXlsx,const DeepCollectionEquality().hash(_headers),const DeepCollectionEquality().hash(_sampleRows),totalRowsHint);

@override
String toString() {
  return 'ProductImportPreview(fileName: $fileName, isXlsx: $isXlsx, headers: $headers, sampleRows: $sampleRows, totalRowsHint: $totalRowsHint)';
}


}

/// @nodoc
abstract mixin class _$ProductImportPreviewCopyWith<$Res> implements $ProductImportPreviewCopyWith<$Res> {
  factory _$ProductImportPreviewCopyWith(_ProductImportPreview value, $Res Function(_ProductImportPreview) _then) = __$ProductImportPreviewCopyWithImpl;
@override @useResult
$Res call({
 String fileName, bool isXlsx, List<String> headers, List<List<String>> sampleRows, int? totalRowsHint
});




}
/// @nodoc
class __$ProductImportPreviewCopyWithImpl<$Res>
    implements _$ProductImportPreviewCopyWith<$Res> {
  __$ProductImportPreviewCopyWithImpl(this._self, this._then);

  final _ProductImportPreview _self;
  final $Res Function(_ProductImportPreview) _then;

/// Create a copy of ProductImportPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? isXlsx = null,Object? headers = null,Object? sampleRows = null,Object? totalRowsHint = freezed,}) {
  return _then(_ProductImportPreview(
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
