import 'dart:math';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import 'UserModel.dart';

Future<void> saveLocalSubscriber(String name, String email, String subscriberId) async {
  final prefs = await SharedPreferences.getInstance();
  final subscriberJson = prefs.getString('subscriber');
  if (subscriberJson == null) return; // no existing subscriber

  final Map<String, dynamic> subscriber = jsonDecode(subscriberJson);
  if (name != null) subscriber['name'] = name;
  if (email != null) subscriber['email'] = email;

  await prefs.setString('subscriber', jsonEncode(subscriber));
}
//verification section
Future<void> sendVerificationEmail(String name, String email,
    String code) async {
  String username = '237showbiz@gmail.com';
  String password = 'vwgjkxcqqbtocbdu';

  final smtpServer = gmail(
      username, password); // or use smtp(username, host, ...)

  final message = Message()
    ..from = Address(username, 'Your App Name')
    ..recipients.add(email)
    ..subject = 'Your Verification Code'
    ..text = 'Hello $name,\n\nYour verification code is: $code\n\nThanks for subscribing!';

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } catch (e) {
    print('Message not sent. $e');
    throw Exception('Failed to send email: $e');
  }
}
void showUpdateModal(BuildContext context, {
  required String subscriberId,
  required bool isDarkMode,
  required String username,
}) {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool showCodeField = false;
  bool isLoading = false;
  String generatedCode = "";
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      final userModel = Provider.of<UserModel>(context);

      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0A1F44) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
                const SizedBox(height: 15),

                if (!showCodeField) ...[
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: username,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],

                if (showCodeField) ...[
                  const Text(
                    'Enter the verification code sent to your email',
                    style: TextStyle(fontFamily: "Poppins"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 20),

                if (isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      final username = usernameController.text.trim();
                      final email = emailController.text.trim();

                      if (!showCodeField) {
                        if (username.isEmpty || email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields')),
                          );
                          return;
                        }

                        String newCode = (Random().nextInt(900000) + 100000).toString();
                        setState(() {
                          isLoading = true;
                          generatedCode = newCode;
                        });

                        print('Generated Code: $generatedCode');
                        print('Sending email to: $email');

                        try {
                          await sendVerificationEmail(username, email, generatedCode);
                          print('Email sent successfully');
                          setState(() {
                            showCodeField = true;
                          });
                        } catch (e) {
                          print('Error sending verification email: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send email: $e')),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      } else {
                        final inputCode = codeController.text.trim();
                        print('User entered code: $inputCode');
                        print('Expected code: $generatedCode');

                        if (inputCode == generatedCode) {
                          setState(() => isLoading = true);
                          final uri = Uri.parse('https://api.237showbiz.com/api/subscribers');

                          try {
                            print('Sending update request...');
                            final response = await http.post(
                              uri,
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({
                                'action': 'update',
                                'id': subscriberId,
                                'name': username,
                                'email': email,
                              }),
                            );

                            print('Update response status: ${response.statusCode}');
                            print('Response body: ${response.body}');

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              userModel.setUsername(username);
                              await saveLocalSubscriber(username, email, subscriberId);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Update successful')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Update failed: ${json.decode(response.body)['error'] ?? 'Unknown error'}'),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Network error during update: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Network error: $e')),
                            );
                          } finally {
                            setState(() => isLoading = false);
                          }
                        } else {
                          print('Incorrect verification code entered');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incorrect verification code.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showCodeField ? Colors.orange : Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text(
                      showCodeField ? "Verify & Submit" : "Send Code",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}


