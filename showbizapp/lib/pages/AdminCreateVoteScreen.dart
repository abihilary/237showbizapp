import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../DTOs/UserModel.dart';

class Artist {
  String? id; // assume backend returns an id for each artist
  String name;
  String imageUrl; // url string from backend
  int votes;

  // For local new images, you may want a File as well
  File? localImageFile;

  Artist({
    this.id,
    required this.name,
    required this.imageUrl,
    this.votes = 0,
    this.localImageFile,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['image_path'] ?? '';
    String fullUrl = rawUrl.startsWith('http')?rawUrl :'https://api.237showbiz.com/api/$rawUrl';
    print('Artist.fromJson - imageUrl: $fullUrl');
    return Artist(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: fullUrl,
      votes: json['votes'] ?? 0,
    );
  }
  @override
  String toString() {
    return 'Artist(id: $id, name: $name, votes: $votes, imageUrl: $imageUrl)';
  }
}

class AdminCreateVoteScreen extends StatefulWidget {
  const AdminCreateVoteScreen({Key? key}) : super(key: key);

  @override
  _AdminCreateVoteScreenState createState() => _AdminCreateVoteScreenState();
}

class _AdminCreateVoteScreenState extends State<AdminCreateVoteScreen> {
  final TextEditingController _artistNameController = TextEditingController();
  File? _pickedImageFile;
  final List<Artist> _artists = [];

  int? _editingIndex;
  bool _loading = false;


  final String backendUrl = "https://api.237showbiz.com/api/artist/";

  @override
  void initState() {
    super.initState();
    _fetchArtists();
  }


  Future<void> _fetchArtists() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(Uri.parse(backendUrl), body: {'action': 'fetch'});
      print(response);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final loadedArtists = jsonData.map((e) => Artist.fromJson(e)).toList();

        setState(() {
          _artists.clear();
          _artists.addAll(loadedArtists);
        });
        print("this are the artist ${_artists}");
      } else {
        _showSnackBar("Failed to load artists.");
      }
    } catch (e) {
      _showSnackBar("Error fetching artists: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path);
      });
    }
  }
  Future<String?> getSubscriberId() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriberJson = prefs.getString('subscriber');
    if (subscriberJson == null) return null;

    final Map<String, dynamic> subscriber = jsonDecode(subscriberJson);
    return subscriber['subscriber_id'];
  }
  Future<void> _submitVoteEntry(BuildContext context) async {
    final name = _artistNameController.text.trim();
    final subscriberId = await getSubscriberId();
    if (subscriberId == null) {
      _showSnackBar("No subscriber found.");
      return;
    }

    if (name.isEmpty || (_pickedImageFile == null && _editingIndex == null)) {
      _showSnackBar("Please add both name and image");
      return;
    }

    setState(() => _loading = true);

    try {
      if (_editingIndex != null) {
        final artist = _artists[_editingIndex!];
        await _editArtistOnServer(artist.id!, name, _pickedImageFile);
      } else {
        await _addArtistToServer(name, _pickedImageFile!, subscriberId);
      }
      await _fetchArtists();
      _clearForm();
      _showSnackBar(_editingIndex != null ? "Artist updated successfully" : "Artist added successfully");
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }


  Future<void> _addArtistToServer(String name, File imageFile, String subscriberId) async {
    var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
    request.fields['action'] = 'add';
    request.fields['name'] = name;
    request.fields['subscriber_id'] = subscriberId;
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: basename(imageFile.path)));

    final response = await http.Response.fromStream(await request.send());

    print("🔽 Server Response: ${response.body}");
    await _fetchArtists();


    if (response.statusCode != 200) {
      throw Exception("Failed to add artist: ${response.body}");
    }

    // ✅ Optional: Handle backend response "status: success" or "error"
    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse is Map && jsonResponse['status'] != 'success') {
      throw Exception("Backend error: ${jsonResponse['message'] ?? 'Unknown error'}");
    }
  }


  Future<void> _editArtistOnServer(String? id, String name, File? imageFile) async {
    if (id == null) {
      throw Exception("Cannot edit artist: ID is null");
    }

    var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
    request.fields['action'] = 'edit';
    request.fields['id'] = id.toString();
    request.fields['name'] = name;

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: basename(imageFile.path),
      ));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception("Failed to update artist: ${response.body}");
    }
  }


  Future<void> _deleteArtistFromServer(String id) async {
    final response = await http.post(Uri.parse(backendUrl), body: {
      'action': 'delete',
      'id': id.toString(),
    });

    if (response.statusCode != 200) {
      throw Exception("Failed to delete artist: ${response.body}");
    }
  }

  void _deleteArtist(int index) async {
    final artist = _artists[index];
    if (artist.id == null) {
      setState(() => _artists.removeAt(index));
      return;
    }

    setState(() => _loading = true);
    try {
      await _deleteArtistFromServer(artist.id!);
      _showSnackBar("Artist deleted successfully");
      await _fetchArtists();
    } catch (e) {
      _showSnackBar("Error deleting artist: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _editArtist(int index) {
    final artist = _artists[index];
    _artistNameController.text = artist.name;
    setState(() {
      _pickedImageFile = null;
      _editingIndex = index;
    });
  }

  void _clearForm() {
    _artistNameController.clear();
    setState(() {
      _pickedImageFile = null;
      _editingIndex = null;
    });
  }

  void _showSnackBar(String message) {
    // For now, just print the message instead of showing a snackbar
    print("this is what happened: $message");
  }


  Widget _buildArtistCard(Artist artist, int index) {
    Widget imageWidget;
    if (_editingIndex == index && _pickedImageFile != null) {
      imageWidget = Image.file(_pickedImageFile!, width: 60, height: 60, fit: BoxFit.cover);
    } else if (artist.imageUrl.isNotEmpty) {
      imageWidget = Image.network(artist.imageUrl, width: 60, height: 60, fit: BoxFit.cover);
    } else {
      imageWidget = Container(
        width: 60,
        height: 60,
        color: Colors.grey,
        child: const Icon(Icons.person),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: imageWidget),
        title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Votes: ${artist.votes}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editArtist(index)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteArtist(index)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _artistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingIndex != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Edit Artist Entry" : "Create Voting Entry")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: _pickedImageFile != null
                      ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                      : const Center(child: Text("Tap to select image")),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _artistNameController,
                decoration: const InputDecoration(
                  labelText: "Artist Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(
                        isEditing ? Icons.update : Icons.upload,
                        color: Colors.white,
                      ),
                      label: Text(
                        isEditing ? "Update" : "Submit",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: ()=>_submitVoteEntry(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditing ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ),
                  if (isEditing) const SizedBox(width: 12),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      tooltip: 'Cancel Edit',
                      onPressed: _clearForm,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Artists", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (_artists.isEmpty)
                const Center(child: Text("No artists found.")),
              ..._artists.asMap().entries.map((entry) {
                int index = entry.key;
                Artist artist = entry.value;
                return _buildArtistCard(artist, index);
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
