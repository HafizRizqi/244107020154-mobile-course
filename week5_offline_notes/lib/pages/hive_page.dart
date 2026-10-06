import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HivePage extends StatefulWidget {
  const HivePage({super.key});

  @override
  State<HivePage> createState() => _HivePageState();
}

class _HivePageState extends State<HivePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  Box? _box;
  List<Map<String, dynamic>> _notes = [];
  String _status = 'Membuka box...';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('comparison_hive_notes');
    await _load();
  }

  Future<void> _load() async {
    final box = _box;
    if (box == null) return;

    final notes = <Map<String, dynamic>>[];
    for (final value in box.values) {
      if (value is Map) {
        notes.add(Map<String, dynamic>.from(value));
      }
    }
    notes.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    final maxId = notes.isEmpty ? 0 : notes.first['id'] as int;

    if (!mounted) return;
    setState(() {
      _notes = notes;
      _nextId = maxId + 1;
      _status = 'READ: ${notes.length} catatan.';
    });
  }

  Future<void> _add() async {
    final box = _box;
    if (box == null) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) return;

    final id = _nextId;
    await box.put(id, {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _titleController.clear();
    _contentController.clear();
    await _load();
    _setStatus('CREATE berhasil.');
  }

  Future<void> _update(int id) async {
    final box = _box;
    if (box == null) return;
    await box.put(id, {
      'id': id,
      'title': 'Updated Hive #$id',
      'content': 'Data diperbarui pada ${DateTime.now()}',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _load();
    _setStatus('UPDATE berhasil untuk id $id.');
  }

  Future<void> _delete(int id) async {
    await _box?.delete(id);
    await _load();
    _setStatus('DELETE berhasil untuk id $id.');
  }

  Future<void> _clear() async {
    await _box?.clear();
    await _load();
    _setStatus('Semua data Hive dihapus.');
  }

  Future<void> _seed1000() async {
    final box = _box;
    if (box == null) return;
    final stopwatch = Stopwatch()..start();
    final startId = _nextId;
    final entries = <dynamic, dynamic>{};
    for (var i = 0; i < 1000; i++) {
      final id = startId + i;
      entries[id] = {
        'id': id,
        'title': 'Hive Note $id',
        'content': 'Data uji 1000+ catatan',
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
    await box.putAll(entries);
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
    _box?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _notesView();
  }

  Widget _notesView() {
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
                title: Text(note['title'] as String? ?? ''),
                subtitle: Text('ID $id • ${note['content'] ?? ''}'),
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
