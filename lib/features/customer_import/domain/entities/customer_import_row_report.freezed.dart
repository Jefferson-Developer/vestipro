// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_import_row_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerImportRowReport {

/// 1-based position in the source file, counting only data rows (not
/// the header, when [CustomerImportMapping.hasHeaderRow] is true) — the
/// same numbering the gestor sees when they open the spreadsheet.
 int get rowNumber; CustomerImportRowOutcome get outcome;/// Human-readable reason, always present for [CustomerImportRowOutcome
/// .rejected]/`duplicateInFile`/`duplicateExisting`, always absent for
/// `imported`.
 String? get reason;/// The created `Customer.id`, only for [CustomerImportRowOutcome
/// .imported].
 String? get createdCustomerId;/// The `Customer.id` this row collided with, only for
/// [CustomerImportRowOutcome.duplicateExisting] — lets the gestor jump
/// straight to the existing customer record.
 String? get matchedExistingCustomerId;/// Whether [matchedExistingCustomerId] matched by e-mail only (not by
/// document) — the only case `resolveCustomerImportDuplicateRow` accepts
/// [CustomerImportDuplicateResolution.createAnyway] for.
 bool get matchedByEmailOnly;/// The gestor's decision for a `duplicateExisting` row, once resolved —
/// `null` while still pending review.
 String? get resolution;/// Raw mapped values as read from the spreadsheet (field code -> raw
/// text), shown in the report row for context without needing the
/// original file again.
 Map<String, String> get rawValues;
/// Create a copy of CustomerImportRowReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerImportRowReportCopyWith<CustomerImportRowReport> get copyWith => _$CustomerImportRowReportCopyWithImpl<CustomerImportRowReport>(this as CustomerImportRowReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerImportRowReport&&(identical(other.rowNumber, rowNumber) || other.rowNumber == rowNumber)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdCustomerId, createdCustomerId) || other.createdCustomerId == createdCustomerId)&&(identical(other.matchedExistingCustomerId, matchedExistingCustomerId) || other.matchedExistingCustomerId == matchedExistingCustomerId)&&(identical(other.matchedByEmailOnly, matchedByEmailOnly) || other.matchedByEmailOnly == matchedByEmailOnly)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&const DeepCollectionEquality().equals(other.rawValues, rawValues));
}


@override
int get hashCode => Object.hash(runtimeType,rowNumber,outcome,reason,createdCustomerId,matchedExistingCustomerId,matchedByEmailOnly,resolution,const DeepCollectionEquality().hash(rawValues));

@override
String toString() {
  return 'CustomerImportRowReport(rowNumber: $rowNumber, outcome: $outcome, reason: $reason, createdCustomerId: $createdCustomerId, matchedExistingCustomerId: $matchedExistingCustomerId, matchedByEmailOnly: $matchedByEmailOnly, resolution: $resolution, rawValues: $rawValues)';
}


}

