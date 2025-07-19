// VotingScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showbizapp/DTOs/Artist.dart';


import 'ArtistUiComponent.dart'; // Your artist card widget builder
// Artist.dart

import './jsonClass.dart';
class VotingScreen extends StatefulWidget {
  @override
  _VotingScreenState createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List<jArtist> artists = [];
  bool isLoading = false;

  final String backendUrl = 'https://api.237showbiz.com/api/artist/';

  @override
  void initState() {
    super.initState();
    _fetchArtists();
  }

  Future<void> _fetchArtists() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(Uri.parse(backendUrl), body: {'action': 'fetch'});



      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print(jsonData);

        final fetchedArtists = jsonData.map((e) => jArtist.fromJson(e)).toList();

        setState(() {
          artists = fetchedArtists;
        });
        print(artists);
      } else {
        print("Failed to load artists: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching artists: $e");
    } finally {
      setState(() {
        isLoading = false;
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
  void _voteForArtist(int index) async {
    final artist = artists[index];
    print('Artist ID: ${artist.id}');

    setState(() {
      artists[index].votes++; // Optimistic UI update
    });

    try {
      final subscriberId = await getSubscriberId();
      if (subscriberId == null) {
        print("No subscriber found.");
        return;
      }
      final response = await http.post(
        Uri.parse(backendUrl),
        body: {
          'action': 'vote',
          'artist_id': artist.id,
          'subscriber_id': subscriberId,  // Replace this with actual subscriber ID from your app state
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          // If backend returns error, revert the optimistic update
          setState(() {
            artists[index].votes--;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vote failed: ${data['error']}')),
          );
        } else {
          // Vote succeeded, optionally refresh list sorted by votes
          _fetchArtists(); // Re-fetch to get updated votes and sorting by highest votes on backend
        }
      } else {
        setState(() {
          artists[index].votes--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to vote. Server error you can only vote once')),
        );
      }
    } catch (e) {
      setState(() {
        artists[index].votes--;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vote for Your Favorite Artist')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : artists.isEmpty
          ? const Center(child: Text('No artists found.'))
          : ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, index) {
          return buildArtistCard(
            context,
            artists[index] ,
                () => _voteForArtist(index),
          );
        },
      ),
    );
  }
}
