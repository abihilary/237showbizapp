import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';
class ContactPage extends StatefulWidget {
   final bool isDarkMode;
  const ContactPage({

    required this.isDarkMode}
      );
  @override
  _ContactPageState createState() => _ContactPageState();
}


class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String subject = '';
  String message = '';
  bool isDarkMode = false;

  Future<void> sendEmail() async {
    // Configure the SMTP server
    String username = '237showbiz@gmail.com'; // Your email address
    String password = 'vwgjkxcqqbtocbdu'; // Your email password

    final smtpServer = gmail(username, password); // Use Gmail SMTP server

    // Create the email message
    final mailMessage = Message()
      ..from = Address(username, name)
      ..recipients.add(email) // Replace with the recipient's email
      ..subject = subject
      ..text = message
      ..html = "<h1>$subject</h1>\n<p>$message</p>"; // Optional HTML content

    try {
      // Send the email
      await send(mailMessage, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Message sent successfully!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to send message.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the height of the keyboard
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: widget.isDarkMode?const Color(0xFF0A1F44) :  Colors.white,
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 10, bottom: keyboardHeight + 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) {
                  name = value;
                },
              ),
              const SizedBox(height: 16.0),

              // Email input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  email = value;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),

              // Subject input field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
                onChanged: (value) {
                  subject = value;
                },
              ),
              const SizedBox(height: 16.0),

              // Message textarea
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Message',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your message';
                  }
                  return null;
                },
                onChanged: (value) {
                  message = value;
                },
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      sendEmail();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20.0),

              // Website link
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final Uri url = Uri.parse("https://237showbizstudios.com");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      throw "Could not launch $url";
                    }
                  },
                  child: const Text(
                    "Our Website: 237showbizstudios.com",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // WhatsApp button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final String phoneNumber = "+237671470870"; // Replace with your WhatsApp phone number
                    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber");

                    if (await canLaunchUrl(whatsappUrl)) {
                      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication); // Open WhatsApp
                    } else {
                      throw "Could not launch WhatsApp";
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green color
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.chat, color: Colors.white), // WhatsApp icon
                  label: const Text(
                    'Contact Us on WhatsApp',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

            ],
          ),
        ),
      )

    );
  }
}