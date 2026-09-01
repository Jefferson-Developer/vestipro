// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Insight {

 String get id; InsightType get type; String get title; String get description; List<InsightEvidence> get evidence; InsightEstimatedImpact get estimatedImpact; InsightSeverity get severity; double get confidenceScore; String get recommendation; InsightAction get quickAction; List<InsightAction> get secondaryActions; String get organizationId; String get companyId; String get recipientUserId; String? get customerId; String? get productId; String? get sellerId; DateTime get generatedAt; DateTime get expiresAt; InsightStatus get status;
/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InsightCopyWith<Insight> get copyWith => _$InsightCopyWithImpl<Insight>(this as Insight, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Insight&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.evidence, evidence)&&(identical(other.estimatedImpact, estimatedImpact) || other.estimatedImpact == estimatedImpact)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation)&&(identical(other.quickAction, quickAction) || other.quickAction == quickAction)&&const DeepCollectionEquality().equals(other.secondaryActions, secondaryActions)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.recipientUserId, recipientUserId) || other.recipientUserId == recipientUserId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,type,title,description,const DeepCollectionEquality().hash(evidence),estimatedImpact,severity,confidenceScore,recommendation,quickAction,const DeepCollectionEquality().hash(secondaryActions),organizationId,companyId,recipientUserId,customerId,productId,sellerId,generatedAt,expiresAt,status]);

