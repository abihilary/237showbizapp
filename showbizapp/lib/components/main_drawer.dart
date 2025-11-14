// main_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showbizapp/DTOs/UserModel.dart';
import 'package:showbizapp/pages/AboutUs.dart';
import 'package:showbizapp/pages/Admin.dart';
import 'package:showbizapp/pages/Artist.dart';
import 'package:showbizapp/pages/CommingSoon.dart';
import 'package:showbizapp/pages/Event.dart';
import 'package:showbizapp/pages/LatestHit.dart';
import 'package:showbizapp/pages/MusicVideoPage.dart';
import 'package:showbizapp/pages/News.dart';
import 'package:showbizapp/pages/surport.dart';
import 'package:showbizapp/DTOs/VotingScreen.dart';
import 'package:showbizapp/pages/237showbizStudios.dart';

class MainDrawer extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String? subscriberName;
  final VoidCallback onUnsubscribe;
  final VoidCallback onUpdateSubscription; // Simplified callback
  final Function() getSubscriberId;

  const MainDrawer({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.subscriberName,
    required this.onUnsubscribe,
    required this.onUpdateSubscription, // New, simpler parameter
    required this.getSubscriberId,
  });

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context);
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor:
      isDarkMode ? const Color(0xFF0A1F44) : Colors.orange[600],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: isDarkMode ? const Color(0xFF0A1F44) : Colors.orange[600],
            height: 70,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Row(
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text(
                  "UserName: ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: "Poppins",
                  ),
                ),
                Text(
                  userModel.username.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Colors.white70),
          _buildExpansionTile('Music', Icons.library_music, [
            _buildDrawerItem('Latest Hits', () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        RecentPostsPage(isDarkMode: isDarkMode)))),
            _buildDrawerItem('Music Video', () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => MusicVideo()))),
          ]),
          _buildExpansionTile('Our Services', Icons.newspaper, [
            _buildDrawerItem(
                '237Showbiz Studios',
                    () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ShowbizStudiosPage()))),
            _buildDrawerItem('Shows', () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Commingsoon()))),
          ]),
          _buildListTile('Movies', Icons.movie, () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Commingsoon()))),
          _buildListTile('Artists', Icons.person, () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => GalleryPage()))),
          _buildListTile('Events', Icons.event, () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => EventsPage()))),
          _buildListTile('News', Icons.newspaper, () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => NewsPage()))),
          _buildListTile(
              'Trending',
              Icons.trending_up,
                  () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Commingsoon()))),
          _buildListTile(
              'Contact Us',
              Icons.group,
                  () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ContactPage(isDarkMode: isDarkMode)))),
          _buildListTile('About Us', Icons.info, () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => const AboutUs()))),
          _buildListTile('Vote', Icons.how_to_vote, () => Navigator.push(
              context, MaterialPageRoute(builder: (context) => VotingScreen()))),
          _buildListTile(
              'Live',
              Icons.video_camera_front,
                  () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Commingsoon()))),
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            title: const Text('Switch Theme',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            leading: const Icon(Icons.brightness_4, color: Colors.white, size: 18),
            trailing: Switch(
              value: isDarkMode,
              onChanged: onThemeChanged,
            ),
          ),
          if (userModel.showAdmin)
            _buildListTile('Admin', Icons.admin_panel_settings, () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => AdminPage()))),
          _buildExpansionTile('Settings', Icons.settings, [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton.icon(
                onPressed: () async {
                  final id = await getSubscriberId();
                  if (id != null) {
                    onUpdateSubscription();
                  }
                },
                icon: const Icon(Icons.update, color: Colors.white, size: 18),
                label: const Text("Update Subscription",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextButton.icon(
                onPressed: onUnsubscribe,
                icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                label: const Text("Unsubscribe",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(String title, IconData icon, List<Widget> children) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.only(left: 24),
      dense: true,
      title: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: "Poppins")),
      leading: Icon(icon, color: Colors.white, size: 18),
      trailing:
      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
      children: children,
    );
  }

  Widget _buildDrawerItem(String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: "Poppins")),
      onTap: onTap,
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: "Poppins")),
      leading: Icon(icon, color: Colors.white, size: 18),
      onTap: onTap,
    );
  }
}
