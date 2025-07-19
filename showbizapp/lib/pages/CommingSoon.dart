import 'package:flutter/material.dart';

import '../DTOs/Mainscafold.dart';
import '../components/buttomnav.dart';
class Commingsoon extends StatefulWidget {
  const Commingsoon({super.key});

  @override
  State<Commingsoon> createState() => _CommingsoonState();
}

class _CommingsoonState extends State<Commingsoon> {
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      selectedIndex: 1, // 🔸 Trending index
      isDarkMode: false, // or true if you're using dark mode logic
      externalSearchFunction: () {
        // TODO: define search function or pass from parent
        print("Search tapped from Commingsoon");
      },
      body: const Center(
        child: Text(
          "Coming soon....",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("Add Event"),
        backgroundColor: Colors.orange,
      ), backgroundColor: Colors.white, drawer: Drawer(), 
    );
  }
}

