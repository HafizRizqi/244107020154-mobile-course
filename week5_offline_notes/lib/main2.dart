import 'package:flutter/material.dart';

import 'data/drift_database.dart';
import 'pages/drift_page.dart';
import 'pages/hive_page.dart';
import 'pages/shared_preferences_page.dart';
import 'pages/sqflite_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final driftDatabase = AppDatabase();
  runApp(StorageComparisonApp(driftDatabase: driftDatabase));
}

class StorageComparisonApp extends StatefulWidget {
  const StorageComparisonApp({super.key, required this.driftDatabase});

  final AppDatabase driftDatabase;

  @override
  State<StorageComparisonApp> createState() => _StorageComparisonAppState();
}

class _StorageComparisonAppState extends State<StorageComparisonApp> {
  int _index = 0;

  late final List<Widget> _pages = [
    const SharedPreferencesPage(),
    const HivePage(),
    const SqflitePage(),
    DriftPage(database: widget.driftDatabase),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Storage Comparison Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            setState(() => _index = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Preferences',
            ),
            NavigationDestination(
              icon: Icon(Icons.storage_outlined),
              selectedIcon: Icon(Icons.storage),
              label: 'Hive',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_chart_outlined),
              selectedIcon: Icon(Icons.table_chart),
              label: 'sqflite',
            ),
            NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt),
              label: 'Drift',
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (_index) {
      case 0:
        return '1. SharedPreferences';
      case 1:
        return '2. Hive CE';
      case 2:
        return '3. sqflite (SQLite)';
      case 3:
        return '4. Drift';
      default:
        return 'Storage Comparison';
    }
  }

  @override
  void dispose() {
    widget.driftDatabase.close();
    super.dispose();
  }
}
