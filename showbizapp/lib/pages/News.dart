import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:showbizapp/DTOs/Mainscafold.dart';

import '../components/buttomnav.dart';

class NewsPage extends StatelessWidget {
  NewsPage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> sampleNews = [
    {
      "title": "Big News Today",
      "content": [
        {"insert": "This is some important news content.\nIt supports rich text.\n"}
      ],
      "imageUrl": "https://picsum.photos/400/200?random=1",
    },
    {
      "title": "Another News Item",
      "content": [
        {"insert": "Details about another news event.\nHere is a new line.\n"} // <-- added \n here
      ],
      "imageUrl": "https://picsum.photos/400/200?random=2",
    },
    {
      "title": "Big News Today",
      "content": [
        {"insert": "This is some important news content.\nIt supports rich text.\n"}
      ],
      "imageUrl": "https://picsum.photos/400/200?random=1",
    },
    {
      "title": "Another News Item",
      "content": [
        {"insert": "Details about another news event.\nHere is a new line.\n"} // <-- added \n here
      ],
      "imageUrl": "https://picsum.photos/400/200?random=2",
    },
  ];

  // Helper to ensure last insert ends with newline
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
      appBar: AppBar(title: const Text("News")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sampleNews.length,
        itemBuilder: (context, index) {
          final item = sampleNews[index];
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
      ), selectedIndex: 2, externalSearchFunction: (){}, backgroundColor: Colors.white, drawer: Drawer(),
      
    );
  }
}
