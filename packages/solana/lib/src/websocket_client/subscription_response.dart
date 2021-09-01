import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_response.freezed.dart';
part 'subscription_response.g.dart';

@Freezed(unionKey: 'method', fallbackUnion: 'response')
class SubscriptionMessage with _$SubscriptionMessage {
  const SubscriptionMessage._();

  const factory SubscriptionMessage.response({
    required int result,
    required String id,
  }) = SubscriptionResponse;

  const factory SubscriptionMessage.signatureNotification({
    required ResponseParams<SignatureNotification> params,
  }) = SignatureNotificationMessage;

  factory SubscriptionMessage.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionMessageFromJson(json);
}

@JsonSerializable(createToJson: false, genericArgumentFactories: true)
class ResponseParams<T> {
  const ResponseParams({
    required this.result,
    required this.subscription,
  });

  factory ResponseParams.fromJson(
    Map<String, dynamic> json,
    T Function(Object? object) fromJsonT,
  ) =>
      _$ResponseParamsFromJson(json, fromJsonT);

  Map<String, dynamic> toJson() {
    throw UnsupportedError('you never need to convert this to json');
  }

  final T result;
  final int subscription;
}

@JsonSerializable(createToJson: false)
class SignatureNotification {
  const SignatureNotification({
    required this.context,
    required this.value,
  });

  factory SignatureNotification.fromJson(Map<String, dynamic> json) =>
      _$SignatureNotificationFromJson(json);

  final SignatureNotificationContext context;
  final SignatureNotificationValue value;
}

@JsonSerializable(createToJson: false)
class SignatureNotificationContext {
  const SignatureNotificationContext({
    required this.slot,
  });

  factory SignatureNotificationContext.fromJson(Map<String, dynamic> json) =>
      _$SignatureNotificationContextFromJson(json);

  final int slot;
}

@JsonSerializable(createToJson: false)
class SignatureNotificationValue {
  SignatureNotificationValue({
    required this.err,
  });

  factory SignatureNotificationValue.fromJson(Map<String, dynamic> json) =>
      _$SignatureNotificationValueFromJson(json);

  final Object? err;
}
