import 'package:borsh_annotation/borsh_annotation.dart';
import 'package:collection/collection.dart';
import 'package:solana/encoder.dart';
import 'package:solana/src/crypto/ed25519_hd_public_key.dart';
import 'package:solana/src/encoder/compact_array.dart';
import 'package:solana/src/encoder/compact_u16.dart';
import 'package:solana/src/encoder/message_header.dart';

/// This is an implementation of the [Message Format][1].
///
/// [1]: https://docs.solana.com/developing/programming-model/transactions#message-format
class Message {
  /// Construct a message to send with a transaction to execute the provided
  /// [instructions].
  const Message({
    required this.instructions,
  }) : super();

  Message.only(Instruction instruction) : instructions = [instruction];

  factory Message.decompile(CompiledMessage compiledMessage) {
    final data = Uint8List.fromList(compiledMessage.data.toList());
    final reader = BinaryReader(data.buffer.asByteData());

    final header = MessageHeader(
      numRequiredSignatures: reader.readU8(),
      numReadonlySignedAccounts: reader.readU8(),
      numReadonlyUnsignedAccounts: reader.readU8(),
    );

    final accountsLength = reader.readCompactU16Value();

    final lastWriteableSignerIndex =
        header.numRequiredSignatures - header.numReadonlySignedAccounts;
    final lastWriteableNonSigner =
        accountsLength - header.numReadonlyUnsignedAccounts;

    final accounts = reader
        .readFixedArray(
          accountsLength,
          () => reader.readFixedArray(32, reader.readU8),
        )
        .map(Ed25519HDPublicKey.new)
        .mapIndexed(
      (i, a) {
        final isSigner = i < header.numRequiredSignatures;

        return AccountMeta(
          pubKey: a,
          isWriteable: isSigner
              ? i < lastWriteableSignerIndex
              : i < lastWriteableNonSigner,
          isSigner: isSigner,
        );
      },
    ).toList();

    // Ignoring blockhash.
    reader.readFixedArray(32, reader.readU8);

    final instructionsLength = reader.readCompactU16Value();

    final instructions = reader.readFixedArray(
      instructionsLength,
      () => _decompileInstruction(reader, accounts),
    );

    return Message(instructions: instructions);
  }

  final List<Instruction> instructions;

  /// Compiles a message into the array of bytes that would be interpreted by
  /// solana. The [recentBlockhash] is passed here as this is the final step
  /// before sending the [Message].
  ///
  /// If provided the [feePayer] can be added to the accounts if it's not
  /// present.
  ///
  /// Returns a [CompiledMessage] that can be used to sign the transaction, and
  /// also verify that the number of signers is correct.
  CompiledMessage compile({
    required String recentBlockhash,
    Ed25519HDPublicKey? feePayer,
  }) {
    final accounts =
        instructions.getAccountsWithOptionalFeePayer(feePayer: feePayer);
    final keys = accounts.map((e) => e.pubKey.toByteArray());
    final accountsIndexesMap = accounts.toIndexesMap();
    final header = MessageHeader.fromAccounts(accounts);
    final compiledInstructions =
        instructions.map((i) => i.compile(accountsIndexesMap));

    return CompiledMessage(
      ByteArray.merge([
        header.toByteArray(),
        CompactArray.fromIterable(keys).toByteArray(),
        ByteArray.fromBase58(recentBlockhash),
        CompactArray.fromIterable(compiledInstructions).toByteArray(),
      ]),
    );
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(instructions);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          const DeepCollectionEquality().equals(instructions, instructions);
}

Instruction _decompileInstruction(
  BinaryReader reader,
  List<AccountMeta> allAccounts,
) {
  final programIdIndex = reader.readU8();
  final programId = allAccounts[programIdIndex].pubKey;

  final accountsLength = reader.readCompactU16Value();

  final accountIndexes =
      reader.readFixedArray(accountsLength, reader.readU8).toList();
  final accounts = accountIndexes.map((i) => allAccounts[i]).toList();

  final dataLength = reader.readCompactU16Value();

  return Instruction(
    programId: programId,
    accounts: accounts,
    data: ByteArray(reader.readFixedArray(dataLength, reader.readU8)),
  );
}

extension on BinaryReader {
  int readCompactU16Value() {
    final keysLength = CompactU16.raw(buf.buffer.asUint8List(offset));

    for (var i = 0; i < keysLength.size; i++) {
      readU8();
    }

    return keysLength.value;
  }
}
