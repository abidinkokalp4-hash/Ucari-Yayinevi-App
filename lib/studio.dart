import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'data.dart';
import 'widgets.dart';

class StudioPage extends StatefulWidget {
  final AppStore store;
  const StudioPage({super.key, required this.store});
  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  String query = '', category = 'Tümü';
  @override
  Widget build(BuildContext c) {
    final categories = [
      'Tümü',
      ...widget.store.catalog.videos.map((v) => v.category).toSet(),
    ];
    final selected = categories.contains(category) ? category : 'Tümü';
    final videos = widget.store.catalog.videos
        .where(
          (v) =>
              (selected == 'Tümü' || v.category == selected) &&
              normalized('${v.title} ${v.description}')
                  .contains(normalized(query.trim())),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: widget.store.refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          const Text(
            'ZEYN STÜDYO',
            style: TextStyle(
              fontSize: 27,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hikâyeler bu kez ekranda.',
            style: TextStyle(fontFamily: 'serif', fontSize: 19, color: gold),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Film ve videolarda ara…',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: categories
                .map(
                  (v) => ChoiceChip(
                    label: Text(v),
                    selected: v == selected,
                    onSelected: (_) => setState(() => category = v),
                  ),
                )
                .toList(),
          ),
          if (videos.isEmpty)
            const EmptyState(
              Icons.movie_outlined,
              'Gösterilecek yapım yok',
              'ZEYN film ve videoları yayımlandığında burada izleyebilirsiniz. Arama yaptıysanız farklı bir sözcük deneyin.',
            ),
          for (final v in videos)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => openPage(c, StudioPlayer(video: v)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Cover(
                            v.poster,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          const Center(
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      v.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${v.category} • ${v.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StudioPlayer extends StatefulWidget {
  final StudioVideo video;
  const StudioPlayer({super.key, required this.video});
  @override
  State<StudioPlayer> createState() => _StudioPlayerState();
}

class _StudioPlayerState extends State<StudioPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? controller;
  final transform = TransformationController();
  Timer? timer;
  bool controls = true, locked = false, landscape = false, loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  Future<void> load() async {
    final old = controller;
    controller = null;
    await old?.dispose();
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    final uri = secureUrl(widget.video.url);
    if (uri == null) {
      setState(() {
        loading = false;
        error = 'Video bağlantısı geçersiz.';
      });
      return;
    }
    final next = VideoPlayerController.networkUrl(uri);
    controller = next;
    try {
      await next.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || controller != next) return;
      setState(() => loading = false);
      await next.play();
      hideLater();
    } catch (_) {
      if (mounted && controller == next) {
        setState(() {
          loading = false;
          error = 'Video açılamadı. Bağlantınızı kontrol edip tekrar deneyin.';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(controller?.pause());
  }

  Future<void> rotate() async {
    final value = !landscape;
    await SystemChrome.setPreferredOrientations(
      value
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp],
    );
    await SystemChrome.setEnabledSystemUIMode(
      value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
    if (mounted) setState(() => landscape = value);
    hideLater();
  }

  void hideLater() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 4), () {
      if (mounted && controller?.value.isPlaying == true) {
        setState(() => controls = false);
      }
    });
  }

  Future<void> action(Future<void> Function(VideoPlayerController) fn) async {
    final c = controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      await fn(c);
      hideLater();
    } catch (_) {
      if (mounted) message(context, 'Oynatma ayarı uygulanamadı.');
    }
  }

  void seek(int seconds) => action(
    (c) => c.seekTo(
      Duration(
        milliseconds: (c.value.position.inMilliseconds + seconds * 1000).clamp(
          0,
          c.value.duration.inMilliseconds,
        ),
      ),
    ),
  );
  String time(Duration d) {
    final s = d.inSeconds;
    return s >= 3600
        ? '${s ~/ 3600}:${((s ~/ 60) % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}'
        : '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(controller?.dispose());
    transform.dispose();
    unawaited(SystemChrome.setPreferredOrientations([]));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  Widget button(String tip, IconData icon, VoidCallback? onTap) => IconButton(
    tooltip: tip,
    onPressed: onTap,
    icon: Icon(icon, color: Colors.white),
  );
  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData.dark(useMaterial3: true),
    child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: controller == null || loading || error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const CircularProgressIndicator()
                    else ...[
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          error ?? 'Video açılamadı.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      FilledButton(
                        onPressed: load,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Geri dön'),
                    ),
                  ],
                ),
              )
            : ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller!,
                builder: (context, value, _) {
                  if (value.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Video oynatılırken bir hata oluştu.'),
                          TextButton(
                            onPressed: load,
                            child: const Text('Tekrar dene'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Geri dön'),
                          ),
                        ],
                      ),
                    );
                  }
                  final duration = value.duration.inMilliseconds.toDouble();
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            if (!locked) setState(() => controls = !controls);
                            hideLater();
                          },
                          child: InteractiveViewer(
                            transformationController: transform,
                            minScale: 1,
                            maxScale: 4,
                            panEnabled: !locked,
                            scaleEnabled: !locked,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: value.aspectRatio > 0
                                    ? value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(controller!),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (value.isBuffering)
                        const Center(
                          child: IgnorePointer(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (controls && !locked) ...[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                button(
                                  'Geri dön',
                                  Icons.arrow_back,
                                  () => Navigator.pop(context),
                                ),
                                Expanded(
                                  child: Text(
                                    widget.video.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                button(
                                  'Kontrolleri kilitle',
                                  Icons.lock_open,
                                  () => setState(() => locked = true),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black.withValues(alpha: .8),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(time(value.position)),
                                    Expanded(
                                      child: Slider(
                                        value: value.position.inMilliseconds
                                            .toDouble()
                                            .clamp(0, duration),
                                        max: duration > 0 ? duration : 1,
                                        onChangeStart: (_) => timer?.cancel(),
                                        onChanged: duration > 0
                                            ? (v) => action(
                                                (c) => c.seekTo(
                                                  Duration(
                                                    milliseconds: v.round(),
                                                  ),
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    Text(time(value.duration)),
                                  ],
                                ),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      button(
                                        '10 saniye geri',
                                        Icons.replay_10,
                                        () => seek(-10),
                                      ),
                                      button(
                                        value.isPlaying ? 'Duraklat' : 'Oynat',
                                        value.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                        () => action((c) async {
                                          if (value.isPlaying) {
                                            await c.pause();
                                          } else {
                                            if (value.position >=
                                                value.duration) {
                                              await c.seekTo(Duration.zero);
                                            }
                                            await c.play();
                                          }
                                        }),
                                      ),
                                      button(
                                        '10 saniye ileri',
                                        Icons.forward_10,
                                        () => seek(10),
                                      ),
                                      PopupMenuButton<double>(
                                        tooltip: 'Oynatma hızı',
                                        initialValue: value.playbackSpeed,
                                        onOpened: () => timer?.cancel(),
                                        onCanceled: hideLater,
                                        onSelected: (v) => action(
                                          (c) => c.setPlaybackSpeed(v),
                                        ),
                                        itemBuilder: (_) => [
                                          for (final speed in [
                                            .5,
                                            .75,
                                            1.0,
                                            1.25,
                                            1.5,
                                            2.0,
                                          ])
                                            CheckedPopupMenuItem(
                                              value: speed,
                                              checked:
                                                  value.playbackSpeed == speed,
                                              child: Text('${speed}x'),
                                            ),
                                        ],
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            '${value.playbackSpeed}x',
                                          ),
                                        ),
                                      ),
                                      button(
                                        value.volume == 0
                                            ? 'Sesi aç'
                                            : 'Sesi kapat',
                                        value.volume == 0
                                            ? Icons.volume_off
                                            : Icons.volume_up,
                                        () => action(
                                          (c) => c.setVolume(
                                            value.volume == 0 ? 1 : 0,
                                          ),
                                        ),
                                      ),
                                      button(
                                        'Yakınlaştırmayı sıfırla',
                                        Icons.fit_screen,
                                        () {
                                          transform.value = Matrix4.identity();
                                          hideLater();
                                        },
                                      ),
                                      button(
                                        'Ekranı döndür',
                                        Icons.screen_rotation,
                                        rotate,
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'İki parmakla yakınlaştırın ve görüntüyü sürükleyin.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (locked)
                        Positioned(
                          right: 16,
                          top: 12,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                            child: button(
                              'Kontrol kilidini aç',
                              Icons.lock,
                              () {
                                setState(() {
                                  locked = false;
                                  controls = true;
                                });
                                hideLater();
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    ),
  );
}
