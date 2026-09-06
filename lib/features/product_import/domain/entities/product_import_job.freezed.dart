// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_import_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImportJob {

 String get id; String get organizationId; String get companyId; String get fileName; String get storagePath;/// Storage path prefix under which optional product images were
/// uploaded before the job started (`organizations/{organizationId}/
/// productImports/{batchId}/images/`) — `null` when the gestor imported
/// products without an image package.
 String? get imagesFolderPath; String? get reportStoragePath; String? get templateId; ProductImportJobStatus get status; int? get totalRows; int get processedRows; int get createdProductsCount; int get createdVariantsCount; int get imagesAssociatedCount; int get imagesOrphanCount; int get rejectedCount; String? get errorMessage; DateTime get createdAt; String get createdBy; DateTime? get startedAt; DateTime? get completedAt;
/// Create a copy of ProductImportJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImportJobCopyWith<ProductImportJob> get copyWith => _$ProductImportJobCopyWithImpl<ProductImportJob>(this as ProductImportJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.imagesFolderPath, imagesFolderPath) || other.imagesFolderPath == imagesFolderPath)&&(identical(other.reportStoragePath, reportStoragePath) || other.reportStoragePath == reportStoragePath)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.processedRows, processedRows) || other.processedRows == processedRows)&&(identical(other.createdProductsCount, createdProductsCount) || other.createdProductsCount == createdProductsCount)&&(identical(other.createdVariantsCount, createdVariantsCount) || other.createdVariantsCount == createdVariantsCount)&&(identical(other.imagesAssociatedCount, imagesAssociatedCount) || other.imagesAssociatedCount == imagesAssociatedCount)&&(identical(other.imagesOrphanCount, imagesOrphanCount) || other.imagesOrphanCount == imagesOrphanCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,fileName,storagePath,imagesFolderPath,reportStoragePath,templateId,status,totalRows,processedRows,createdProductsCount,createdVariantsCount,imagesAssociatedCount,imagesOrphanCount,rejectedCount,errorMessage,createdAt,createdBy,startedAt,completedAt]);

