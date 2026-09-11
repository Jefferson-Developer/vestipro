// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pack_component.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PackComponent {

 String get id; PackComponentScopeType get scopeType; String get scopeReferenceId; PackComponentCompositionType get compositionType; int? get quantity; int? get minQuantity; int? get maxQuantity; double? get proportion; bool get isBonusItem;
/// Create a copy of PackComponent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackComponentCopyWith<PackComponent> get copyWith => _$PackComponentCopyWithImpl<PackComponent>(this as PackComponent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackComponent&&(identical(other.id, id) || other.id == id)&&(identical(other.scopeType, scopeType) || other.scopeType == scopeType)&&(identical(other.scopeReferenceId, scopeReferenceId) || other.scopeReferenceId == scopeReferenceId)&&(identical(other.compositionType, compositionType) || other.compositionType == compositionType)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity)&&(identical(other.proportion, proportion) || other.proportion == proportion)&&(identical(other.isBonusItem, isBonusItem) || other.isBonusItem == isBonusItem));
}


@override
int get hashCode => Object.hash(runtimeType,id,scopeType,scopeReferenceId,compositionType,quantity,minQuantity,maxQuantity,proportion,isBonusItem);

@override
String toString() {
  return 'PackComponent(id: $id, scopeType: $scopeType, scopeReferenceId: $scopeReferenceId, compositionType: $compositionType, quantity: $quantity, minQuantity: $minQuantity, maxQuantity: $maxQuantity, proportion: $proportion, isBonusItem: $isBonusItem)';
}


}

/// @nodoc
abstract mixin class $PackComponentCopyWith<$Res>  {
  factory $PackComponentCopyWith(PackComponent value, $Res Function(PackComponent) _then) = _$PackComponentCopyWithImpl;
@useResult
$Res call({
 String id, PackComponentScopeType scopeType, String scopeReferenceId, PackComponentCompositionType compositionType, int? quantity, int? minQuantity, int? maxQuantity, double? proportion, bool isBonusItem
});




}
/// @nodoc
class _$PackComponentCopyWithImpl<$Res>
    implements $PackComponentCopyWith<$Res> {
  _$PackComponentCopyWithImpl(this._self, this._then);

  final PackComponent _self;
  final $Res Function(PackComponent) _then;

/// Create a copy of PackComponent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scopeType = null,Object? scopeReferenceId = null,Object? compositionType = null,Object? quantity = freezed,Object? minQuantity = freezed,Object? maxQuantity = freezed,Object? proportion = freezed,Object? isBonusItem = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scopeType: null == scopeType ? _self.scopeType : scopeType // ignore: cast_nullable_to_non_nullable
as PackComponentScopeType,scopeReferenceId: null == scopeReferenceId ? _self.scopeReferenceId : scopeReferenceId // ignore: cast_nullable_to_non_nullable
as String,compositionType: null == compositionType ? _self.compositionType : compositionType // ignore: cast_nullable_to_non_nullable
as PackComponentCompositionType,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int?,minQuantity: freezed == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int?,maxQuantity: freezed == maxQuantity ? _self.maxQuantity : maxQuantity // ignore: cast_nullable_to_non_nullable
as int?,proportion: freezed == proportion ? _self.proportion : proportion // ignore: cast_nullable_to_non_nullable
as double?,isBonusItem: null == isBonusItem ? _self.isBonusItem : isBonusItem // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PackComponent].
extension PackComponentPatterns on PackComponent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackComponent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackComponent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackComponent value)  $default,){
final _that = this;
switch (_that) {
case _PackComponent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackComponent value)?  $default,){
final _that = this;
switch (_that) {
case _PackComponent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PackComponentScopeType scopeType,  String scopeReferenceId,  PackComponentCompositionType compositionType,  int? quantity,  int? minQuantity,  int? maxQuantity,  double? proportion,  bool isBonusItem)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackComponent() when $default != null:
return $default(_that.id,_that.scopeType,_that.scopeReferenceId,_that.compositionType,_that.quantity,_that.minQuantity,_that.maxQuantity,_that.proportion,_that.isBonusItem);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PackComponentScopeType scopeType,  String scopeReferenceId,  PackComponentCompositionType compositionType,  int? quantity,  int? minQuantity,  int? maxQuantity,  double? proportion,  bool isBonusItem)  $default,) {final _that = this;
switch (_that) {
case _PackComponent():
return $default(_that.id,_that.scopeType,_that.scopeReferenceId,_that.compositionType,_that.quantity,_that.minQuantity,_that.maxQuantity,_that.proportion,_that.isBonusItem);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PackComponentScopeType scopeType,  String scopeReferenceId,  PackComponentCompositionType compositionType,  int? quantity,  int? minQuantity,  int? maxQuantity,  double? proportion,  bool isBonusItem)?  $default,) {final _that = this;
switch (_that) {
case _PackComponent() when $default != null:
return $default(_that.id,_that.scopeType,_that.scopeReferenceId,_that.compositionType,_that.quantity,_that.minQuantity,_that.maxQuantity,_that.proportion,_that.isBonusItem);case _:
  return null;

}
}

}

