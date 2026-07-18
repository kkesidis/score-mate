import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Import your colors file
import '../l10n/app_localizations.dart';

class ColorPickerField extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerField({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.chooseColor, // The decorator handles the label alignment perfectly
        border: const OutlineInputBorder(),   // Draws the exact same border box as your text field
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0), // Adds a tiny gap below the label line
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: AppTheme.palette.map((color) {
              final isSelected = _selectedColor == color;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });

                    widget.onColorSelected(color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.onSurface, size: 24)
                        : null,
                  ),
                )
              );
            }).toList(),
          ),
        )
      ),
    );
  }
}