// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_import_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerImportJob {

 String get id; String get organizationId; String get companyId; String get fileName; String get storagePath; String? get reportStoragePath; String? get templateId; CustomerImportMapping get mapping; CustomerImportJobStatus get status; int? get totalRows; int get processedRows; int get importedCount; int get rejectedCount; int get duplicateCount; String? get errorMessage; DateTime get createdAt; String get createdBy; DateTime? get startedAt; DateTime? get completedAt;
/// Create a copy of CustomerImportJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerImportJobCopyWith<CustomerImportJob> get copyWith => _$CustomerImportJobCopyWithImpl<CustomerImportJob>(this as CustomerImportJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.reportStoragePath, reportStoragePath) || other.reportStoragePath == reportStoragePath)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.processedRows, processedRows) || other.processedRows == processedRows)&&(identical(other.importedCount, importedCount) || other.importedCount == importedCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,fileName,storagePath,reportStoragePath,templateId,mapping,status,totalRows,processedRows,importedCount,rejectedCount,duplicateCount,errorMessage,createdAt,createdBy,startedAt,completedAt]);

@override
String toString() {
  return 'CustomerImportJob(id: $id, organizationId: $organizationId, companyId: $companyId, fileName: $fileName, storagePath: $storagePath, reportStoragePath: $reportStoragePath, templateId: $templateId, mapping: $mapping, status: $status, totalRows: $totalRows, processedRows: $processedRows, importedCount: $importedCount, rejectedCount: $rejectedCount, duplicateCount: $duplicateCount, errorMessage: $errorMessage, createdAt: $createdAt, createdBy: $createdBy, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $CustomerImportJobCopyWith<$Res>  {
  factory $CustomerImportJobCopyWith(CustomerImportJob value, $Res Function(CustomerImportJob) _then) = _$CustomerImportJobCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, String fileName, String storagePath, String? reportStoragePath, String? templateId, CustomerImportMapping mapping, CustomerImportJobStatus status, int? totalRows, int processedRows, int importedCount, int rejectedCount, int duplicateCount, String? errorMessage, DateTime createdAt, String createdBy, DateTime? startedAt, DateTime? completedAt
});


