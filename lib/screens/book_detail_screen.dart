import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/book_service.dart';
import '../services/supabase_service.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/genre_chip.dart';
import '../main.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();
  final _service = SupabaseService();
  final _pageCtrl = TextEditingController();
  bool _descExpanded = false;
  List<Map<String, dynamic>> _similar = [];

  // Library state (null = not in library yet)
  String? _supaBookId;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadSimilar();
    _checkLibraryStatus();
    _totalPages = (widget.book['pages'] as int?) ?? 0;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSimilar() async {
    try {
      final raw = await _bookService.similar(widget.book['author'] ?? '', widget.book['category'] ?? '');
      if (mounted) setState(() => _similar = raw.map(_bookService.parse).toList());
    } catch (_) {}
  }

  Future<void> _checkLibraryStatus() async {
    final apiId = widget.book['id'] as String?;
    if (apiId == null) return;
    final existing = await _service.getBookByApiId(apiId);
    if (existing != null && mounted) {
      setState(() {
        _supaBookId  = existing['book_id'] as String?;
        _currentPage = (existing['current_page'] as int?) ?? 0;
        _totalPages  = (existing['total_pages'] as int?) ?? _totalPages;
        _pageCtrl.text = _currentPage.toString();
      });
    }
  }

  Future<void> _addWithStatus(String status) async {
    final user = supabase.auth.currentUser!;
    try {
      final result = await _service.upsertBook({
        'user_id'    : user.id,
        'api_id'     : widget.book['id'],
        'title'      : widget.book['title'],
        'author'     : widget.book['author'],
        'cover_url'  : widget.book['cover'],
        'total_pages': widget.book['pages'] ?? 0,
        'genre'      : widget.book['category'] ?? '',
        'rating'     : widget.book['rating'],
        'language'   : widget.book['language'] ?? '',
        'status'     : status,
        'updated_at' : DateTime.now().toIso8601String(),
      });
      if (mounted) {
        setState(() => _supaBookId = result['book_id'] as String?);
        final label = status == 'reading' ? 'Currently Reading' : 'Wishlist';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to $label!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddToShelfSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddToShelfSheet(
        book: widget.book,
        supaBookId: _supaBookId,
        onBookEnsured: (id) => setState(() => _supaBookId = id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarH = MediaQuery.of(context).padding.top;
    final cover = widget.book['cover'] as String?;
    final title = widget.book['title'] ?? '';
    final author = widget.book['author'] ?? '';
    final desc = widget.book['description'] ?? '';
    final rating = (widget.book['rating'] as num?)?.toDouble() ?? 0.0;
    final ratingsCount = (widget.book['ratingsCount'] as int?) ?? 0;
    final tags = (widget.book['category'] as String? ?? '').isNotEmpty
        ? ['#${widget.book['category']}']
        : <String>[];

    const bgHeight = 250.0;
    const coverW = 160.0;
    const coverH = 230.0;
    final coverTop = statusBarH + 30.0;
    final overlapH = (coverTop + coverH - bgHeight).clamp(0.0, coverH);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: bgHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover != null && cover.isNotEmpty)
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Image.network(cover, fit: BoxFit.cover),
                        ),
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppTheme.bgPrimary,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: coverTop, left: 0, right: 0,
                  child: Center(child: BookCoverWidget(imageUrl: cover, width: coverW, height: coverH)),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(20, overlapH + 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(title, style: AppTheme.screenTitle, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('by : $author', style: AppTheme.caption),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (i) => Icon(
                        i < rating.round() ? Icons.star : Icons.star_border,
                        color: AppTheme.starFilled, size: 18,
                      )),
                      if (rating > 0) ...[
                        const SizedBox(width: 6),
                        Text('(${rating.toStringAsFixed(0)})', style: AppTheme.caption),
                      ],
                      if (ratingsCount > 0) ...[
                        const SizedBox(width: 4),
                        Text('(${_fmtCount(ratingsCount)} ratings)', style: AppTheme.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(child: _statusBtn('Currently Reading', () => _addWithStatus('reading'))),
                      const SizedBox(width: 8),
                      Expanded(child: _statusBtn('Wishlist', () => _addWithStatus('wishlist'))),
                      const SizedBox(width: 8),
                      Expanded(child: _statusBtn('Add to Shelf', _showAddToShelfSheet)),
                    ],
                  ),

                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    GestureDetector(
                      onTap: () => setState(() => _descExpanded = !_descExpanded),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('"$desc"',
                            maxLines: _descExpanded ? null : 6,
                            overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: AppTheme.body.copyWith(height: 1.65),
                          ),
                          const SizedBox(height: 4),
                          Text(_descExpanded ? 'Read less' : 'Read more',
                            style: AppTheme.caption.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),
                  Align(alignment: Alignment.centerLeft,
                    child: Text('Tags', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16))),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [...tags.map((t) => GenreChip(label: t)), const GenreChip(label: '#Fiction')],
                    ),
                  ),

                  if (_similar.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Align(alignment: Alignment.centerLeft,
                      child: Text('Similar Books', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 210,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similar.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final b = _similar[i];
                          return GestureDetector(
                            onTap: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => BookDetailScreen(book: b))),
                            child: SizedBox(
                              width: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  BookCoverWidget(imageUrl: b['cover'], width: 110, height: 155),
                                  const SizedBox(height: 6),
                                  Text(b['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.body.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
                                  Text('By : ${b['author'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppTheme.caption.copyWith(fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.surface,
        side: const BorderSide(color: Color(0xFF3D3933), width: 1),
        foregroundColor: AppTheme.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, textAlign: TextAlign.center, softWrap: true),
    );
  }

  String _fmtCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(0)},000' : '$n';
}
class _AddToShelfSheet extends StatefulWidget {
  final Map<String, dynamic> book;
  final String? supaBookId;
  final void Function(String bookId) onBookEnsured;

  const _AddToShelfSheet({required this.book, required this.supaBookId, required this.onBookEnsured});

  @override
  State<_AddToShelfSheet> createState() => _AddToShelfSheetState();
}

class _AddToShelfSheetState extends State<_AddToShelfSheet> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _shelves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getShelves().then((s) {
      if (mounted) setState(() { _shelves = s; _loading = false; });
    });
  }

  Future<String> _ensureBook() async {
    if (widget.supaBookId != null) return widget.supaBookId!;
    final result = await _service.upsertBook({
      'user_id'    : supabase.auth.currentUser!.id,
      'api_id'     : widget.book['id'],
      'title'      : widget.book['title'],
      'author'     : widget.book['author'],
      'cover_url'  : widget.book['cover'],
      'total_pages': widget.book['pages'] ?? 0,
      'genre'      : widget.book['category'] ?? '',
      'rating'     : widget.book['rating'],
      'language'   : widget.book['language'] ?? '',
      'status'     : 'wishlist',
    });
    final id = result['book_id'] as String;
    widget.onBookEnsured(id);
    return id;
  }

  Future<void> _addToShelf(Map<String, dynamic> shelf) async {
    try {
      final bookId = await _ensureBook();
      await _service.addBookToShelf(shelf['shelf_id'] as String, bookId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to ${shelf['name']}!')),
        );
      }
    } on Exception catch (e) {
      if (e.toString().contains('already_in_shelf')) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already in this shelf')));
        }
      }
    }
  }

  void _createShelf() {
    Navigator.pop(context);
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Shelf', style: AppTheme.screenTitle),
            const SizedBox(height: 16),
            TextField(controller: ctrl, autofocus: true, decoration: AppTheme.inputDecoration('Shelf name')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  await _service.addShelf(name);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelf created!')));
                },
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add to Shelf', style: AppTheme.screenTitle),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.textPrimary)))
          else if (_shelves.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No shelves yet', style: AppTheme.caption))
          else
            ..._shelves.map((shelf) => ListTile(
              title: Text(shelf['name'] as String? ?? '', style: AppTheme.body),
              contentPadding: EdgeInsets.zero,
              onTap: () => _addToShelf(shelf),
            )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: AppTheme.textPrimary),
            title: Text('Create New Shelf', style: AppTheme.body),
            contentPadding: EdgeInsets.zero,
            onTap: _createShelf,
          ),
        ],
      ),
    );
  }
}
