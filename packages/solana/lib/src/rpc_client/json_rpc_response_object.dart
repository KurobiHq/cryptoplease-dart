import 'package:json_annotation/json_annotation.dart';

part 'json_rpc_response_object.g.dart';

class JsonRpcResponse<T> {
  JsonRpcResponse({required this.result});

  final T result;
}

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class NullableValueResponse<T> {
  NullableValueResponse({this.value});

  factory NullableValueResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$NullableValueResponseFromJson(json, fromJsonT);

  final T? value;
}

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class ValueResponse<T> {
  ValueResponse({required this.value});

  factory ValueResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ValueResponseFromJson(json, fromJsonT);

  final T value;
}
