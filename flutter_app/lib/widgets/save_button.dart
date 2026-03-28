// lib/widgets/save_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SaveButton extends StatelessWidget {
  final bool   isSaving;
  final String label;
  final VoidCallback? onPressed;

  const SaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
    this.label = 'Save Task',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isSaving
            ? AppColors.accentSoft
            : AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // onPressed is null while saving — prevents double tap
          onTap: isSaving ? null : onPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSaving
                  ? const SizedBox(
                      key: ValueKey('loader'),
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      key: const ValueKey('label'),
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
