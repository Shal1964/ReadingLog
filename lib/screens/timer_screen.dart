import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const _totalSeconds = 1500;
  final _service = SupabaseService();

  Timer? _ticker;
  int _secondsLeft = _totalSeconds;
  bool _isRunning = false;
  String? _selectedBookId;
  String? _selectedBookTitle;
  List<Map<String, dynamic>> _readingBooks = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _service.getBooks('reading');
      if (mounted) setState(() => _readingBooks = books);
    } catch (_) {}
  }

  String get _formatted =>
      '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:'
      '${(_secondsLeft % 60).toString().padLeft(2, '0')}';

  void _startPause() {
    if (_isRunning) {
      _ticker?.cancel();
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft == 0) {
          _ticker?.cancel();
          _onSessionComplete();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _reset() {
    _ticker?.cancel();
    setState(() { _secondsLeft = _totalSeconds; _isRunning = false; });
  }

  Future<void> _onSessionComplete() async {
    if (_selectedBookId != null) {
      try {
        await _service.addReadingMinutes(_selectedBookId!, 25);
      } catch (_) {}
    }
    if (mounted) _showCompleteDialog();
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgPrimary,
        title: Text('Session Complete!', style: AppTheme.screenTitle.copyWith(fontSize: 18)),
        content: Text('+25 minutes logged', style: AppTheme.body),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _reset(); },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _selectBook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgPrimary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a Book', style: AppTheme.screenTitle),
            const SizedBox(height: 16),
            if (_readingBooks.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('No books in Reading shelf', style: AppTheme.caption),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _readingBooks.length,
                  itemBuilder: (_, i) {
                    final b = _readingBooks[i];
                    return ListTile(
                      title: Text(b['title'] ?? '', style: AppTheme.body),
                      subtitle: Text(b['author'] ?? '', style: AppTheme.caption),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        setState(() {
                          _selectedBookId = b['book_id'];
                          _selectedBookTitle = b['title'];
                        });
                        Navigator.pop(sheetCtx);
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_secondsLeft / _totalSeconds);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _TimerRing(progress: progress, label: _formatted),
            const SizedBox(height: 20),
            Text(
              _selectedBookTitle ?? 'Select a book to start',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            _buildControls(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.textPrimary, size: 28),
          onPressed: _reset,
        ),
        const SizedBox(width: 24),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.buttonBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.buttonBorder, width: 2),
          ),
          child: IconButton(
            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: AppTheme.textPrimary, size: 32),
            onPressed: _startPause,
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.library_books_outlined, color: AppTheme.textPrimary, size: 28),
          onPressed: () => _selectBook(context),
        ),
      ],
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double progress;
  final String label;

  const _TimerRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(240, 240),
      painter: _RingPainter(progress),
      child: SizedBox(
        width: 240,
        height: 240,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.playfairDisplay(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: AppTheme.timerText,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final trackPaint = Paint()
      ..color = AppTheme.timerTrack.withValues(alpha: 0.4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppTheme.timerFilled
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
