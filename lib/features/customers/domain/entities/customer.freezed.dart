// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Customer {

 String get id; String get organizationId; String get companyId; CustomerType get type; CnpjCpf get document; String? get legalName; String? get tradeName; String? get fullName; String? get stateRegistration; String? get primaryEmail; String? get primaryPhone; CustomerStatus get status; String? get classification; String? get potential; String? get segment; String? get originChannel; String? get responsibleSellerId;// Traceability back to the originating Lead (TASK-055), when the
// Customer was created through `ConvertLeadToCustomerUseCase`.
 String? get sourceLeadId; DateTime get registeredAt; DateTime? get lastPurchaseAt; List<CustomerAddress> get addresses; List<CustomerContact> get contacts; List<String> get tags; Map<String, Object?> get customFields; DateTime get createdAt; String get createdBy; DateTime get updatedAt; String get updatedBy; DateTime? get deletedAt; int get version; CustomerSyncStatus get syncStatus;
/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCopyWith<Customer> get copyWith => _$CustomerCopyWithImpl<Customer>(this as Customer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.type, type) || other.type == type)&&(identical(other.document, document) || other.document == document)&&(identical(other.legalName, legalName) || other.legalName == legalName)&&(identical(other.tradeName, tradeName) || other.tradeName == tradeName)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.stateRegistration, stateRegistration) || other.stateRegistration == stateRegistration)&&(identical(other.primaryEmail, primaryEmail) || other.primaryEmail == primaryEmail)&&(identical(other.primaryPhone, primaryPhone) || other.primaryPhone == primaryPhone)&&(identical(other.status, status) || other.status == status)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.potential, potential) || other.potential == potential)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.originChannel, originChannel) || other.originChannel == originChannel)&&(identical(other.responsibleSellerId, responsibleSellerId) || other.responsibleSellerId == responsibleSellerId)&&(identical(other.sourceLeadId, sourceLeadId) || other.sourceLeadId == sourceLeadId)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.lastPurchaseAt, lastPurchaseAt) || other.lastPurchaseAt == lastPurchaseAt)&&const DeepCollectionEquality().equals(other.addresses, addresses)&&const DeepCollectionEquality().equals(other.contacts, contacts)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.customFields, customFields)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,type,document,legalName,tradeName,fullName,stateRegistration,primaryEmail,primaryPhone,status,classification,potential,segment,originChannel,responsibleSellerId,sourceLeadId,registeredAt,lastPurchaseAt,const DeepCollectionEquality().hash(addresses),const DeepCollectionEquality().hash(contacts),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(customFields),createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Customer(id: $id, organizationId: $organizationId, companyId: $companyId, type: $type, document: $document, legalName: $legalName, tradeName: $tradeName, fullName: $fullName, stateRegistration: $stateRegistration, primaryEmail: $primaryEmail, primaryPhone: $primaryPhone, status: $status, classification: $classification, potential: $potential, segment: $segment, originChannel: $originChannel, responsibleSellerId: $responsibleSellerId, sourceLeadId: $sourceLeadId, registeredAt: $registeredAt, lastPurchaseAt: $lastPurchaseAt, addresses: $addresses, contacts: $contacts, tags: $tags, customFields: $customFields, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class $CustomerCopyWith<$Res>  {
  factory $CustomerCopyWith(Customer value, $Res Function(Customer) _then) = _$CustomerCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String companyId, CustomerType type, CnpjCpf document, String? legalName, String? tradeName, String? fullName, String? stateRegistration, String? primaryEmail, String? primaryPhone, CustomerStatus status, String? classification, String? potential, String? segment, String? originChannel, String? responsibleSellerId, String? sourceLeadId, DateTime registeredAt, DateTime? lastPurchaseAt, List<CustomerAddress> addresses, List<CustomerContact> contacts, List<String> tags, Map<String, Object?> customFields, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, CustomerSyncStatus syncStatus
});




}
/// @nodoc
class _$CustomerCopyWithImpl<$Res>
    implements $CustomerCopyWith<$Res> {
  _$CustomerCopyWithImpl(this._self, this._then);

  final Customer _self;
  final $Res Function(Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? type = null,Object? document = null,Object? legalName = freezed,Object? tradeName = freezed,Object? fullName = freezed,Object? stateRegistration = freezed,Object? primaryEmail = freezed,Object? primaryPhone = freezed,Object? status = null,Object? classification = freezed,Object? potential = freezed,Object? segment = freezed,Object? originChannel = freezed,Object? responsibleSellerId = freezed,Object? sourceLeadId = freezed,Object? registeredAt = null,Object? lastPurchaseAt = freezed,Object? addresses = null,Object? contacts = null,Object? tags = null,Object? customFields = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CustomerType,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as CnpjCpf,legalName: freezed == legalName ? _self.legalName : legalName // ignore: cast_nullable_to_non_nullable
as String?,tradeName: freezed == tradeName ? _self.tradeName : tradeName // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,stateRegistration: freezed == stateRegistration ? _self.stateRegistration : stateRegistration // ignore: cast_nullable_to_non_nullable
as String?,primaryEmail: freezed == primaryEmail ? _self.primaryEmail : primaryEmail // ignore: cast_nullable_to_non_nullable
as String?,primaryPhone: freezed == primaryPhone ? _self.primaryPhone : primaryPhone // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CustomerStatus,classification: freezed == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String?,potential: freezed == potential ? _self.potential : potential // ignore: cast_nullable_to_non_nullable
as String?,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,originChannel: freezed == originChannel ? _self.originChannel : originChannel // ignore: cast_nullable_to_non_nullable
as String?,responsibleSellerId: freezed == responsibleSellerId ? _self.responsibleSellerId : responsibleSellerId // ignore: cast_nullable_to_non_nullable
as String?,sourceLeadId: freezed == sourceLeadId ? _self.sourceLeadId : sourceLeadId // ignore: cast_nullable_to_non_nullable
as String?,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastPurchaseAt: freezed == lastPurchaseAt ? _self.lastPurchaseAt : lastPurchaseAt // ignore: cast_nullable_to_non_nullable
as DateTime?,addresses: null == addresses ? _self.addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<CustomerAddress>,contacts: null == contacts ? _self.contacts : contacts // ignore: cast_nullable_to_non_nullable
as List<CustomerContact>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,customFields: null == customFields ? _self.customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as CustomerSyncStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [Customer].
extension CustomerPatterns on Customer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Customer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Customer value)  $default,){
final _that = this;
switch (_that) {
case _Customer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Customer value)?  $default,){
final _that = this;
switch (_that) {
case _Customer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  CustomerType type,  CnpjCpf document,  String? legalName,  String? tradeName,  String? fullName,  String? stateRegistration,  String? primaryEmail,  String? primaryPhone,  CustomerStatus status,  String? classification,  String? potential,  String? segment,  String? originChannel,  String? responsibleSellerId,  String? sourceLeadId,  DateTime registeredAt,  DateTime? lastPurchaseAt,  List<CustomerAddress> addresses,  List<CustomerContact> contacts,  List<String> tags,  Map<String, Object?> customFields,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  CustomerSyncStatus syncStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.type,_that.document,_that.legalName,_that.tradeName,_that.fullName,_that.stateRegistration,_that.primaryEmail,_that.primaryPhone,_that.status,_that.classification,_that.potential,_that.segment,_that.originChannel,_that.responsibleSellerId,_that.sourceLeadId,_that.registeredAt,_that.lastPurchaseAt,_that.addresses,_that.contacts,_that.tags,_that.customFields,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String companyId,  CustomerType type,  CnpjCpf document,  String? legalName,  String? tradeName,  String? fullName,  String? stateRegistration,  String? primaryEmail,  String? primaryPhone,  CustomerStatus status,  String? classification,  String? potential,  String? segment,  String? originChannel,  String? responsibleSellerId,  String? sourceLeadId,  DateTime registeredAt,  DateTime? lastPurchaseAt,  List<CustomerAddress> addresses,  List<CustomerContact> contacts,  List<String> tags,  Map<String, Object?> customFields,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  CustomerSyncStatus syncStatus)  $default,) {final _that = this;
switch (_that) {
case _Customer():
return $default(_that.id,_that.organizationId,_that.companyId,_that.type,_that.document,_that.legalName,_that.tradeName,_that.fullName,_that.stateRegistration,_that.primaryEmail,_that.primaryPhone,_that.status,_that.classification,_that.potential,_that.segment,_that.originChannel,_that.responsibleSellerId,_that.sourceLeadId,_that.registeredAt,_that.lastPurchaseAt,_that.addresses,_that.contacts,_that.tags,_that.customFields,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String companyId,  CustomerType type,  CnpjCpf document,  String? legalName,  String? tradeName,  String? fullName,  String? stateRegistration,  String? primaryEmail,  String? primaryPhone,  CustomerStatus status,  String? classification,  String? potential,  String? segment,  String? originChannel,  String? responsibleSellerId,  String? sourceLeadId,  DateTime registeredAt,  DateTime? lastPurchaseAt,  List<CustomerAddress> addresses,  List<CustomerContact> contacts,  List<String> tags,  Map<String, Object?> customFields,  DateTime createdAt,  String createdBy,  DateTime updatedAt,  String updatedBy,  DateTime? deletedAt,  int version,  CustomerSyncStatus syncStatus)?  $default,) {final _that = this;
switch (_that) {
case _Customer() when $default != null:
return $default(_that.id,_that.organizationId,_that.companyId,_that.type,_that.document,_that.legalName,_that.tradeName,_that.fullName,_that.stateRegistration,_that.primaryEmail,_that.primaryPhone,_that.status,_that.classification,_that.potential,_that.segment,_that.originChannel,_that.responsibleSellerId,_that.sourceLeadId,_that.registeredAt,_that.lastPurchaseAt,_that.addresses,_that.contacts,_that.tags,_that.customFields,_that.createdAt,_that.createdBy,_that.updatedAt,_that.updatedBy,_that.deletedAt,_that.version,_that.syncStatus);case _:
  return null;

}
}

}

