import 'dart:convert';

import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

import '../../mock_factory.dart';

void main() {
  group('TaprootWalletBase', () {
    late TaprootVault vault;
    setUp(() {
      vault = MockFactory.createP2trVaultWithPolicies();
    });

    group('getAddress', () {
      test('returns a valid taproot address', () {
        NetworkType.setNetworkType(NetworkType.regtest);
        expect(vault.getAddress(0),
            'bcrt1p4jk004e854y8c84n5ymv4tm3dv0tqu6uhms9zheskj4gexakwrpsd04al6');
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
        expect(Codec.encodeHex(vault.getAggregatedPublicKey(0)),
            'ca86cf1e3ca9f06623db7c9e84ad1f1e6c5bf5eea7b107cd39031b84be94be1e');
      });
    });

    group('getMerkleRoot', () {
      test('returns 32-byte merkle root', () {
        expect(Codec.encodeHex(vault.getMerkleRoot(0)),
            '92117d3d19caa7d5e4f6c30ef9cf6a1409120b1b45605ebe6c73b6e40840acdf');
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
