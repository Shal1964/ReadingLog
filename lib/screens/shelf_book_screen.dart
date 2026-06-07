import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/book_cover_widget.dart';

class ShelfBookScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  const ShelfBookScreen({super.key, required this.book});

  @override
  State<ShelfBookScreen> createState() => _ShelfBookScreenState();
}

class _ShelfBookScreenState extends State<ShelfBookScreen> {
  late Map<String, dynamic> _book;
  final _reviewCtrl         = TextEditingController();
  final _reviewFocus        = FocusNode();
  final _afterThoughtsCtrl  = TextEditingController();
  final _afterThoughtsFocus = FocusNode();
  final _service            = SupabaseService();
  Timer? _debounce;
  Timer? _afterThoughtsDebounce;
  int _starRating = 0;

  static const _allTags = [
    '#Emotional', '#Romance', '#Angst', '#Fantasy',
    '#DarkAcademia', '#Cozy', '#Mystery', '#Thriller', '#YA',
  ];

  @override
  void initState() {
    super.initState();
    _book = Map<String, dynamic>.from(widget.book);
    _reviewCtrl.text        = _book['notes'] ?? '';
    _afterThoughtsCtrl.text = _book['after_thoughts'] ?? '';
    _starRating             = (_book['star_rating'] as int?) ?? 0;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _afterThoughtsDebounce?.cancel();
    _saveReviewNow();
    _saveAfterThoughtsNow();
    _reviewCtrl.dispose();
    _reviewFocus.dispose();
    _afterThoughtsCtrl.dispose();
    _afterThoughtsFocus.dispose();
    super.dispose();
  }

  List<String> get _selectedTags {
    final raw = _book['tags'];
    if (raw == null) return [];
    if (raw is List) return List<String>.from(raw);
    return [];
  }

  Future<void> _pickDate(String field) async {
    final bookId = _book['book_id'] as String?;
    if (bookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save: book has no ID. Try reopening from your library.')),
      );
      return;
    }
    DateTime initial;
    try {
      initial = _book[field] != null
          ? DateTime.parse(_book[field].toString())
          : DateTime.now();
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final iso = picked.toIso8601String().split('T')[0];
    try {
      await _service.updateBookField(bookId, field, iso);
      setState(() => _book[field] = iso);
      if (field == 'start_date' && _book['end_date'] == null) {
        await _service.updateBookField(bookId, 'status', 'reading');
        await _service.updateBookField(bookId, 'updated_at', DateTime.now().toIso8601String());
        setState(() => _book['status'] = 'reading');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as currently reading!')),
          );
        }
      }
      if (field == 'end_date') {
        await _service.updateBookField(bookId, 'status', 'completed');
        await _service.updateBookField(bookId, 'completed_at', iso);
        setState(() {
          _book['status'] = 'completed';
          _book['completed_at'] = iso;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as completed!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _clearDate(String field) async {
    final bookId = _book['book_id'] as String?;
    if (bookId == null) return;
    try {
      await _service.updateBookField(bookId, field, null);
      setState(() => _book[field] = null);
      if (field == 'end_date') {
        await _service.updateBookField(bookId, 'status', 'reading');
        await _service.updateBookField(bookId, 'completed_at', null);
        setState(() {
          _book['status'] = 'reading';
          _book['completed_at'] = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Moved back to Currently Reading')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clear failed: $e')),
        );
      }
    }
  }

  Future<void> _editProgress() async {
    final bookId = _book['book_id'] as String?;
    if (bookId == null) return;
    final total = (_book['total_pages'] as int?) ?? 0;
    final ctrl = TextEditingController(
      text: ((_book['current_page'] as int?) ?? 0).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Update Progress', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: AppTheme.inputDecoration('Current page${total > 0 ? ' (of $total)' : ''}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.body),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(ctrl.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await _service.updatePageWithComplete(bookId, result, total);
    setState(() => _book['current_page'] = result);
  }

  void _saveReview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _saveReviewNow);
  }

  void _saveReviewNow() {
    final bookId = _book['book_id'] as String?;
    if (bookId == null) return;
    _service.updateBookField(bookId, 'notes', _reviewCtrl.text.trim());
  }

  void _saveAfterThoughts() {
    _afterThoughtsDebounce?.cancel();
    _afterThoughtsDebounce = Timer(const Duration(milliseconds: 800), _saveAfterThoughtsNow);
  }

  void _saveAfterThoughtsNow() {
    final bookId = _book['book_id'] as String?;
    if (bookId == null) return;
    _service.updateBookField(bookId, 'after_thoughts', _afterThoughtsCtrl.text.trim());
  }

  Future<void> _saveStarRating(int rating) async {
    final bookId = _book['book_id'] as String?;
    if (bookId == null) return;
    setState(() => _starRating = rating);
    await _service.updateBookField(bookId, 'star_rating', rating);
  }

  Future<void> _toggleTag(String tag) async {
    final current = List<String>.from(_selectedTags);
    current.contains(tag) ? current.remove(tag) : current.add(tag);
    await _service.updateBookField(_book['book_id'], 'tags', current.isEmpty ? null : current);
    setState(() => _book['tags'] = current.isEmpty ? null : current);
  }

  void _showTagSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Tags', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () async {
                      await _toggleTag(tag);
                      setSheetState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.buttonBg : Colors.white,
                        border: Border.all(color: const Color(0xFFC5C1BB)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: AppTheme.body.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF5A5652),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = (_book['current_page'] as int?) ?? 0;
    final total = (_book['total_pages'] as int?) ?? 0;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('ReadingLog', style: AppTheme.appName.copyWith(fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Book info
          _card(Row(
            children: [
              BookCoverWidget(imageUrl: _book['cover_url'], width: 80, height: 115),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _book['title'] ?? '',
                      style: AppTheme.body.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text('by : ${_book['author'] ?? ''}', style: AppTheme.caption),
                    const SizedBox(height: 4),
                    Text('${_book['total_pages'] ?? 0} Pages', style: AppTheme.caption),
                    const SizedBox(height: 4),
                    Text('Genre : ${_book['genre'] ?? '-'}', style: AppTheme.caption),
                  ],
                ),
              ),
            ],
          )),
          const SizedBox(height: 12),

