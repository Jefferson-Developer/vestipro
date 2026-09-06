// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_row_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportRowReport {

/// 1-based position in the source file, counting only data rows.
 int get rowNumber; ProductImportRowOutcome get outcome;/// Human-readable reason, always present for
/// [ProductImportRowOutcome.rejected], always absent for `created`.
 String? get reason; String? get sku;/// The created `Product.id`, only for [ProductImportRowOutcome.created].
 String? get createdProductId;/// The created `ProductVariant.id`, only for
/// [ProductImportRowOutcome.created].
 String? get createdVariantId;/// Whether an uploaded image was matched to this row's SKU/reference —
/// always `false` for a rejected row.
 bool get imageAssociated;/// Raw mapped values as read from the spreadsheet (field code -> raw
/// text), shown in the report row for context.
 Map<String, String> get rawValues;
/// Create a copy of ProductImportRowReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportRowReportCopyWith<ProductImportRowReport> get copyWith => _$ProductImportRowReportCopyWithImpl<ProductImportRowReport>(this as ProductImportRowReport, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportRowReport&&(identical(other.rowNumber, rowNumber) || other.rowNumber == rowNumber)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.createdProductId, createdProductId) || other.createdProductId == createdProductId)&&(identical(other.createdVariantId, createdVariantId) || other.createdVariantId == createdVariantId)&&(identical(other.imageAssociated, imageAssociated) || other.imageAssociated == imageAssociated)&&const DeepCollectionEquality().equals(other.rawValues, rawValues));
}


@override
int get hashCode => Object.hash(runtimeType,rowNumber,outcome,reason,sku,createdProductId,createdVariantId,imageAssociated,const DeepCollectionEquality().hash(rawValues));

@override
String toString() {
  return 'ProductImportRowReport(rowNumber: $rowNumber, outcome: $outcome, reason: $reason, sku: $sku, createdProductId: $createdProductId, createdVariantId: $createdVariantId, imageAssociated: $imageAssociated, rawValues: $rawValues)';
}


}

