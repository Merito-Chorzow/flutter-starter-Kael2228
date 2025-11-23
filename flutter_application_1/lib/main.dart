import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
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
    return const Center(child: Text('Home'));
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

            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Zrób zdjęcie"),
            ),
          ],
        ),
      ),
    );
  }
}

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Files'));
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