          _card(Column(
            children: [
              _dateRow('Start Date', 'start_date'),
              const Divider(height: 20, color: Color(0xFFE8E4DF)),
              _dateRow('End Date', 'end_date'),
            ],
          )),
          const SizedBox(height: 12),
          _card(GestureDetector(
            onTap: _editProgress,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.progressTrack,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.progressFilled),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('Page $current / $total', style: AppTheme.caption),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),

          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notes', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewCtrl,
                focusNode: _reviewFocus,
                maxLines: null,
                minLines: 4,
                style: AppTheme.body.copyWith(fontSize: 13, height: 1.6),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write your thoughts here',
                  hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint, fontSize: 13),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => _saveReview(),
                onTapOutside: (_) => _reviewFocus.unfocus(),
              ),
            ],
          )),
          const SizedBox(height: 12),

          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('After Thoughts & Review', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              TextField(
                controller: _afterThoughtsCtrl,
                focusNode: _afterThoughtsFocus,
                maxLines: null,
                minLines: 5,
                style: AppTheme.body.copyWith(fontSize: 13, height: 1.6),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Your final thoughts, review, or takeaways...',
                  hintStyle: AppTheme.body.copyWith(color: AppTheme.textHint, fontSize: 13),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => _saveAfterThoughts(),
                onTapOutside: (_) => _afterThoughtsFocus.unfocus(),
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE8E4DF), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Rating', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _starRating;
                      return GestureDetector(
                        onTap: () => _saveStarRating(i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 28,
                            color: filled ? AppTheme.starFilled : AppTheme.textHint,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          )),
          const SizedBox(height: 12),

          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tags', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
                  GestureDetector(
                    onTap: _showTagSheet,
                    child: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              if (_selectedTags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E4DF),
                      border: Border.all(color: const Color(0xFFC5C1BB)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: AppTheme.body.copyWith(fontSize: 13, color: const Color(0xFF5A5652)),
                    ),
                  )).toList(),
                ),
              ],
            ],
          )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _dateRow(String label, String field) {
    final hasDate = _book[field] != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
        Row(
          children: [
            GestureDetector(
              onTap: () => _pickDate(field),
              child: Text(
                hasDate ? _formatDate(_book[field]) : 'Set date',
                style: AppTheme.body.copyWith(
                  color: hasDate ? AppTheme.textPrimary : AppTheme.textHint,
                ),
              ),
            ),
            if (hasDate) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _clearDate(field),
                child: const Icon(Icons.cancel, size: 18, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5D1CB)),
      ),
      child: child,
    );
  }

  String _formatDate(dynamic raw) {
    try {
      final dt = DateTime.parse(raw.toString());
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${months[dt.month - 1]} , ${dt.day} , ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
