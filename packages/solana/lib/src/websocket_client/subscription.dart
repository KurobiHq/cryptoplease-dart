import 'dart:async';
import 'dart:convert';

import 'package:solana/src/exceptions/bad_state_exception.dart';
import 'package:solana/src/websocket_client/subscription_response.dart';

class Subscription<T> {
  Subscription({
    required Stream<dynamic> originalStream,
    required void Function(int) unsubscribeCallback,
  })  : _unsubscribeCallback = unsubscribeCallback,
        _controller = StreamController<T>() {
    _idCollectorSubscription = originalStream.listen(_installRootListener);
  }

  final void Function(int) _unsubscribeCallback;
  final StreamController<T> _controller;

  // Collect the id of the stream and remove it!
  late final StreamSubscription<dynamic> _idCollectorSubscription;

  int? _id;

  void unsubscribe() {
    final id = _id;
    if (id != null) {
      _idCollectorSubscription.cancel();
      _unsubscribeCallback(id);
    }
  }

  void _emit(dynamic notification) {
    if (notification is ResponseParams<T>) {
      _controller.add(notification.result);
    } else {
      throw const BadStateException(
        'stream is attempting to emit an incompatible message',
      );
    }
  }

  void _installRootListener(dynamic data) {
    SubscriptionMessage.fromJson(
      json.decode(data as String) as Map<String, dynamic>,
    ).when(
      response: (result, id) {
        _id = result;
      },
      signatureNotification: _emit,
    );
  }

  StreamSubscription<T> listen(void Function(T, Subscription<T>) onData) =>
      _controller.stream.listen((T data) => onData(data, this));
}
