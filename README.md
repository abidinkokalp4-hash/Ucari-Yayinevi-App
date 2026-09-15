# UÇARI Yayınevi

Flutter Android uygulaması. UÇARI marka tasarımı, Kitapyurdu satış yönlendirmesi,
10 sayfayla sınırlı kitap önizlemesi, kalıcı favoriler, eser başvuru taslağı ve
ZEYN STÜDYO film/video bölümü içerir.

## Yayın modeli
Başvurular önce UÇARI ekibine ulaşır; ekip yayına hazırlığı ve ilgili yere
iletimi koordine eder. Basım/satış iş ortağında yürütülür. Kullanıcının verdiği
tanıtıma göre ücretsiz yayın, %20 telif, ilk 500 satışa 10.000 TL ödül ve ZEYN
yapım desteği gösterilir. Uygulama satış ya da telif tutarı hesaplamaz.
Satış sadece doğrulanan HTTPS Kitapyurdu bağlantısında gerçekleşir.

## Gerçek içerik ekleme
`assets/catalog.json` yayınevinin gerçek içerikleriyle doldurulur. Uygulama
aynı dosyanın GitHub main sürümünü açılışta/yenilemede indirir, geçerli son
kataloğu cihazda saklar; bağlantı yoksa kayıtlı katalog kullanılır.
Alternatif HTTPS katalog için `--dart-define=CATALOG_URL=...` kullanılabilir.
E-posta isteğe uygun olarak boştur; `contactEmail` alanı daha sonra doldurulur.
WhatsApp: kullanıcı tarafından sağlanan tanıtımdaki 0531 202 30 68.

Kitap alanları: `id`, `title`, `author`, `category`, `description`, `cover`
(HTTPS kapak görseli), `kitapyurduUrl`, `previewPages` (sıralı HTTPS sayfa
görselleri, en fazla ilk 10 sayfa). Tam kitap dosyasını veya 11. ve sonraki
sayfaları bu herkese açık depoya/kataloğa yüklemeyin. Uygulama tam PDF indirmez;
yalnızca ayrı önizleme görsellerini sunar ve ilk 10 URL dışındakileri atar.

Video alanları: `id`, `title`, `category`, `description`, `poster`, `url`.
`url` doğrudan HTTPS MP4/HLS medya bağlantısı olmalıdır; YouTube sayfa adresi
değildir. Yayın hakları sizde olan içerikleri ekleyin. Oynatıcıda döndürme,
1–4x yakınlaştırma, sürükleme, hız (0.5–2x), 10 saniye sarma, ses aç/kapat,
kontrol kilidi ve arka plana geçince duraklatma bulunur.

Katalog başlangıçta boştur: tasarımdaki örnek eserler gerçek eser diye kullanılmaz.
İçerik ekleme şu aşamada bu JSON üzerinden yapılır; yönetici sunucusu yoktur.

## Başvurular ve veriler
Taslak form ve seçilen PDF/Word (en fazla 25 MB) uygulamanın özel cihaz alanında
saklanır; dosyalar bir sunucuya otomatik yüklenmez. WhatsApp butonu metni
hazırlar, kullanıcı kontrol edip gönderir ve eser dosyasını sohbete kendisi
ekler. Gönderim, kabul, ödeme veya gelir konusunda sahte başarı durumu yoktur.
Taslak uygulama içinden silinebilir. Android otomatik yedeklemesi kapalıdır.

## Kontroller ve APK
GitHub Actions: Flutter 3.47.4, Java 17, `flutter analyze --no-fatal-infos`,
`flutter test`, `flutter build apk --release`. Android proje dosyaları workflow
ile üretilir; isim, internet izni, minSdk 24 ve logo uygulanır.
APK ve SHA256 çıktısı başarılı run'ın artifacts bölümündedir.
APK kurulum testi içindir; Play Store dağıtımı için yayınevinin özel imzalama
anahtarı ve mağaza bilgileri ayrıca yapılandırılmalıdır.
