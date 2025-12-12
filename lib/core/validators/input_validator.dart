class InputValidator {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title required';
    if (value.length < 3) return 'Title too short';
    if (value.length > 100) return 'Title too long';
    if (RegExp(r'[<>]').hasMatch(value)) return 'Invalid characters';
    return null;
  }

  static int? validatePrice(String? value) {
    final price = int.tryParse(value ?? '');
    if (price == null || price < 0) return null;
    if (price > 10000000) return null; // 10M DZD max
    return price;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number required';
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(value)) return 'Invalid phone number';
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP required';
    if (value.length != 6) return 'OTP must be 6 digits';
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Message cannot be empty';
    if (value.length > 500) return 'Message too long';
    return null;
  }

  static String? validatePriceString(String? value) {
    if (validatePrice(value) == null) {
      return 'Please enter a valid price';
    }
    return null;
  }
}