$CustomerImportMappingCopyWith<$Res> get mapping;

}
/// @nodoc
class _$CustomerImportJobCopyWithImpl<$Res>
    implements $CustomerImportJobCopyWith<$Res> {
  _$CustomerImportJobCopyWithImpl(this._self, this._then);

  final CustomerImportJob _self;
  final $Res Function(CustomerImportJob) _then;

/// Create a copy of CustomerImportJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? fileName = null,Object? storagePath = null,Object? reportStoragePath = freezed,Object? templateId = freezed,Object? mapping = null,Object? status = null,Object? totalRows = freezed,Object? processedRows = null,Object? importedCount = null,Object? rejectedCount = null,Object? duplicateCount = null,Object? errorMessage = freezed,Object? createdAt = null,Object? createdBy = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,reportStoragePath: freezed == reportStoragePath ? _self.reportStoragePath : reportStoragePath // ignore: cast_nullable_to_non_nullable
as String?,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as CustomerImportMapping,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CustomerImportJobStatus,totalRows: freezed == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int?,processedRows: null == processedRows ? _self.processedRows : processedRows // ignore: cast_nullable_to_non_nullable
as int,importedCount: null == importedCount ? _self.importedCount : importedCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of CustomerImportJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerImportMappingCopyWith<$Res> get mapping {
  
  return $CustomerImportMappingCopyWith<$Res>(_self.mapping, (value) {
    return _then(_self.copyWith(mapping: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerImportJob].
extension CustomerImportJobPatterns on CustomerImportJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerImportJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerImportJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerImportJob value)  $default,){
final _that = this;
switch (_that) {
case _CustomerImportJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerImportJob value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerImportJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String fileName,  String storagePath,  String? reportStoragePath,  String? templateId,  CustomerImportMapping mapping,  CustomerImportJobStatus status,  int? totalRows,  int processedRows,  int importedCount,  int rejectedCount,  int duplicateCount,  String? errorMessage,  DateTime createdAt,  String createdBy,  DateTime? startedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerImportJob() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.fileName,_that.storagePath,_that.reportStoragePath,_that.templateId,_that.mapping,_that.status,_that.totalRows,_that.processedRows,_that.importedCount,_that.rejectedCount,_that.duplicateCount,_that.errorMessage,_that.createdAt,_that.createdBy,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  String fileName,  String storagePath,  String? reportStoragePath,  String? templateId,  CustomerImportMapping mapping,  CustomerImportJobStatus status,  int? totalRows,  int processedRows,  int importedCount,  int rejectedCount,  int duplicateCount,  String? errorMessage,  DateTime createdAt,  String createdBy,  DateTime? startedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _CustomerImportJob():
return $default(_that.id,_that.organizationId,_that.companyId,_that.fileName,_that.storagePath,_that.reportStoragePath,_that.templateId,_that.mapping,_that.status,_that.totalRows,_that.processedRows,_that.importedCount,_that.rejectedCount,_that.duplicateCount,_that.errorMessage,_that.createdAt,_that.createdBy,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  String fileName,  String storagePath,  String? reportStoragePath,  String? templateId,  CustomerImportMapping mapping,  CustomerImportJobStatus status,  int? totalRows,  int processedRows,  int importedCount,  int rejectedCount,  int duplicateCount,  String? errorMessage,  DateTime createdAt,  String createdBy,  DateTime? startedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomerImportJob() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.fileName,_that.storagePath,_that.reportStoragePath,_that.templateId,_that.mapping,_that.status,_that.totalRows,_that.processedRows,_that.importedCount,_that.rejectedCount,_that.duplicateCount,_that.errorMessage,_that.createdAt,_that.createdBy,_that.startedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerImportJob extends CustomerImportJob {
  const _CustomerImportJob({required this.id, required this.organizationId, required this.companyId, required this.fileName, required this.storagePath, this.reportStoragePath, this.templateId, required this.mapping, required this.status, this.totalRows, this.processedRows = 0, this.importedCount = 0, this.rejectedCount = 0, this.duplicateCount = 0, this.errorMessage, required this.createdAt, required this.createdBy, this.startedAt, this.completedAt}): super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  String fileName;
@override final  String storagePath;
@override final  String? reportStoragePath;
@override final  String? templateId;
@override final  CustomerImportMapping mapping;
@override final  CustomerImportJobStatus status;
@override final  int? totalRows;
@override@JsonKey() final  int processedRows;
@override@JsonKey() final  int importedCount;
@override@JsonKey() final  int rejectedCount;
@override@JsonKey() final  int duplicateCount;
@override final  String? errorMessage;
@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime? startedAt;
@override final  DateTime? completedAt;

/// Create a copy of CustomerImportJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerImportJobCopyWith<_CustomerImportJob> get copyWith => __$CustomerImportJobCopyWithImpl<_CustomerImportJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerImportJob&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.reportStoragePath, reportStoragePath) || other.reportStoragePath == reportStoragePath)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.mapping, mapping) || other.mapping == mapping)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalRows, totalRows) || other.totalRows == totalRows)&&(identical(other.processedRows, processedRows) || other.processedRows == processedRows)&&(identical(other.importedCount, importedCount) || other.importedCount == importedCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.duplicateCount, duplicateCount) || other.duplicateCount == duplicateCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,fileName,storagePath,reportStoragePath,templateId,mapping,status,totalRows,processedRows,importedCount,rejectedCount,duplicateCount,errorMessage,createdAt,createdBy,startedAt,completedAt]);

@override
String toString() {
  return 'CustomerImportJob(id: $id, organizationId: $organizationId, companyId: $companyId, fileName: $fileName, storagePath: $storagePath, reportStoragePath: $reportStoragePath, templateId: $templateId, mapping: $mapping, status: $status, totalRows: $totalRows, processedRows: $processedRows, importedCount: $importedCount, rejectedCount: $rejectedCount, duplicateCount: $duplicateCount, errorMessage: $errorMessage, createdAt: $createdAt, createdBy: $createdBy, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerImportJobCopyWith<$Res> implements $CustomerImportJobCopyWith<$Res> {
  factory _$CustomerImportJobCopyWith(_CustomerImportJob value, $Res Function(_CustomerImportJob) _then) = __$CustomerImportJobCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, String fileName, String storagePath, String? reportStoragePath, String? templateId, CustomerImportMapping mapping, CustomerImportJobStatus status, int? totalRows, int processedRows, int importedCount, int rejectedCount, int duplicateCount, String? errorMessage, DateTime createdAt, String createdBy, DateTime? startedAt, DateTime? completedAt
});


@override $CustomerImportMappingCopyWith<$Res> get mapping;

}
/// @nodoc
class __$CustomerImportJobCopyWithImpl<$Res>
    implements _$CustomerImportJobCopyWith<$Res> {
  __$CustomerImportJobCopyWithImpl(this._self, this._then);

  final _CustomerImportJob _self;
  final $Res Function(_CustomerImportJob) _then;

/// Create a copy of CustomerImportJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? fileName = null,Object? storagePath = null,Object? reportStoragePath = freezed,Object? templateId = freezed,Object? mapping = null,Object? status = null,Object? totalRows = freezed,Object? processedRows = null,Object? importedCount = null,Object? rejectedCount = null,Object? duplicateCount = null,Object? errorMessage = freezed,Object? createdAt = null,Object? createdBy = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_CustomerImportJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,reportStoragePath: freezed == reportStoragePath ? _self.reportStoragePath : reportStoragePath // ignore: cast_nullable_to_non_nullable
as String?,templateId: freezed == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String?,mapping: null == mapping ? _self.mapping : mapping // ignore: cast_nullable_to_non_nullable
as CustomerImportMapping,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CustomerImportJobStatus,totalRows: freezed == totalRows ? _self.totalRows : totalRows // ignore: cast_nullable_to_non_nullable
as int?,processedRows: null == processedRows ? _self.processedRows : processedRows // ignore: cast_nullable_to_non_nullable
as int,importedCount: null == importedCount ? _self.importedCount : importedCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,duplicateCount: null == duplicateCount ? _self.duplicateCount : duplicateCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of CustomerImportJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerImportMappingCopyWith<$Res> get mapping {
  
  return $CustomerImportMappingCopyWith<$Res>(_self.mapping, (value) {
    return _then(_self.copyWith(mapping: value));
  });
}
}

// dart format on
