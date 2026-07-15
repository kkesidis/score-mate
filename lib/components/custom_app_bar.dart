// lib/widgets/score_den_app_bar.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? additionalActions;

  const CustomAppBar({
    required this.title,
    this.additionalActions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        ...?additionalActions,
        
        // This is our global menu button that will show up on every page
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                drawerScaffoldKey.currentState?.openEndDrawer();
              },
            );
          },
        ),
      ],
    );
  }

  // This is required when implementing PreferredSizeWidget.
  // It tells Flutter to make this the standard top-bar height.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}