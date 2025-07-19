import 'package:flutter/material.dart';
import 'package:showbizapp/pages/CommingSoon.dart';
import '../pages/Home.dart';
import '../pages/News.dart';
import '../pages/Event.dart';

class BottomNav extends StatelessWidget {
  final Function externalSearchFunction;
  final bool isDarkMode;
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNav({
    Key? key,
    required this.externalSearchFunction,
    required this.isDarkMode,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: isDarkMode ? const Color(0xFF0A1F44) : Colors.orange[600],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.trending_up, "Trending", 1),
          _buildNavItem(Icons.newspaper, "News", 2),
          _buildNavItem(Icons.event, "Events", 3),
          _buildNavItem(Icons.search, "Search", 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white.withOpacity(0.6);

    return InkWell(
      onTap: () => onItemTapped(index),
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

