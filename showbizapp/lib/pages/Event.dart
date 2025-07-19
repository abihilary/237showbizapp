import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:showbizapp/DTOs/Mainscafold.dart';

import '../components/buttomnav.dart';

class EventsPage extends StatelessWidget {
  EventsPage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> sampleEvents = [
    {
      "title": "Upcoming Event 1",
      "content": [
        {"insert": "Details about event 1.\nEvent happening soon!\n"}
      ],
      "imageUrl": "https://picsum.photos/400/200?random=3",
    },
    {
      "title": "Event 2 Announcement",
      "content": [
        {"insert": "Event 2 will be spectacular!\nJoin us to find out more.\n"} // <- added \n here
      ],
      "imageUrl": "https://picsum.photos/400/200?random=4",
    },
    {
      "title": "Event 2 Announcement",
      "content": [
        {"insert": "Event 2 will be spectacular!\nJoin us to find out more.\n"} // <- added \n here
      ],
      "imageUrl": "https://picsum.photos/400/200?random=4",
    },
    {
      "title": "Event 2 Announcement",
      "content": [
        {"insert": "Event 2 will be spectacular!\nJoin us to find out more.\n"} // <- added \n here
      ],
      "imageUrl": "https://picsum.photos/400/200?random=4",
    },
  ];

  // Helper: ensures last insert ends with newline
  List<Map<String, dynamic>> fixContent(List<Map<String, dynamic>> content) {
    if (content.isEmpty) return content;
    final lastBlock = content.last;
    if (lastBlock['insert'] is String) {
      final text = lastBlock['insert'] as String;
      if (!text.endsWith('\n')) {
        final fixedLast = {'insert': '$text\n'};
        return [...content.sublist(0, content.length - 1), fixedLast];
      }
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      appBar: AppBar(title: const Text("Events",style: TextStyle(color:Colors.white),),backgroundColor: Colors.orange,),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sampleEvents.length,
        itemBuilder: (context, index) {
          final item = sampleEvents[index];
          final fixedContent = fixContent(List<Map<String, dynamic>>.from(item['content']));
          final quillDoc = quill.Document.fromJson(fixedContent);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(item['imageUrl'], height: 180, fit: BoxFit.cover),
                  const SizedBox(height: 8),
                  Text(item['title'], style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  quill.QuillEditor.basic(
                    controller: quill.QuillController(
                      document: quillDoc,
                      selection: const TextSelection.collapsed(offset: 0),
                    ),

                  ),
                ],
              ),
            ),
          );
        },
      ), selectedIndex: 3,
      externalSearchFunction: (){},

    );
  }
}
