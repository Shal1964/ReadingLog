import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../services/book_service.dart';
import '../widgets/book_cover_widget.dart';
import '../widgets/genre_chip.dart';
import '../main.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bookService = BookService();

  List<Map<String, dynamic>> _newReleases = [];
  List<Map<String, dynamic>> _popular = [];
  List<Map<String, dynamic>> _recommendations = [];

  bool _loadingNR = true;
  bool _loadingPop = true;
  bool _loadingRec = true;

  bool _errorNR = false;
  bool _errorPop = false;
  bool _errorRec = false;

  String _recLabel = '';

  String get _username {
    final meta = supabase.auth.currentUser?.userMetadata;
    return meta?['username'] as String? ?? meta?['full_name'] as String? ?? 'Reader';
  }

  @override
  void initState() {
    super.initState();
    _loadAllSections();
  }

  Future<void> _loadAllSections() async {
    await Future.wait([
      _loadNewReleases(),
      _loadPopular(),
      _loadRecommendations(),
    ]);
    _deduplicateAcrossSections();
  }

  void _deduplicateAcrossSections() {
    if (!mounted) return;
    final seen = <String>{};
    setState(() {
      _newReleases      = _newReleases.where((b)      => seen.add(b['id'] as String? ?? '')).toList();
      _popular          = _popular.where((b)          => seen.add(b['id'] as String? ?? '')).toList();
      _recommendations  = _recommendations.where((b)  => seen.add(b['id'] as String? ?? '')).toList();
    });
  }

  Future<void> _loadNewReleases() async {
    if (mounted) setState(() { _loadingNR = true; _errorNR = false; });
    try {
      final raw = await _bookService.fetchNewReleases();
      if (mounted) {
        setState(() {
          _newReleases = raw.map(_bookService.parse).toList();
          _loadingNR = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingNR = false; _errorNR = true; });
    }
  }

  Future<void> _loadPopular() async {
    if (mounted) setState(() { _loadingPop = true; _errorPop = false; });
    try {
      final raw = await _bookService.fetchPopular();
      if (mounted) {
        setState(() {
          _popular = raw.map(_bookService.parse).toList();
          _loadingPop = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingPop = false; _errorPop = true; });
    }
  }

  Future<void> _loadRecommendations() async {
    if (mounted) setState(() { _loadingRec = true; _errorRec = false; _recLabel = ''; });
    try {
      final userId = supabase.auth.currentUser!.id;
      final userBooksRaw = await supabase
          .from('books')
          .select('genre, author, title')
          .eq('user_id', userId);
      final userBooks = List<Map<String, dynamic>>.from(userBooksRaw);

      if (userBooks.isEmpty) {
        final raw = await _bookService.fetchRecommendations('subject:fiction');
        if (mounted) {
          setState(() {
            _recommendations = raw.map(_bookService.parse).toList();
            _recLabel = 'Explore Popular Books';
            _loadingRec = false;
          });
        }
        return;
      }

      final genres = userBooks
          .map((b) => b['genre'] as String?)
          .where((g) => g != null && g.isNotEmpty)
          .cast<String>()
          .toList();

      final authors = userBooks
          .map((b) => b['author'] as String?)
          .where((a) => a != null && a.isNotEmpty)
          .cast<String>()
          .toList();

      final genreCount = <String, int>{};
      for (final g in genres) {
        genreCount[g] = (genreCount[g] ?? 0) + 1;
      }
      final topGenre = genreCount.isNotEmpty
          ? (genreCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
          : null;

      final shuffledAuthors = List<String>.from(authors)..shuffle();
      final randomAuthor = shuffledAuthors.isNotEmpty ? shuffledAuthors.first : null;

      String query;
      String label;
      if (topGenre != null && randomAuthor != null) {
        query = 'subject:${Uri.encodeComponent(topGenre)}+inauthor:${Uri.encodeComponent(randomAuthor)}';
        label = 'Based on your love of $topGenre';
      } else if (topGenre != null) {
        query = 'subject:${Uri.encodeComponent(topGenre)}';
        label = 'Based on your love of $topGenre';
      } else if (randomAuthor != null) {
        query = 'inauthor:${Uri.encodeComponent(randomAuthor)}';
        label = 'Because you read $randomAuthor';
      } else {
        query = 'subject:fiction';
        label = 'Explore Popular Books';
      }

      final raw = await _bookService.fetchRecommendations(query);

      final savedTitles = userBooks
          .map((b) => (b['title'] as String? ?? '').toLowerCase())
          .toSet();

      var filtered = raw.where((item) {
        final title = ((item['volumeInfo'] as Map?)?['title'] ?? '').toString().toLowerCase();
        return !savedTitles.contains(title);
      }).take(10).toList();

      // If the combined genre+author query returned nothing, retry with genre alone
      if (filtered.isEmpty && topGenre != null && randomAuthor != null) {
        final genreOnly = await _bookService.fetchRecommendations('subject:${Uri.encodeComponent(topGenre)}');
        filtered = genreOnly.where((item) {
          final title = ((item['volumeInfo'] as Map?)?['title'] ?? '').toString().toLowerCase();
          return !savedTitles.contains(title);
        }).take(10).toList();
      }

      if (filtered.isEmpty) {
        final fallback = await _bookService.fetchRecommendations('subject:fiction');
        filtered = fallback.take(10).toList();
        label = 'Explore Popular Books';
      }

      if (mounted) {
        setState(() {
          _recommendations = filtered.map(_bookService.parse).toList();
          _recLabel = label;
          _loadingRec = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingRec = false; _errorRec = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.textPrimary,
          onRefresh: _loadAllSections,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildBanner()),
              SliverToBoxAdapter(child: _buildGenreRow()),
              SliverToBoxAdapter(child: _sectionHeader('New Release')),
              SliverToBoxAdapter(child: _buildSection(_newReleases, _loadingNR, _errorNR, _loadNewReleases)),
              SliverToBoxAdapter(child: _buildPromoBanner()),
              SliverToBoxAdapter(child: _sectionHeader('Popular this Week')),
              SliverToBoxAdapter(child: _buildSection(_popular, _loadingPop, _errorPop, _loadPopular)),
              SliverToBoxAdapter(
                child: _sectionHeader('Recommendation', subtitle: _recLabel),
              ),
              SliverToBoxAdapter(child: _buildSection(_recommendations, _loadingRec, _errorRec, _loadRecommendations)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.inputBg,
                child: Icon(Icons.person_outline, size: 20, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 10),
              Text('Hi, $_username !', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          Text('ReadingLog', style: AppTheme.appName.copyWith(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.textHint, size: 20),
            const SizedBox(width: 8),
            Text('Search books...', style: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 140,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/home_banner.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: AppTheme.inputBg),
      ),
    );
  }

  Widget _buildGenreRow() {
    const genres = ['Romance', 'Fantasy', 'Horror', "Children's", 'Fiction'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (int i = 0; i < genres.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            GenreChip(
              label: genres[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => _GenreBookListScreen(genre: genres[i])),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7570), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    List<Map<String, dynamic>> books,
    bool loading,
    bool hasError,
    VoidCallback onRetry,
  ) {
    if (loading) return _buildShimmerRow();
    if (hasError) return _buildErrorRow(onRetry);
    if (books.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No books available', style: TextStyle(color: AppTheme.textHint))),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final book = books[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/book-detail', arguments: book),
            child: SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCoverWidget(imageUrl: book['cover'], showBookmark: true),
                  const SizedBox(height: 6),
                  Text(
                    book['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'By: ${book['author'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerRow() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Shimmer.fromColors(
          baseColor: const Color(0xFFE8E4DF),
          highlightColor: const Color(0xFFF9F8F6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(height: 6),
              Container(
                width: 90,
                height: 11,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 4),
              Container(
                width: 70,
                height: 10,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorRow(VoidCallback onRetry) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load books. Check your connection.',
              style: AppTheme.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 120,
      decoration: BoxDecoration(color: AppTheme.buttonBg, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(
          'Find Your Books',
          style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

// ── Genre Book List Screen ─────────────────────────────────────────────────────

class _GenreBookListScreen extends StatefulWidget {
  final String genre;
  const _GenreBookListScreen({required this.genre});

  @override
  State<_GenreBookListScreen> createState() => _GenreBookListScreenState();
}

class _GenreBookListScreenState extends State<_GenreBookListScreen> {
  final _bookService = BookService();
  List<Map<String, dynamic>> _books = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final raw = await _bookService.fetchByGenre(widget.genre);
      if (mounted) {
        setState(() {
          _books = raw.map(_bookService.parse).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
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
          : _error
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load books. Check your connection.', style: AppTheme.caption, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      IconButton(icon: const Icon(Icons.refresh, color: AppTheme.textSecondary), onPressed: _load),
                    ],
                  ),
                )
              : _books.isEmpty
                  ? Center(child: Text('No books found.', style: AppTheme.caption))
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: _books.length,
                      itemBuilder: (_, i) {
                        final book = _books[i];
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/book-detail', arguments: book),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BookCoverWidget(imageUrl: book['cover'], width: 140, height: 190),
                              const SizedBox(height: 4),
                              Text(
                                book['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                book['author'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
