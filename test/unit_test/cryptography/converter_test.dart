@Tags(['unit'])
import 'dart:typed_data';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Converter', () {
    group('decToHex', () {
      test('Get hexadecimal text from decimal', () {
        int decimalValue = 10;
        expect(Converter.decToHex(decimalValue), 'a');
      });
    });
    group('decToHexWithPadding', () {
      test('Get hexadecimal with padding from decimal', () {
        int decimalValue = 10;
        int padding = 5;
        expect(Converter.decToHexWithPadding(decimalValue, padding), '0000a');
      });
    });
    group('bigDecToHex', () {
      test('Get hexadecimal from big decimal', () {
        BigInt decimalValue = BigInt.parse('1000000000000000000000');
        expect(Converter.bigDecToHex(decimalValue), '3635c9adc5dea00000');
      });
    });
    group('decToBin', () {
      test('Get binary from decimal', () {
        int decimalValue = 10;
        expect(Converter.decToBin(decimalValue), '1010');
      });
    });
    group('hexToDec', () {
      test('Get decimal from hexadecimal', () {
        String hexString = 'a';
        expect(Converter.hexToDec(hexString), 10);
      });
    });
    group('hexToBin', () {
      test('Get binary from hexadeciaml', () {
        String hexString = 'a';
        expect(Converter.hexToBin(hexString), '1010');
      });
    });
    group('binToHex', () {
      test('Get hexadecimal from binary', () {
        String binary = '1010';
        expect(Converter.binToHex(binary), 'A');
      });
    });
    group('binToBytes', () {
      test('Get bytes from binary', () {
        String binary = '10101101';
        expect(Converter.binToBytes(binary), [173]);
      });
    });
    group('bytesToBin', () {
      test('Get binary from bytes', () {
        List<int> bytes = [173];
        expect(Converter.bytesToBin(bytes), '10101101');
      });
    });
    group('intToLittleEndianBytes', () {
      test('Get little endian from integer', () {
        int value = 10;
        expect(Converter.intToLittleEndianBytes(value, 4), [10, 0, 0, 0]);
      });
    });
    group('littleEndianToInt', () {
      test('Get integer from little endian', () {
        List<int> bytes = [10, 0, 0, 0];
        expect(Converter.littleEndianToInt(Uint8List.fromList(bytes)), 10);
      });
    });
    group('littleEndianToBigInt', () {
      test('Get bit integer from little endian', () {
        List<int> bytes = [10, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0, 10, 0, 0, 0];
        expect(Converter.littleEndianToBigInt(Uint8List.fromList(bytes)),
            BigInt.parse('13292279960944008827972097230598307840'));
      });
    });
    group('convertBits', () {
      test('8-bit to 5-bit conversion (Bech32 encoding)', () {
        var input = [255]; // 8-bit max value (1111 1111)
        var expectedOutput = [31, 28]; // 5-bit max value chunks
        expect(Converter.convertBits(input, 8, 5, pad: true),
            equals(expectedOutput));
      });

      test('5-bit to 8-bit conversion', () {
        var input = [31, 31, 31, 31, 31]; // 5-bit chunks
        var expectedOutput = [255, 255, 255, 128]; // 8-bit value
        expect(Converter.convertBits(input, 5, 8, pad: true),
            equals(expectedOutput));
      });

      test('Zero input case', () {
        var input = [0, 0, 0];
        var expectedOutput = [0, 0, 0, 0, 0];
        expect(Converter.convertBits(input, 8, 5, pad: true),
            equals(expectedOutput));
      });

      test('Padding enabled should add zero bits', () {
        var input = [1, 2, 3];
        var expectedOutput = [0, 4, 1, 0, 6]; // Adjusted to 5-bit chunks
        expect(Converter.convertBits(input, 8, 5, pad: true),
            equals(expectedOutput));
      });

      test('Illegal zero padding should throw Exception', () {
        var input = [1, 2, 3];
        expect(() => Converter.convertBits(input, 8, 5, pad: false),
            throwsException);
      });

      test('Negative values should throw Exception', () {
        var input = [-1, 2, 3];
        expect(() => Converter.convertBits(input, 8, 5, pad: true),
            throwsException);
      });

      test('Values out of range should throw Exception', () {
        var input = [256]; // 8-bit max is 255
        expect(() => Converter.convertBits(input, 8, 5, pad: true),
            throwsException);
      });
    });
  });
}
