import 'package:flutter/material.dart';

const plum = Color(0xFF210D2C);
const violet = Color(0xFF8050EF);
const coral = Color(0xFFFF786B);
const paper = Color(0xFFFCF9F3);
const muted = Color(0xFF82798D);
const brandGradient = LinearGradient(
  colors: [violet, Color(0xFFBB5ADC), coral],
);

ThemeData sketchoraTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: violet,
    brightness: Brightness.light,
    surface: paper,
    secondary: coral,
  );
  return ThemeData(
    fontFamily: 'DMSans',
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'DMSans',
      bodyColor: plum,
      displayColor: plum,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: plum,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .26),
    child: Image.asset(
      'assets/branding/sketchora-icon-v1.png',
      width: size,
      height: size,
      semanticLabel: 'Sketchora brush S logo',
    ),
  );
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: brandGradient,
      borderRadius: BorderRadius.circular(16),
    ),
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
    ),
  );
}

Future<String?> requestName(
  BuildContext context,
  String initial, {
  String heading = 'Name your sketch',
}) async {
  final controller = TextEditingController(text: initial);
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(heading),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Sketch name'),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  // Dialog route owns the text field until its exit transition completes.
  Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
  return value;
}
