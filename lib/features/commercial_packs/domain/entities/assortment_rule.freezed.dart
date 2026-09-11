// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assortment_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssortmentRule {

 String get id; AssortmentRuleType get type; String? get colorId; String? get sizeId; double? get minPercentage; int? get minQuantity;
/// Create a copy of AssortmentRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssortmentRuleCopyWith<AssortmentRule> get copyWith => _$AssortmentRuleCopyWithImpl<AssortmentRule>(this as AssortmentRule, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssortmentRule&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.colorId, colorId) || other.colorId == colorId)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.minPercentage, minPercentage) || other.minPercentage == minPercentage)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,colorId,sizeId,minPercentage,minQuantity);

@override
String toString() {
  return 'AssortmentRule(id: $id, type: $type, colorId: $colorId, sizeId: $sizeId, minPercentage: $minPercentage, minQuantity: $minQuantity)';
}


}

/// @nodoc
abstract mixin class $AssortmentRuleCopyWith<$Res>  {
  factory $AssortmentRuleCopyWith(AssortmentRule value, $Res Function(AssortmentRule) _then) = _$AssortmentRuleCopyWithImpl;
@useResult
$Res call({
 String id, AssortmentRuleType type, String? colorId, String? sizeId, double? minPercentage, int? minQuantity
});




}
/// @nodoc
class _$AssortmentRuleCopyWithImpl<$Res>
    implements $AssortmentRuleCopyWith<$Res> {
  _$AssortmentRuleCopyWithImpl(this._self, this._then);

  final AssortmentRule _self;
  final $Res Function(AssortmentRule) _then;

/// Create a copy of AssortmentRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? colorId = freezed,Object? sizeId = freezed,Object? minPercentage = freezed,Object? minQuantity = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AssortmentRuleType,colorId: freezed == colorId ? _self.colorId : colorId // ignore: cast_nullable_to_non_nullable
as String?,sizeId: freezed == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String?,minPercentage: freezed == minPercentage ? _self.minPercentage : minPercentage // ignore: cast_nullable_to_non_nullable
as double?,minQuantity: freezed == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AssortmentRule].
extension AssortmentRulePatterns on AssortmentRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssortmentRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssortmentRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssortmentRule value)  $default,){
final _that = this;
switch (_that) {
case _AssortmentRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssortmentRule value)?  $default,){
final _that = this;
switch (_that) {
case _AssortmentRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AssortmentRuleType type,  String? colorId,  String? sizeId,  double? minPercentage,  int? minQuantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssortmentRule() when $default != null:
return $default(_that.id,_that.type,_that.colorId,_that.sizeId,_that.minPercentage,_that.minQuantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AssortmentRuleType type,  String? colorId,  String? sizeId,  double? minPercentage,  int? minQuantity)  $default,) {final _that = this;
switch (_that) {
case _AssortmentRule():
return $default(_that.id,_that.type,_that.colorId,_that.sizeId,_that.minPercentage,_that.minQuantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AssortmentRuleType type,  String? colorId,  String? sizeId,  double? minPercentage,  int? minQuantity)?  $default,) {final _that = this;
switch (_that) {
case _AssortmentRule() when $default != null:
return $default(_that.id,_that.type,_that.colorId,_that.sizeId,_that.minPercentage,_that.minQuantity);case _:
  return null;

}
}

}

/// @nodoc


class _AssortmentRule implements AssortmentRule {
  const _AssortmentRule({required this.id, required this.type, this.colorId, this.sizeId, this.minPercentage, this.minQuantity});
  

@override final  String id;
@override final  AssortmentRuleType type;
@override final  String? colorId;
@override final  String? sizeId;
@override final  double? minPercentage;
@override final  int? minQuantity;

/// Create a copy of AssortmentRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssortmentRuleCopyWith<_AssortmentRule> get copyWith => __$AssortmentRuleCopyWithImpl<_AssortmentRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssortmentRule&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.colorId, colorId) || other.colorId == colorId)&&(identical(other.sizeId, sizeId) || other.sizeId == sizeId)&&(identical(other.minPercentage, minPercentage) || other.minPercentage == minPercentage)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,colorId,sizeId,minPercentage,minQuantity);

@override
String toString() {
  return 'AssortmentRule(id: $id, type: $type, colorId: $colorId, sizeId: $sizeId, minPercentage: $minPercentage, minQuantity: $minQuantity)';
}


}

/// @nodoc
abstract mixin class _$AssortmentRuleCopyWith<$Res> implements $AssortmentRuleCopyWith<$Res> {
  factory _$AssortmentRuleCopyWith(_AssortmentRule value, $Res Function(_AssortmentRule) _then) = __$AssortmentRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, AssortmentRuleType type, String? colorId, String? sizeId, double? minPercentage, int? minQuantity
});




}
/// @nodoc
class __$AssortmentRuleCopyWithImpl<$Res>
    implements _$AssortmentRuleCopyWith<$Res> {
  __$AssortmentRuleCopyWithImpl(this._self, this._then);

  final _AssortmentRule _self;
  final $Res Function(_AssortmentRule) _then;

/// Create a copy of AssortmentRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? colorId = freezed,Object? sizeId = freezed,Object? minPercentage = freezed,Object? minQuantity = freezed,}) {
  return _then(_AssortmentRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AssortmentRuleType,colorId: freezed == colorId ? _self.colorId : colorId // ignore: cast_nullable_to_non_nullable
as String?,sizeId: freezed == sizeId ? _self.sizeId : sizeId // ignore: cast_nullable_to_non_nullable
as String?,minPercentage: freezed == minPercentage ? _self.minPercentage : minPercentage // ignore: cast_nullable_to_non_nullable
as double?,minQuantity: freezed == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