/// @nodoc


class _Customer extends Customer {
  const _Customer({required this.id, required this.organizationId, required this.companyId, required this.type, required this.document, this.legalName, this.tradeName, this.fullName, this.stateRegistration, this.primaryEmail, this.primaryPhone, required this.status, this.classification, this.potential, this.segment, this.originChannel, this.responsibleSellerId, this.sourceLeadId, required this.registeredAt, this.lastPurchaseAt, final  List<CustomerAddress> addresses = const <CustomerAddress>[], final  List<CustomerContact> contacts = const <CustomerContact>[], final  List<String> tags = const <String>[], final  Map<String, Object?> customFields = const <String, Object?>{}, required this.createdAt, required this.createdBy, required this.updatedAt, required this.updatedBy, this.deletedAt, required this.version, required this.syncStatus}): _addresses = addresses,_contacts = contacts,_tags = tags,_customFields = customFields,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String companyId;
@override final  CustomerType type;
@override final  CnpjCpf document;
@override final  String? legalName;
@override final  String? tradeName;
@override final  String? fullName;
@override final  String? stateRegistration;
@override final  String? primaryEmail;
@override final  String? primaryPhone;
@override final  CustomerStatus status;
@override final  String? classification;
@override final  String? potential;
@override final  String? segment;
@override final  String? originChannel;
@override final  String? responsibleSellerId;
// Traceability back to the originating Lead (TASK-055), when the
// Customer was created through `ConvertLeadToCustomerUseCase`.
@override final  String? sourceLeadId;
@override final  DateTime registeredAt;
@override final  DateTime? lastPurchaseAt;
 final  List<CustomerAddress> _addresses;
@override@JsonKey() List<CustomerAddress> get addresses {
  if (_addresses is EqualUnmodifiableListView) return _addresses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addresses);
}

 final  List<CustomerContact> _contacts;
