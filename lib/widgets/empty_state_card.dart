import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final Widget child;

  const EmptyStateCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // <-- Forces the card to stretch to full screen width
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer, 
          borderRadius: BorderRadius.circular(12),
          // ... your border and shadow setup ...
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}