@override
String toString() {
  return 'Insight(id: $id, type: $type, title: $title, description: $description, evidence: $evidence, estimatedImpact: $estimatedImpact, severity: $severity, confidenceScore: $confidenceScore, recommendation: $recommendation, quickAction: $quickAction, secondaryActions: $secondaryActions, organizationId: $organizationId, companyId: $companyId, recipientUserId: $recipientUserId, customerId: $customerId, productId: $productId, sellerId: $sellerId, generatedAt: $generatedAt, expiresAt: $expiresAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $InsightCopyWith<$Res>  {
  factory $InsightCopyWith(Insight value, $Res Function(Insight) _then) = _$InsightCopyWithImpl;
@useResult
$Res call({
 String id, InsightType type, String title, String description, List<InsightEvidence> evidence, InsightEstimatedImpact estimatedImpact, InsightSeverity severity, double confidenceScore, String recommendation, InsightAction quickAction, List<InsightAction> secondaryActions, String organizationId, String companyId, String recipientUserId, String? customerId, String? productId, String? sellerId, DateTime generatedAt, DateTime expiresAt, InsightStatus status
});


$InsightEstimatedImpactCopyWith<$Res> get estimatedImpact;$InsightActionCopyWith<$Res> get quickAction;

}
/// @nodoc
class _$InsightCopyWithImpl<$Res>
    implements $InsightCopyWith<$Res> {
  _$InsightCopyWithImpl(this._self, this._then);

  final Insight _self;
  final $Res Function(Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = null,Object? evidence = null,Object? estimatedImpact = null,Object? severity = null,Object? confidenceScore = null,Object? recommendation = null,Object? quickAction = null,Object? secondaryActions = null,Object? organizationId = null,Object? companyId = null,Object? recipientUserId = null,Object? customerId = freezed,Object? productId = freezed,Object? sellerId = freezed,Object? generatedAt = null,Object? expiresAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InsightType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<InsightEvidence>,estimatedImpact: null == estimatedImpact ? _self.estimatedImpact : estimatedImpact // ignore: cast_nullable_to_non_nullable
as InsightEstimatedImpact,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as InsightSeverity,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,recommendation: null == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as String,quickAction: null == quickAction ? _self.quickAction : quickAction // ignore: cast_nullable_to_non_nullable
as InsightAction,secondaryActions: null == secondaryActions ? _self.secondaryActions : secondaryActions // ignore: cast_nullable_to_non_nullable
as List<InsightAction>,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,recipientUserId: null == recipientUserId ? _self.recipientUserId : recipientUserId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InsightStatus,
  ));
}
/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InsightEstimatedImpactCopyWith<$Res> get estimatedImpact {
  
  return $InsightEstimatedImpactCopyWith<$Res>(_self.estimatedImpact, (value) {
    return _then(_self.copyWith(estimatedImpact: value));
  });
}/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InsightActionCopyWith<$Res> get quickAction {
  
  return $InsightActionCopyWith<$Res>(_self.quickAction, (value) {
    return _then(_self.copyWith(quickAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [Insight].
extension InsightPatterns on Insight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Insight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Insight value)  $default,){
final _that = this;
switch (_that) {
case _Insight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Insight value)?  $default,){
final _that = this;
switch (_that) {
case _Insight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  InsightType type,  String title,  String description,  List<InsightEvidence> evidence,  InsightEstimatedImpact estimatedImpact,  InsightSeverity severity,  double confidenceScore,  String recommendation,  InsightAction quickAction,  List<InsightAction> secondaryActions,  String organizationId,  String companyId,  String recipientUserId,  String? customerId,  String? productId,  String? sellerId,  DateTime generatedAt,  DateTime expiresAt,  InsightStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.evidence,_that.estimatedImpact,_that.severity,_that.confidenceScore,_that.recommendation,_that.quickAction,_that.secondaryActions,_that.organizationId,_that.companyId,_that.recipientUserId,_that.customerId,_that.productId,_that.sellerId,_that.generatedAt,_that.expiresAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  InsightType type,  String title,  String description,  List<InsightEvidence> evidence,  InsightEstimatedImpact estimatedImpact,  InsightSeverity severity,  double confidenceScore,  String recommendation,  InsightAction quickAction,  List<InsightAction> secondaryActions,  String organizationId,  String companyId,  String recipientUserId,  String? customerId,  String? productId,  String? sellerId,  DateTime generatedAt,  DateTime expiresAt,  InsightStatus status)  $default,) {final _that = this;
switch (_that) {
case _Insight():
return $default(_that.id,_that.type,_that.title,_that.description,_that.evidence,_that.estimatedImpact,_that.severity,_that.confidenceScore,_that.recommendation,_that.quickAction,_that.secondaryActions,_that.organizationId,_that.companyId,_that.recipientUserId,_that.customerId,_that.productId,_that.sellerId,_that.generatedAt,_that.expiresAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  InsightType type,  String title,  String description,  List<InsightEvidence> evidence,  InsightEstimatedImpact estimatedImpact,  InsightSeverity severity,  double confidenceScore,  String recommendation,  InsightAction quickAction,  List<InsightAction> secondaryActions,  String organizationId,  String companyId,  String recipientUserId,  String? customerId,  String? productId,  String? sellerId,  DateTime generatedAt,  DateTime expiresAt,  InsightStatus status)?  $default,) {final _that = this;
switch (_that) {
case _Insight() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.description,_that.evidence,_that.estimatedImpact,_that.severity,_that.confidenceScore,_that.recommendation,_that.quickAction,_that.secondaryActions,_that.organizationId,_that.companyId,_that.recipientUserId,_that.customerId,_that.productId,_that.sellerId,_that.generatedAt,_that.expiresAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _Insight extends Insight {
  const _Insight({required this.id, required this.type, required this.title, required this.description, final  List<InsightEvidence> evidence = const <InsightEvidence>[], required this.estimatedImpact, required this.severity, required this.confidenceScore, required this.recommendation, required this.quickAction, final  List<InsightAction> secondaryActions = const <InsightAction>[], required this.organizationId, required this.companyId, required this.recipientUserId, this.customerId, this.productId, this.sellerId, required this.generatedAt, required this.expiresAt, required this.status}): _evidence = evidence,_secondaryActions = secondaryActions,super._();
  

@override final  String id;
@override final  InsightType type;
@override final  String title;
@override final  String description;
 final  List<InsightEvidence> _evidence;
@override@JsonKey() List<InsightEvidence> get evidence {
  if (_evidence is EqualUnmodifiableListView) return _evidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evidence);
}

@override final  InsightEstimatedImpact estimatedImpact;
@override final  InsightSeverity severity;
@override final  double confidenceScore;
@override final  String recommendation;
@override final  InsightAction quickAction;
 final  List<InsightAction> _secondaryActions;
@override@JsonKey() List<InsightAction> get secondaryActions {
  if (_secondaryActions is EqualUnmodifiableListView) return _secondaryActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryActions);
}

@override final  String organizationId;
@override final  String companyId;
@override final  String recipientUserId;
@override final  String? customerId;
@override final  String? productId;
@override final  String? sellerId;
@override final  DateTime generatedAt;
@override final  DateTime expiresAt;
@override final  InsightStatus status;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InsightCopyWith<_Insight> get copyWith => __$InsightCopyWithImpl<_Insight>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Insight&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._evidence, _evidence)&&(identical(other.estimatedImpact, estimatedImpact) || other.estimatedImpact == estimatedImpact)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.confidenceScore, confidenceScore) || other.confidenceScore == confidenceScore)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation)&&(identical(other.quickAction, quickAction) || other.quickAction == quickAction)&&const DeepCollectionEquality().equals(other._secondaryActions, _secondaryActions)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.recipientUserId, recipientUserId) || other.recipientUserId == recipientUserId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.sellerId, sellerId) || other.sellerId == sellerId)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,type,title,description,const DeepCollectionEquality().hash(_evidence),estimatedImpact,severity,confidenceScore,recommendation,quickAction,const DeepCollectionEquality().hash(_secondaryActions),organizationId,companyId,recipientUserId,customerId,productId,sellerId,generatedAt,expiresAt,status]);

