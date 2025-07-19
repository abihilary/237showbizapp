import 'package:flutter/material.dart';
import '../components/buttomnav.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final int selectedIndex;
  final bool isDarkMode;
  final Function externalSearchFunction;
  final Color? backgroundColor;
  final Widget? drawer;
  final FloatingActionButton? floatingActionButton;

  const MainScaffold({
    Key? key,
    required this.body,
    required this.selectedIndex,
    required this.externalSearchFunction,
    this.appBar,
    this.isDarkMode = false,
    this.backgroundColor,
    this.drawer,
    this.floatingActionButton,
  }) : super(key: key);


  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _onNavigate(int index) {
    if (index == widget.selectedIndex) return; // Avoid reloading current page

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/trending');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/news');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/events');
        break;
      case 4:
        widget.externalSearchFunction(); // Call search from parent
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: widget.body,
      drawer: widget.drawer,
      backgroundColor: widget.backgroundColor,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: BottomNav(
        currentIndex: widget.selectedIndex,
        isDarkMode: widget.isDarkMode,
        externalSearchFunction: widget.externalSearchFunction,
        onItemTapped: _onNavigate,
      ),
    );
  }

}
