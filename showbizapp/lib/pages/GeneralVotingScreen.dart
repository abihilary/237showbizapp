import 'package:flutter/material.dart';
import 'VoteResultScreen.dart';
import 'AdminCreateVoteScreen.dart';

class GeneralVotingScreen extends StatelessWidget {
  const GeneralVotingScreen({Key? key}) : super(key: key);

  void _navigateToCreateVote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminCreateVoteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Voting DashBoard"),
      ),
      body:  VoteResultScreen(), // shows vote results by default
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateVote(context),
        icon: const Icon(Icons.add,color: Colors.white,),
        label: const Text("Create Vote",style:TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
