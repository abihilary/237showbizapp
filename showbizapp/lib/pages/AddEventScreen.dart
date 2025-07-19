import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' ;
import 'package:image_picker/image_picker.dart';

class AdminEventScreen extends StatefulWidget {
  const AdminEventScreen({Key? key}) : super(key: key);

  @override
  State<AdminEventScreen> createState() => _AdminNewsEventScreenState();
}

class _AdminNewsEventScreenState extends State<AdminEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  QuillController _controller = QuillController.basic();
  File? _image;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  void _submitNews() {
    if (_titleController.text.trim().isEmpty || _image == null || _controller.document.isEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title, image, and content required")),
      );
      return;
    }

    final title = _titleController.text.trim();
    final contentJson = _controller.document.toDelta().toJson(); // Can be sent to backend

    // TODO: Send `title`, `contentJson`, and `_image` to backend

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("News/Event added")),
    );

    _titleController.clear();
    setState(() {
      _image = null;
      _controller = QuillController.basic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Event"),backgroundColor: Colors.orange,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image == null
                      ? const Center(child: Text("Tap to select image"))
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "News/Event Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              QuillSimpleToolbar(controller: _controller),
              const SizedBox(height: 8),
              Container(
                height: 300,  // fixed height for editor
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: QuillEditor.basic(
                  controller: _controller,
                  config: QuillEditorConfig(
                    placeholder: 'Start writing your notes...',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Submit", style: TextStyle(color: Colors.white)),
                onPressed: _submitNews,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
