import 'package:json_annotation/json_annotation.dart';

part 'json_rpc_request.g.dart';

@JsonSerializable(createFactory: false)
class JsonRpcRequest {
  const JsonRpcRequest({
    required this.method,
    required this.id,
    this.params,
  });

  final String jsonrpc = '2.0';
  final String method;
  final String id;
  final List<dynamic>? params;

  Map<String, dynamic> toJson() => _$JsonRpcRequestToJson(this);
}