@override@JsonKey() List<CustomerContact> get contacts {
  if (_contacts is EqualUnmodifiableListView) return _contacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contacts);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  Map<String, Object?> _customFields;
@override@JsonKey() Map<String, Object?> get customFields {
  if (_customFields is EqualUnmodifiableMapView) return _customFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_customFields);
}

@override final  DateTime createdAt;
@override final  String createdBy;
@override final  DateTime updatedAt;
@override final  String updatedBy;
@override final  DateTime? deletedAt;
@override final  int version;
@override final  CustomerSyncStatus syncStatus;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerCopyWith<_Customer> get copyWith => __$CustomerCopyWithImpl<_Customer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Customer&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.type, type) || other.type == type)&&(identical(other.document, document) || other.document == document)&&(identical(other.legalName, legalName) || other.legalName == legalName)&&(identical(other.tradeName, tradeName) || other.tradeName == tradeName)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.stateRegistration, stateRegistration) || other.stateRegistration == stateRegistration)&&(identical(other.primaryEmail, primaryEmail) || other.primaryEmail == primaryEmail)&&(identical(other.primaryPhone, primaryPhone) || other.primaryPhone == primaryPhone)&&(identical(other.status, status) || other.status == status)&&(identical(other.classification, classification) || other.classification == classification)&&(identical(other.potential, potential) || other.potential == potential)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.originChannel, originChannel) || other.originChannel == originChannel)&&(identical(other.responsibleSellerId, responsibleSellerId) || other.responsibleSellerId == responsibleSellerId)&&(identical(other.sourceLeadId, sourceLeadId) || other.sourceLeadId == sourceLeadId)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.lastPurchaseAt, lastPurchaseAt) || other.lastPurchaseAt == lastPurchaseAt)&&const DeepCollectionEquality().equals(other._addresses, _addresses)&&const DeepCollectionEquality().equals(other._contacts, _contacts)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._customFields, _customFields)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.version, version) || other.version == version)&&(identical(other.syncStatus, syncStatus) || other.syncStatus == syncStatus));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,organizationId,companyId,type,document,legalName,tradeName,fullName,stateRegistration,primaryEmail,primaryPhone,status,classification,potential,segment,originChannel,responsibleSellerId,sourceLeadId,registeredAt,lastPurchaseAt,const DeepCollectionEquality().hash(_addresses),const DeepCollectionEquality().hash(_contacts),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_customFields),createdAt,createdBy,updatedAt,updatedBy,deletedAt,version,syncStatus]);

