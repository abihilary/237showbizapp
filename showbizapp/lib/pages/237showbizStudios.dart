import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class ShowbizStudiosPage extends StatelessWidget {
  // Sample list of studio services
  final List<Map<String, String>> studioServices = [
    {
      'title': 'Video Production',
      'description': 'High quality video shoots with professional equipment.',
      'icon': '🎥',
    },
    {
      'title': 'Photo Studio',
      'description': 'Studio photography with lighting and backdrop setups.',
      'icon': '📸',
    },
    {
      'title': 'Audio Recording',
      'description': 'Sound recording and mixing with soundproof booths.',
      'icon': '🎙️',
    },
    {
      'title': 'Editing & Post-production',
      'description': 'Video and audio editing to deliver polished content.',
      'icon': '✂️',
    },
    {
      'title': 'Live Streaming',
      'description': 'Professional live streaming services for events.',
      'icon': '📡',
    },
    {
      'title': 'Drone services',
      'description': 'Professional drone services with pilot.',
    'icon': '🚁',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('237 Showbiz Studios', style: TextStyle(color: Colors.white)),
        backgroundColor: isDarkMode ? Colors.blueGrey[900] : Colors.orange[600],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: studioServices.length,
                itemBuilder: (context, index) {
                  final service = studioServices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    child: ListTile(
                      leading: Text(
                        service['icon'] ?? '',
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        service['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        service['description'] ?? '',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: isDarkMode ? Colors.white70 : Colors.black38),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selected: ${service['title']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextButton(
              onPressed: () {
                // Open link using url_launcher
                launchUrl(Uri.parse('https://237showbizstudios.com'));
              },
              child: const Text(
                'Visit 237ShowbizStudios.com',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
