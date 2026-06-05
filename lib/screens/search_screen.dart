import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/book_service.dart';
import '../widgets/book_cover_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _bookService = BookService();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  List<String> _recents = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recents = prefs.getStringList('recent_searches') ?? []);
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_searches') ?? [];
    list.remove(query);
    list.insert(0, query);
    await prefs.setStringList('recent_searches', list.take(10).toList());
    setState(() => _recents = list.take(10).toList());
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(q));
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final raw = await _bookService.search(q);
      if (mounted) setState(() => _results = raw.map(_bookService.parse).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onSelect(Map<String, dynamic> book) {
    _saveRecent(book['title'] ?? '');
    Navigator.pushNamed(context, '/book-detail', arguments: book);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onChanged: _onChanged,
                      decoration: AppTheme.inputDecoration('Search books, authors...').copyWith(
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textHint),
                                onPressed: () {
                                  _ctrl.clear();
                                  setState(() => _results = []);
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_searching) const LinearProgressIndicator(color: AppTheme.textPrimary, backgroundColor: AppTheme.progressTrack),
            Expanded(
              child: _ctrl.text.isEmpty
                  ? _buildRecents()
                  : _results.isEmpty && !_searching
                      ? Center(child: Text('No results found', style: AppTheme.caption))
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecents() {
    if (_recents.isEmpty) {
      return Center(child: Text('Start typing to search books', style: AppTheme.caption));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Recent Searches', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600)),
        ),
        ..._recents.map((r) => ListTile(
              leading: const Icon(Icons.history, color: AppTheme.textSecondary),
              title: Text(r, style: AppTheme.body),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                _ctrl.text = r;
                _doSearch(r);
              },
            )),
      ],
    );
  }

  Widget _buildResults() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(color: AppTheme.inputBg, height: 1),
      itemBuilder: (_, i) {
        final book = _results[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: BookCoverWidget(imageUrl: book['cover'], width: 60, height: 87),
          title: Text(book['title'] ?? '', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500), maxLines: 2),
          subtitle: Text(book['author'] ?? '', style: AppTheme.caption),
          onTap: () => _onSelect(book),
        );
      },
    );
  }
}
