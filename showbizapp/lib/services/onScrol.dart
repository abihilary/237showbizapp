
import 'package:flutter/cupertino.dart';


void scrollToTop() {
  ScrollController scrollController = ScrollController();
  scrollController.animateTo(
    0.0,
    duration: Duration(milliseconds: 500),
    curve: Curves.easeInOut,
  );
}