/// @nodoc


class _PackComponent implements PackComponent {
  const _PackComponent({required this.id, required this.scopeType, required this.scopeReferenceId, required this.compositionType, this.quantity, this.minQuantity, this.maxQuantity, this.proportion, this.isBonusItem = false});
  

@override final  String id;
@override final  PackComponentScopeType scopeType;
@override final  String scopeReferenceId;
@override final  PackComponentCompositionType compositionType;
@override final  int? quantity;
@override final  int? minQuantity;
@override final  int? maxQuantity;
@override final  double? proportion;
@override@JsonKey() final  bool isBonusItem;

/// Create a copy of PackComponent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackComponentCopyWith<_PackComponent> get copyWith => __$PackComponentCopyWithImpl<_PackComponent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackComponent&&(identical(other.id, id) || other.id == id)&&(identical(other.scopeType, scopeType) || other.scopeType == scopeType)&&(identical(other.scopeReferenceId, scopeReferenceId) || other.scopeReferenceId == scopeReferenceId)&&(identical(other.compositionType, compositionType) || other.compositionType == compositionType)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity)&&(identical(other.proportion, proportion) || other.proportion == proportion)&&(identical(other.isBonusItem, isBonusItem) || other.isBonusItem == isBonusItem));
}


@override
int get hashCode => Object.hash(runtimeType,id,scopeType,scopeReferenceId,compositionType,quantity,minQuantity,maxQuantity,proportion,isBonusItem);

@override
String toString() {
  return 'PackComponent(id: $id, scopeType: $scopeType, scopeReferenceId: $scopeReferenceId, compositionType: $compositionType, quantity: $quantity, minQuantity: $minQuantity, maxQuantity: $maxQuantity, proportion: $proportion, isBonusItem: $isBonusItem)';
}


}

/// @nodoc
abstract mixin class _$PackComponentCopyWith<$Res> implements $PackComponentCopyWith<$Res> {
  factory _$PackComponentCopyWith(_PackComponent value, $Res Function(_PackComponent) _then) = __$PackComponentCopyWithImpl;
@override @useResult
$Res call({
 String id, PackComponentScopeType scopeType, String scopeReferenceId, PackComponentCompositionType compositionType, int? quantity, int? minQuantity, int? maxQuantity, double? proportion, bool isBonusItem
});




}
/// @nodoc
class __$PackComponentCopyWithImpl<$Res>
    implements _$PackComponentCopyWith<$Res> {
  __$PackComponentCopyWithImpl(this._self, this._then);

  final _PackComponent _self;
  final $Res Function(_PackComponent) _then;

/// Create a copy of PackComponent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scopeType = null,Object? scopeReferenceId = null,Object? compositionType = null,Object? quantity = freezed,Object? minQuantity = freezed,Object? maxQuantity = freezed,Object? proportion = freezed,Object? isBonusItem = null,}) {
  return _then(_PackComponent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scopeType: null == scopeType ? _self.scopeType : scopeType // ignore: cast_nullable_to_non_nullable
as PackComponentScopeType,scopeReferenceId: null == scopeReferenceId ? _self.scopeReferenceId : scopeReferenceId // ignore: cast_nullable_to_non_nullable
as String,compositionType: null == compositionType ? _self.compositionType : compositionType // ignore: cast_nullable_to_non_nullable
as PackComponentCompositionType,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int?,minQuantity: freezed == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as int?,maxQuantity: freezed == maxQuantity ? _self.maxQuantity : maxQuantity // ignore: cast_nullable_to_non_nullable
as int?,proportion: freezed == proportion ? _self.proportion : proportion // ignore: cast_nullable_to_non_nullable
as double?,isBonusItem: null == isBonusItem ? _self.isBonusItem : isBonusItem // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
