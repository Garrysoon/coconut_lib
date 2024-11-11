part of '../../coconut_lib.dart';

/// Represents the setup of a Bitcoin secure multisig wallet.(BIP-0129)
class BSMS {
  String version = 'BSMS 1.0';
  String secretToken = '00';
  Coordinator? coordinator;
  Signer? signer;

  BSMS({this.coordinator, this.signer});

  factory BSMS.fromSigner(String fingerPrint, String derivationPath,
      String extendedPublicKey, String description) {
    return BSMS(
        signer: Signer(fingerPrint, derivationPath,
            ExtendedPublicKey.parse(extendedPublicKey), description));
  }

  factory BSMS.fromCoordinator(String firstAddress, String descriptor) {
    return BSMS(
        coordinator: Coordinator(firstAddress, Descriptor.parse(descriptor)));
  }

  factory BSMS.parseSigner(String bsmsText) {
    final lines = bsmsText.split('\n');
    if (lines.length < 4) {
      throw FormatException('Incomplete BSMS data');
    }

    String version = lines[0].trim();
    String secretToken = lines[1].trim();
    String keyInfo = lines[2].trim();
    String description = lines[3].trim();

    if (version != 'BSMS 1.0') {
      throw FormatException('Unsupported BSMS version');
    }

    if (secretToken != '00') {
      throw FormatException('Unsupported secret token');
    }

    final keyInfoMatch =
        RegExp(r"\[(\w{8})\/((\d+'?\/?)+)\](\w+)").firstMatch(keyInfo);
    if (keyInfoMatch == null) {
      throw FormatException('Invalid key info format');
    }

    String? fingerprint = keyInfoMatch.group(1);
    String? derivationPath = keyInfoMatch.group(2);
    String? xpub = keyInfoMatch.group(4)!;

    BSMS bsms = BSMS();
    bsms.signer = Signer(fingerprint!, derivationPath!,
        ExtendedPublicKey.parse(xpub), description);
    return bsms;
  }

  factory BSMS.parseCoordinator(String bsmsText) {
    BSMS bsms = BSMS();

    final lines = bsmsText.split('\n');

    final version = lines[0].trim();
    final descriptorText = lines[1].trim();
    final derivationPath = lines[2].trim();
    final firstAddress = lines[3].trim();

    if (!WalletUtility.validateAddress(firstAddress)) {
      throw FormatException('Invalid address');
    }

    if (version != 'BSMS 1.0') {
      throw FormatException('Unsupported BSMS version');
    }

    if (derivationPath != 'No path restrictions' &&
        derivationPath != '/0/*,/1/*') {
      throw FormatException('Not support customized path');
    }

    bsms.coordinator =
        Coordinator(firstAddress, Descriptor.parse(descriptorText));
    return bsms;
  }

  String serializeSigner() {
    if (signer == null) {
      throw Exception('Signer is not set');
    }
    return "$version\n$secretToken\n[${signer!.masterFingerPrint}/${signer!.path}]${signer!.extendedPublicKey.serialize()}\n${signer!.description}";
  }

  String serializeCoordinator() {
    if (coordinator == null) {
      throw Exception('Coordinator is not set');
    }
    return "$version\n${coordinator!.descriptor.serialize()}\n/0/*,/1/*\n${coordinator!.firstAddress}";
  }
}

class Signer {
  String masterFingerPrint;
  String path;
  ExtendedPublicKey extendedPublicKey;
  String description;

  Signer(this.masterFingerPrint, this.path, this.extendedPublicKey,
      this.description);
}

class Coordinator {
  Descriptor descriptor;
  String firstAddress;

  Coordinator(this.firstAddress, this.descriptor);
}