/// @nodoc
abstract mixin class $ProductImportRowReportCopyWith<$Res>  {
  factory $ProductImportRowReportCopyWith(ProductImportRowReport value, $Res Function(ProductImportRowReport) _then) = _$ProductImportRowReportCopyWithImpl;
@useResult
$Res call({
 int rowNumber, ProductImportRowOutcome outcome, String? reason, String? sku, String? createdProductId, String? createdVariantId, bool imageAssociated, Map<String, String> rawValues
});




}
/// @nodoc
class _$ProductImportRowReportCopyWithImpl<$Res>
    implements $ProductImportRowReportCopyWith<$Res> {
  _$ProductImportRowReportCopyWithImpl(this._self, this._then);

  final ProductImportRowReport _self;
  final $Res Function(ProductImportRowReport) _then;

/// Create a copy of ProductImportRowReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowNumber = null,Object? outcome = null,Object? reason = freezed,Object? sku = freezed,Object? createdProductId = freezed,Object? createdVariantId = freezed,Object? imageAssociated = null,Object? rawValues = null,}) {
  return _then(_self.copyWith(
rowNumber: null == rowNumber ? _self.rowNumber : rowNumber // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as ProductImportRowOutcome,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,createdProductId: freezed == createdProductId ? _self.createdProductId : createdProductId // ignore: cast_nullable_to_non_nullable
as String?,createdVariantId: freezed == createdVariantId ? _self.createdVariantId : createdVariantId // ignore: cast_nullable_to_non_nullable
as String?,imageAssociated: null == imageAssociated ? _self.imageAssociated : imageAssociated // ignore: cast_nullable_to_non_nullable
as bool,rawValues: null == rawValues ? _self.rawValues : rawValues // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImportRowReport].
extension ProductImportRowReportPatterns on ProductImportRowReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportRowReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportRowReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportRowReport value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportRowReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportRowReport value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportRowReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rowNumber,  ProductImportRowOutcome outcome,  String? reason,  String? sku,  String? createdProductId,  String? createdVariantId,  bool imageAssociated,  Map<String, String> rawValues)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImportRowReport() when $default != null:
return $default(_that.rowNumber,_that.outcome,_that.reason,_that.sku,_that.createdProductId,_that.createdVariantId,_that.imageAssociated,_that.rawValues);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rowNumber,  ProductImportRowOutcome outcome,  String? reason,  String? sku,  String? createdProductId,  String? createdVariantId,  bool imageAssociated,  Map<String, String> rawValues)  $default,) {final _that = this;
switch (_that) {
case _ProductImportRowReport():
return $default(_that.rowNumber,_that.outcome,_that.reason,_that.sku,_that.createdProductId,_that.createdVariantId,_that.imageAssociated,_that.rawValues);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rowNumber,  ProductImportRowOutcome outcome,  String? reason,  String? sku,  String? createdProductId,  String? createdVariantId,  bool imageAssociated,  Map<String, String> rawValues)?  $default,) {final _that = this;
switch (_that) {
case _ProductImportRowReport() when $default != null:
return $default(_that.rowNumber,_that.outcome,_that.reason,_that.sku,_that.createdProductId,_that.createdVariantId,_that.imageAssociated,_that.rawValues);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportRowReport implements ProductImportRowReport {
  const _ProductImportRowReport({required this.rowNumber, required this.outcome, this.reason, this.sku, this.createdProductId, this.createdVariantId, this.imageAssociated = false, final  Map<String, String> rawValues = const <String, String>{}}): _rawValues = rawValues;
  

/// 1-based position in the source file, counting only data rows.
@override final  int rowNumber;
@override final  ProductImportRowOutcome outcome;
/// Human-readable reason, always present for
/// [ProductImportRowOutcome.rejected], always absent for `created`.
@override final  String? reason;
@override final  String? sku;
/// The created `Product.id`, only for [ProductImportRowOutcome.created].
@override final  String? createdProductId;
/// The created `ProductVariant.id`, only for
/// [ProductImportRowOutcome.created].
@override final  String? createdVariantId;
/// Whether an uploaded image was matched to this row's SKU/reference —
/// always `false` for a rejected row.
@override@JsonKey() final  bool imageAssociated;
/// Raw mapped values as read from the spreadsheet (field code -> raw
/// text), shown in the report row for context.
 final  Map<String, String> _rawValues;
/// Raw mapped values as read from the spreadsheet (field code -> raw
/// text), shown in the report row for context.
@override@JsonKey() Map<String, String> get rawValues {
  if (_rawValues is EqualUnmodifiableMapView) return _rawValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_rawValues);
}


/// Create a copy of ProductImportRowReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportRowReportCopyWith<_ProductImportRowReport> get copyWith => __$ProductImportRowReportCopyWithImpl<_ProductImportRowReport>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportRowReport&&(identical(other.rowNumber, rowNumber) || other.rowNumber == rowNumber)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.createdProductId, createdProductId) || other.createdProductId == createdProductId)&&(identical(other.createdVariantId, createdVariantId) || other.createdVariantId == createdVariantId)&&(identical(other.imageAssociated, imageAssociated) || other.imageAssociated == imageAssociated)&&const DeepCollectionEquality().equals(other._rawValues, _rawValues));
}


@override
int get hashCode => Object.hash(runtimeType,rowNumber,outcome,reason,sku,createdProductId,createdVariantId,imageAssociated,const DeepCollectionEquality().hash(_rawValues));

@override
String toString() {
  return 'ProductImportRowReport(rowNumber: $rowNumber, outcome: $outcome, reason: $reason, sku: $sku, createdProductId: $createdProductId, createdVariantId: $createdVariantId, imageAssociated: $imageAssociated, rawValues: $rawValues)';
}


}

/// @nodoc
abstract mixin class _$ProductImportRowReportCopyWith<$Res> implements $ProductImportRowReportCopyWith<$Res> {
  factory _$ProductImportRowReportCopyWith(_ProductImportRowReport value, $Res Function(_ProductImportRowReport) _then) = __$ProductImportRowReportCopyWithImpl;
@override @useResult
$Res call({
 int rowNumber, ProductImportRowOutcome outcome, String? reason, String? sku, String? createdProductId, String? createdVariantId, bool imageAssociated, Map<String, String> rawValues
});




}
/// @nodoc
class __$ProductImportRowReportCopyWithImpl<$Res>
    implements _$ProductImportRowReportCopyWith<$Res> {
  __$ProductImportRowReportCopyWithImpl(this._self, this._then);

  final _ProductImportRowReport _self;
  final $Res Function(_ProductImportRowReport) _then;

/// Create a copy of ProductImportRowReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowNumber = null,Object? outcome = null,Object? reason = freezed,Object? sku = freezed,Object? createdProductId = freezed,Object? createdVariantId = freezed,Object? imageAssociated = null,Object? rawValues = null,}) {
  return _then(_ProductImportRowReport(
rowNumber: null == rowNumber ? _self.rowNumber : rowNumber // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as ProductImportRowOutcome,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,createdProductId: freezed == createdProductId ? _self.createdProductId : createdProductId // ignore: cast_nullable_to_non_nullable
as String?,createdVariantId: freezed == createdVariantId ? _self.createdVariantId : createdVariantId // ignore: cast_nullable_to_non_nullable
as String?,imageAssociated: null == imageAssociated ? _self.imageAssociated : imageAssociated // ignore: cast_nullable_to_non_nullable
as bool,rawValues: null == rawValues ? _self._rawValues : rawValues // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
