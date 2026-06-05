import 'dart:convert';
import 'package:http/http.dart' as http;

class BookService {
  static const _base = 'https://www.googleapis.com/books/v1/volumes';
  static const _key = 'AIzaSyD9up-0tUCVJpq0se0lbcq8efTH0BSpfbE';

  Future<List<Map<String, dynamic>>> search(String query) async {
    final res = await http.get(Uri.parse('$_base?q=${Uri.encodeComponent(query)}&maxResults=10&key=$_key'));
    final items = (jsonDecode(res.body)['items'] as List?) ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchNewReleases() async {
    final year = DateTime.now().year;
    final responses = await Future.wait([
      http.get(Uri.parse('$_base?q=subject:fiction+$year&orderBy=newest&printType=books&maxResults=20&langRestrict=en&key=$_key')),
      http.get(Uri.parse('$_base?q=subject:fiction+${year - 1}&orderBy=newest&printType=books&maxResults=20&langRestrict=en&key=$_key')),
    ]);
    final all = <Map<String, dynamic>>[];
    for (final res in responses) {
      final items = jsonDecode(res.body)['items'] as List? ?? [];
      all.addAll(items.cast<Map<String, dynamic>>());
    }
    all.sort((a, b) {
      return _parseDate((b['volumeInfo'] as Map?)?['publishedDate'] as String?)
          .compareTo(_parseDate((a['volumeInfo'] as Map?)?['publishedDate'] as String?));
    });
    // deduplicate by id within the list
    final seen = <String>{};
    return all.where((item) => seen.add(item['id'] as String? ?? '')).take(10).toList();
  }

  Future<List<Map<String, dynamic>>> fetchPopular() async {
    final res = await http.get(Uri.parse(
      '$_base?q=bestseller+fiction&orderBy=relevance&printType=books&maxResults=10&langRestrict=en&key=$_key',
    ));
    final items = jsonDecode(res.body)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchRecommendations(String query) async {
    final res = await http.get(Uri.parse(
      '$_base?q=$query&orderBy=relevance&printType=books&maxResults=15&langRestrict=en&key=$_key',
    ));
    final items = jsonDecode(res.body)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  DateTime _parseDate(String? s) {
    if (s == null || s.length < 4) return DateTime(0);
    try {
      final y = int.tryParse(s.substring(0, 4)) ?? 0;
      final m = s.length >= 7 ? int.tryParse(s.substring(5, 7)) ?? 1 : 1;
      final d = s.length >= 10 ? int.tryParse(s.substring(8, 10)) ?? 1 : 1;
      return DateTime(y, m, d);
    } catch (_) {
      return DateTime(0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchByGenre(String genre) async {
    final res = await http.get(Uri.parse(
      '$_base?q=subject:${Uri.encodeComponent(genre)}&orderBy=relevance&printType=books&maxResults=20&langRestrict=en&key=$_key',
    ));
    final items = jsonDecode(res.body)['items'] as List? ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> similar(String author, String category) async {
    final q = category.isNotEmpty
        ? 'subject:${Uri.encodeComponent(category)}'
        : 'inauthor:${Uri.encodeComponent(author)}';
    final res = await http.get(Uri.parse('$_base?q=$q&maxResults=10&key=$_key'));
    final items = (jsonDecode(res.body)['items'] as List?) ?? [];
    return items.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> parse(Map<String, dynamic> item) {
    final v = item['volumeInfo'] as Map<String, dynamic>? ?? {};
    return {
      'id': item['id'],
      'title': v['title'] ?? 'Unknown',
      'author': (v['authors'] as List?)?.join(', ') ?? 'Unknown',
      'cover': (v['imageLinks']?['thumbnail'] as String?)?.replaceAll('http:', 'https:') ?? '',
      'pages': v['pageCount'] ?? 0,
      'description': v['description'] ?? '',
      'category': (v['categories'] as List?)?.firstOrNull ?? '',
      'rating': (v['averageRating'] as num?)?.toDouble(),
      'ratingsCount': (v['ratingsCount'] as int?) ?? 0,
      'language': v['language'] ?? '',
    };
  }
}
