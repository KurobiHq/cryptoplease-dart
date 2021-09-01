import 'dart:convert';

import 'package:solana/src/json_rpc_request/json_rpc_request.dart';
import 'package:solana/src/rpc_client/commitment.dart';
import 'package:solana/src/rpc_client/transaction_signature.dart';
import 'package:solana/src/websocket_client/subscription.dart';
import 'package:solana/src/websocket_client/subscription_response.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketClient(this._url);

  final String _url;
  int _lastId = 1;

  Subscription<T> _callMethod<T>(
    String method,
    String unsubscribeMethod,
    List<dynamic>? params,
  ) {
    final channel = WebSocketChannel.connect(Uri.parse(_url));
    final sink = channel.sink;
    final request = JsonRpcRequest(
      id: (_lastId++).toString(),
      method: method,
      params: params,
    );
    sink.add(json.encode(request.toJson()));

    final subscription = Subscription<T>(
      originalStream: channel.stream,
      unsubscribeCallback: (id) {
        sink
          ..add(json.encode(
            JsonRpcRequest(
              id: (_lastId++).toString(),
              method: unsubscribeMethod,
              params: <dynamic>[id],
            ),
          ))
          ..close();
      },
    );

    return subscription;
  }

  /// Subscribe to a transaction signature and listen to changes in its status.
  Subscription<SignatureNotification> signatureSubscribe(
    TransactionSignature signature, {
    Commitment? commitment,
  }) =>
      _callMethod<SignatureNotification>(
        'signatureSubscribe',
        'signatureUnsubscribe',
        <dynamic>[
          signature.toString(),
          if (commitment != null)
            <String, dynamic>{
              'commitment': commitment.value,
            },
        ],
      );
}
