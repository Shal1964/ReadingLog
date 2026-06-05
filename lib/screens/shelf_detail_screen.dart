import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/book_cover_widget.dart';
import 'shelf_book_screen.dart';

class ShelfDetailScreen extends StatefulWidget {
  final Map<String, dynamic> shelf;
  const ShelfDetailScreen({super.key, required this.shelf});

  @override
  State<ShelfDetailScreen> createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  String get _shelfId => widget.shelf['shelf_id'] as String;
  String get _shelfName => widget.shelf['name'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getShelfBooks(_shelfId);
      if (mounted) setState(() { _books = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete shelf?', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
        content: Text('This will remove "$_shelfName" and all its book links.', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppTheme.body)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _service.deleteShelf(_shelfId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmRemove(Map<String, dynamic> row, String bookId) async {
    final book = Map<String, dynamic>.from(row['books'] as Map? ?? {});
    final title = book['title'] as String? ?? 'this book';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Remove from shelf?', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
        content: Text('Remove "$title" from $_shelfName?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppTheme.body)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _service.removeBookFromShelf(_shelfId, bookId);
    _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(_shelfName, style: AppTheme.screenTitle),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.textPrimary),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.textPrimary))
          : _books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/empty_shelf.png', height: 100,
                          errorBuilder: (_, _, _) => const Icon(Icons.shelves, size: 56, color: Color(0xFFB0ABA6))),
                      const SizedBox(height: 12),
                      Text('No books in this shelf yet', style: AppTheme.caption),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (_, i) {
                    final row = _books[i];
                    final book = Map<String, dynamic>.from(row['books'] as Map? ?? {});
                    final bookId = row['book_id'] as String;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShelfBookScreen(book: book)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (_, constraints) => Stack(
                                children: [
                                  BookCoverWidget(
                                    imageUrl: book['cover_url'],
                                    width: constraints.maxWidth,
                                    height: constraints.maxHeight,
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _confirmRemove(row, bookId),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book['title'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
