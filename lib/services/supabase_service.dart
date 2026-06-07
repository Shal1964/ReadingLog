import '../main.dart';

class SupabaseService {
  Future<List<Map<String, dynamic>>> getBooks(String status) async {
    final data = await supabase.from('books').select().eq('status', status);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getReadingBooks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final data = await supabase.from('books').select()
        .eq('user_id', user.id).eq('status', 'reading')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getWishlistBooks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final data = await supabase.from('books').select()
        .eq('user_id', user.id).eq('status', 'wishlist')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCompletedBooks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final data = await supabase.from('books').select()
        .eq('user_id', user.id).eq('status', 'completed')
        .order('completed_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getBooksByGenre(String genre) async {
    final data = await supabase.from('books').select().eq('genre', genre);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> getBookByApiId(String apiId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await supabase.from('books').select()
          .eq('user_id', user.id)
          .eq('api_id', apiId)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> upsertBook(Map<String, dynamic> fields) async {
    final existing = await getBookByApiId(fields['api_id'] as String);
    if (existing != null) {
      final updates = <String, dynamic>{
        'status': fields['status'],
        'updated_at': DateTime.now().toIso8601String(),
      };
      await supabase.from('books').update(updates).eq('book_id', existing['book_id']);
      return Map<String, dynamic>.from(existing)..addAll(updates);
    }
    final result = await supabase.from('books').insert(fields).select().single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> addBook(Map<String, dynamic> book) async {
    await supabase.from('books').insert(book);
  }

  Future<void> deleteBook(String bookId) async {
    await supabase.from('books').delete().eq('book_id', bookId);
  }

  Future<void> updatePage(String bookId, int page) async {
    await supabase.from('books').update({
      'current_page': page,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('book_id', bookId);
  }

  Future<void> updatePageWithComplete(String bookId, int page, int totalPages) async {
    final updates = <String, dynamic>{
      'current_page': page,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (totalPages > 0 && page >= totalPages) {
      updates['status'] = 'completed';
      updates['completed_at'] = DateTime.now().toIso8601String();
    }
    await supabase.from('books').update(updates).eq('book_id', bookId);
  }

  Future<void> updateBookField(String bookId, String field, dynamic value) async {
    await supabase.from('books').update({field: value}).eq('book_id', bookId);
  }

  Future<void> addReadingMinutes(String bookId, int minutes) async {
    final row = await supabase.from('books').select('total_reading_minutes').eq('book_id', bookId).single();
    final current = (row['total_reading_minutes'] as int?) ?? 0;
    await supabase.from('books').update({'total_reading_minutes': current + minutes}).eq('book_id', bookId);
  }

  Future<int> getCompletedBooksCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;
    final data = await supabase.from('books').select('book_id').eq('user_id', user.id).eq('status', 'completed');
    return (data as List).length;
  }

  Future<List<Map<String, dynamic>>> getQuotes(String bookId) async {
    final data = await supabase.from('quotes').select().eq('book_id', bookId)
        .order('date_added', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addQuote(String bookId, String text, int? page) async {
    await supabase.from('quotes').insert({'book_id': bookId, 'quote_text': text, 'page_number': page});
  }

  Future<void> deleteQuote(String quoteId) async {
    await supabase.from('quotes').delete().eq('quote_id', quoteId);
  }

  Future<List<Map<String, dynamic>>> getJournals(String bookId) async {
    final data = await supabase.from('journals').select().eq('book_id', bookId)
        .order('date_added', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addJournal(String bookId, String text, String? chapter) async {
    await supabase.from('journals').insert({'book_id': bookId, 'entry_text': text, 'chapter_reference': chapter});
  }

  Future<void> deleteJournal(String journalId) async {
    await supabase.from('journals').delete().eq('journal_id', journalId);
  }

  Future<List<Map<String, dynamic>>> getShelves() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final data = await supabase.from('shelves').select()
        .eq('user_id', user.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getShelvesWithCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];
    final data = await supabase.from('shelves').select('*, shelf_books(count)')
        .eq('user_id', user.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> getShelvesCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;
    final data = await supabase.from('shelves').select('shelf_id').eq('user_id', user.id);
    return (data as List).length;
  }

  Future<void> addShelf(String name) async {
    final user = supabase.auth.currentUser!;
    await supabase.from('shelves').insert({'user_id': user.id, 'name': name});
  }

  Future<void> deleteShelf(String shelfId) async {
    await supabase.from('shelves').delete().eq('shelf_id', shelfId);
  }

  Future<List<Map<String, dynamic>>> getShelfBooks(String shelfId) async {
    final data = await supabase.from('shelf_books').select('book_id, books(*)')
        .eq('shelf_id', shelfId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addBookToShelf(String shelfId, String bookId) async {
    final existing = await supabase.from('shelf_books').select()
        .eq('shelf_id', shelfId).eq('book_id', bookId);
    if ((existing as List).isNotEmpty) throw Exception('already_in_shelf');
    await supabase.from('shelf_books').insert({'shelf_id': shelfId, 'book_id': bookId});
  }

  Future<void> removeBookFromShelf(String shelfId, String bookId) async {
    await supabase.from('shelf_books').delete()
        .eq('shelf_id', shelfId).eq('book_id', bookId);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final data = await supabase.from('profiles').select().eq('user_id', user.id).single();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertProfile(Map<String, dynamic> fields) async {
    final user = supabase.auth.currentUser!;
    await supabase.from('profiles').upsert({...fields, 'user_id': user.id});
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final userId = supabase.auth.currentUser!.id;
    final results = await Future.wait([
      supabase.from('books').select('title, completed_at')
          .eq('user_id', userId).eq('status', 'completed')
          .order('completed_at', ascending: false).limit(5),
      supabase.from('journals').select('entry_text, date_added, books!inner(title, user_id)')
          .eq('books.user_id', userId)
          .order('date_added', ascending: false).limit(5),
      supabase.from('quotes').select('quote_text, date_added, books!inner(title, user_id)')
          .eq('books.user_id', userId)
          .order('date_added', ascending: false).limit(5),
    ]);

    final activities = <Map<String, dynamic>>[];
    for (final b in (results[0] as List)) {
      final m = b as Map<String, dynamic>;
      if (m['completed_at'] != null) {
        activities.add({'type': 'completed', 'title': m['title'] ?? '', 'subtitle': 'Finished reading', 'date': m['completed_at']});
      }
    }
    for (final j in (results[1] as List)) {
      final m = j as Map<String, dynamic>;
      activities.add({'type': 'journal', 'title': (m['books'] as Map?)?['title'] ?? '', 'subtitle': 'Wrote a journal entry', 'date': m['date_added']});
    }
    for (final q in (results[2] as List)) {
      final m = q as Map<String, dynamic>;
      activities.add({'type': 'quote', 'title': (m['books'] as Map?)?['title'] ?? '', 'subtitle': 'Saved a quote', 'date': m['date_added']});
    }
    activities.sort((a, b) {
      final da = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    return activities.take(5).toList();
  }
}
