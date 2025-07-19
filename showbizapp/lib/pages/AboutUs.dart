import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    String data =
        "237Showbiz is a Cameroonian entertainment platform founded by Emmanuel Veranyuy Mfon in 2015.\n\n"
        "237Showbiz is the Trend Guru. We Discover, We Buzz, We Share.\n"
        "It is the most professional entertainment powerhouse in Cameroon, delivering trending and fresh Cameroonian music content daily, including Rap, RnB, Makossa, Dancehall, Bikutsi, and more.\n\n"
        "Our platform exposes outstanding artists from the fast-growing Cameroonian music industry to the world. Music lovers globally can watch, comment, and stay updated with the latest tracks, with easy access on all devices.\n"
        "Artists benefit from active comments sections for feedback, which can influence future releases.\n\n"
        "Besides promoting artists, we organize concerts, grant interviews, and provide management support.\n\n"
        "Our head office is in Douala (Deido) Bonateki.";

    return Scaffold(
      appBar: AppBar(
        title: Text('About Us',style:TextStyle(
          fontFamily:"Poppins",
          fontWeight:FontWeight.bold
        )),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to 237Showbiz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                fontFamily: "Poppins",
              ),
            ),
            SizedBox(height: 16),
            Text(
              data,
              style: TextStyle(fontSize: 16, height: 1.5,fontFamily: "Poppins"),
            ),
            SizedBox(height: 20),
            // Optionally, add more sections or images here
          ],
        ),
      ),
    );
  }
}
