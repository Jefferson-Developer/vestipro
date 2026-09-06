// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportReport {

 int get totalRows; int get createdProductsCount; int get createdVariantsCount; int get imagesAssociatedCount; int get imagesOrphanCount; int get rejectedCount; List<ProductImportRowReport> get rows;/// File names from the uploaded image package that matched no SKU/
/// reference in the spreadsheet — reported, never blocking the import
/// of the products themselves (`tasks.md`).
 List<String> get orphanImageFileNames;
/// Create a copy of ProductImportReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportReportCopyWith<ProductImportReport> get copyWith => _$ProductImportReportCopyWithImpl<ProductImportReport>(this as ProductImportReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportReport&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.createdProductsCount, createdProductsCount) || other.createdProductsCount == createdProductsCount)&&(identical(other.createdVariantsCount, createdVariantsCount) || other.createdVariantsCount == createdVariantsCount)&&(identical(other.imagesAssociatedCount, imagesAssociatedCount) || other.imagesAssociatedCount == imagesAssociatedCount)&&(identical(other.imagesOrphanCount, imagesOrphanCount) || other.imagesOrphanCount == imagesOrphanCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.orphanImageFileNames, orphanImageFileNames));
}


@override
int get hashCode => Object.hash(runtimeType,totalRows,createdProductsCount,createdVariantsCount,imagesAssociatedCount,imagesOrphanCount,rejectedCount,const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(orphanImageFileNames));

@override
String toString() {
  return 'ProductImportReport(totalRows: $totalRows, createdProductsCount: $createdProductsCount, createdVariantsCount: $createdVariantsCount, imagesAssociatedCount: $imagesAssociatedCount, imagesOrphanCount: $imagesOrphanCount, rejectedCount: $rejectedCount, rows: $rows, orphanImageFileNames: $orphanImageFileNames)';
}


}

