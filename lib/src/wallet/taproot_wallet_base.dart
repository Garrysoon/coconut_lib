// part of '../../coconut_lib.dart';

// abstract class InheritancePlan {
//   final KeyStore keyStore;
//   InheritancePlan(this.keyStore);
//   Script get script;
// }

// class AbsoluteInheritancePlan extends InheritancePlan {
//   final int locktime;
//   AbsoluteInheritancePlan(this.locktime, super.keyStore);

//   @override
//   Script get script => InheritanceScript.withCheckLockTimeVerify(
//       locktime, keyStore.getPublicKeyBytes(0, isChange: false, isXOnly: true));
// }

// class RelativeInheritancePlan extends InheritancePlan {
//   final int sequence;
//   RelativeInheritancePlan(this.sequence, super.keyStore);

//   @override
//   Script get script => InheritanceScript.withCheckSequenceVerify(
//       sequence, keyStore.getPublicKeyBytes(0, isChange: false, isXOnly: true));
// }

// abstract class TaprootWalletBase extends WalletBase {
//   final List<KeyStore> _keyStoreList;
//   final List<InheritancePlan>? _inheritancePlanList;
//   final bool _isVault;

//   /// Get the list of keyStores.
//   List<KeyStore> get keyStoreList => _keyStoreList;

//   /// Check if this is a vault.
//   bool get isVault => _isVault;

//   /// Get the list of inheritance plans.
//   List<InheritancePlan>? get inheritancePlanList => _inheritancePlanList;

//   /// @nodoc
//   TaprootWalletBase(this._keyStoreList, this._inheritancePlanList,
//       AddressType _addressType, String _derivationPath, this._isVault)
//       : super(_addressType, _derivationPath) {
//     if (!_addressType.isTaproot) {
//       throw Exception('Address type must be Taproot.');
//     }

//     for (KeyStore keyStore in _keyStoreList) {
//       if (NetworkType.currentNetworkType.isTestnet !=
//           AddressType.isTestnetVersion(keyStore.extendedPublicKey.version)) {
//         throw Exception('Network type mismatch.');
//       }
//     }

//     // Check derivation path
//     final segments = derivationPath.split('/');
//     if (segments.length < 3 || segments[0] != 'm') {
//       throw Exception('Invalid derivation path.');
//     }
//     final coinTypeSegment = segments[2];

//     final coinType =
//         int.tryParse(coinTypeSegment.replaceAll(RegExp(r"[h']"), ""));

//     if (coinType == 1 && !NetworkType.currentNetworkType.isTestnet) {
//       throw Exception('Invalid derivation path.');
//     } else if (coinType == 0 && NetworkType.currentNetworkType.isTestnet) {
//       throw Exception('Invalid derivation path.');
//     }

//     _descriptor = Descriptor.forMultisignature(
//         _addressType,
//         _keyStoreList.map((e) => e.extendedPublicKey.serialize()).toList(),
//         _derivationPath.replaceAll("m/", ""),
//         _keyStoreList.map((e) => e.masterFingerprint).toList(),
//         _keyStoreList.length);
//   }

//   Uint8List getAggregatedPublicKey(int addressIndex, {bool isChange = false}) {
//     List<String> publicKeyList = _keyStoreList
//         .map((keyStore) => keyStore.getPublicKey(addressIndex,
//             isChange: isChange, isXOnly: true))
//         .toList();
//     List<Uint8List> publicKeysBytes =
//         publicKeyList.map((e) => Codec.decodeHex(e)).toList();

//     List<Uint8List> prefixedPublicKeyList = [];
//     for (Uint8List publicKey in publicKeysBytes) {
//       if (publicKey.length == 32) {
//         prefixedPublicKeyList.add(Uint8List.fromList([0x02, ...publicKey]));
//       } else if (publicKey.length == 33) {
//         prefixedPublicKeyList.add(publicKey);
//       } else {
//         throw ArgumentError(
//             "publicKey must be 32 or 33 bytes (got ${publicKey.length})");
//       }
//     }

//     late Uint8List secondKey = Uint8List(0);
//     for (Uint8List key in prefixedPublicKeyList) {
//       if (Codec.encodeHex(prefixedPublicKeyList[0]) != Codec.encodeHex(key)) {
//         secondKey = key;
//         break;
//       }
//     }

//     String concatenatedPublicKey =
//         prefixedPublicKeyList.map((e) => Codec.encodeHex(e)).join();

