import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({super.key, this.message = 'No books here yet'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/empty_shelf.png',
            width: 180,
            errorBuilder: (_, _, _) => const Icon(Icons.menu_book_outlined, size: 80, color: AppTheme.textHint),
          ),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
