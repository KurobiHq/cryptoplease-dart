// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_rpc_response_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NullableValueResponse<T> _$NullableValueResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) {
  return NullableValueResponse<T>(
    value: _$nullableGenericFromJson(json['value'], fromJsonT),
  );
}

ValueResponse<T> _$ValueResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    ValueResponse<T>(
      value: fromJsonT(json['value']),
    );