//     Uint8List Q = prefixedPublicKeyList[0];

//     for (int i = 0; i < prefixedPublicKeyList.length; i++) {
//       Uint8List coefficient = Uint8List(0);
//       if (Codec.encodeHex(prefixedPublicKeyList[i]) ==
//           Codec.encodeHex(secondKey)) {
//         coefficient = Uint8List.fromList(List<int>.generate(
//             32,
//             (i) => int.parse(
//                 BigInt.one
//                     .toRadixString(16)
//                     .padLeft(64, '0')
//                     .substring(i * 2, i * 2 + 2),
//                 radix: 16)));
//       } else {
//         String data = Hash.taggedHash(
//                 'KeyAgg list', Codec.decodeHex(concatenatedPublicKey)) +
//             Codec.encodeHex(prefixedPublicKeyList[i]);
//         coefficient = Codec.decodeHex(
//             Hash.taggedHash('KeyAgg coefficient', Codec.decodeHex(data)));
//       }

//       if (i == 0) {
//         Q = Ecc.pointMultiplyScalar(
//             prefixedPublicKeyList[i], coefficient, true)!;
//       } else {
//         Q = Ecc.pointCombine(
//             Q,
//             Ecc.pointMultiplyScalar(
//                 prefixedPublicKeyList[i], coefficient, true)!,
//             true)!;
//       }
//     }

//     return Q.sublist(1);
//   }

//   /// Get the address of the given index.
//   @override
//   String getAddress(int addressIndex, {bool isChange = false}) {
//     String pubkey = _keyStore.getPublicKey(addressIndex,
//         isChange: isChange, applyTweak: true, isXOnly: true);
//     return _addressType.getAddress(pubkey);
//   }

//   @override
//   String getAddressWithDerivationPath(String derivationPath) {
//     if (!WalletUtility.validateDerivationPath(_derivationPath)) {
//       throw Exception("Invalid derivation path (e.g., m/44'/0'/0'/0/0)");
//     }

//     if (!derivationPath.startsWith(_derivationPath)) {
//       throw Exception("Derivation path does not match");
//     }

//     String pubkey = _keyStore.getPublicKey(
//         WalletUtility.getAccountIndexFromDerivationPath(derivationPath),
//         isChange: WalletUtility.isChangeFromDerivationPath(derivationPath),
//         applyTweak: true,
//         isXOnly: true);
//     return _addressType.getAddress(pubkey);
//   }

//   /// Create a timelock script for emergency recovery.
//   ///
//   /// [timelockType] The type of timelock: 'CLTV' or 'CSV'.
//   /// [timelockValue] The timelock value (block height for CLTV, relative blocks for CSV).
//   /// [beneficiaryDerivationPath] The derivation path for the beneficiary (emergency recovery) key.
//   ///
//   /// Returns a TimelockScript instance.
//   InheritanceScript createEmergencyRecoveryTimelockScript(String timelockType,
//       int timelockValue, String beneficiaryDerivationPath) {
//     if (timelockType != 'CLTV' && timelockType != 'CSV') {
//       throw ArgumentError("timelockType must be 'CLTV' or 'CSV'");
//     }

//     // Get beneficiary public key from derivation path
//     int beneficiaryIndex = WalletUtility.getAccountIndexFromDerivationPath(
//         beneficiaryDerivationPath);
//     bool beneficiaryIsChange =
//         WalletUtility.isChangeFromDerivationPath(beneficiaryDerivationPath);
//     String beneficiaryPubkeyHex = _keyStore.getPublicKey(beneficiaryIndex,
//         isChange: beneficiaryIsChange, isXOnly: true);
//     Uint8List beneficiaryPubkey = Codec.decodeHex(beneficiaryPubkeyHex);

//     if (timelockType == 'CLTV') {
//       return InheritanceScript.withCheckLockTimeVerify(
//           timelockValue, beneficiaryPubkey);
//     } else {
//       return InheritanceScript.withCheckSequenceVerify(
//           timelockValue, beneficiaryPubkey);
//     }
//   }

