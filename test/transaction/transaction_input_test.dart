@Tags(['unit'])
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

main() {
  group('TransactionInput', () {
    group('get transactionHash', () {
      test('Get transaction hash', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        expect(input.transactionHash,
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0');
      });
    });
    group('get index', () {
      test('Get index', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        expect(input.index, 0);
      });
    });
    group('get sequence', () {
      test('Get sequence', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        expect(input.sequence, 4294967295);
      });
    });
    group('get length', () {
      test('Get length of transaction input', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        expect(input.length, 41);
      });
    });
    group('TransactionInput.parse', () {
      test('Generate transaction input from parsing on p2pkh', () {
        String inputText =
            'd06050454abde3bdd947312b9f54439acb097608a47b0b36a23d76820a3a4044000000006a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8dfffffffff';
        TransactionInput input = TransactionInput.parse(inputText);
        expect(input.transactionHash,
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0');
        expect(input.index, 0);
        expect(input.sequence, 4294967295);
        expect(input.scriptSig.serialize(),
            '6a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8df');
      });
      test('Generate transaction input from parsing on p2wpkh', () {
        String inputText =
            'a463a7a78daffa1bdb1248121adb14b94f70a1fabffc81637f4049c3d65cc69f000000000000000080';
        TransactionInput input = TransactionInput.parse(inputText);
        expect(input.transactionHash,
            '9fc65cd6c349407f6381fcbffaa1704fb914db1a124812db1bfaaf8da7a763a4');
        expect(input.index, 0);
        expect(input.sequence, 2147483648);
        expect(input.scriptSig.serialize(), '00');
      });
    });
    group('TransactionInput.parseForPsbt', () {
      test('Generate transaction input for psbt', () {
        String inputText =
            'd06050454abde3bdd947312b9f54439acb097608a47b0b36a23d76820a3a40440000000000ffffffff';
        TransactionInput input = TransactionInput.parseForPsbt(inputText);
        expect(input.transactionHash,
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0');
        expect(input.index, 0);
        expect(input.sequence, 4294967295);
        expect(input.scriptSig.serialize(), '00');
      });
    });
    group('TransactionInput.forPayment', () {
      test('Generate transaction input for payment on p2pkh', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        expect(input, isA<TransactionInput>());
      });
      test('Generate transaction input for payment on p2wpkh', () {
        TransactionInput input = TransactionInput.forPayment(
            'a770b9c757cd83461de06049e0898740dc112e32b7543b2f2d038d5ce0d201db',
            1,
            sequence: 2147483648);
        expect(input, isA<TransactionInput>());
      });
    });
    group('setSignature', () {
      test('Set signature to transaction input on p2pkh', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        input.setSignature(AddressType.p2pkh, [
          Signature(
              '30440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be001',
              '02742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8df')
        ]);
        expect(input.scriptSig.serialize(),
            '6a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8df');
      });
      test('Set signature to transaction input on p2wpkh', () {
        TransactionInput input = TransactionInput.forPayment(
            'a770b9c757cd83461de06049e0898740dc112e32b7543b2f2d038d5ce0d201db',
            1,
            sequence: 2147483648);
        input.setSignature(AddressType.p2wpkh, [
          Signature(
              '304402201627e63472fc39db307a5db0e0450748fc6ea876c6376da7b1885a7464f2441302206ea2e3257755efa6552d4cb2082a6a4595fdff512411f51785ab7453ad3c092001',
              '03c0c4d5bd6ab4ad72bf4b386db12767aa0043ac1652b621afdcf3eeb299fe2fb4')
        ]);
        expect(input.scriptSig.serialize(), '00');
        expect(input.witnessList.length, 2);
        expect(input.witnessList[0],
            '304402201627e63472fc39db307a5db0e0450748fc6ea876c6376da7b1885a7464f2441302206ea2e3257755efa6552d4cb2082a6a4595fdff512411f51785ab7453ad3c092001');
        expect(input.witnessList[1],
            '03c0c4d5bd6ab4ad72bf4b386db12767aa0043ac1652b621afdcf3eeb299fe2fb4');
      });
    });
    group('hasSignature', () {
      test('Check the transaction input has signature on p2pkh', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        expect(input.hasSignature(false), false);
        input.setSignature(AddressType.p2pkh, [
          Signature(
              '30440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be001',
              '02742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8df')
        ]);
        expect(input.hasSignature(false), true);
      });
      test('Check the transaction input has signature on p2wpkh', () {
        TransactionInput input = TransactionInput.forPayment(
            'a770b9c757cd83461de06049e0898740dc112e32b7543b2f2d038d5ce0d201db',
            1,
            sequence: 2147483648);
        expect(input.hasSignature(true), false);
        input.setSignature(AddressType.p2wpkh, [
          Signature(
              '304402201627e63472fc39db307a5db0e0450748fc6ea876c6376da7b1885a7464f2441302206ea2e3257755efa6552d4cb2082a6a4595fdff512411f51785ab7453ad3c092001',
              '03c0c4d5bd6ab4ad72bf4b386db12767aa0043ac1652b621afdcf3eeb299fe2fb4')
        ]);
        expect(input.hasSignature(true), true);
      });
    });
    group('serialize', () {
      test('Serialize transaction input on p2pkh ', () {
        TransactionInput input = TransactionInput.forPayment(
            '44403a0a82763da2360b7ba4087609cb9a43549f2b3147d9bde3bd4a455060d0',
            0);
        input.setSignature(AddressType.p2pkh, [
          Signature(
              '30440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be001',
              '02742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8df')
        ]);
        expect(input.serialize(),
            'd06050454abde3bdd947312b9f54439acb097608a47b0b36a23d76820a3a4044000000006a4730440220360e6c5348a85270a3b14b84780ad56cd189bd12848b125c488a678f5e0d95be022011e51cfd849e5d005fc5352885a954c756f6073de633545f6045c4ad96ac9be0012102742148dd2f73733ce36202798298e8294b42b5aabf1ba87a9bb9b0167abfb8dfffffffff');
      });
      test('Serialize transaction input on p2wpkh ', () {
        TransactionInput input = TransactionInput.forPayment(
            'a770b9c757cd83461de06049e0898740dc112e32b7543b2f2d038d5ce0d201db',
            1,
            sequence: 2147483648);
        input.setSignature(AddressType.p2wpkh, [
          Signature(
              '304402201627e63472fc39db307a5db0e0450748fc6ea876c6376da7b1885a7464f2441302206ea2e3257755efa6552d4cb2082a6a4595fdff512411f51785ab7453ad3c092001',
              '03c0c4d5bd6ab4ad72bf4b386db12767aa0043ac1652b621afdcf3eeb299fe2fb4')
        ]);
        expect(input.serialize(),
            'db01d2e05c8d032d2f3b54b7322e11dc408789e04960e01d4683cd57c7b970a7010000000000000080');
      });
    });
  });
}
