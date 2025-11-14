// subscription_dialog.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showbizapp/DTOs/UserModel.dart';

// Sample API Endpoint for Email Verification (Login)
const String _VERIFY_EMAIL_URL = 'https://api.237showbiz.com/api/verify_email_for_login';
// Sample API Endpoint for User Data Retrieval after Code Verification (Login)
const String _LOGIN_USER_URL = 'https://api.237showbiz.com/api/login_by_code';


class SubscriptionDialog extends StatefulWidget {
  final Function(String, String, String) onSaveSubscriber;

  const SubscriptionDialog({
    super.key,
    required this.onSaveSubscriber,
  });

  @override
  _SubscriptionDialogState createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<SubscriptionDialog> {
  // Common Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  // Subscription States
  String _generatedCode = '';
  bool _showCodeField = false;
  bool _isSendingCode = false;
  bool _isVerifyingCode = false;

  // Login States
  bool _isLoginMode = false; // New state to toggle between Subscribe and Login screens
  bool _isLoginSendingCode = false;
  bool _isLoginVerifyingCode = false;
  String _loginEmail = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // --- Utility Methods ---

  Future<void> _sendVerificationEmail(String name, String email, String code) async {
    // This is the external mailer service logic (kept as is)
    String username = '237showbiz@gmail.com';
    String password = 'vwgjkxcqqbtocbdu';
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, '237showbiz')
      ..recipients.add(email)
      ..subject = 'Your Verification Code'
      ..text = 'Hello $name,\n\nYour verification code is: $code\n\nThanks for subscribing!';
    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // --- Subscription Flow Methods (Unchanged) ---

  void _sendCode() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showSnackBar('Please enter valid name and email.');
      return;
    }

    _generatedCode = (Random().nextInt(900000) + 100000).toString();
    setState(() => _isSendingCode = true);

