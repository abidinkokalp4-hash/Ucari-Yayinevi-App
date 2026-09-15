import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucari_yayinevi/data.dart';
import 'package:ucari_yayinevi/main.dart';
import 'package:ucari_yayinevi/author.dart';

Book book(
  String id,
  String title,
  String author,
  String category, {
  List<String> pages = const [],
}) => Book.fromJson({
  'id': id,
  'title': title,
  'author': author,
  'category': category,
  'previewPages': pages,
});
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Purchase links only allow HTTPS Kitapyurdu book destinations', () {
    expect(
      purchaseUrl('https://www.kitapyurdu.com/kitap/eser/123.html'),
      isNotNull,
    );
    for (final url in [
      'http://kitapyurdu.com/kitap/x',
      'https://kitapyurdu.com.evil.test/kitap/x',
      'https://evil.test/kitapyurdu.com',
      'https://user@kitapyurdu.com/kitap/x',
      'javascript:alert(1)',
      'https://kitapyurdu.com/',
    ]) {
      expect(purchaseUrl(url), isNull, reason: url);
    }
  });
  test('Preview never exposes page eleven', () {
    final b = book(
      'a',
      'Test',
      'Yazar',
      'Roman',
      pages: List.generate(
        25,
        (i) => 'https://example.org/preview/${i + 1}.jpg',
      ),
    );
    expect(b.previewPages.length, 10);
    expect(b.previewPages.last, endsWith('/10.jpg'));
    expect(b.previewPages.any((p) => p.endsWith('/11.jpg')), isFalse);
  });
  test('Turkish search combines author and category and supports sort', () {
    final books = [
      book('1', 'İz', 'Işık', 'Roman'),
      book('2', 'Ada', 'Selin', 'Şiir'),
    ];
    expect(filterBooks(books, 'iz', 'Tümü').single.id, '1');
    expect(filterBooks(books, 'ışık', 'Roman').single.id, '1');
    expect(filterBooks(books, 'selin', 'Roman'), isEmpty);
    expect(filterBooks(books, '', 'Tümü').first.id, '2');
    expect(filterBooks(books, '', 'Tümü', descending: true).first.id, '1');
    expect(books.first.id, '1');
  });
  test('Catalog rejects duplicate IDs and invalid video URLs', () {
    final entry = {
      'id': 'a',
      'title': 'Test',
      'author': 'Yazar',
      'category': 'Roman',
    };
    expect(
      () => Catalog.decode(
        jsonEncode({
          'books': [entry, entry],
          'videos': [],
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => Catalog.decode(
        jsonEncode({
          'books': [],
          'videos': [
            {'id': 'v', 'title': 'Film', 'url': 'http://example.org/v.mp4'},
          ],
        }),
      ),
      throwsFormatException,
    );
  });
  test('Favorites and drafts survive reopening and can be deleted', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = AppStore(prefs, Catalog([], [], ''));
    final b = book('a', 'Test', 'Yazar', 'Roman');
    await store.toggle(b);
    await store.saveDraft({'title': 'Eserim', 'name': 'Okur'});
    final reopened = AppStore(
      await SharedPreferences.getInstance(),
      Catalog([], [], ''),
    );
    expect(reopened.favorite(b), isTrue);
    expect(reopened.draft['title'], 'Eserim');
    await reopened.toggle(b);
    await reopened.clearDraft();
    expect(reopened.favorite(b), isFalse);
    expect(reopened.draft, isEmpty);
  });
  testWidgets(
    'Small phone navigation and empty real catalog render without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = AppStore(
        await SharedPreferences.getInstance(),
        Catalog([], [], ''),
      );
      await tester.pumpWidget(UcariApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Yeni hikâyeler yolda'), findsOneWidget);
      for (final label in ['Kitaplar', 'ZEYN', 'Hesabım', 'Yazar Ol']) {
        await tester.tap(find.widgetWithText(NavigationDestination, label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('Application saves an actual draft and never reports sent', (
    tester,
  ) async {
    final store = AppStore(
      await SharedPreferences.getInstance(),
      Catalog([], [], ''),
    );
    await tester.pumpWidget(MaterialApp(home: ApplicationPage(store: store)));
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Yazar');
    await tester.enterText(find.byType(TextFormField).at(2), 'Eser Taslağı');
    await tester.dragUntilVisible(
      find.text('Taslağı Kaydet'),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taslağı Kaydet'));
    await tester.pumpAndSettle();
    expect(store.draft['title'], 'Eser Taslağı');
    expect(
      find.text('Taslak cihazınıza kaydedildi. Henüz gönderilmedi.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
