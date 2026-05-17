import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShikshaSetuApp());
}

class ShikshaSetuApp extends StatelessWidget {
  const ShikshaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BooksProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()..load()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()..init()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Get Top Marks With Shiksha Setu',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F7CF6)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('hi')],
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _search = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BooksProvider>();
    final filtered = books.search(_search.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shiksha Setu'),
        actions: [
          IconButton(
            tooltip: 'Voice Input',
            onPressed: () async {
              if (!_listening) {
                bool available = await _speech.initialize();
                if (available) {
                  setState(() => _listening = true);
                  _speech.listen(onResult: (res) {
                    setState(() {
                      _search.text = res.recognizedWords;
                      _listening = false;
                      _speech.stop();
                    });
                  });
                }
              } else {
                setState(() => _listening = false);
                _speech.stop();
              }
            },
            icon: Icon(_listening ? Icons.mic : Icons.mic_none),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search / खोजें',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search.clear()),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      title: Text(item['title']),
                      subtitle: Text(item['subtitle']),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SubjectPage(node: item),
                        ));
                      },
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: const _BottomBar(),
    );
  }
}

class _BottomBar extends StatefulWidget {
  const _BottomBar();

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const SizedBox.shrink(), // Home already on scaffold body
      const BookmarksPage(),
      const DownloadsPage(),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 0, child: pages[idx]),
        NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (v) => setState(() => idx = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Bookmarks'),
            NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download), label: 'Downloads'),
          ],
          height: 65,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
      ],
    );
  }
}

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});
  @override
  Widget build(BuildContext context) {
    final bm = context.watch<BookmarkProvider>();
    final items = bm.items;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const SizedBox(height: 8),
          const Text('Bookmarks / पसंदीदा', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final t in items)
            Card(
              child: ListTile(
                title: Text(t),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => bm.toggle(t)),
              ),
            ),
        ],
      ),
    );
  }
}

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<DownloadProvider>(context, listen: false).listDownloads(),
      builder: (_, snap) {
        final files = (snap.data ?? []) as List<FileSystemEntity>;
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const SizedBox(height: 8),
              const Text('Offline Downloads / ऑफ़लाइन डाउनलोड', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final f in files)
                Card(
                  child: ListTile(
                    title: Text(f.path.split('/').last),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      Navigator.push(_,
                        MaterialPageRoute(builder: (_) => PDFView(filePath: f.path))
                      );
                    },
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}

class SubjectPage extends StatelessWidget {
  final Map<String, dynamic> node;
  const SubjectPage({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final chapters = node['chapters'] as List<dynamic>? ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(node['title'])),
      body: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (_, i) {
          final ch = chapters[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ExpansionTile(
                title: Text(ch['title']),
                children: [
                  for (final a in (ch['assignments'] as List<dynamic>))
                    ListTile(
                      title: Text('Assignment: $a'),
                      trailing: const Icon(Icons.picture_as_pdf),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PdfReaderScreen(title: a),
                        ));
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PdfReaderScreen extends StatefulWidget {
  final String title;
  const PdfReaderScreen({super.key, required this.title});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final downloads = await DownloadProvider.of(context).ensurePlaceholder();
    setState(() => localPath = downloads);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = context.watch<BookmarkProvider>();
    final isSaved = bookmarks.isBookmarked(widget.title);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark',
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => bookmarks.toggle(widget.title),
          ),
          Consumer<DownloadProvider>(builder: (_, d, __) {
            return IconButton(
              tooltip: 'Download for Offline',
              icon: const Icon(Icons.download),
              onPressed: () async {
                await d.downloadDemo(widget.title);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved for offline.')));
                }
              },
            );
          }),
        ],
      ),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(filePath: localPath!),
    );
  }
}

class BooksProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _nodes = [];

  Future<void> loadData() async {
    final raw = await rootBundle.loadString('assets/data/subjects.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final List<Map<String, dynamic>> nodes = [];
    for (final cls in data['classes']) {
      for (final subj in cls['subjects']) {
        nodes.add({
          'title': f"{cls['name']} • {subj['name']}",
          'subtitle': 'Chapters: ${(subj['chapters'] as List).length}',
          'chapters': subj['chapters'],
        });
      }
    }
    _nodes = nodes;
    notifyListeners();
  }

  List<Map<String, dynamic>> search(String q) {
    if (q.trim().isEmpty) return _nodes;
    final query = q.toLowerCase();
    return _nodes.where((e) => e['title'].toLowerCase().contains(query)).toList();
  }
}

class BookmarkProvider extends ChangeNotifier {
  static const _key = 'bookmarks_v1';
  Set<String> _bookmarks = {};

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    _bookmarks = sp.getStringList(_key)?.toSet() ?? {};
    notifyListeners();
  }

  bool isBookmarked(String id) => _bookmarks.contains(id);
  List<String> get items => _bookmarks.toList();

  Future<void> toggle(String id) async {
    final sp = await SharedPreferences.getInstance();
    if (_bookmarks.contains(id)) {
      _bookmarks.remove(id);
    } else {
      _bookmarks.add(id);
    }
    await sp.setStringList(_key, _bookmarks.toList());
    notifyListeners();
  }
}

class DownloadProvider extends ChangeNotifier {
  late Directory appDir;
  String placeholderName = 'placeholder.pdf';

  static DownloadProvider of(BuildContext context) => Provider.of<DownloadProvider>(context, listen: false);

  Future<void> init() async {
    appDir = await getApplicationDocumentsDirectory();
    notifyListeners();
  }

  Future<String> ensurePlaceholder() async {
    final out = File('${appDir.path}/$placeholderName');
    if (!(await out.exists())) {
      final data = await rootBundle.load('assets/pdfs/placeholder.pdf');
      await out.writeAsBytes(data.buffer.asUint8List());
    }
    return out.path;
  }

  Future<void> downloadDemo(String title) async {
    final path = '${appDir.path}/$title.pdf';
    final data = await rootBundle.load('assets/pdfs/placeholder.pdf');
    await File(path).writeAsBytes(data.buffer.asUint8List());
  }

  Future<List<FileSystemEntity>> listDownloads() async {
    if (!await appDir.exists()) return [];
    return appDir.list().where((e) => e.path.endswith('.pdf')).toList();
  }
}