/// @nodoc
abstract mixin class $ProductImportReportCopyWith<$Res>  {
  factory $ProductImportReportCopyWith(ProductImportReport value, $Res Function(ProductImportReport) _then) = _$ProductImportReportCopyWithImpl;
@useResult
$Res call({
 int totalRows, int createdProductsCount, int createdVariantsCount, int imagesAssociatedCount, int imagesOrphanCount, int rejectedCount, List<ProductImportRowReport> rows, List<String> orphanImageFileNames
});




}
/// @nodoc
class _$ProductImportReportCopyWithImpl<$Res>
    implements $ProductImportReportCopyWith<$Res> {
  _$ProductImportReportCopyWithImpl(this._self, this._then);

  final ProductImportReport _self;
  final $Res Function(ProductImportReport) _then;

/// Create a copy of ProductImportReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalRows = null,Object? createdProductsCount = null,Object? createdVariantsCount = null,Object? imagesAssociatedCount = null,Object? imagesOrphanCount = null,Object? rejectedCount = null,Object? rows = null,Object? orphanImageFileNames = null,}) {
  return _then(_self.copyWith(
totalRows: null == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int,createdProductsCount: null == createdProductsCount ? _self.createdProductsCount : createdProductsCount // ignore: cast_nullable_to_non_nullable
as int,createdVariantsCount: null == createdVariantsCount ? _self.createdVariantsCount : createdVariantsCount // ignore: cast_nullable_to_non_nullable
as int,imagesAssociatedCount: null == imagesAssociatedCount ? _self.imagesAssociatedCount : imagesAssociatedCount // ignore: cast_nullable_to_non_nullable
as int,imagesOrphanCount: null == imagesOrphanCount ? _self.imagesOrphanCount : imagesOrphanCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<ProductImportRowReport>,orphanImageFileNames: null == orphanImageFileNames ? _self.orphanImageFileNames : orphanImageFileNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImportReport].
extension ProductImportReportPatterns on ProductImportReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportReport value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportReport value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalRows,  int createdProductsCount,  int createdVariantsCount,  int imagesAssociatedCount,  int imagesOrphanCount,  int rejectedCount,  List<ProductImportRowReport> rows,  List<String> orphanImageFileNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImportReport() when $default != null:
return $default(_that.totalRows,_that.createdProductsCount,_that.createdVariantsCount,_that.imagesAssociatedCount,_that.imagesOrphanCount,_that.rejectedCount,_that.rows,_that.orphanImageFileNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalRows,  int createdProductsCount,  int createdVariantsCount,  int imagesAssociatedCount,  int imagesOrphanCount,  int rejectedCount,  List<ProductImportRowReport> rows,  List<String> orphanImageFileNames)  $default,) {final _that = this;
switch (_that) {
case _ProductImportReport():
return $default(_that.totalRows,_that.createdProductsCount,_that.createdVariantsCount,_that.imagesAssociatedCount,_that.imagesOrphanCount,_that.rejectedCount,_that.rows,_that.orphanImageFileNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalRows,  int createdProductsCount,  int createdVariantsCount,  int imagesAssociatedCount,  int imagesOrphanCount,  int rejectedCount,  List<ProductImportRowReport> rows,  List<String> orphanImageFileNames)?  $default,) {final _that = this;
switch (_that) {
case _ProductImportReport() when $default != null:
return $default(_that.totalRows,_that.createdProductsCount,_that.createdVariantsCount,_that.imagesAssociatedCount,_that.imagesOrphanCount,_that.rejectedCount,_that.rows,_that.orphanImageFileNames);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportReport implements ProductImportReport {
  const _ProductImportReport({required this.totalRows, required this.createdProductsCount, required this.createdVariantsCount, required this.imagesAssociatedCount, required this.imagesOrphanCount, required this.rejectedCount, required final  List<ProductImportRowReport> rows, final  List<String> orphanImageFileNames = const <String>[]}): _rows = rows,_orphanImageFileNames = orphanImageFileNames;
  

@override final  int totalRows;
@override final  int createdProductsCount;
@override final  int createdVariantsCount;
@override final  int imagesAssociatedCount;
@override final  int imagesOrphanCount;
@override final  int rejectedCount;
 final  List<ProductImportRowReport> _rows;
@override List<ProductImportRowReport> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

/// File names from the uploaded image package that matched no SKU/
/// reference in the spreadsheet — reported, never blocking the import
/// of the products themselves (`tasks.md`).
 final  List<String> _orphanImageFileNames;
/// File names from the uploaded image package that matched no SKU/
/// reference in the spreadsheet — reported, never blocking the import
/// of the products themselves (`tasks.md`).
@override@JsonKey() List<String> get orphanImageFileNames {
  if (_orphanImageFileNames is EqualUnmodifiableListView) return _orphanImageFileNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orphanImageFileNames);
}


/// Create a copy of ProductImportReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportReportCopyWith<_ProductImportReport> get copyWith => __$ProductImportReportCopyWithImpl<_ProductImportReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportReport&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.createdProductsCount, createdProductsCount) || other.createdProductsCount == createdProductsCount)&&(identical(other.createdVariantsCount, createdVariantsCount) || other.createdVariantsCount == createdVariantsCount)&&(identical(other.imagesAssociatedCount, imagesAssociatedCount) || other.imagesAssociatedCount == imagesAssociatedCount)&&(identical(other.imagesOrphanCount, imagesOrphanCount) || other.imagesOrphanCount == imagesOrphanCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._orphanImageFileNames, _orphanImageFileNames));
}


@override
int get hashCode => Object.hash(runtimeType,totalRows,createdProductsCount,createdVariantsCount,imagesAssociatedCount,imagesOrphanCount,rejectedCount,const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_orphanImageFileNames));

@override
String toString() {
  return 'ProductImportReport(totalRows: $totalRows, createdProductsCount: $createdProductsCount, createdVariantsCount: $createdVariantsCount, imagesAssociatedCount: $imagesAssociatedCount, imagesOrphanCount: $imagesOrphanCount, rejectedCount: $rejectedCount, rows: $rows, orphanImageFileNames: $orphanImageFileNames)';
}


}

/// @nodoc
abstract mixin class _$ProductImportReportCopyWith<$Res> implements $ProductImportReportCopyWith<$Res> {
  factory _$ProductImportReportCopyWith(_ProductImportReport value, $Res Function(_ProductImportReport) _then) = __$ProductImportReportCopyWithImpl;
@override @useResult
$Res call({
 int totalRows, int createdProductsCount, int createdVariantsCount, int imagesAssociatedCount, int imagesOrphanCount, int rejectedCount, List<ProductImportRowReport> rows, List<String> orphanImageFileNames
});




}
/// @nodoc
class __$ProductImportReportCopyWithImpl<$Res>
    implements _$ProductImportReportCopyWith<$Res> {
  __$ProductImportReportCopyWithImpl(this._self, this._then);

  final _ProductImportReport _self;
  final $Res Function(_ProductImportReport) _then;

/// Create a copy of ProductImportReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalRows = null,Object? createdProductsCount = null,Object? createdVariantsCount = null,Object? imagesAssociatedCount = null,Object? imagesOrphanCount = null,Object? rejectedCount = null,Object? rows = null,Object? orphanImageFileNames = null,}) {
  return _then(_ProductImportReport(
totalRows: null == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int,createdProductsCount: null == createdProductsCount ? _self.createdProductsCount : createdProductsCount // ignore: cast_nullable_to_non_nullable
as int,createdVariantsCount: null == createdVariantsCount ? _self.createdVariantsCount : createdVariantsCount // ignore: cast_nullable_to_non_nullable
as int,imagesAssociatedCount: null == imagesAssociatedCount ? _self.imagesAssociatedCount : imagesAssociatedCount // ignore: cast_nullable_to_non_nullable
as int,imagesOrphanCount: null == imagesOrphanCount ? _self.imagesOrphanCount : imagesOrphanCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<ProductImportRowReport>,orphanImageFileNames: null == orphanImageFileNames ? _self._orphanImageFileNames : orphanImageFileNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