@override
String toString() {
  return 'ProductImportJob(id: $id, organizationId: $organizationId, companyId: $companyId, fileName: $fileName, storagePath: $storagePath, imagesFolderPath: $imagesFolderPath, reportStoragePath: $reportStoragePath, templateId: $templateId, status: $status, totalRows: $totalRows, processedRows: $processedRows, createdProductsCount: $createdProductsCount, createdVariantsCount: $createdVariantsCount, imagesAssociatedCount: $imagesAssociatedCount, imagesOrphanCount: $imagesOrphanCount, rejectedCount: $rejectedCount, errorMessage: $errorMessage, createdAt: $createdAt, createdBy: $createdBy, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $ProductImportJobCopyWith<$Res>  {
  factory $ProductImportJobCopyWith(ProductImportJob value, $Res Function(ProductImportJob) _then) = _$ProductImportJobCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, String fileName, String storagePath, String? imagesFolderPath, String? reportStoragePath, String? templateId, ProductImportJobStatus status, int? totalRows, int processedRows, int createdProductsCount, int createdVariantsCount, int imagesAssociatedCount, int imagesOrphanCount, int rejectedCount, String? errorMessage, DateTime createdAt, String createdBy, DateTime? startedAt, DateTime? completedAt
});




}
/// @nodoc
class _$ProductImportJobCopyWithImpl<$Res>
    implements $ProductImportJobCopyWith<$Res> {
  _$ProductImportJobCopyWithImpl(this._self, this._then);

  final ProductImportJob _self;
  final $Res Function(ProductImportJob) _then;

/// Create a copy of ProductImportJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? fileName = null,Object? storagePath = null,Object? imagesFolderPath = freezed,Object? reportStoragePath = freezed,Object? templateId = freezed,Object? status = null,Object? totalRows = freezed,Object? processedRows = null,Object? createdProductsCount = null,Object? createdVariantsCount = null,Object? imagesAssociatedCount = null,Object? imagesOrphanCount = null,Object? rejectedCount = null,Object? errorMessage = freezed,Object? createdAt = null,Object? createdBy = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,imagesFolderPath: freezed == imagesFolderPath ? _self.imagesFolderPath : imagesFolderPath // ignore: cast_nullable_to_non_nullable
as String?,reportStoragePath: freezed == reportStoragePath ? _self.reportStoragePath : reportStoragePath // ignore: cast_nullable_to_non_nullable
as String?,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductImportJobStatus,totalRows: freezed == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int?,processedRows: null == processedRows ? _self.processedRows : processedRows // ignore: cast_nullable_to_non_nullable
as int,createdProductsCount: null == createdProductsCount ? _self.createdProductsCount : createdProductsCount // ignore: cast_nullable_to_non_nullable
as int,createdVariantsCount: null == createdVariantsCount ? _self.createdVariantsCount : createdVariantsCount // ignore: cast_nullable_to_non_nullable
as int,imagesAssociatedCount: null == imagesAssociatedCount ? _self.imagesAssociatedCount : imagesAssociatedCount // ignore: cast_nullable_to_non_nullable
as int,imagesOrphanCount: null == imagesOrphanCount ? _self.imagesOrphanCount : imagesOrphanCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImportJob].
extension ProductImportJobPatterns on ProductImportJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImportJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImportJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImportJob value)  $default,){
final _that = this;
switch (_that) {
case _ProductImportJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImportJob value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImportJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String fileName,  String storagePath,  String? imagesFolderPath,  String? reportStoragePath,  String? templateId,  ProductImportJobStatus status,  int? totalRows,  int processedRows,  int createdProductsCount,  int createdVariantsCount,  int imagesAssociatedCount,  int imagesOrphanCount,  int rejectedCount,  String? errorMessage,  DateTime createdAt,  String createdBy,  DateTime? startedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImportJob() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.fileName,_that.storagePath,_that.imagesFolderPath,_that.reportStoragePath,_that.templateId,_that.status,_that.totalRows,_that.processedRows,_that.createdProductsCount,_that.createdVariantsCount,_that.imagesAssociatedCount,_that.imagesOrphanCount,_that.rejectedCount,_that.errorMessage,_that.createdAt,_that.createdBy,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String fileName,  String storagePath,  String? imagesFolderPath,  String? reportStoragePath,  String? templateId,  ProductImportJobStatus status,  int? totalRows,  int processedRows,  int createdProductsCount,  int createdVariantsCount,  int imagesAssociatedCount,  int imagesOrphanCount,  int rejectedCount,  String? errorMessage,  DateTime createdAt,  String createdBy,  DateTime? startedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _ProductImportJob():
return $default(_that.id,_that.organizationId,_that.companyId,_that.fileName,_that.storagePath,_that.imagesFolderPath,_that.reportStoragePath,_that.templateId,_that.status,_that.totalRows,_that.processedRows,_that.createdProductsCount,_that.createdVariantsCount,_that.imagesAssociatedCount,_that.imagesOrphanCount,_that.rejectedCount,_that.errorMessage,_that.createdAt,_that.createdBy,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  String fileName,  String storagePath,  String? imagesFolderPath,  String? reportStoragePath,  String? templateId,  ProductImportJobStatus status,  int? totalRows,  int processedRows,  int createdProductsCount,  int createdVariantsCount,  int imagesAssociatedCount,  int imagesOrphanCount,  int rejectedCount,  String? errorMessage,  DateTime createdAt,  String createdBy,  DateTime? startedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProductImportJob() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.fileName,_that.storagePath,_that.imagesFolderPath,_that.reportStoragePath,_that.templateId,_that.status,_that.totalRows,_that.processedRows,_that.createdProductsCount,_that.createdVariantsCount,_that.imagesAssociatedCount,_that.imagesOrphanCount,_that.rejectedCount,_that.errorMessage,_that.createdAt,_that.createdBy,_that.startedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ProductImportJob extends ProductImportJob {
  const _ProductImportJob({required this.id, required this.organizationId, required this.companyId, required this.fileName, required this.storagePath, this.imagesFolderPath, this.reportStoragePath, this.templateId, required this.status, this.totalRows, this.processedRows = 0, this.createdProductsCount = 0, this.createdVariantsCount = 0, this.imagesAssociatedCount = 0, this.imagesOrphanCount = 0, this.rejectedCount = 0, this.errorMessage, required this.createdAt, required this.createdBy, this.startedAt, this.completedAt}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  String fileName;
@override final  String storagePath;
/// Storage path prefix under which optional product images were
/// uploaded before the job started (`organizations/{organizationId}/
/// productImports/{batchId}/images/`) — `null` when the gestor imported
/// products without an image package.
@override final  String? imagesFolderPath;
@override final  String? reportStoragePath;
@override final  String? templateId;
@override final  ProductImportJobStatus status;
@override final  int? totalRows;
@override@JsonKey() final  int processedRows;
@override@JsonKey() final  int createdProductsCount;
@override@JsonKey() final  int createdVariantsCount;
@override@JsonKey() final  int imagesAssociatedCount;
@override@JsonKey() final  int imagesOrphanCount;
@override@JsonKey() final  int rejectedCount;
@override final  String? errorMessage;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime? startedAt;
@override final  DateTime? completedAt;

/// Create a copy of ProductImportJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImportJobCopyWith<_ProductImportJob> get copyWith => __$ProductImportJobCopyWithImpl<_ProductImportJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.imagesFolderPath, imagesFolderPath) || other.imagesFolderPath == imagesFolderPath)&&(identical(other.reportStoragePath, reportStoragePath) || other.reportStoragePath == reportStoragePath)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.processedRows, processedRows) || other.processedRows == processedRows)&&(identical(other.createdProductsCount, createdProductsCount) || other.createdProductsCount == createdProductsCount)&&(identical(other.createdVariantsCount, createdVariantsCount) || other.createdVariantsCount == createdVariantsCount)&&(identical(other.imagesAssociatedCount, imagesAssociatedCount) || other.imagesAssociatedCount == imagesAssociatedCount)&&(identical(other.imagesOrphanCount, imagesOrphanCount) || other.imagesOrphanCount == imagesOrphanCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,fileName,storagePath,imagesFolderPath,reportStoragePath,templateId,status,totalRows,processedRows,createdProductsCount,createdVariantsCount,imagesAssociatedCount,imagesOrphanCount,rejectedCount,errorMessage,createdAt,createdBy,startedAt,completedAt]);

@override
String toString() {
  return 'ProductImportJob(id: $id, organizationId: $organizationId, companyId: $companyId, fileName: $fileName, storagePath: $storagePath, imagesFolderPath: $imagesFolderPath, reportStoragePath: $reportStoragePath, templateId: $templateId, status: $status, totalRows: $totalRows, processedRows: $processedRows, createdProductsCount: $createdProductsCount, createdVariantsCount: $createdVariantsCount, imagesAssociatedCount: $imagesAssociatedCount, imagesOrphanCount: $imagesOrphanCount, rejectedCount: $rejectedCount, errorMessage: $errorMessage, createdAt: $createdAt, createdBy: $createdBy, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$ProductImportJobCopyWith<$Res> implements $ProductImportJobCopyWith<$Res> {
  factory _$ProductImportJobCopyWith(_ProductImportJob value, $Res Function(_ProductImportJob) _then) = __$ProductImportJobCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, String fileName, String storagePath, String? imagesFolderPath, String? reportStoragePath, String? templateId, ProductImportJobStatus status, int? totalRows, int processedRows, int createdProductsCount, int createdVariantsCount, int imagesAssociatedCount, int imagesOrphanCount, int rejectedCount, String? errorMessage, DateTime createdAt, String createdBy, DateTime? startedAt, DateTime? completedAt
});




}
/// @nodoc
class __$ProductImportJobCopyWithImpl<$Res>
    implements _$ProductImportJobCopyWith<$Res> {
  __$ProductImportJobCopyWithImpl(this._self, this._then);

  final _ProductImportJob _self;
  final $Res Function(_ProductImportJob) _then;

/// Create a copy of ProductImportJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? fileName = null,Object? storagePath = null,Object? imagesFolderPath = freezed,Object? reportStoragePath = freezed,Object? templateId = freezed,Object? status = null,Object? totalRows = freezed,Object? processedRows = null,Object? createdProductsCount = null,Object? createdVariantsCount = null,Object? imagesAssociatedCount = null,Object? imagesOrphanCount = null,Object? rejectedCount = null,Object? errorMessage = freezed,Object? createdAt = null,Object? createdBy = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_ProductImportJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,imagesFolderPath: freezed == imagesFolderPath ? _self.imagesFolderPath : imagesFolderPath // ignore: cast_nullable_to_non_nullable
as String?,reportStoragePath: freezed == reportStoragePath ? _self.reportStoragePath : reportStoragePath // ignore: cast_nullable_to_non_nullable
as String?,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ProductImportJobStatus,totalRows: freezed == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int?,processedRows: null == processedRows ? _self.processedRows : processedRows // ignore: cast_nullable_to_non_nullable
as int,createdProductsCount: null == createdProductsCount ? _self.createdProductsCount : createdProductsCount // ignore: cast_nullable_to_non_nullable
as int,createdVariantsCount: null == createdVariantsCount ? _self.createdVariantsCount : createdVariantsCount // ignore: cast_nullable_to_non_nullable
as int,imagesAssociatedCount: null == imagesAssociatedCount ? _self.imagesAssociatedCount : imagesAssociatedCount // ignore: cast_nullable_to_non_nullable
as int,imagesOrphanCount: null == imagesOrphanCount ? _self.imagesOrphanCount : imagesOrphanCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
