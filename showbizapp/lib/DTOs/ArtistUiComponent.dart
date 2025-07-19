import 'package:flutter/material.dart';

import './jsonClass.dart';
Widget buildArtistCard(context,jArtist artist, VoidCallback onVote) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 1.5,
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.5,
              child:ClipRRect(
                child: Image.network(artist.imageUrl,fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,),
              )
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(artist.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Text('Votes: ${artist.votes}', style: const TextStyle(fontSize: 16,fontFamily: "Poppins")),
          ElevatedButton(
            onPressed: onVote,
            child: const Text('Vote',style: TextStyle(color: Colors.orange,fontFamily: "Poppins"),),
          ),
        ],
      ),
    ),
  );
}