@override
String toString() {
  return 'Customer(id: $id, organizationId: $organizationId, companyId: $companyId, type: $type, document: $document, legalName: $legalName, tradeName: $tradeName, fullName: $fullName, stateRegistration: $stateRegistration, primaryEmail: $primaryEmail, primaryPhone: $primaryPhone, status: $status, classification: $classification, potential: $potential, segment: $segment, originChannel: $originChannel, responsibleSellerId: $responsibleSellerId, sourceLeadId: $sourceLeadId, registeredAt: $registeredAt, lastPurchaseAt: $lastPurchaseAt, addresses: $addresses, contacts: $contacts, tags: $tags, customFields: $customFields, createdAt: $createdAt, createdBy: $createdBy, updatedAt: $updatedAt, updatedBy: $updatedBy, deletedAt: $deletedAt, version: $version, syncStatus: $syncStatus)';
}


}

/// @nodoc
abstract mixin class _$CustomerCopyWith<$Res> implements $CustomerCopyWith<$Res> {
  factory _$CustomerCopyWith(_Customer value, $Res Function(_Customer) _then) = __$CustomerCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String companyId, CustomerType type, CnpjCpf document, String? legalName, String? tradeName, String? fullName, String? stateRegistration, String? primaryEmail, String? primaryPhone, CustomerStatus status, String? classification, String? potential, String? segment, String? originChannel, String? responsibleSellerId, String? sourceLeadId, DateTime registeredAt, DateTime? lastPurchaseAt, List<CustomerAddress> addresses, List<CustomerContact> contacts, List<String> tags, Map<String, Object?> customFields, DateTime createdAt, String createdBy, DateTime updatedAt, String updatedBy, DateTime? deletedAt, int version, CustomerSyncStatus syncStatus
});




}
/// @nodoc
class __$CustomerCopyWithImpl<$Res>
    implements _$CustomerCopyWith<$Res> {
  __$CustomerCopyWithImpl(this._self, this._then);

  final _Customer _self;
  final $Res Function(_Customer) _then;

/// Create a copy of Customer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? companyId = null,Object? type = null,Object? document = null,Object? legalName = freezed,Object? tradeName = freezed,Object? fullName = freezed,Object? stateRegistration = freezed,Object? primaryEmail = freezed,Object? primaryPhone = freezed,Object? status = null,Object? classification = freezed,Object? potential = freezed,Object? segment = freezed,Object? originChannel = freezed,Object? responsibleSellerId = freezed,Object? sourceLeadId = freezed,Object? registeredAt = null,Object? lastPurchaseAt = freezed,Object? addresses = null,Object? contacts = null,Object? tags = null,Object? customFields = null,Object? createdAt = null,Object? createdBy = null,Object? updatedAt = null,Object? updatedBy = null,Object? deletedAt = freezed,Object? version = null,Object? syncStatus = null,}) {
  return _then(_Customer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CustomerType,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as CnpjCpf,legalName: freezed == legalName ? _self.legalName : legalName // ignore: cast_nullable_to_non_nullable
as String?,tradeName: freezed == tradeName ? _self.tradeName : tradeName // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,stateRegistration: freezed == stateRegistration ? _self.stateRegistration : stateRegistration // ignore: cast_nullable_to_non_nullable
as String?,primaryEmail: freezed == primaryEmail ? _self.primaryEmail : primaryEmail // ignore: cast_nullable_to_non_nullable
as String?,primaryPhone: freezed == primaryPhone ? _self.primaryPhone : primaryPhone // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CustomerStatus,classification: freezed == classification ? _self.classification : classification // ignore: cast_nullable_to_non_nullable
as String?,potential: freezed == potential ? _self.potential : potential // ignore: cast_nullable_to_non_nullable
as String?,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,originChannel: freezed == originChannel ? _self.originChannel : originChannel // ignore: cast_nullable_to_non_nullable
as String?,responsibleSellerId: freezed == responsibleSellerId ? _self.responsibleSellerId : responsibleSellerId // ignore: cast_nullable_to_non_nullable
as String?,sourceLeadId: freezed == sourceLeadId ? _self.sourceLeadId : sourceLeadId // ignore: cast_nullable_to_non_nullable
as String?,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastPurchaseAt: freezed == lastPurchaseAt ? _self.lastPurchaseAt : lastPurchaseAt // ignore: cast_nullable_to_non_nullable
as DateTime?,addresses: null == addresses ? _self._addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<CustomerAddress>,contacts: null == contacts ? _self._contacts : contacts // ignore: cast_nullable_to_non_nullable
as List<CustomerContact>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,customFields: null == customFields ? _self._customFields : customFields // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedBy: null == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,syncStatus: null == syncStatus ? _self.syncStatus : syncStatus // ignore: cast_nullable_to_non_nullable
as CustomerSyncStatus,
  ));
}


}

// dart format on
