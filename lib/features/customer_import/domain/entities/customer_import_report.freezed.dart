// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_import_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerImportReport {

 int get totalRows; int get importedCount; int get rejectedCount; int get duplicateCount; List<CustomerImportRowReport> get rows;
/// Create a copy of CustomerImportReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerImportReportCopyWith<CustomerImportReport> get copyWith => _$CustomerImportReportCopyWithImpl<CustomerImportReport>(this as CustomerImportReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerImportReport&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.importedCount, importedCount) || other.importedCount == importedCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&const DeepCollectionEquality().equals(other.rows, rows));
}


@override
int get hashCode => Object.hash(runtimeType,totalRows,importedCount,rejectedCount,duplicateCount,const DeepCollectionEquality().hash(rows));

@override
String toString() {
  return 'CustomerImportReport(totalRows: $totalRows, importedCount: $importedCount, rejectedCount: $rejectedCount, duplicateCount: $duplicateCount, rows: $rows)';
}


}

/// @nodoc
abstract mixin class $CustomerImportReportCopyWith<$Res>  {
  factory $CustomerImportReportCopyWith(CustomerImportReport value, $Res Function(CustomerImportReport) _then) = _$CustomerImportReportCopyWithImpl;
@useResult
$Res call({
 int totalRows, int importedCount, int rejectedCount, int duplicateCount, List<CustomerImportRowReport> rows
});




}
/// @nodoc
class _$CustomerImportReportCopyWithImpl<$Res>
    implements $CustomerImportReportCopyWith<$Res> {
  _$CustomerImportReportCopyWithImpl(this._self, this._then);

  final CustomerImportReport _self;
  final $Res Function(CustomerImportReport) _then;

/// Create a copy of CustomerImportReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalRows = null,Object? importedCount = null,Object? rejectedCount = null,Object? duplicateCount = null,Object? rows = null,}) {
  return _then(_self.copyWith(
totalRows: null == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int,importedCount: null == importedCount ? _self.importedCount : importedCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<CustomerImportRowReport>,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerImportReport].
extension CustomerImportReportPatterns on CustomerImportReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerImportReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerImportReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerImportReport value)  $default,){
final _that = this;
switch (_that) {
case _CustomerImportReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerImportReport value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerImportReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalRows,  int importedCount,  int rejectedCount,  int duplicateCount,  List<CustomerImportRowReport> rows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerImportReport() when $default != null:
return $default(_that.totalRows,_that.importedCount,_that.rejectedCount,_that.duplicateCount,_that.rows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalRows,  int importedCount,  int rejectedCount,  int duplicateCount,  List<CustomerImportRowReport> rows)  $default,) {final _that = this;
switch (_that) {
case _CustomerImportReport():
return $default(_that.totalRows,_that.importedCount,_that.rejectedCount,_that.duplicateCount,_that.rows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalRows,  int importedCount,  int rejectedCount,  int duplicateCount,  List<CustomerImportRowReport> rows)?  $default,) {final _that = this;
switch (_that) {
case _CustomerImportReport() when $default != null:
return $default(_that.totalRows,_that.importedCount,_that.rejectedCount,_that.duplicateCount,_that.rows);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerImportReport implements CustomerImportReport {
  const _CustomerImportReport({required this.totalRows, required this.importedCount, required this.rejectedCount, required this.duplicateCount, required final  List<CustomerImportRowReport> rows}): _rows = rows;
  

@override final  int totalRows;
@override final  int importedCount;
@override final  int rejectedCount;
@override final  int duplicateCount;
 final  List<CustomerImportRowReport> _rows;
@override List<CustomerImportRowReport> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of CustomerImportReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerImportReportCopyWith<_CustomerImportReport> get copyWith => __$CustomerImportReportCopyWithImpl<_CustomerImportReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerImportReport&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.importedCount, importedCount) || other.importedCount == importedCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&const DeepCollectionEquality().equals(other._rows, _rows));
}


@override
int get hashCode => Object.hash(runtimeType,totalRows,importedCount,rejectedCount,duplicateCount,const DeepCollectionEquality().hash(_rows));

@override
String toString() {
  return 'CustomerImportReport(totalRows: $totalRows, importedCount: $importedCount, rejectedCount: $rejectedCount, duplicateCount: $duplicateCount, rows: $rows)';
}


}

/// @nodoc
abstract mixin class _$CustomerImportReportCopyWith<$Res> implements $CustomerImportReportCopyWith<$Res> {
  factory _$CustomerImportReportCopyWith(_CustomerImportReport value, $Res Function(_CustomerImportReport) _then) = __$CustomerImportReportCopyWithImpl;
@override @useResult
$Res call({
 int totalRows, int importedCount, int rejectedCount, int duplicateCount, List<CustomerImportRowReport> rows
});




}
/// @nodoc
class __$CustomerImportReportCopyWithImpl<$Res>
    implements _$CustomerImportReportCopyWith<$Res> {
  __$CustomerImportReportCopyWithImpl(this._self, this._then);

  final _CustomerImportReport _self;
  final $Res Function(_CustomerImportReport) _then;

/// Create a copy of CustomerImportReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalRows = null,Object? importedCount = null,Object? rejectedCount = null,Object? duplicateCount = null,Object? rows = null,}) {
  return _then(_CustomerImportReport(
totalRows: null == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int,importedCount: null == importedCount ? _self.importedCount : importedCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<CustomerImportRowReport>,
  ));
}


}

// dart format on