/// @nodoc
abstract mixin class $CustomerImportRowReportCopyWith<$Res>  {
  factory $CustomerImportRowReportCopyWith(CustomerImportRowReport value, $Res Function(CustomerImportRowReport) _then) = _$CustomerImportRowReportCopyWithImpl;
@useResult
$Res call({
 int rowNumber, CustomerImportRowOutcome outcome, String? reason, String? createdCustomerId, String? matchedExistingCustomerId, bool matchedByEmailOnly, String? resolution, Map<String, String> rawValues
});




}
/// @nodoc
class _$CustomerImportRowReportCopyWithImpl<$Res>
    implements $CustomerImportRowReportCopyWith<$Res> {
  _$CustomerImportRowReportCopyWithImpl(this._self, this._then);

  final CustomerImportRowReport _self;
  final $Res Function(CustomerImportRowReport) _then;

/// Create a copy of CustomerImportRowReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowNumber = null,Object? outcome = null,Object? reason = freezed,Object? createdCustomerId = freezed,Object? matchedExistingCustomerId = freezed,Object? matchedByEmailOnly = null,Object? resolution = freezed,Object? rawValues = null,}) {
  return _then(_self.copyWith(
rowNumber: null == rowNumber ? _self.rowNumber : rowNumber // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CustomerImportRowOutcome,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdCustomerId: freezed == createdCustomerId ? _self.createdCustomerId : createdCustomerId // ignore: cast_nullable_to_non_nullable
as String?,matchedExistingCustomerId: freezed == matchedExistingCustomerId ? _self.matchedExistingCustomerId : matchedExistingCustomerId // ignore: cast_nullable_to_non_nullable
as String?,matchedByEmailOnly: null == matchedByEmailOnly ? _self.matchedByEmailOnly : matchedByEmailOnly // ignore: cast_nullable_to_non_nullable
as bool,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,rawValues: null == rawValues ? _self.rawValues : rawValues // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerImportRowReport].
extension CustomerImportRowReportPatterns on CustomerImportRowReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerImportRowReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerImportRowReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerImportRowReport value)  $default,){
final _that = this;
switch (_that) {
case _CustomerImportRowReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerImportRowReport value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerImportRowReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowNumber,  CustomerImportRowOutcome outcome,  String? reason,  String? createdCustomerId,  String? matchedExistingCustomerId,  bool matchedByEmailOnly,  String? resolution,  Map<String, String> rawValues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerImportRowReport() when $default != null:
return $default(_that.rowNumber,_that.outcome,_that.reason,_that.createdCustomerId,_that.matchedExistingCustomerId,_that.matchedByEmailOnly,_that.resolution,_that.rawValues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowNumber,  CustomerImportRowOutcome outcome,  String? reason,  String? createdCustomerId,  String? matchedExistingCustomerId,  bool matchedByEmailOnly,  String? resolution,  Map<String, String> rawValues)  $default,) {final _that = this;
switch (_that) {
case _CustomerImportRowReport():
return $default(_that.rowNumber,_that.outcome,_that.reason,_that.createdCustomerId,_that.matchedExistingCustomerId,_that.matchedByEmailOnly,_that.resolution,_that.rawValues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowNumber,  CustomerImportRowOutcome outcome,  String? reason,  String? createdCustomerId,  String? matchedExistingCustomerId,  bool matchedByEmailOnly,  String? resolution,  Map<String, String> rawValues)?  $default,) {final _that = this;
switch (_that) {
case _CustomerImportRowReport() when $default != null:
return $default(_that.rowNumber,_that.outcome,_that.reason,_that.createdCustomerId,_that.matchedExistingCustomerId,_that.matchedByEmailOnly,_that.resolution,_that.rawValues);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerImportRowReport implements CustomerImportRowReport {
  const _CustomerImportRowReport({required this.rowNumber, required this.outcome, this.reason, this.createdCustomerId, this.matchedExistingCustomerId, this.matchedByEmailOnly = false, this.resolution, final  Map<String, String> rawValues = const <String, String>{}}): _rawValues = rawValues;
  

/// 1-based position in the source file, counting only data rows (not
/// the header, when [CustomerImportMapping.hasHeaderRow] is true) — the
/// same numbering the gestor sees when they open the spreadsheet.
@override final  int rowNumber;
@override final  CustomerImportRowOutcome outcome;
/// Human-readable reason, always present for [CustomerImportRowOutcome
/// .rejected]/`duplicateInFile`/`duplicateExisting`, always absent for
/// `imported`.
@override final  String? reason;
/// The created `Customer.id`, only for [CustomerImportRowOutcome
/// .imported].
@override final  String? createdCustomerId;
/// The `Customer.id` this row collided with, only for
/// [CustomerImportRowOutcome.duplicateExisting] — lets the gestor jump
/// straight to the existing customer record.
@override final  String? matchedExistingCustomerId;
/// Whether [matchedExistingCustomerId] matched by e-mail only (not by
/// document) — the only case `resolveCustomerImportDuplicateRow` accepts
/// [CustomerImportDuplicateResolution.createAnyway] for.
@override@JsonKey() final  bool matchedByEmailOnly;
/// The gestor's decision for a `duplicateExisting` row, once resolved —
/// `null` while still pending review.
@override final  String? resolution;
/// Raw mapped values as read from the spreadsheet (field code -> raw
/// text), shown in the report row for context without needing the
/// original file again.
 final  Map<String, String> _rawValues;
/// Raw mapped values as read from the spreadsheet (field code -> raw
/// text), shown in the report row for context without needing the
/// original file again.
@override@JsonKey() Map<String, String> get rawValues {
  if (_rawValues is EqualUnmodifiableMapView) return _rawValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rawValues);
}


/// Create a copy of CustomerImportRowReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerImportRowReportCopyWith<_CustomerImportRowReport> get copyWith => __$CustomerImportRowReportCopyWithImpl<_CustomerImportRowReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerImportRowReport&&(identical(other.rowNumber, rowNumber) || other.rowNumber == rowNumber)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdCustomerId, createdCustomerId) || other.createdCustomerId == createdCustomerId)&&(identical(other.matchedExistingCustomerId, matchedExistingCustomerId) || other.matchedExistingCustomerId == matchedExistingCustomerId)&&(identical(other.matchedByEmailOnly, matchedByEmailOnly) || other.matchedByEmailOnly == matchedByEmailOnly)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&const DeepCollectionEquality().equals(other._rawValues, _rawValues));
}


@override
int get hashCode => Object.hash(runtimeType,rowNumber,outcome,reason,createdCustomerId,matchedExistingCustomerId,matchedByEmailOnly,resolution,const DeepCollectionEquality().hash(_rawValues));

@override
String toString() {
  return 'CustomerImportRowReport(rowNumber: $rowNumber, outcome: $outcome, reason: $reason, createdCustomerId: $createdCustomerId, matchedExistingCustomerId: $matchedExistingCustomerId, matchedByEmailOnly: $matchedByEmailOnly, resolution: $resolution, rawValues: $rawValues)';
}


}

/// @nodoc
abstract mixin class _$CustomerImportRowReportCopyWith<$Res> implements $CustomerImportRowReportCopyWith<$Res> {
  factory _$CustomerImportRowReportCopyWith(_CustomerImportRowReport value, $Res Function(_CustomerImportRowReport) _then) = __$CustomerImportRowReportCopyWithImpl;
@override @useResult
$Res call({
 int rowNumber, CustomerImportRowOutcome outcome, String? reason, String? createdCustomerId, String? matchedExistingCustomerId, bool matchedByEmailOnly, String? resolution, Map<String, String> rawValues
});




}
/// @nodoc
class __$CustomerImportRowReportCopyWithImpl<$Res>
    implements _$CustomerImportRowReportCopyWith<$Res> {
  __$CustomerImportRowReportCopyWithImpl(this._self, this._then);

  final _CustomerImportRowReport _self;
  final $Res Function(_CustomerImportRowReport) _then;

/// Create a copy of CustomerImportRowReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowNumber = null,Object? outcome = null,Object? reason = freezed,Object? createdCustomerId = freezed,Object? matchedExistingCustomerId = freezed,Object? matchedByEmailOnly = null,Object? resolution = freezed,Object? rawValues = null,}) {
  return _then(_CustomerImportRowReport(
rowNumber: null == rowNumber ? _self.rowNumber : rowNumber // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CustomerImportRowOutcome,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdCustomerId: freezed == createdCustomerId ? _self.createdCustomerId : createdCustomerId // ignore: cast_nullable_to_non_nullable
as String?,matchedExistingCustomerId: freezed == matchedExistingCustomerId ? _self.matchedExistingCustomerId : matchedExistingCustomerId // ignore: cast_nullable_to_non_nullable
as String?,matchedByEmailOnly: null == matchedByEmailOnly ? _self.matchedByEmailOnly : matchedByEmailOnly // ignore: cast_nullable_to_non_nullable
as bool,resolution: freezed == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as String?,rawValues: null == rawValues ? _self._rawValues : rawValues // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
