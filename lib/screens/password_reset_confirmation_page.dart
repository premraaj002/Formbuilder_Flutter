import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordResetConfirmationPage extends StatefulWidget {
  final String? oobCode; // Out-of-band code from the email link
  
  const PasswordResetConfirmationPage({
    super.key,
    this.oobCode,
  });

  @override
  _PasswordResetConfirmationPageState createState() => _PasswordResetConfirmationPageState();
}

class _PasswordResetConfirmationPageState extends State<PasswordResetConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _message;
  bool _isSuccess = false;
  bool _isValidCode = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _verifyResetCode();
  }

  Future<void> _verifyResetCode() async {
    if (widget.oobCode == null) {
      setState(() {
        _message = 'Invalid reset link. Please request a new password reset.';
        _isSuccess = false;
      });
      return;
    }

    try {
      // Verify the password reset code and get the associated email
      final email = await FirebaseAuth.instance.verifyPasswordResetCode(widget.oobCode!);
      setState(() {
        _email = email;
        _isValidCode = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _getErrorMessage(e.code);
        _isSuccess = false;
        _isValidCode = false;
      });
    } catch (e) {
      setState(() {
        _message = 'An error occurred. Please try again.';
        _isSuccess = false;
        _isValidCode = false;
      });
    }
  }

  Future<void> _confirmPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.oobCode == null) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode!,
        newPassword: _newPasswordController.text,
      );
      
      setState(() {
        _message = 'Password reset successfully! You can now sign in with your new password.';
        _isSuccess = true;
      });

      // Auto-navigate to login after success
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _message = _getErrorMessage(e.code);
        _isSuccess = false;
      });
    } catch (e) {
      setState(() {
        _message = 'An unexpected error occurred. Please try again.';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'expired-action-code':
        return 'This password reset link has expired. Please request a new one.';
      case 'invalid-action-code':
        return 'This password reset link is invalid. Please request a new one.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: _isValidCode ? _buildPasswordResetForm(theme, colorScheme) : _buildErrorView(theme, colorScheme),
      ),
    );
  }

  Widget _buildPasswordResetForm(ThemeData theme, ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 40),
          
          // Icon
          Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.blue[600],
          ),
          SizedBox(height: 20),
          
          // Title
          Text(
            'Set New Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 10),
          
          // Subtitle
          if (_email != null)
            Text(
              'Setting new password for: $_email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          SizedBox(height: 40),
          
          // Message Display
          if (_message != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSuccess ? Colors.green[300]! : Colors.red[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    color: _isSuccess ? Colors.green[700] : Colors.red[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 20),

          if (!_isSuccess) ...[
            // New Password Field
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: _obscureNewPassword,
              validator: _validatePassword,
            ),
            SizedBox(height: 16),
            
            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
            ),
            SizedBox(height: 24),
            
            // Update Password Button
            ElevatedButton(
              onPressed: _loading ? null : _confirmPasswordReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text("Updating Password..."),
                      ],
                    )
                  : Text(
                      "Update Password",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
          
          if (_isSuccess) ...[
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Password Updated!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You will be redirected to the login page shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 80,
          color: Colors.red[600],
        ),
        SizedBox(height: 20),
        Text(
          'Invalid Reset Link',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
        SizedBox(height: 20),
        if (_message != null)
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Back to Login'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
