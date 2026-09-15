import 'dart:async';

import 'package:flutter/material.dart';

import 'data.dart';
import 'widgets.dart';
import 'books.dart';
import 'author.dart';
import 'studio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.load();
  runApp(UcariApp(store: store));
  unawaited(store.refresh());
}

class UcariApp extends StatelessWidget {
  final AppStore store;
  const UcariApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'UÇARI Yayınevi',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        surface: cream,
        primary: const Color(0xFF806020),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EDE6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: ink,
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
    home: Shell(store: store),
  );
}

class Shell extends StatefulWidget {
  final AppStore store;
  const Shell({super.key, required this.store});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            home(),
            BooksPage(store: widget.store),
            AuthorPage(store: widget.store),
            StudioPage(store: widget.store),
            account(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        backgroundColor: cream,
        indicatorColor: gold.withValues(alpha: .20),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Kitaplar',
          ),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Yazar Ol'),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            label: 'ZEYN',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Hesabım',
          ),
        ],
      ),
    ),
  );
  Widget home() => RefreshIndicator(
    onRefresh: widget.store.refresh,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Brand(),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UÇARI YAYINEVİ',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      letterSpacing: 1.4,
                    ),
                  ),
                  Text(
                    'Eserinizden kitabınıza.',
                    style: TextStyle(color: gold, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'İletişim',
              onPressed: () =>
                  openPage(context, ContactPage(store: widget.store)),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openPage(
            context,
            Scaffold(
              appBar: AppBar(title: const Text('Kitapları keşfet')),
              body: BooksPage(store: widget.store, autofocus: true),
            ),
          ),
          child: const InputDecorator(
            decoration: InputDecoration(prefixIcon: Icon(Icons.search)),
            child: Text(
              'Kitap, yazar veya kategori ara…',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [ink, Color(0xFF3A3121)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YAZIN  •  PAYLAŞIN  •  YAYINLAYIN',
                style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1.8),
              ),
              const SizedBox(height: 20),
              const Text(
                'Her hikaye,\nbir iz bırakır.',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: cream,
                  height: 1.15,
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => setState(() => index = 1),
                child: const Text('Kitapları Keşfet'),
              ),
            ],
          ),
        ),
        if (widget.store.warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.store.warning!,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Yeni Çıkanlar',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => setState(() => index = 1),
              child: const Text('Tümünü gör ›'),
            ),
          ],
        ),
        if (widget.store.catalog.books.isEmpty)
          const EmptyState(
            Icons.auto_stories_outlined,
            'Yeni hikâyeler yolda',
            'Kitaplar yayımlandığında kapakları ve ilk 10 sayfalık önizlemeleri burada yer alacak.',
          )
        else
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.store.catalog.books.length.clamp(0, 8),
              separatorBuilder: (_, i) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final b = widget.store.catalog.books[i];
                return SizedBox(
                  width: 125,
                  child: InkWell(
                    onTap: () => openPage(
                      context,
                      BookDetail(store: widget.store, book: b),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Cover(b.cover, width: 125, height: 174),
                        const SizedBox(height: 10),
                        Text(
                          b.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          b.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(Icons.edit_document, color: gold),
            title: const Text('Eserinizi birlikte hazırlayalım'),
            subtitle: const Text('Ücretsiz yayın • %20 telif'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => setState(() => index = 2),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: ink,
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const Icon(
              Icons.play_circle_outline,
              color: gold,
              size: 36,
            ),
            title: const Text(
              'ZEYN STÜDYO',
              style: TextStyle(color: cream, letterSpacing: 2),
            ),
            subtitle: const Text(
              'Film, video ve yeni hikâyeler',
              style: TextStyle(color: Colors.white60),
            ),
            trailing: const Icon(Icons.arrow_forward, color: gold),
            onTap: () => setState(() => index = 3),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '“İyi kitaplar, daha iyi bir dünyanın başlangıcıdır.”',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'serif', color: gold, fontSize: 16),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
  Widget account() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const SizedBox(height: 16),
      const Center(child: Brand(size: 100)),
      const SizedBox(height: 18),
      const Text(
        'Okur alanım',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Favorileriniz ve başvuru taslağınız bu cihazda saklanır.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
      const SizedBox(height: 26),
      ListTile(
        leading: const Icon(Icons.favorite_border),
        title: const Text('Favorilerim'),
        trailing: Text('${widget.store.favorites.length}  ›'),
        onTap: () => openPage(
          context,
          Scaffold(
            appBar: AppBar(title: const Text('Favorilerim')),
            body: BooksPage(store: widget.store, favoritesOnly: true),
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.drafts_outlined),
        title: const Text('Başvuru taslağım'),
        subtitle: Text(widget.store.draft['title'] ?? 'Henüz taslak yok'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(context, ApplicationPage(store: widget.store)),
      ),
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Nasıl çalışıyoruz?'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(
          context,
          Scaffold(
            appBar: AppBar(title: const Text('Yayın süreci')),
            body: AuthorPage(store: widget.store),
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.chat_outlined),
        title: const Text('Yardım ve iletişim'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openPage(context, ContactPage(store: widget.store)),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('Uygulama hakkında'),
        onTap: () => showAboutDialog(
          context: context,
          applicationName: 'UÇARI Yayınevi',
          applicationVersion: '1.1.0',
          applicationIcon: const Brand(),
          children: [
            const Text(
              'Eserinizden kitabınıza.\nKitap alışverişi Kitapyurdu üzerinden yapılır. Başvurular UÇARI ekibine iletilir.',
            ),
          ],
        ),
      ),
      const Divider(),
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Uygulama ödeme veya satış raporu toplamaz. Satış ve telif süreçleri yayınevi tarafından yürütülür.',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
      ),
    ],
  );
}
