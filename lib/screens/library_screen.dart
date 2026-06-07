import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/book_cover_widget.dart';
import 'shelf_book_screen.dart';
import 'shelf_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = SupabaseService();

  List<Map<String, dynamic>> _reading = [];
  List<Map<String, dynamic>> _wishlist = [];
  List<Map<String, dynamic>> _completed = [];
  List<Map<String, dynamic>> _shelves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void refresh() => _loadData();

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getReadingBooks(),
        _service.getWishlistBooks(),
        _service.getCompletedBooks(),
        _service.getShelvesWithCount(),
      ]);
      if (mounted) {
        setState(() {
          _reading   = results[0];
          _wishlist  = results[1];
          _completed = results[2];
          _shelves   = results[3];
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddShelfSheet() {
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
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: AppTheme.inputDecoration('Shelf name'),
              onSubmitted: (_) => _createShelf(ctrl, ctx),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _createShelf(ctrl, ctx),
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createShelf(TextEditingController ctrl, BuildContext sheetCtx) async {
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      await _service.addShelf(name);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shelf created!')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFF3D3933),
      labelColor: const Color(0xFF3D3933),
      unselectedLabelColor: const Color(0xFFB0ABA6),
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
      tabs: const [
        Tab(text: 'Currently Reading'),
        Tab(text: 'Wishlist'),
        Tab(text: 'Completed'),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('My Library', style: AppTheme.screenTitle),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: Container(color: AppTheme.bgPrimary, child: tabBar),
                height: 48,
              ),
            ),

            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator(color: AppTheme.textPrimary)),
                    )
                  : _buildCurrentTabContent(),
            ),

            SliverToBoxAdapter(child: _buildShelvesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_tabController.index) {
      case 0: return _buildBookList(_reading, 'reading', 'No book currently being read', Icons.menu_book_outlined);
      case 1: return _buildBookList(_wishlist, 'wishlist', 'No books in wishlist yet', Icons.bookmark_border);
      case 2: return _buildBookList(_completed, 'completed', 'No completed books yet', Icons.check_circle_outline);
      default: return const SizedBox.shrink();
    }
  }

  Future<void> _deleteBook(Map<String, dynamic> book) async {
    final bookId = book['book_id'] as String?;
    if (bookId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Remove from Wishlist?', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
        content: Text('Delete "${book['title']}" from your wishlist?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppTheme.body)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _service.deleteBook(bookId);
    _loadData();
  }

  Widget _buildBookList(List<Map<String, dynamic>> books, String status, String emptyMsg, IconData emptyIcon) {
    if (books.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 36, color: const Color(0xFFB0ABA6)),
            const SizedBox(height: 8),
            Text(emptyMsg, style: AppTheme.caption),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      itemCount: books.length,
      itemBuilder: (_, i) => _BookCard(
        book: books[i],
        status: status,
        onRefresh: _loadData,
        onDelete: status == 'wishlist' ? () => _deleteBook(books[i]) : null,
      ),
    );
  }

  Widget _buildShelvesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Shelves', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF3D3933))),
          const SizedBox(height: 12),

          // New Shelf button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddShelfSheet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Shelf'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFD5D1CB),
                side: const BorderSide(color: Color(0xFF000000)),
                foregroundColor: const Color(0xFF3D3933),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_shelves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Image.asset('assets/images/empty_shelf.png', height: 80,
                        errorBuilder: (_, _, _) => const Icon(Icons.shelves, size: 48, color: Color(0xFFB0ABA6))),
                    const SizedBox(height: 8),
                    Text('No shelves yet', style: AppTheme.caption),
                  ],
                ),
              ),
            )
          else
            ..._shelves.map((shelf) => _ShelfCard(shelf: shelf, onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => ShelfDetailScreen(shelf: shelf)));
              _loadData();
            })),
        ],
      ),
    );
  }
}
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _StickyTabBarDelegate({required this.child, required this.height});

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => child != old.child;
}
class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final String status;
  final VoidCallback onRefresh;
  final VoidCallback? onDelete;

  const _BookCard({required this.book, required this.status, required this.onRefresh, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final current = (book['current_page'] as int?) ?? 0;
    final total   = (book['total_pages'] as int?) ?? 0;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ShelfBookScreen(book: book)));
        onRefresh();
      },
      child: Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            BookCoverWidget(imageUrl: book['cover_url'], width: 75, height: 110),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    book['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF3D3933)),
                  ),
                  const SizedBox(height: 3),
                  Text(book['author'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7570))),
                  if (status == 'reading') ...[
                    const SizedBox(height: 4),
                    Text('Page $current of $total', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB0ABA6))),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: const Color(0xFF3D3933),
                        backgroundColor: const Color(0xFFD5D1CB),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  if (status == 'wishlist') ...[
                    const SizedBox(height: 6),
                    if ((book['genre'] as String? ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE8E4DF), borderRadius: BorderRadius.circular(20)),
                        child: Text(book['genre'] as String, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5A5652))),
                      ),
                  ],
                  if (status == 'completed') ...[
                    if ((book['end_date'] ?? book['completed_at']) != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Finished: ${_fmt(book['end_date'] ?? book['completed_at'])}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB0ABA6)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline, size: 20, color: Color(0xFFB0ABA6)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic raw) {
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return ''; }
  }
}

class _ShelfCard extends StatelessWidget {
  final Map<String, dynamic> shelf;
  final VoidCallback onTap;
  const _ShelfCard({required this.shelf, required this.onTap});

  int get _count {
    final raw = shelf['shelf_books'];
    if (raw is List && raw.isNotEmpty) return (raw[0] as Map)['count'] as int? ?? 0;
    if (raw is int) return raw;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF0EDE8), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.book_outlined, color: Color(0xFF3D3933), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shelf['name'] as String? ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3D3933))),
                  Text('$_count books', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7570))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB0ABA6)),
          ],
        ),
      ),
    );
  }
}
