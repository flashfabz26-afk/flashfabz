import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_page.dart';
import 'auth_service.dart';
import '../utils/password_validator.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialCharacter = false;
  bool _hasNoSpaces = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStatus);
    _nameController.addListener(_clearError);
    _emailController.addListener(_clearError);
    _confirmPasswordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _updatePasswordStatus() {
    _clearError();
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = PasswordValidator.hasMinLength(password);
      _hasUppercase = PasswordValidator.hasUppercase(password);
      _hasLowercase = PasswordValidator.hasLowercase(password);
      _hasNumber = PasswordValidator.hasNumber(password);
      _hasSpecialCharacter = PasswordValidator.hasSpecialCharacter(password);
      _hasNoSpaces = PasswordValidator.hasNoSpaces(password);
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStatus);
    _nameController.removeListener(_clearError);
    _emailController.removeListener(_clearError);
    _confirmPasswordController.removeListener(_clearError);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordValid {
    return _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSpecialCharacter &&
        _hasNoSpaces &&
        _passwordController.text == _confirmPasswordController.text &&
        !PasswordValidator.containsNameOrEmail(
            _passwordController.text, _nameController.text, _emailController.text) &&
        !PasswordValidator.isCommonPassword(_passwordController.text);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.shade700 : Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 5 : 2),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      _showSnackBar('Please fill in all required fields.');
      return;
    }

    if (!PasswordValidator.hasMinLength(password)) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      _showSnackBar('Password must be at least 8 characters.');
      return;
    }
    if (!PasswordValidator.hasUppercase(password)) {
      setState(() => _errorMessage = 'Password must contain at least one uppercase letter.');
      _showSnackBar('Password must contain at least one uppercase letter.');
      return;
    }
    if (!PasswordValidator.hasLowercase(password)) {
      setState(() => _errorMessage = 'Password must contain at least one lowercase letter.');
      _showSnackBar('Password must contain at least one lowercase letter.');
      return;
    }
    if (!PasswordValidator.hasNumber(password)) {
      setState(() => _errorMessage = 'Password must contain at least one number.');
      _showSnackBar('Password must contain at least one number.');
      return;
    }
    if (!PasswordValidator.hasSpecialCharacter(password)) {
      setState(() => _errorMessage = 'Password must contain at least one special character.');
      _showSnackBar('Password must contain at least one special character.');
      return;
    }
    if (!PasswordValidator.hasNoSpaces(password)) {
      setState(() => _errorMessage = 'Password cannot contain spaces.');
      _showSnackBar('Password cannot contain spaces.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      _showSnackBar('Passwords do not match.');
      return;
    }
    if (PasswordValidator.containsNameOrEmail(password, name, email)) {
      setState(() => _errorMessage = 'Security: Password cannot contain your Name or Email prefix.');
      _showSnackBar('Password cannot contain your name or email prefix.');
      return;
    }

    if (PasswordValidator.isCommonPassword(password)) {
      setState(() => _errorMessage = 'Please choose a less common, more secure password.');
      _showSnackBar('Please choose a less common, more secure password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.registerWithDetails(name, email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar(
          result['message'] ?? 'Account created successfully!',
          isError: false,
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final errorMsg = result['error'] ?? 'Registration failed. Please check server connection.';
        setState(() => _errorMessage = errorMsg);
        _showSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      final err = 'Unexpected registration error: $e';
      setState(() => _errorMessage = err);
      _showSnackBar(err, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildChecklistItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.white.withOpacity(0.4),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = PasswordValidator.getStrength(_passwordController.text);
    Color strengthColor = Colors.grey;
    if (passwordStrength == 'Weak') strengthColor = Colors.red;
    if (passwordStrength == 'Medium') strengthColor = Colors.orange;
    if (passwordStrength == 'Strong') strengthColor = Colors.lightGreen;
    if (passwordStrength == 'Very Strong') strengthColor = Colors.green;

    final canSubmit = _isPasswordValid && !_isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.5,
                colors: [
                  Color(0xFF003049),
                  Color(0xFF07070A),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(40.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_add, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join 8HRPCB today',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          enabled: !_isLoading,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Strength: $passwordStrength',
                              style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildChecklistItem('Minimum 8 characters', _hasMinLength),
                          _buildChecklistItem('One uppercase letter', _hasUppercase),
                          _buildChecklistItem('One lowercase letter', _hasLowercase),
                          _buildChecklistItem('One number', _hasNumber),
                          _buildChecklistItem('One special character', _hasSpecialCharacter),
                          _buildChecklistItem('No spaces', _hasNoSpaces),
                          _buildChecklistItem('Does not contain name or email prefix', !PasswordValidator.containsNameOrEmail(_passwordController.text, _nameController.text, _emailController.text)),
                          _buildChecklistItem('Passwords match', _passwordController.text == _confirmPasswordController.text && _confirmPasswordController.text.isNotEmpty),
                        ],
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          enabled: !_isLoading,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade700.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.white.withOpacity(0.1),
                            ).copyWith(
                              elevation: ButtonStyleButton.allOrNull(0.0),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: canSubmit
                                    ? const LinearGradient(
                                        colors: [Color(0xFF00E5FF), Color(0xFF0072FF)],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF00E5FF),
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'SIGN UP',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.2,
                                          color: canSubmit ? Colors.white : Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginPage()),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    bool enabled = true,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: enabled ? onToggleVisibility : null,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }
}
