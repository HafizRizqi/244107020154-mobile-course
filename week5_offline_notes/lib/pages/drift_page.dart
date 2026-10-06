import 'package:flutter/material.dart';

import '../data/drift_database.dart';

class DriftPage extends StatefulWidget {
  const DriftPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<DriftPage> createState() => _DriftPageState();
}

class _DriftPageState extends State<DriftPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _status = 'Stream watch aktif.';

  Future<void> _add() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) return;
    await widget.database.addNote(title, content);
    _titleController.clear();
    _contentController.clear();
    _setStatus('INSERT berhasil. Stream akan memperbarui UI.');
  }

  Future<void> _update(int id) async {
    final ok = await widget.database.updateNote(id);
    _setStatus(ok ? 'UPDATE berhasil untuk id $id.' : 'UPDATE gagal.');
  }

  Future<void> _delete(int id) async {
    final ok = await widget.database.deleteNote(id);
    _setStatus(ok ? 'DELETE berhasil untuk id $id.' : 'DELETE gagal.');
  }

  Future<void> _clear() async {
    await widget.database.clearNotes();
    _setStatus('Semua data Drift dihapus.');
  }

  Future<void> _seed1000() async {
    final stopwatch = Stopwatch()..start();
    await widget.database.seed1000();
    stopwatch.stop();
    _setStatus('INSERT 1000 data: ${stopwatch.elapsedMilliseconds} ms.');
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
          child: StreamBuilder<List<Note>>(
            stream: widget.database.watchAllNotes(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final notes = snapshot.data ?? const <Note>[];
              if (notes.isEmpty) {
                return const Center(child: Text('Belum ada catatan.'));
              }
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return ListTile(
                    title: Text(note.title),
                    subtitle: Text('ID ${note.id} • ${note.content}'),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Update',
                          onPressed: () => _update(note.id),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _delete(note.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
