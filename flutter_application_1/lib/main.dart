import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const Main());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp.router(
          routerConfig: _router,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.light(),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.dark(),
          ),
          themeMode: currentMode,
        );
      },
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/camera',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/files',
          builder: (context, state) => const FilesScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ColorScheme = Theme.of(context).colorScheme;
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: ColorScheme.surface,
        selectedItemColor: ColorScheme.primary,
        currentIndex: _getIndex(location),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/camera');
              break;
            case 2:
              context.go('/files');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Strona główna'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'aparat',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'pliki'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'ustawienia',
          ),
        ],
      ),
    );
  }

  int _getIndex(String location) {
    if (location.startsWith('/camera')) return 1;
    if (location.startsWith('/files')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }
}


//EKRANY


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dziennik zdjęć'));
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _photo;
  final TextEditingController _noteController = TextEditingController();

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (image != null) {
      setState(() {
        _photo = File(image.path);
      });
    }
  }

  Future<void> _savePhoto() async {
    if (_photo == null) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory photosDir = Directory("${appDir.path}/photos");

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final String fileName =
        "photo_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final String newPath = p.join(photosDir.path, fileName);

    await _photo!.copy(newPath);

    final File noteFile = File("$newPath.txt");
    await noteFile.writeAsString(_noteController.text);

    setState(() {
      _photo = null;
      _noteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Zdjęcie zapisane w pamięci!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: _photo == null
                  ? const Center(child: Text("Brak zdjęcia – zrób nowe."))
                  : Image.file(_photo!, fit: BoxFit.cover),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "Notatka do zdjęcia",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Zrób zdjęcie"),
                ),
                ElevatedButton.icon(
                  onPressed: _savePhoto,
                  icon: const Icon(Icons.save),
                  label: const Text("Zapisz"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<Map<String, dynamic>> _savedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPhotos();
  }

  Future<void> _loadSavedPhotos() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory photosDir = Directory("${appDir.path}/photos");

    if (!await photosDir.exists()) {
      setState(() => _savedFiles = []);
      return;
    }

    final List<FileSystemEntity> files = photosDir.listSync();

    List<Map<String, dynamic>> items = [];

    for (var file in files) {
      if (file.path.endsWith(".jpg")) {
        final String imagePath = file.path;
        final String notePath = "$imagePath.txt";

        String note = "";
        if (await File(notePath).exists()) {
          note = await File(notePath).readAsString();
        }

        items.add({
          "image": File(imagePath),
          "note": note,
        });
      }
    }

    items = items.reversed.toList();

    setState(() {
      _savedFiles = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zapisane zdjęcia")),
      body: _savedFiles.isEmpty
          ? const Center(child: Text("Brak zapisanych zdjęć."))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _savedFiles.length,
              itemBuilder: (context, index) {
                final File image = _savedFiles[index]["image"];
                final String note = _savedFiles[index]["note"];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.file(image, height: 250, fit: BoxFit.cover),

                        const SizedBox(height: 8),

                        Text(
                          note.isEmpty ? "(brak notatki)" : note,
                          style: const TextStyle(fontSize: 16),
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


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tryb jasny/ciemny: '),
              Switch(
                value: currentMode == ThemeMode.dark,
                onChanged: (isDark) {
                  themeNotifier.value = isDark
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
