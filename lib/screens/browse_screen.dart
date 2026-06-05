import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/book_service.dart';
import '../services/supabase_service.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/genre_chip.dart';
import 'shelf_book_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('ReadingLog', style: AppTheme.appName.copyWith(fontSize: 20)),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Browse By', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          _browseItem(context, 'Release Date', () => _pushDecadeScreen(context)),
          const SizedBox(height: 8),
          _browseItem(context, 'Genre', () => _pushGenreScreen(context)),
          const SizedBox(height: 8),
          _browseItem(context, 'Most Popular', () => _pushBookList(context, 'Most Popular', 'popular+books')),
          const SizedBox(height: 8),
          _browseItem(context, 'Highest Rated', () => _pushBookList(context, 'Highest Rated', 'best+books')),
          const SizedBox(height: 28),
          Text('Tags', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              '#Emotional', '#Romance', '#Angst',
              '#Fantasy', '#DarkAcademia', '#Cozy',
              '#Mystery', '#Thriller', '#YA',
            ].map((t) => GenreChip(label: t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _browseItem(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.inputBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _pushGenreScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _GenreListScreen()));
  }

  void _pushDecadeScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _DecadeScreen()));
  }

  void _pushBookList(BuildContext context, String title, String query) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookListScreen(title: title, query: query)));
  }
}

class _GenreListScreen extends StatelessWidget {
  const _GenreListScreen();

  static const _genres = ['Action', 'Adventure', 'Comedy', 'Fantasy', 'Horror', 'Romance', 'Science Fiction', 'Family'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('ReadingLog', style: AppTheme.appName.copyWith(fontSize: 20)),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Genre', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._genres.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LibraryGenreScreen(genre: g)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(g, style: AppTheme.body),
                        const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _DecadeScreen extends StatelessWidget {
  const _DecadeScreen();

  static const _decades = ['2011 - 2020 +', '2001 - 2010', '1991 - 2000', '1981 - 1990', '1971 - 1980'];
  static const _queries = ['2011+', '2001-2010', '1991-2000', '1981-1990', '1971-1980'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('ReadingLog', style: AppTheme.appName.copyWith(fontSize: 20)),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Genre', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...List.generate(_decades.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BookListScreen(title: _decades[i], query: 'publishedDate:${_queries[i]}')),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_decades[i], style: AppTheme.body),
                        const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class BookListScreen extends StatefulWidget {
  final String title;
  final String query;
  const BookListScreen({super.key, required this.title, required this.query});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _bookService = BookService();
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _bookService.search(widget.query);
      if (mounted) setState(() { _books = raw.map(_bookService.parse).toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(widget.title, style: AppTheme.screenTitle),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.textPrimary))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: _books.length,
              itemBuilder: (_, i) {
                final book = _books[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/book-detail', arguments: book),
                  child: Column(
                    children: [
                      BookCoverWidget(imageUrl: book['cover'], width: 90, height: 130),
                      const SizedBox(height: 4),
                      Text(
                        book['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class LibraryGenreScreen extends StatefulWidget {
  final String genre;
  const LibraryGenreScreen({super.key, required this.genre});

  @override
  State<LibraryGenreScreen> createState() => _LibraryGenreScreenState();
}

class _LibraryGenreScreenState extends State<LibraryGenreScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getBooksByGenre(widget.genre);
      if (mounted) setState(() { _books = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(widget.genre, style: AppTheme.screenTitle),
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.textPrimary))
          : _books.isEmpty
              ? Center(child: Text('No books in this genre yet.', style: AppTheme.caption))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (_, i) {
                    final book = _books[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShelfBookScreen(book: book)),
                      ),
                      child: Column(
                        children: [
                          BookCoverWidget(imageUrl: book['cover_url'], width: 90, height: 130),
                          const SizedBox(height: 4),
                          Text(
                            book['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
