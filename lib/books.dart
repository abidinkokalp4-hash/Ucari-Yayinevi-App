import 'package:flutter/material.dart';

import 'data.dart';
import 'widgets.dart';

class BooksPage extends StatefulWidget {
  final AppStore store;
  final bool favoritesOnly, autofocus;
  const BooksPage({
    super.key,
    required this.store,
    this.favoritesOnly = false,
    this.autofocus = false,
  });
  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  String query = '', category = 'Tümü';
  bool descending = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final source = widget.store.catalog.books
          .where((b) => !widget.favoritesOnly || widget.store.favorite(b))
          .toList();
      final categories = ['Tümü', ...source.map((b) => b.category).toSet()];
      final selected = categories.contains(category) ? category : 'Tümü';
      final results = filterBooks(
        source,
        query,
        selected,
        descending: descending,
      );
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.favoritesOnly ? 'Sevdiğiniz hikâyeler' : 'Kitaplar',
                    style: const TextStyle(fontFamily: 'serif', fontSize: 28),
                  ),
                ),
                PopupMenuButton<bool>(
                  tooltip: 'Kitapları sırala',
                  onSelected: (v) => setState(() => descending = v),
                  itemBuilder: (_) => [
                    CheckedPopupMenuItem(
                      value: false,
                      checked: !descending,
                      child: const Text('Başlık A → Z'),
                    ),
                    CheckedPopupMenuItem(
                      value: true,
                      checked: descending,
                      child: const Text('Başlık Z → A'),
                    ),
                  ],
                  icon: const Icon(Icons.sort),
                ),
                IconButton(
                  tooltip: 'Kataloğu yenile',
                  onPressed: widget.store.refreshing
                      ? null
                      : widget.store.refresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: widget.autofocus,
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Kitap, yazar veya kategori ara…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 62,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(categories[i]),
                selected: categories[i] == selected,
                onSelected: (_) => setState(() => category = categories[i]),
              ),
            ),
          ),
          if (widget.store.refreshing)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.store.refresh,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (results.isEmpty)
                    EmptyState(
                      Icons.menu_book_outlined,
                      widget.favoritesOnly
                          ? 'Favori kitap bulunamadı'
                          : 'Kitap bulunamadı',
                      source.isEmpty
                          ? 'Yayımlanan kitaplar burada görünecek.'
                          : 'Arama veya kategori seçiminizi değiştirin.',
                    ),
                  for (final b in results)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(4),
                        leading: Cover(b.cover, width: 55, height: 80),
                        title: Text(
                          b.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${b.author}\n${b.category}',
                          style: const TextStyle(height: 1.5),
                        ),
                        trailing: FavoriteButton(store: widget.store, book: b),
                        onTap: () => openPage(
                          context,
                          BookDetail(store: widget.store, book: b),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class BookDetail extends StatelessWidget {
  final AppStore store;
  final Book book;
  const BookDetail({super.key, required this.store, required this.book});
  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: ink,
    appBar: AppBar(
      backgroundColor: ink,
      foregroundColor: cream,
      actions: [FavoriteButton(store: store, book: book)],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Cover(book.cover, width: 190, height: 275)),
          const SizedBox(height: 30),
          Text(
            book.title,
            style: const TextStyle(
              color: cream,
              fontFamily: 'serif',
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.author,
            style: const TextStyle(color: Colors.white60, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(book.category)),
          ),
          const SizedBox(height: 16),
          Text(
            book.description.isEmpty
                ? 'Kitap açıklaması yakında eklenecek.'
                : book.description,
            style: const TextStyle(color: cream, height: 1.7, fontSize: 16),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: book.previewPages.isEmpty
                ? null
                : () => openPage(c, PreviewPage(book: book)),
            style: OutlinedButton.styleFrom(
              foregroundColor: cream,
              disabledForegroundColor: Colors.white38,
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: gold),
            ),
            child: Text(
              book.previewPages.isEmpty
                  ? 'Önizleme hazırlanıyor'
                  : 'İlk ${book.previewPages.length} sayfayı ücretsiz oku',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: purchaseUrl(book.buyUrl) == null
                ? null
                : () => openLink(c, purchaseUrl(book.buyUrl)!),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Kitapyurdu’nda Satın Al'),
          ),
          const SizedBox(height: 12),
          Text(
            purchaseUrl(book.buyUrl) == null
                ? 'Satış bağlantısı henüz eklenmedi.'
                : 'Güncel fiyat, ödeme ve teslimat bilgileri Kitapyurdu’nda gösterilir.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class PreviewPage extends StatefulWidget {
  final Book book;
  const PreviewPage({super.key, required this.book});
  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final controller = PageController();
  int page = 0;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void go(int v) => controller.animateToPage(
    v,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) {
    final pages = widget.book.previewPages.take(10).toList();
    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        backgroundColor: ink,
        foregroundColor: cream,
        title: Text(widget.book.title),
      ),
      body: SafeArea(
        child: pages.isEmpty
            ? const EmptyState(Icons.menu_book, 'Önizleme henüz yok', '')
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: pages.length,
                      onPageChanged: (v) => setState(() => page = v),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: Image.network(
                              pages[i],
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                  ? child
                                  : const CircularProgressIndicator(
                                      color: gold,
                                    ),
                              errorBuilder: (_, error, stack) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Sayfa yüklenemedi.',
                                    style: TextStyle(color: cream),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await NetworkImage(pages[i]).evict();
                                      if (mounted) setState(() {});
                                    },
                                    child: const Text('Tekrar dene'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Önceki sayfa',
                          onPressed: page > 0 ? () => go(page - 1) : null,
                          icon: const Icon(Icons.chevron_left, color: gold),
                        ),
                        Expanded(
                          child: Text(
                            '${page + 1} / ${pages.length} • Ücretsiz önizleme',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: cream),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sonraki sayfa',
                          onPressed: page < pages.length - 1
                              ? () => go(page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right, color: gold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
