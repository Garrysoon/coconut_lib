part of '../../coconut_lib.dart';

/// Represents the setup of a Bitcoin secure multisig wallet.(BIP-0129)
class BSMS {
  String version = 'BSMS 1.0';
  String token = '00';
  Coordinator? coordinator;
  Signer? signer;

  BSMS({this.coordinator, this.signer});

  factory BSMS.fromSigner(String fingerPrint, String derivationPath,
      String extendedPublicKey, String description) {
    return BSMS(
        signer: Signer(
            fingerPrint, derivationPath, extendedPublicKey, description));
  }

  factory BSMS.fromCoordinator(String firstAddress, String descriptor) {
    return BSMS(coordinator: Coordinator(firstAddress, descriptor));
  }

  factory BSMS.parseSigner(String signer) {
    BSMS bsms = BSMS();
    //TODO: parse the signer
    bsms.signer = Signer('', '', '', '');
    return bsms;
  }

  factory BSMS.parseCoordinator(String coordinator) {
    BSMS bsms = BSMS();
    //TODO: parse the coordinator
    bsms.coordinator = Coordinator(coordinator, '');
    return bsms;
  }

  String serializeSigner() {
    if (signer == null) {
      throw Exception('Signer is not set');
    }
    return "$version\n$token\n[${signer!.fingerPrint}/${signer!.path}]${signer!.xpub.serialize()}\n${signer!.description}]";
  }

  String serializeCoordinator() {
    if (coordinator == null) {
      throw Exception('Coordinator is not set');
    }
    return "$version\n${coordinator!.descriptor.serialize()}\n/0/*,/1/*\n${coordinator!.firstAddress}";
  }
}

class Signer {
  String fingerPrint;
  String path;
  ExtendedPublicKey xpub;
  String description;

  Signer(
      this.fingerPrint, this.path, String extendedPublicKey, this.description)
      : xpub = ExtendedPublicKey.parse(extendedPublicKey);
}

class Coordinator {
  Descriptor descriptor;
  String firstAddress;

  Coordinator(this.firstAddress, String descriptor)
      : descriptor = Descriptor.parse(descriptor);
}
