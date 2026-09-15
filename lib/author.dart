import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data.dart';
import 'widgets.dart';

class AuthorPage extends StatelessWidget {
  final AppStore store;
  const AuthorPage({super.key, required this.store});
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 12),
      const Center(child: Brand(size: 94)),
      const SizedBox(height: 24),
      const Text(
        'Modern yayıncılığa\nhoş geldiniz.',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'serif', fontSize: 32, height: 1.2),
      ),
      const SizedBox(height: 16),
      const Text(
        'Eseriniz için önce bizimle iletişime geçin. UÇARI ekibi başvurunuzu değerlendirir, yayına hazırlık sürecini koordine eder ve gereken yere iletir.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.65),
      ),
      const SizedBox(height: 24),
      for (final item in const [
        (
          Icons.edit_document,
          'Ücretsiz yayın',
          'Editörlük, mizanpaj, dizgi ve kapak tasarımı dahil yayına hazırlık desteği.',
        ),
        (
          Icons.percent,
          '%20 telif',
          'Yazarlara eser başına %20 telif hakkı sunuyoruz.',
        ),
        (
          Icons.emoji_events_outlined,
          'İlk 500 satışa 10 bin TL',
          'İlk 500 satışını gerçekleştiren yazarlarımıza nakit ödül desteği.',
        ),
        (
          Icons.movie_creation_outlined,
          'ZEYN yapım iş birliği',
          'Eser tanıtımı ve projeleri beyaz perdeye taşıma desteği.',
        ),
        (
          Icons.campaign_outlined,
          'Birlikte daha geniş kitlelere',
          'Sosyal medya ve platformlarda koordineli tanıtım, yazar söyleşileri ve reklam çalışmaları.',
        ),
      ])
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(item.$1, color: gold),
            title: Text(
              item.$2,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(item.$3, style: const TextStyle(height: 1.5)),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Basım ve satış ilgili iş ortağı tarafından yürütülür. Kitap satın alma işlemi Kitapyurdu bağlantısından yapılır. Başvurunuzun koşullarını ve yayın sürecini UÇARI ekibiyle görüşebilirsiniz.',
          style: TextStyle(height: 1.6, color: Colors.grey),
        ),
      ),
      FilledButton.icon(
        onPressed: () => openPage(c, ApplicationPage(store: store)),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Başvurumu Hazırla'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => openPage(c, ContactPage(store: store)),
        icon: const Icon(Icons.chat_outlined),
        label: const Text('Bizimle İletişime Geç'),
      ),
    ],
  );
}

class ContactPage extends StatelessWidget {
  final AppStore store;
  const ContactPage({super.key, required this.store});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('UÇARI ile iletişim')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: Brand(size: 110)),
        const SizedBox(height: 26),
        const Text(
          'Eserinizin yolculuğu\nbir merhaba ile başlar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'serif', fontSize: 28),
        ),
        const SizedBox(height: 18),
        const Text(
          'Başvurunuz önce bize ulaşır. Ekibimiz sizinle görüşerek eserinizi ilgili yere iletir.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.6),
        ),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: () => openLink(
            c,
            Uri.https('wa.me', '/905312023068', {
              'text': 'Merhaba, UÇARI Yayınevi ile eserim hakkında görüşmek istiyorum.',
            }),
          ),
          icon: const Icon(Icons.chat_outlined),
          label: const Text('WhatsApp ile iletişim'),
        ),
        const SizedBox(height: 10),
        const SelectableText('0531 202 30 68', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (store.catalog.email.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () =>
                openLink(c, Uri(scheme: 'mailto', path: store.catalog.email)),
            icon: const Icon(Icons.mail_outline),
            label: Text(store.catalog.email),
          )
        else
          const Text(
            'E-posta iletişimi daha sonra eklenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
      ],
    ),
  );
}

class ApplicationPage extends StatefulWidget {
  final AppStore store;
  const ApplicationPage({super.key, required this.store});
  @override
  State<ApplicationPage> createState() => _ApplicationPageState();
}