    try {
      await _sendVerificationEmail(name, email, _generatedCode);
      setState(() {
        _showCodeField = true;
        _isSendingCode = false;
      });
    } catch (e) {
      setState(() => _isSendingCode = false);
      _showSnackBar('Failed to send verification code. Please check your email or connection.');
    }
  }

  void _verifyCode() async {
    if (_codeController.text.trim() != _generatedCode) {
      _showSnackBar('Incorrect verification code.');
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final uri = Uri.parse('https://api.237showbiz.com/api/subscribers');

    setState(() => _isVerifyingCode = true);

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String? subscriberId;

        // Normalize API response for ID
        if (responseData['id'] != null) {
          subscriberId = responseData['id'] is Map && responseData['id']['subscriber_id'] != null
              ? responseData['id']['subscriber_id'].toString()
              : responseData['id'].toString();
        }

        if (subscriberId != null && subscriberId.isNotEmpty) {
          final userModel = Provider.of<UserModel>(context, listen: false);

          // Fix Caching: Save to SharedPreferences with correct keys
          userModel.setSubscriber(name, subscriberId);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('subscriberName', name);
          await prefs.setString('subscriberId', subscriberId);

          widget.onSaveSubscriber(name, email, subscriberId);
          Navigator.of(context).pop();
          _showSnackBar('Thank you for subscribing!', color: Colors.orange);
        } else {
          _showSnackBar('Failed to get subscriber ID. Subscription recorded, but unable to log in.');
        }
      } else {
        _showSnackBar('Failed to save subscriber. Server returned: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Network error during subscription: $e');
    } finally {
      setState(() => _isVerifyingCode = false);
    }
  }

  // --- Login Flow Methods (NEW) ---

  void _handleLoginEmailSubmit() async {
    _loginEmail = _emailController.text.trim();
    if (_loginEmail.isEmpty || !_loginEmail.contains('@') || !_loginEmail.contains('.')) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    _generatedCode = (Random().nextInt(900000) + 100000).toString();
    setState(() => _isLoginSendingCode = true);

    try {
      // 1. Submit email to backend (using sample endpoint)
      final emailSubmitUri = Uri.parse(_VERIFY_EMAIL_URL);
      await http.post(
        emailSubmitUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _loginEmail, 'code': _generatedCode}), // Sending code for backend logging/verification
      );

      // 2. Send email to user
      await _sendVerificationEmail("User", _loginEmail, _generatedCode);

      setState(() {
        _isLoginSendingCode = false;
        _showCodeField = true; // Use the same field to show the code input
      });
      _codeController.clear(); // Clear code field for new input
      _showSnackBar('Verification code sent to $_loginEmail', color: Colors.green);

    } catch (e) {
      setState(() => _isLoginSendingCode = false);
      _showSnackBar('Login failed: Could not verify email or send code. $e');
    }
  }

  void _handleLoginVerifyCode() async {
    if (_codeController.text.trim() != _generatedCode) {
      _showSnackBar('Incorrect verification code.');
      return;
    }

    setState(() => _isLoginVerifyingCode = true);

    try {
      // 3. Verify code and retrieve user data
      final loginUri = Uri.parse(_LOGIN_USER_URL);
      final response = await http.post(
        loginUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _loginEmail, 'code': _codeController.text.trim()}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final subscriberId = responseData['subscriber_id']?.toString() ?? responseData['id']?.toString() ?? '';
        final username = responseData['username'] ?? responseData['name'] ?? 'User';

        if (subscriberId.isNotEmpty) {
          final userModel = Provider.of<UserModel>(context, listen: false);

          // Fix Caching: Save to SharedPreferences with correct keys
          userModel.setSubscriber(username, subscriberId);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('subscriberName', username);
          await prefs.setString('subscriberId', subscriberId);

          Navigator.of(context).pop(); // Close the dialog
          _showSnackBar('Welcome back, $username! Login successful.', color: Colors.green);
        } else {
          _showSnackBar('Login failed: User data not found.');
        }
      } else {
        _showSnackBar('Login failed. Server returned: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Network error during login: $e');
    } finally {
      setState(() => _isLoginVerifyingCode = false);
    }
  }


  // --- Dialog Build Logic ---

  @override
  Widget build(BuildContext context) {
    // Determine the current loading state based on mode
    final isLoading = _isLoginMode
        ? (_isLoginSendingCode || _isLoginVerifyingCode)
        : (_isSendingCode || _isVerifyingCode);

    // Determine the action button text and function
    String buttonText;
    VoidCallback buttonAction;

    if (_isLoginMode) {
      if (!_showCodeField) {
        buttonText = 'Send Login Code';
        buttonAction = _handleLoginEmailSubmit;
      } else {
        buttonText = 'Verify & Log In';
        buttonAction = _handleLoginVerifyCode;
      }
    } else { // Subscription Mode
      if (!_showCodeField) {
        buttonText = 'Send Code';
        buttonAction = _sendCode;
      } else {
        buttonText = 'Verify Code';
        buttonAction = _verifyCode;
      }
    }

    return AlertDialog(
      title: Text(_isLoginMode ? 'Log In to Your Account' : 'Subscribe for Interactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name field only in initial Subscription mode
            if (!_isLoginMode && !_showCodeField)
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name')
              ),

            // Email field visible in initial subscription and initial login
            if (!_showCodeField)
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress
              ),

            // Code field
            if (_showCodeField) ...[
              const SizedBox(height: 10),
              Text('Enter the code sent to ${_isLoginMode ? _loginEmail : _emailController.text.trim()}'),
              TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Verification Code'),
                  keyboardType: TextInputType.number
              ),
            ],

            const SizedBox(height: 10),

            // Toggle/Account already exists button
            if (!isLoading)
              TextButton(
                onPressed: () {
                  setState(() {
                    // Reset fields when switching modes
                    _isLoginMode = !_isLoginMode;
                    _showCodeField = false;
                    _codeController.clear();
                    _emailController.clear(); // Clear email controller on mode switch
                    _nameController.clear();
                  });
                },
                child: Text(
                  _isLoginMode ? 'New user? Sign Up' : 'Account already exists? Log In',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 15.0),
                child: LinearProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Close')),
        ElevatedButton(
          onPressed: isLoading ? null : buttonAction,
          child: Text(buttonText),
        ),
      ],
    );
  }
}