@override
String toString() {
  return 'Insight(id: $id, type: $type, title: $title, description: $description, evidence: $evidence, estimatedImpact: $estimatedImpact, severity: $severity, confidenceScore: $confidenceScore, recommendation: $recommendation, quickAction: $quickAction, secondaryActions: $secondaryActions, organizationId: $organizationId, companyId: $companyId, recipientUserId: $recipientUserId, customerId: $customerId, productId: $productId, sellerId: $sellerId, generatedAt: $generatedAt, expiresAt: $expiresAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$InsightCopyWith<$Res> implements $InsightCopyWith<$Res> {
  factory _$InsightCopyWith(_Insight value, $Res Function(_Insight) _then) = __$InsightCopyWithImpl;
@override @useResult
$Res call({
 String id, InsightType type, String title, String description, List<InsightEvidence> evidence, InsightEstimatedImpact estimatedImpact, InsightSeverity severity, double confidenceScore, String recommendation, InsightAction quickAction, List<InsightAction> secondaryActions, String organizationId, String companyId, String recipientUserId, String? customerId, String? productId, String? sellerId, DateTime generatedAt, DateTime expiresAt, InsightStatus status
});


@override $InsightEstimatedImpactCopyWith<$Res> get estimatedImpact;@override $InsightActionCopyWith<$Res> get quickAction;

}
/// @nodoc
class __$InsightCopyWithImpl<$Res>
    implements _$InsightCopyWith<$Res> {
  __$InsightCopyWithImpl(this._self, this._then);

  final _Insight _self;
  final $Res Function(_Insight) _then;

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? description = null,Object? evidence = null,Object? estimatedImpact = null,Object? severity = null,Object? confidenceScore = null,Object? recommendation = null,Object? quickAction = null,Object? secondaryActions = null,Object? organizationId = null,Object? companyId = null,Object? recipientUserId = null,Object? customerId = freezed,Object? productId = freezed,Object? sellerId = freezed,Object? generatedAt = null,Object? expiresAt = null,Object? status = null,}) {
  return _then(_Insight(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InsightType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,evidence: null == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<InsightEvidence>,estimatedImpact: null == estimatedImpact ? _self.estimatedImpact : estimatedImpact // ignore: cast_nullable_to_non_nullable
as InsightEstimatedImpact,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as InsightSeverity,confidenceScore: null == confidenceScore ? _self.confidenceScore : confidenceScore // ignore: cast_nullable_to_non_nullable
as double,recommendation: null == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as String,quickAction: null == quickAction ? _self.quickAction : quickAction // ignore: cast_nullable_to_non_nullable
as InsightAction,secondaryActions: null == secondaryActions ? _self._secondaryActions : secondaryActions // ignore: cast_nullable_to_non_nullable
as List<InsightAction>,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,recipientUserId: null == recipientUserId ? _self.recipientUserId : recipientUserId // ignore: cast_nullable_to_non_nullable
as String,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,sellerId: freezed == sellerId ? _self.sellerId : sellerId // ignore: cast_nullable_to_non_nullable
as String?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InsightStatus,
  ));
}

/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InsightEstimatedImpactCopyWith<$Res> get estimatedImpact {
  
  return $InsightEstimatedImpactCopyWith<$Res>(_self.estimatedImpact, (value) {
    return _then(_self.copyWith(estimatedImpact: value));
  });
}/// Create a copy of Insight
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InsightActionCopyWith<$Res> get quickAction {
  
  return $InsightActionCopyWith<$Res>(_self.quickAction, (value) {
    return _then(_self.copyWith(quickAction: value));
  });
}
}

// dart format on
