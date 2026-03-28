// lib/widgets/highlighted_text.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? baseStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);

    final lower   = text.toLowerCase();
    final lowerHL = highlight.toLowerCase();
    final spans   = <TextSpan>[];
    int start = 0;

    for (int idx = lower.indexOf(lowerHL, start);
         idx != -1;
         idx = lower.indexOf(lowerHL, start)) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + highlight.length),
        style: (baseStyle ?? const TextStyle()).copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          backgroundColor: AppColors.accentSoft,
        ),
      ));
      start = idx + highlight.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}