class _ApplicationPageState extends State<ApplicationPage> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> fields;
  String category = 'Roman', attachment = '', attachmentName = '';
  bool busy = false, dirty = false;
  static const categories = [
    'Roman',
    'Şiir',
    'Öykü',
    'Araştırma',
    'Çocuk',
    'Diğer',
  ];
  @override
  void initState() {
    super.initState();
    final d = widget.store.draft;
    fields = {
      for (final key in ['name', 'contact', 'title', 'description'])
        key: TextEditingController(text: d[key] ?? ''),
    };
    category = categories.contains(d['category']) ? d['category']! : 'Roman';
    attachment = d['attachment'] ?? '';
    attachmentName = d['attachmentName'] ?? '';
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Map<String, String> get data => {
    for (final e in fields.entries) e.key: e.value.text.trim(),
    'category': category,
    'attachment': attachment,
    'attachmentName': attachmentName,
    'savedAt': DateTime.now().toIso8601String(),
  };
  Future<void> cleanAttachments(String keep) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/manuscripts');
    if (!await dir.exists()) return;
    await for (final file in dir.list()) {
      if (file is File && file.path != keep) await file.delete();
    }
  }

  Future<bool> save({bool validate = false}) async {
    if (validate && !form.currentState!.validate()) return false;
    setState(() => busy = true);
    try {
      await widget.store.saveDraft(data);
      if (mounted) setState(() => dirty = false);
      try {
        await cleanAttachments(attachment);
      } catch (_) {
        /* A saved draft is not invalidated by optional cleanup. */
      }
      return true;
    } catch (_) {
      if (mounted) {
        message(context, 'Taslak kaydedilemedi. Lütfen tekrar deneyin.');
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pick() async {
    setState(() => busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );
      if (result == null) return;
      final file = result.files.single;
      if (file.size > 25 * 1024 * 1024) {
        if (mounted) {
          message(context, 'En fazla 25 MB boyutunda bir dosya seçin.');
        }
        return;
      }
      if (file.path == null) throw const FileSystemException();
      final root = await getApplicationDocumentsDirectory();
      final dir = await Directory('${root.path}/manuscripts')
          .create(recursive: true);
      final target =
          '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.${file.extension}';
      await File(file.path!).copy(target);
      if (mounted) {
        setState(() {
          attachment = target;
          attachmentName = file.name;
          dirty = true;
        });
      }
    } catch (_) {
      if (mounted) {
        message(
          context,
          'Dosya eklenemedi. Dosyanın cihazınızda bulunduğunu kontrol edin.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> contact() async {
    if (!await save(validate: true) || !mounted) return;
    final d = data;
    final text =
        'Merhaba UÇARI Yayınevi, eserim hakkında görüşmek istiyorum.\n\nAd Soyad: ${d['name']}\nİletişim: ${d['contact']}\nEser: ${d['title']}\nTür: $category\n\n${d['description']}${attachmentName.isEmpty ? '' : '\n\nEser dosyam: $attachmentName (sohbete ayrıca ekleyeceğim).'}';
    await openLink(
      context,
      Uri.https('wa.me', '/905312023068', {'text': text}),
    );
  }

  Future<void> leave() async {
    if (busy) return;
    if (!dirty) {
      Navigator.pop(context);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Taslağınız kaydedilsin mi?'),
        content: const Text(
          'Başvuru bilgilerinizi daha sonra tamamlayabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'stay'),
            child: const Text('Düzenlemeye dön'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('Kaydetmeden çık'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, 'save'),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final exit = choice == 'discard' || (choice == 'save' && await save());
    if (exit && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Taslak silinsin mi?'),
        content: const Text(
          'Bu cihazdaki başvuru taslağı ve ekleri silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => busy = true);
    try {
      await widget.store.clearDraft();
      await cleanAttachments('');
      for (final field in fields.values) {
        field.clear();
      }
      if (mounted) {
        setState(() {
          attachment = '';
          attachmentName = '';
          category = 'Roman';
          dirty = false;
        });
      }
    } catch (_) {
      if (mounted) {
        message(context, 'Taslak tamamen temizlenemedi. Tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Eser başvurusu'),
        actions: [
          IconButton(
            tooltip: 'Taslağı sil',
            onPressed: busy ? null : delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Form(
        key: form,
        onChanged: () {
          if (!dirty) setState(() => dirty = true);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Hikâyenizi bizimle paylaşın.',
              style: TextStyle(fontFamily: 'serif', fontSize: 27),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bilgilerinizi hazırlayın, taslağınızı saklayın ve UÇARI ekibiyle görüşün.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 24),
            for (final item in const [
              ('name', 'Ad soyad', 100),
              ('contact', 'Telefon veya e-posta', 150),
              ('title', 'Eser adı', 160),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  enabled: !busy,
                  controller: fields[item.$1],
                  maxLength: item.$3,
                  decoration: InputDecoration(
                    labelText: item.$2,
                    counterText: '',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Bu alanı doldurun.' : null,
                ),
              ),
            DropdownButtonFormField<String>(
              key: ValueKey(category),
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Eser türü'),
              items: categories
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      category = v!;
                      dirty = true;
                    }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              enabled: !busy,
              controller: fields['description'],
              minLines: 4,
              maxLines: 7,
              maxLength: 1500,
              decoration: const InputDecoration(labelText: 'Eseriniz hakkında'),
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Eserinizi kısaca anlatın.'
                  : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : pick,
              icon: const Icon(Icons.attach_file),
              label: const Text('PDF / Word dosyası ekle (en fazla 25 MB)'),
            ),
            if (attachmentName.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.description_outlined, color: gold),
                title: Text(attachmentName),
                subtitle: const Text(
                  'Bu cihazda saklanır. WhatsApp’a ayrıca ekleyin.',
                ),
                trailing: IconButton(
                  tooltip: 'Eki kaldır',
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          attachment = '';
                          attachmentName = '';
                          dirty = true;
                        }),
                  icon: const Icon(Icons.close),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (await save() && context.mounted) {
                        message(
                          context,
                          'Taslak cihazınıza kaydedildi. Henüz gönderilmedi.',
                        );
                      }
                    },
              child: Text(busy ? 'Kaydediliyor…' : 'Taslağı Kaydet'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy ? null : contact,
              icon: const Icon(Icons.chat_outlined),
              label: const Text('WhatsApp’ta Başvuruyu Hazırla'),
            ),
            const SizedBox(height: 14),
            const Text(
              'WhatsApp mesajını kontrol edip kendiniz gönderirsiniz. Eser dosyanızı açılan sohbete ayrıca ekleyin. Uygulama başvuruyu otomatik göndermez.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Başvurunuz önce UÇARI ekibine ulaşır. E-posta kanalı daha sonra eklenecek.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
