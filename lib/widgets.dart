import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';

const gold = Color(0xFFBD913F),
    ink = Color(0xFF191A18),
    cream = Color(0xFFFAF7F0);
void message(BuildContext c, String text) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));
Future<void> openLink(BuildContext c, Uri uri) async {
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        c.mounted)
      message(c, 'Bağlantı açılamadı. Tarayıcı ayarlarınızı kontrol edin.');
  } catch (_) {
    if (c.mounted) message(c, 'Bağlantı açılamadı. Lütfen tekrar deneyin.');
  }
}

void openPage(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page));

class Brand extends StatelessWidget {
  final double size;
  const Brand({super.key, this.size = 52});
  @override
  Widget build(BuildContext c) => ClipOval(
    child: Image.asset(
      'assets/logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: 'UÇARI Yayınevi logosu',
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, detail;
  const EmptyState(this.icon, this.title, this.detail, {super.key});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
    child: Column(
      children: [
        Icon(icon, size: 48, color: gold),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5, color: Colors.grey),
        ),
      ],
    ),
  );
}

class Cover extends StatelessWidget {
  final String url;
  final double width, height;
  const Cover(this.url, {super.key, this.width = 70, this.height = 98});
  @override
  Widget build(BuildContext c) {
    final fallback = Container(
      color: ink,
      alignment: Alignment.center,
      child: const Icon(Icons.auto_stories_outlined, color: gold, size: 32),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: secureUrl(url) == null
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => fallback,
              ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final AppStore store;
  final Book book;
  const FavoriteButton({super.key, required this.store, required this.book});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
    listenable: store,
    builder: (c, _) => IconButton(
      tooltip: store.favorite(book) ? 'Favorilerden çıkar' : 'Favorilere ekle',
      color: gold,
      icon: Icon(store.favorite(book) ? Icons.favorite : Icons.favorite_border),
      onPressed: () async {
        try {
          await store.toggle(book);
        } catch (_) {
          if (c.mounted) message(c, 'Favoriler kaydedilemedi.');
        }
      },
    ),
  );
}