//   /// Get the emergency recovery address with timelock script.
//   ///
//   /// [addressIndex] The address index for the internal key.
//   /// [isChange] Whether this is a change address.
//   /// [timelockType] The type of timelock: 'CLTV' or 'CSV'.
//   /// [timelockValue] The timelock value.
//   /// [beneficiaryDerivationPath] The derivation path for the beneficiary key.
//   ///
//   /// Returns a Taproot address that can be spent via key path or script path (after timelock).
//   String getEmergencyRecoveryAddress(int addressIndex,
//       {bool isChange = false,
//       required String timelockType,
//       required int timelockValue,
//       required String beneficiaryDerivationPath}) {
//     // Get internal key (same as key path spending)
//     String internalKey = _keyStore.getPublicKey(addressIndex,
//         isChange: isChange, applyTweak: false, isXOnly: true);

//     // Create timelock script
//     InheritanceScript timelockScript = createEmergencyRecoveryTimelockScript(
//         timelockType, timelockValue, beneficiaryDerivationPath);

//     // Calculate merkle root from tapscript
//     String tapscriptHex = timelockScript.rawSerialize();
//     Uint8List merkleRoot = _getTapleafHash(0xc0, tapscriptHex);

//     // Generate Taproot address with merkle root
//     return AddressType.getP2trTaprootAddress(internalKey,
//         merkleRoot: Codec.encodeHex(merkleRoot));
//   }

//   @override
//   bool hasPublicKeyInPsbt(String psbt) {
//     return keyStore.hasPublicKeyInPsbt(psbt);
//   }

//   @override
//   String addSignatureToPsbt(String psbt) {
//     Psbt psbtObject = Psbt.parse(psbt);
//     if (psbtObject.addressType != addressType) {
//       throw Exception('Address Type is not matched.');
//     }

//     if (psbtObject.inputs.length !=
//         psbtObject.unsignedTransaction!.inputs.length) {
//       throw Exception('Not enough psbt inputs or transaction inputs');
//     }

//     for (int inputIndex = 0;
//         inputIndex < psbtObject.inputs.length;
//         inputIndex++) {
//       PsbtInput input = psbtObject.inputs[inputIndex];
//       List<TransactionOutput> utxoList = [];
//       for (int j = 0; j < psbtObject.unsignedTransaction!.inputs.length; j++) {
//         utxoList.add(psbtObject.inputs[j].witnessUtxo!);
//       }
//       String sigHash = psbtObject.unsignedTransaction!
//           .getTaprootSigHash(inputIndex, utxoList);

//       List<DerivationPath>? derivationPathList = input.tapBip32Derivation;
//       for (DerivationPath derivationPath in derivationPathList!) {
//         if (derivationPath.masterFingerprint == keyStore.masterFingerprint) {
//           keyStore.addSignatureToPsbtInput(
//               input, addressType, derivationPath.path, sigHash);
//           break;
//         }
//       }
//     }
//     return psbtObject.serialize();
//   }

//   /// Calculate tapleaf hash for a tapscript.
//   ///
//   /// [version] The tapscript version (0xc0 for tapscript).
//   /// [script] The script hex string.
//   ///
//   /// Returns the tapleaf hash (32 bytes).
//   static Uint8List _getTapleafHash(int version, String script) {
//     Uint8List scriptBytes = Codec.decodeHex(script);
//     Uint8List scriptSize = _encodeCompactSize(scriptBytes.length);
//     Uint8List tapleafHash = _taggedHash(
//         "TapLeaf", Uint8List.fromList([version] + scriptSize + scriptBytes));
//     return tapleafHash;
//   }

//   /// Encode compact size for script serialization.
//   static Uint8List _encodeCompactSize(int size) {
//     if (size < 0xfd) {
//       return Uint8List.fromList([size]);
//     } else if (size <= 0xffff) {
//       return Uint8List.fromList([0xfd, size & 0xff, (size >> 8) & 0xff]);
//     } else if (size <= 0xffffffff) {
//       return Uint8List.fromList([
//         0xfe,
//         size & 0xff,
//         (size >> 8) & 0xff,
//         (size >> 16) & 0xff,
//         (size >> 24) & 0xff
//       ]);
//     } else {
//       throw ArgumentError("CompactSize encoding supports up to 4 bytes.");
//     }
//   }

//   /// Calculate tagged hash (BIP-340 style).
//   static Uint8List _taggedHash(String tag, Uint8List data) {
//     Uint8List tagHash =
//         Hash.sha256fromByte(Uint8List.fromList(utf8.encode(tag)));
//     Uint8List prefix = Uint8List.fromList(tagHash + tagHash);
//     return Hash.sha256fromByte(Uint8List.fromList(prefix + data));
//   }
// }
