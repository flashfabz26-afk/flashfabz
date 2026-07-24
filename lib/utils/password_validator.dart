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

  static bool containsNameOrEmail(String password, String name, String email) {
    if (password.isEmpty) return false;
    final lowerPass = password.toLowerCase();
    
    // Check name parts
    if (name.isNotEmpty) {
      final nameParts = name.toLowerCase().split(' ');
      for (var part in nameParts) {
        if (part.length > 2 && lowerPass.contains(part)) {
          return true;
        }
      }
    }
    
    // Check email prefix
    if (email.isNotEmpty && email.contains('@')) {
      final emailPrefix = email.toLowerCase().split('@')[0];
      if (emailPrefix.length > 2 && lowerPass.contains(emailPrefix)) {
        return true;
      }
    }
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
        !containsNameOrEmail(password, name, email) &&
        !isCommonPassword(password);
  }
}
