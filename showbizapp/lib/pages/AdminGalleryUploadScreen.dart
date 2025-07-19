import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminGalleryUploadScreen extends StatefulWidget {
  const AdminGalleryUploadScreen({Key? key}) : super(key: key);

  @override
  State<AdminGalleryUploadScreen> createState() => _AdminGalleryUploadScreenState();
}

class _AdminGalleryUploadScreenState extends State<AdminGalleryUploadScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _submitData() {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter artist name and select an image")),
      );
      return;
    }

    // TODO: Send `name`, `bio`, and `_selectedImage` to backend

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Artist uploaded")),
    );

    setState(() {
      _selectedImage = null;
      _nameController.clear();
      _bioController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Artist Picture")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage == null
                      ? const Center(child: Text("Tap to select image"))
                      : Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Artist Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Bio (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text("Upload", style: TextStyle(color: Colors.white)),
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
