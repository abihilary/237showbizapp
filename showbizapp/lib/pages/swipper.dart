import 'package:flutter/material.dart';
import '../DTOs/CardContent.dart';
import '../components/CustomCard.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'MusicVideoPage.dart';
class swipper extends StatelessWidget {
  const swipper({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180.0, // Set the height for the image container
      child: Container(
        color: Colors.orange, // Background color (optional)
        child: Image.asset(
          'assets/slide.jpg', // Path to your single image
          fit: BoxFit.cover, // Ensure the image covers the entire area
        ),
      ),
    );
  }
}