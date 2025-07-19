import 'package:showbizapp/pages/surport.dart';
import 'package:showbizapp/pages/swipper.dart';
import 'package:flutter/material.dart';
import '../DTOs/CardContent.dart';
import '../components/CustomCard.dart';
//import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';

import '../components/buttomnav.dart';
import 'MusicVideoPage.dart';  // Import for swiper

class Freestyle extends StatefulWidget {
  const Freestyle({super.key});

  @override
  State<Freestyle> createState() => _HomeState();
}

class _HomeState extends State<Freestyle> {
  bool isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  // List of card items using the CardContent DTO
  final List<CardContent> cardItems = [
    CardContent(
        image: 'assets/image1.jpg',
        text: 'Video + Download: Chefor – I Get Faith feat. Freeboi Lamma | 237Showbiz',
        extraInfos: "Your extra text here I Get Faith feat. Freeboi Lamma | 237Showbiz"
    ),
    CardContent(
        image: 'assets/image1.jpg',
        text: 'Video + Download: Chefor – I Get Faith feat. Freeboi Lamma | 237Showbiz',
        extraInfos: "Your extra text here I Get Faith feat. Freeboi Lamma | 237Showbiz"),
    CardContent(
        image: 'assets/image1.jpg',
        text: 'Video + Download: Chefor – I Get Faith feat. Freeboi Lamma | 237Showbiz',
        extraInfos: "Your extra text here I Get Faith feat. Freeboi Lamma | 237Showbiz"),
    CardContent(
        image: 'assets/image1.jpg',
        text: 'Video + Download: Chefor – I Get Faith feat. Freeboi Lamma | 237Showbiz',
        extraInfos: "Your extra text here I Get Faith feat. Freeboi Lamma | 237Showbiz"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Center(
          child: Image.asset(
            'assets/applogo.png', // Replace with your logo image asset
            height: 100, // Adjust height as needed
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.video_camera_front, color: Colors.white),
                  onPressed: () {
                    // Add your camera action here
                  },
                ),
                const Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Swiper widget here
          const swipper(),
          // ListView for cards
          Expanded(
            child: ListView.builder(
              itemCount: cardItems.length,
              itemBuilder: (context, index) {

              },
            ),
          ),
        ],
      ),

    );
  }
}

