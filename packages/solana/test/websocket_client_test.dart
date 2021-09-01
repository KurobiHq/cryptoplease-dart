import 'dart:async';

import 'package:bip39/bip39.dart';
import 'package:solana/src/crypto/ed25519_hd_keypair.dart';
import 'package:solana/src/encoder/signed_tx.dart';
import 'package:solana/src/rpc_client/rpc_client.dart';
import 'package:solana/src/rpc_client/transaction_signature.dart';
import 'package:solana/src/system_program/system_program.dart';
import 'package:solana/src/websocket_client/subscription.dart';
import 'package:solana/src/websocket_client/subscription_response.dart';
import 'package:solana/src/websocket_client/websocket_client.dart';
import 'package:test/test.dart';

import 'airdrop.dart';
import 'config.dart';

const int _transferredAmount = 0x1000;

Future<void> waitForSignature(
  WebSocketClient client,
  TransactionSignature signature, {
  Commitment? commitment,
}) {
  final completer = Completer<void>();

  client.signatureSubscribe(signature, commitment: commitment).listen((
    SignatureNotification data,
    Subscription<SignatureNotification> subscription,
  ) {
    subscription.unsubscribe();
    completer.complete();
  });

  return completer.future;
}

void main() {
  final RPCClient rpcClient = RPCClient(devnetRpcUrl);
  final WebSocketClient webSocketClient = WebSocketClient(devnetWebsocketUrl);
  late Ed25519HDKeyPair destination;
  late Ed25519HDKeyPair source;

  setUpAll(() async {
    destination = await Ed25519HDKeyPair.fromMnemonic(
      generateMnemonic(),
    ); // generateMnemonic());
    source = await Ed25519HDKeyPair.fromMnemonic(
      generateMnemonic(),
      account: 1,
    );
    await airdrop(rpcClient, source, sol: 10);
  });

  test('Transfer SOL', () async {
    final recentBlockhash = await rpcClient.getRecentBlockhash();
    final message = SystemProgram.transfer(
      source: source.address,
      destination: destination.address,
      lamports: _transferredAmount,
    );
    final SignedTx signedTx = await source.signMessage(
      message: message,
      recentBlockhash: recentBlockhash.blockhash,
    );
    final TransactionSignature signature =
        await rpcClient.sendTransaction(signedTx.encode());
    expect(signature, isNot(null));
    await waitForSignature(
      webSocketClient,
      signature,
      commitment: Commitment.finalized,
    );
    final statuses = await rpcClient.getSignatureStatuses([signature]);
    expect(statuses.first?.confirmationStatus, equals(TxStatus.finalized));

    final int balance = await rpcClient.getBalance(destination.address);
    expect(balance, greaterThan(0));
  });
}
