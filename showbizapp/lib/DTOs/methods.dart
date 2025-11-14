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
  await prefs.setString('subscriberName', name);
  await prefs.setString('subscriberId', subscriberId);
  // The 'subscriber' key seems to be for a different purpose, so we'll just use name and id
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
  final TextEditingController usernameController = TextEditingController(text: username); // Prefill with existing username
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
      final userModel = Provider.of<UserModel>(context, listen: false);

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
                      final updatedUsername = usernameController.text.trim();
                      final updatedEmail = emailController.text.trim();

                      if (!showCodeField) {
                        if (updatedUsername.isEmpty || updatedEmail.isEmpty) {
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

                        try {
                          await sendVerificationEmail(updatedUsername, updatedEmail, generatedCode);
                          setState(() {
                            showCodeField = true;
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send email: $e')),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      } else {
                        final inputCode = codeController.text.trim();
                        if (inputCode == generatedCode) {
                          setState(() => isLoading = true);
                          final uri = Uri.parse('https://api.237showbiz.com/api/subscribers');

                          try {
                            final response = await http.post(
                              uri,
                              headers: {'Content-Type': 'application/json'},
                              body: json.encode({
                                'action': 'update',
                                'id': userModel.subscriberId, // Use the ID from the provider
                                'name': updatedUsername,
                                'email': updatedEmail,
                              }),
                            );

                            if (response.statusCode == 200 || response.statusCode == 201) {
                              userModel.setSubscriber(updatedUsername, userModel.subscriberId); // Update provider state
                              await saveLocalSubscriber(updatedUsername, updatedEmail, userModel.subscriberId); // Save to local storage
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Network error: $e')),
                            );
                          } finally {
                            setState(() => isLoading = false);
                          }
                        } else {
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