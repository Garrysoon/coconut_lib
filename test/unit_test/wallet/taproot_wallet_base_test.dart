import 'dart:typed_data';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('TaprootWalletBase', () {
    late TaprootVault vault;
    setUp(() {
      vault = MockFactory.createP2trVaultWithPolicies();
    });

    Uint8List _concat(Uint8List a, Uint8List b) {
      final out = Uint8List(a.length + b.length);
      out.setRange(0, a.length, a);
      out.setRange(a.length, a.length + b.length, b);
      return out;
    }

    int _lexicographicCompare(Uint8List a, Uint8List b) {
      final minLen = a.length < b.length ? a.length : b.length;
      for (int i = 0; i < minLen; i++) {
        if (a[i] != b[i]) return a[i] < b[i] ? -1 : 1;
      }
      if (a.length == b.length) return 0;
      return a.length < b.length ? -1 : 1;
    }

    Uint8List _tapBranchHash(Uint8List a, Uint8List b) {
      final compare = _lexicographicCompare(a, b);
      final first = compare <= 0 ? a : b;
      final second = compare <= 0 ? b : a;
      return Hash.taggedHash('TapBranch', _concat(first, second));
    }

    Uint8List _reconstructMerkleRootFromControlBlock({
      required Uint8List leafHash,
      required Uint8List controlBlockBytes,
    }) {
      // control block = 1 byte (0xc0|parityBit) + 32 bytes (internal key xonly) + N*32 bytes (merkle path)
      if (controlBlockBytes.length < 1 + 32) {
        throw ArgumentError('Invalid control block length');
      }
      final merklePathBytes = controlBlockBytes.sublist(1 + 32);
      if (merklePathBytes.length % 32 != 0) {
        throw ArgumentError('Invalid merkle path length in control block');
      }

      Uint8List current = leafHash;
      for (int i = 0; i < merklePathBytes.length; i += 32) {
        final sibling =
            merklePathBytes.sublist(i, i + 32); // tap sibling at each level
        current = _tapBranchHash(current, sibling);
      }
      return current;
    }

    group('getAddress', () {
      test('returns a valid taproot address', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        expect(vault.getAddress(0),
            'bcrt1ptyvhlupy3snr0f6d2shd3fw9kmfsvd575x8g28gpav7h707550xsayjqcp');
      });

      test('supports change addresses (isChange=true)', () {
        // TODO: change 주소 인덱스에 대한 address 생성 검증
      });
    });

    group('getAddressWithDerivationPath', () {
      test('validates derivation path', () {
        // TODO: 올바른/잘못된 파생경로 케이스 추가
      });

      test(
          'rejects derivation paths that do not start with wallet derivationPath',
          () {
        // TODO: prefix mismatch 케이스 추가
      });
    });

    group('hasPublicKeyInPsbt', () {
      test('returns true when psbt contains a key from one of keyStores', () {
        // TODO: PSBT에 keyStore의 fingerprint/pubkey가 포함될 때 true 검증
      });

      test('returns false when psbt contains no matching keys', () {
        // TODO: 매칭되는 키가 없을 때 false 검증
      });
    });

    group('getAggregatedPublicKey', () {
      test('returns 32-byte x-only aggregated key', () {
        //0331cd531693ac6f845e040afbad01fc13816869436d5bbaa0367abc3809b8848f
        //0336df5f7ac13900bef3fa97c66110397344af522501630a7490cd88e91fff1e24
        expect(Codec.encodeHex(vault.getAggregatedPublicKey(0, isXOnly: true)),
            'ca86cf1e3ca9f06623db7c9e84ad1f1e6c5bf5eea7b107cd39031b84be94be1e');
      });
    });

    group('getMerkleRoot', () {
      test('returns 32-byte merkle root', () {
        expect(Codec.encodeHex(vault.getMerkleRoot(0)),
            '3bd740b79eee8736133cf721d31471f121d4fc3020fba08c9d352566fb3152c4');
      });
    });

    group('getControlBlock', () {
      test('reconstructs merkle root and validates parity (policyIndex=0)', () {
        final int addressIndex = 0;
        final bool isChange = false;
        final int policyIndex = 0;

        final String controlBlockHex = vault
            .getControlBlock(policyIndex, addressIndex, isChange: isChange);
        final Uint8List controlBlockBytes = Codec.decodeHex(controlBlockHex);

        // control block: 1 byte prefix + 32 bytes internal key + 32 bytes * path length
        expect(controlBlockBytes.length, greaterThan(1 + 32));
        expect((controlBlockBytes.length - (1 + 32)) % 32, 0,
            reason: 'merkle path part must be 32-byte aligned');

        final int controlByte = controlBlockBytes[0];
        final Uint8List internalKeyXOnly = controlBlockBytes.sublist(1, 33);

        final Uint8List expectedInternalKeyXOnly =
            vault.getInternalKey(addressIndex, isChange: isChange);
        expect(Codec.encodeHex(internalKeyXOnly),
            Codec.encodeHex(expectedInternalKeyXOnly));

        final List<Uint8List> leafHashes = vault.policyList
            .map((policy) =>
                policy.getTapleafHash(addressIndex, isChange: isChange))
            .toList();
        final Uint8List leafHash = leafHashes[policyIndex];

        final Uint8List merkleRootFromControl =
            _reconstructMerkleRootFromControlBlock(
                leafHash: leafHash, controlBlockBytes: controlBlockBytes);
        final Uint8List expectedMerkleRoot =
            vault.getMerkleRoot(addressIndex, isChange: isChange);

        expect(Codec.encodeHex(merkleRootFromControl),
            Codec.encodeHex(expectedMerkleRoot));

        final Uint8List tweak = Hash.hashTapTweak(
            'TapTweak', expectedInternalKeyXOnly, expectedMerkleRoot);
        final Uint8List outputKey =
            Ecc.pointAddScalar(expectedInternalKeyXOnly, tweak, true)!;
        final int parityBitExpected = outputKey[0] == 0x03 ? 1 : 0;
        final int controlByteExpected = 0xc0 | parityBitExpected;
        expect(controlByte, controlByteExpected);
      });

      test('reconstructs merkle root and validates parity (policyIndex=2)', () {
        final int addressIndex = 0;
        final bool isChange = false;
        final int policyIndex = 2;

        final String controlBlockHex = vault
            .getControlBlock(policyIndex, addressIndex, isChange: isChange);
        final Uint8List controlBlockBytes = Codec.decodeHex(controlBlockHex);

        final Uint8List internalKeyXOnly = controlBlockBytes.sublist(1, 33);
        final Uint8List expectedInternalKeyXOnly =
            vault.getInternalKey(addressIndex, isChange: isChange);
        expect(Codec.encodeHex(internalKeyXOnly),
            Codec.encodeHex(expectedInternalKeyXOnly));

        final List<Uint8List> leafHashes = vault.policyList
            .map((policy) =>
                policy.getTapleafHash(addressIndex, isChange: isChange))
            .toList();

        final Uint8List merkleRootFromControl =
            _reconstructMerkleRootFromControlBlock(
                leafHash: leafHashes[policyIndex],
                controlBlockBytes: controlBlockBytes);
        final Uint8List expectedMerkleRoot =
            vault.getMerkleRoot(addressIndex, isChange: isChange);
        expect(Codec.encodeHex(merkleRootFromControl),
            Codec.encodeHex(expectedMerkleRoot));

        final int controlByte = controlBlockBytes[0];
        final Uint8List tweak = Hash.hashTapTweak(
            'TapTweak', expectedInternalKeyXOnly, expectedMerkleRoot);
        final Uint8List outputKey =
            Ecc.pointAddScalar(expectedInternalKeyXOnly, tweak, true)!;
        final int parityBitExpected = outputKey[0] == 0x03 ? 1 : 0;
        final int controlByteExpected = 0xc0 | parityBitExpected;
        expect(controlByte, controlByteExpected);
      });
    });

    group('addSignatureToPsbt', () {
      test('adds signatures when seeds exist', () {
        // TODO: PSBT 생성 후 서명 추가 플로우 검증
      });

      test('does not change psbt when no keyStore has seed', () {
        // TODO: neutered keyStore만 있을 때 변화 없음 검증
      });

      test('throws when addressType mismatches', () {
        // TODO: addressType 불일치 시 예외 검증
      });
    });

    group('descriptor', () {
      test('is created and parseable (round-trip)', () {
        // TODO: wallet.descriptor serialize/parse round-trip 검증
      });
    });
  });
}
