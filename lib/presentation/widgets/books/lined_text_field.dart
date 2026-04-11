// lib/presentation/widgets/books/lined_text_field.dart

import 'package:flutter/material.dart';

/// A notepad-style text field with horizontal ruled lines drawn behind the text.
/// Replicates the original Java app's LinedEditText custom view.
class LinedTextField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const LinedTextField({
    super.key,
    required this.controller,
    this.maxLength = 1500,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return CustomPaint(
      painter: _LinedPainter(
        lineColor: lineColor,
        lineHeight: _kLineHeight,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: maxLength,
        maxLines: null, // unlimited lines
        expands: true, // fill available space
        textAlignVertical: TextAlignVertical.top,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 16,
          height: _kLineHeight / 16, // match line spacing to painted lines
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          hintText: 'Write your notes here...',
          hintStyle: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          counterStyle: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// The pixel height of each ruled line. Must match the text line height.
const double _kLineHeight = 32.0;

/// Custom painter that draws horizontal ruled lines across the canvas,
/// similar to a lined notebook page.
class _LinedPainter extends CustomPainter {
  final Color lineColor;
  final double lineHeight;

  _LinedPainter({
    required this.lineColor,
    required this.lineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Start drawing lines from the top, offset by the content padding + first line
    double y = lineHeight + 8; // 8 = top contentPadding
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPainter oldDelegate) {
    return lineColor != oldDelegate.lineColor ||
        lineHeight != oldDelegate.lineHeight;
  }
}
