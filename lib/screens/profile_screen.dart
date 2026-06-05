import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = SupabaseService();

  int _booksRead = 0;
  int _shelvesCount = 0;
  List<Map<String, dynamic>> _activity = [];

  final _quoteCtrl  = TextEditingController();
  final _genreCtrl  = TextEditingController();
  final _authorCtrl = TextEditingController();
  bool _editingQuote  = false;
  bool _editingGenre  = false;
  bool _editingAuthor = false;

  String get _username => supabase.auth.currentUser?.userMetadata?['username'] as String? ?? 'reader';
  String get _fullName => supabase.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'ReadingLog User';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quoteCtrl.dispose();
    _genreCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _activity = []);
    try {
      final results = await Future.wait([
        _service.getCompletedBooksCount(),
        _service.getShelvesCount(),
        _service.getRecentActivity(),
        _service.getProfile(),
      ]);
      if (!mounted) return;
      final profile = results[3] as Map<String, dynamic>?;
      setState(() {
        _booksRead    = results[0] as int;
        _shelvesCount = results[1] as int;
        _activity     = results[2] as List<Map<String, dynamic>>;
        _quoteCtrl.text  = profile?['favourite_quote']  as String? ?? '';
        _genreCtrl.text  = profile?['favourite_genre']  as String? ?? '';
        _authorCtrl.text = profile?['favourite_author'] as String? ?? '';
      });
    } catch (_) {}
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Log out?', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
        content: Text('Are you sure you want to log out?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppTheme.body)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to log out. Try again.')));
    }
  }

  // ── Profile saves ──────────────────────────────────────────────────────────

  Future<void> _saveQuote() async {
    setState(() => _editingQuote = false);
    await _service.upsertProfile({'favourite_quote': _quoteCtrl.text.trim()});
  }

  Future<void> _saveGenre() async {
    setState(() => _editingGenre = false);
    await _service.upsertProfile({'favourite_genre': _genreCtrl.text.trim()});
  }

  Future<void> _saveAuthor() async {
    setState(() => _editingAuthor = false);
    await _service.upsertProfile({'favourite_author': _authorCtrl.text.trim()});
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text('Profile', style: AppTheme.screenTitle),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.textPrimary),
                  onPressed: _confirmSignOut,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Avatar
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.inputBg,
                    child: Icon(Icons.person_outline, size: 40, color: AppTheme.textSecondary),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.buttonBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bgPrimary, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(_fullName, style: AppTheme.screenTitle.copyWith(fontSize: 18))),
            Center(child: Text('@$_username', style: AppTheme.caption)),
            const SizedBox(height: 8),

            // Favourite quote
            Center(
              child: _editingQuote
                  ? SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _quoteCtrl,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                        onSubmitted: (_) => _saveQuote(),
                        onTapOutside: (_) => _saveQuote(),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _editingQuote = true),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '"${_quoteCtrl.text.isEmpty ? 'Favourite quote here!' : _quoteCtrl.text}"',
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 14, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Email
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(supabase.auth.currentUser?.email ?? '', style: AppTheme.body),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                Expanded(child: _statCard('Books Read', '$_booksRead')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Book Shelves', '$_shelvesCount')),
              ],
            ),
            const SizedBox(height: 24),

            // Personal Info
            Text('Personal Info', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _editableInfoRow('Favourite Genre',  _genreCtrl,  _editingGenre,
              () => setState(() => _editingGenre  = true), _saveGenre),
            _editableInfoRow('Favourite Author', _authorCtrl, _editingAuthor,
              () => setState(() => _editingAuthor = true), _saveAuthor),
            const SizedBox(height: 24),

            // Recent Activity
            Text('Recent Activity', style: AppTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            if (_activity.isEmpty)
              Text('No recent activity', style: AppTheme.caption)
            else
              ..._activity.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(_activityIcon(a['type'] as String), size: 20, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] as String? ?? '', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
                          Text(a['subtitle'] as String? ?? '', style: AppTheme.caption),
                        ],
                      ),
                    ),
                    Text(_timeAgo(a['date'] as String?), style: AppTheme.caption.copyWith(fontSize: 11)),
                  ],
                ),
              )),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: AppTheme.screenTitle),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _editableInfoRow(String label, TextEditingController ctrl, bool isEditing, VoidCallback onEdit, VoidCallback onSave) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.body),
          isEditing
              ? SizedBox(
                  width: 160,
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    textAlign: TextAlign.end,
                    style: AppTheme.caption,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onSubmitted: (_) => onSave(),
                    onTapOutside: (_) => onSave(),
                  ),
                )
              : GestureDetector(
                  onTap: onEdit,
                  child: Row(
                    children: [
                      Text(ctrl.text.isEmpty ? 'Not set' : ctrl.text, style: AppTheme.caption),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'completed': return Icons.menu_book;
      case 'quote':     return Icons.format_quote;
      case 'journal':   return Icons.edit_note;
      default:          return Icons.circle_outlined;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inDays == 0)  return 'Today';
    if (diff.inDays == 1)  return 'Yesterday';
    if (diff.inDays < 7)   return '${diff.inDays} days ago';
    if (diff.inDays < 30)  return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}
