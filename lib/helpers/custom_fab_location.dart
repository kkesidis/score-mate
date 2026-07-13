import 'package:flutter/material.dart';

class CustomFabLocation extends FloatingActionButtonLocation {
  final double offsetY;
  final double offsetX;

  const CustomFabLocation({required this.offsetY, required this.offsetX});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scarcity) {
    // 1. Grab the width and height safely from the size configuration object
    final double fabWidth = scarcity.floatingActionButtonSize.width;
    final double fabHeight = scarcity.floatingActionButtonSize.height;

    // 2. Compute coordinates relative to the full scaffold size boundaries
    final double x = scarcity.scaffoldSize.width - fabWidth - offsetX;
    final double y = scarcity.scaffoldSize.height - fabHeight - offsetY;
    
    return Offset(x, y);
  }
}