bool validateDerivationPath(String derivationPath) {
  // Corrected regular expression to match a valid derivation path (e.g., m/44'/0'/0'/0/0)
  final regex = RegExp(r"^m(\/(\d+'?))*");

  // Check if the derivation path matches the regex
  if (!regex.hasMatch(derivationPath)) {
    return false;
  }

  // Split the path into components and validate each segment
  final segments = derivationPath.split('/');

  // The first segment must always be 'm'
  if (segments[0] != 'm') {
    return false;
  }

  // Validate the rest of the segments
  for (int i = 1; i < segments.length; i++) {
    final segment = segments[i];

    // Ensure the segment is a number optionally followed by a "'"
    if (!RegExp(r"^\d+'?").hasMatch(segment)) {
      return false;
    }

    // Ensure the number part is within a valid range (e.g., 0 to 2^31-1)
    final numberPart = segment.replaceAll("'", "");
    final number = int.tryParse(numberPart);

    if (number == null || number < 0 || number >= 0x80000000) {
      return false;
    }
  }

  return true;
}

void main() {
  // Test cases
  final validPaths = [
    "m/44'/0'/0'/0/0",
    "m/44'/60'/0'/0/0",
    "m/0'/1/2'/2/1000000000",
  ];

  final invalidPaths = [
    "n/44'/0'/0'/0/0", // Does not start with 'm'
    "m/44'/0'/0", // Missing segment
    "m/44'/0'/-1'", // Negative number
    "m/44'/0'/0'/0/0/", // Trailing slash
    "m/44'/0xG'/0'", // Invalid characters
    "m/44'/0'/2147483648'" // Number out of range
  ];

  print("Valid paths:");
  for (var path in validPaths) {
    print("$path: ${validateDerivationPath(path)}");
  }

  print("\nInvalid paths:");
  for (var path in invalidPaths) {
    print("$path: ${validateDerivationPath(path)}");
  }
}
