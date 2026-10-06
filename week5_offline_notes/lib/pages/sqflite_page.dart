import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class SqflitePage extends StatefulWidget {
  const SqflitePage({super.key});

  @override
  State<SqflitePage> createState() => _SqflitePageState();
}

class _SqflitePageState extends State<SqflitePage> {
  Database? _db;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<Map<String, Object?>> _notes = [];
  String _status = 'Membuka database...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final path = '${await getDatabasesPath()}/comparison_sqflite.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
    await _load();
  }

  Future<void> _load() async {
    final db = _db;
    if (db == null) return;
    final notes = await db.query('notes', orderBy: 'id DESC');
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _status = 'SELECT/READ: ${notes.length} catatan.';
    });
  }

  Future<void> _add() async {
    final db = _db;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (db == null || title.isEmpty) return;

    await db.insert('notes', {
      'title': title,
      'content': content,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    _titleController.clear();
    _contentController.clear();
    await _load();
    _setStatus('INSERT berhasil.');
  }

  Future<void> _update(int id) async {
    final db = _db;
    if (db == null) return;
    await db.update(
      'notes',
      {
        'title': 'Updated sqflite #$id',
        'content': 'Data diperbarui pada ${DateTime.now()}',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _load();
    _setStatus('UPDATE berhasil untuk id $id.');
  }

  Future<void> _delete(int id) async {
    final db = _db;
    if (db == null) return;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    await _load();
    _setStatus('DELETE berhasil untuk id $id.');
  }

  Future<void> _clear() async {
    final db = _db;
    if (db == null) return;
    await db.delete('notes');
    await _load();
    _setStatus('Semua data SQLite dihapus.');
  }

  Future<void> _seed1000() async {
    final db = _db;
    if (db == null) return;
    final stopwatch = Stopwatch()..start();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 1; i <= 1000; i++) {
        batch.insert('notes', {
          'title': 'sqflite Note $i',
          'content': 'Data uji 1000+ catatan',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
      await batch.commit(noResult: true);
    });
    stopwatch.stop();
    await _load();
    _setStatus('INSERT 1000 data: ${stopwatch.elapsedMilliseconds} ms.');
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul catatan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('CREATE'),
                  ),
                  OutlinedButton(
                    onPressed: _seed1000,
                    child: const Text('Tambah 1000'),
                  ),
                  OutlinedButton(
                    onPressed: _clear,
                    child: const Text('CLEAR'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerLeft, child: Text(_status)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              final id = note['id'] as int;
              return ListTile(
                title: Text(note['title'] as String),
                subtitle: Text('ID $id • ${note['content']}'),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Update',
                      onPressed: () => _update(id),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _delete(id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
