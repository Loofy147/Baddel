import 'package:flutter_test/flutter_test.dart';
import 'package:baddel/core/validators/input_validator.dart';

void main() {
  group('InputValidator', () {
    test('validateTitle returns an error when title is empty', () {
      expect(InputValidator.validateTitle(''), 'Title required');
    });

    test('validateTitle returns an error when title is too short', () {
      expect(InputValidator.validateTitle('ab'), 'Title too short');
    });

    test('validateTitle returns an error when title is too long', () {
      expect(InputValidator.validateTitle('a' * 101), 'Title too long');
    });

    test('validateTitle returns an error when title contains invalid characters', () {
      expect(InputValidator.validateTitle('title with <script>'), 'Invalid characters');
    });

    test('validateTitle returns null when title is valid', () {
      expect(InputValidator.validateTitle('Valid Title'), null);
    });

    test('validatePrice returns null when price is invalid', () {
      expect(InputValidator.validatePrice('invalid'), null);
    });

    test('validatePrice returns null when price is negative', () {
      expect(InputValidator.validatePrice('-100'), null);
    });

    test('validatePrice returns null when price is too high', () {
      expect(InputValidator.validatePrice('10000001'), null);
    });

    test('validatePrice returns a number when price is valid', () {
      expect(InputValidator.validatePrice('100'), 100);
    });
  });
}
