import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class BookCoverWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final bool showBookmark;

  const BookCoverWidget({
    super.key,
    this.imageUrl,
    this.width = 110,
    this.height = 160,
    this.showBookmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final spineW = width * 0.07;
    final pageH = height * 0.07;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned(
            left: spineW,
            top: 0,
            right: 0,
            bottom: pageH,
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppTheme.progressTrack),
                    errorWidget: (_, _, _) => Container(
                      color: AppTheme.inputBg,
                      child: const Icon(Icons.book, color: AppTheme.textSecondary, size: 20),
                    ),
                  )
                : Container(color: AppTheme.progressTrack),
          ),

          Positioned(
            left: spineW,
            right: 0,
            bottom: 0,
            height: pageH,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE8E4DF),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(3)),
              ),
            ),
          ),

          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: spineW,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                ),
              ),
            ),
          ),

          Positioned(
            left: spineW,
            top: 0,
            bottom: pageH,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent],
                ),
              ),
            ),
          ),

          if (showBookmark)
            Positioned(
              top: 4,
              right: 6,
              child: const Icon(Icons.bookmark, color: AppTheme.bookmarkAccent, size: 18),
            ),
        ],
      ),
    );
  }
}
