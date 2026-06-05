import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GenreChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const GenreChip({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.tagBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.tagBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.tagText,
          ),
        ),
      ),
    );
  }
}
