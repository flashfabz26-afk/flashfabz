class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 32;

  static const List<String> commonPasswords = [
    'password123',
    '12345678',
    '123456789',
    'qwerty',
    'password',
    '123456',
  ];

  static bool hasMinLength(String password) => password.length >= minLength;
  static bool hasMaxLength(String password) => password.length <= maxLength;
  static bool hasUppercase(String password) => password.contains(RegExp(r'[A-Z]'));
  static bool hasLowercase(String password) => password.contains(RegExp(r'[a-z]'));
  static bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));
  static bool hasSpecialCharacter(String password) =>
      password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:''",.<>?/]'));
  static bool hasNoSpaces(String password) => !password.contains(' ');

  // Username/name is allowed in password — no restriction applied.
  static bool containsNameOrEmail(String password, String name, String email) {
    return false;
  }

  static bool isCommonPassword(String password) {
    return commonPasswords.contains(password.toLowerCase());
  }

  static String getStrength(String password) {
    if (password.isEmpty) return 'Weak';
    
    int score = 0;
    if (hasMinLength(password)) score++;
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasNumber(password)) score++;
    if (hasSpecialCharacter(password)) score++;
    
    if (score <= 2) return 'Weak';
    if (score == 3 || score == 4) return 'Medium';
    if (score == 5 && password.length > 12) return 'Very Strong';
    if (score == 5) return 'Strong';
    
    return 'Weak';
  }

  static bool isPasswordValid(String password, String name, String email) {
    return hasMinLength(password) &&
        hasMaxLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasNumber(password) &&
        hasSpecialCharacter(password) &&
        hasNoSpaces(password) &&
        !isCommonPassword(password);
  }
}
