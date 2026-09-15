import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Uri? secureUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

Uri? purchaseUrl(String value) {
  final uri = secureUrl(value);
  if (uri == null) return null;
  return [
            'kitapyurdu.com',
            'www.kitapyurdu.com',
          ].contains(uri.host.toLowerCase()) &&
          uri.path.length > 1
      ? uri
      : null;
}

String normalized(String text) =>
    text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

class Book {
  final String id, title, author, category, description, cover, buyUrl;
  final List<String> previewPages;
  Book.fromJson(Map<String, dynamic> d)
    : id = d['id'] as String,
      title = d['title'] as String,
      author = d['author'] as String,
      category = d['category'] as String,
      description = d['description'] as String? ?? '',
      cover = d['cover'] as String? ?? '',
      buyUrl = d['kitapyurduUrl'] as String? ?? '',
      previewPages = (d['previewPages'] as List? ?? [])
          .cast<String>()
          .take(10)
          .where((p) => secureUrl(p) != null)
          .toList();
}

class StudioVideo {
  final String id, title, description, category, poster, url;
  StudioVideo.fromJson(Map<String, dynamic> d)
    : id = d['id'] as String,
      title = d['title'] as String,
      category = d['category'] as String? ?? 'Video',
      description = d['description'] as String? ?? '',
      poster = d['poster'] as String? ?? '',
      url = d['url'] as String;
}

class Catalog {
  final List<Book> books;
  final List<StudioVideo> videos;
  final String email;
  Catalog(this.books, this.videos, this.email);
  factory Catalog.decode(String source) {
    final d = jsonDecode(source) as Map<String, dynamic>;
    final books = (d['books'] as List)
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();
    final videos = (d['videos'] as List)
        .map((e) => StudioVideo.fromJson(e as Map<String, dynamic>))
        .toList();
    if (books.any((b) => b.id.isEmpty || b.title.isEmpty) ||
        books.map((b) => b.id).toSet().length != books.length ||
        videos.any(
          (v) => v.id.isEmpty || v.title.isEmpty || secureUrl(v.url) == null,
        ) ||
        videos.map((v) => v.id).toSet().length != videos.length) {
      throw const FormatException('Katalog kayıtları geçersiz.');
    }
    final email = (d['contactEmail'] as String? ?? '').trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw const FormatException('İletişim adresi geçersiz.');
    }
    return Catalog(books, videos, email);
  }
}

List<Book> filterBooks(
  List<Book> books,
  String query,
  String category, {
  bool descending = false,
}) {
  final term = normalized(query.trim());
  final result = books
      .where(
        (b) =>
            (category == 'Tümü' || b.category == category) &&
            normalized('${b.title} ${b.author} ${b.category}').contains(term),
      )
      .toList();
  result.sort(
    (a, b) =>
        normalized(a.title).compareTo(normalized(b.title)) *
        (descending ? -1 : 1),
  );
  return result;
}

class AppStore extends ChangeNotifier {
  final SharedPreferences prefs;
  Catalog catalog;
  String? warning;
  bool refreshing = false;
  AppStore(this.prefs, this.catalog);
  static Future<AppStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    var catalog = Catalog.decode(
      await rootBundle.loadString('assets/catalog.json'),
    );
    final cache = prefs.getString('catalog');
    if (cache != null) {
      try {
        catalog = Catalog.decode(cache);
      } catch (_) {
        /* Keep valid bundled data. */
      }
    }
    return AppStore(prefs, catalog);
  }

  Set<String> get favorites => (prefs.getStringList('favorites') ?? []).toSet();
  bool favorite(Book b) => favorites.contains(b.id);
  Future<void> toggle(Book b) async {
    final ids = favorites;
    if (!ids.add(b.id)) ids.remove(b.id);
    if (!await prefs.setStringList('favorites', ids.toList())) {
      throw StateError('Kaydedilemedi');
    }
    notifyListeners();
  }

  Map<String, String> get draft {
    try {
      return Map<String, String>.from(
        jsonDecode(prefs.getString('draft') ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDraft(Map<String, String> data) async {
    if (!await prefs.setString('draft', jsonEncode(data))) {
      throw StateError('Taslak kaydedilemedi');
    }
    notifyListeners();
  }

  Future<void> clearDraft() async {
    if (!await prefs.remove('draft')) throw StateError('Taslak silinemedi');
    notifyListeners();
  }

  Future<void> refresh() async {
    if (refreshing) return;
    refreshing = true;
    warning = null;
    notifyListeners();
    const source = String.fromEnvironment(
      'CATALOG_URL',
      defaultValue: 'https://raw.githubusercontent.com/abidinkokalp4-hash/Ucari-Yayinevi-App/main/assets/catalog.json',
    );
    try {
      final uri = secureUrl(source);
      if (uri == null) throw const FormatException();
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.bodyBytes.length > 2000000) {
        throw const FormatException();
      }
      final content = utf8.decode(response.bodyBytes);
      final updated = Catalog.decode(content);
      await prefs.setString('catalog', content);
      catalog = updated;
    } catch (_) {
      warning = 'Katalog güncellenemedi. Kayıtlı içerikler gösteriliyor.';
    }
    refreshing = false;
    notifyListeners();
  }
}
