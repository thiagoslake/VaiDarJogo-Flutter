import 'package:flutter_test/flutter_test.dart';
import 'package:vaidarjogo/utils/phone_formatter.dart';

void main() {
  group('Phone Input Formatter Tests', () {
    late PhoneInputFormatter formatter;

    setUp(() {
      formatter = PhoneInputFormatter();
    });

    test('should format DDD only', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '21'),
      );
      expect(result.text, '(21');
    });

    test('should format DDD and first digits', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '219999'),
      );
      expect(result.text, '(21) 9999');
    });

    test('should format landline phone', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '2199999999'),
      );
      expect(result.text, '(21) 9999-9999');
    });

    test('should format mobile phone', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '21999999999'),
      );
      expect(result.text, '(21) 99999-9999');
    });

    test('should format different DDDs', () {
      // Teste com DDD 85 (Fortaleza)
      final result1 = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '85999999999'),
      );
      expect(result1.text, '(85) 99999-9999');

      // Teste com DDD 47 (Joinville)
      final result2 = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '47999999999'),
      );
      expect(result2.text, '(47) 99999-9999');
    });

    test('should limit to 11 digits', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '119999999999999'),
      );
      expect(result.text, '(11) 99999-9999');
    });

    test('should handle empty input', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
    });

    test('should remove non-numeric characters', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '11abc999999999'),
      );
      expect(result.text, '(11) 99999-9999');
    });

    test('should handle partial input correctly', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '(11) 9999'),
        const TextEditingValue(text: '(11) 99999'),
      );
      expect(result.text, '(11) 9999-9');
    });
  });
}
