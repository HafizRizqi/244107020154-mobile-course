import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPage extends StatefulWidget {
  const SharedPreferencesPage({super.key});

  @override
  State<SharedPreferencesPage> createState() => _SharedPreferencesPageState();
}

class _SharedPreferencesPageState extends State<SharedPreferencesPage> {
  final _nameController = TextEditingController();
  bool _darkMode = false;
  String _savedName = '-';
  String _status = 'Belum ada pengujian.';
  final _prefs = SharedPreferencesAsync();

  static const _darkModeKey = 'dark_mode';
  static const _nameKey = 'name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final darkMode = await _prefs.getBool(_darkModeKey) ?? false;
    final name = await _prefs.getString(_nameKey) ?? '';
    if (!mounted) return;
    setState(() {
      _darkMode = darkMode;
      _savedName = name.isEmpty ? '-' : name;
      _nameController.text = name;
      _status = 'Data dibaca dari storage.';
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    await _prefs.setBool(_darkModeKey, _darkMode);
    await _prefs.setString(_nameKey, name);
    await _load();
    if (!mounted) return;
    setState(() => _status = 'WRITE berhasil: tema + nama tersimpan.');
  }

  Future<void> _clear() async {
    await _prefs.remove(_darkModeKey);
    await _prefs.remove(_nameKey);
    await _load();
    if (!mounted) return;
    setState(() => _status = 'DELETE berhasil: key dihapus.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tujuan: menguji penyimpanan key-value sederhana. Gunakan ini untuk data preferensi, bukan daftar catatan.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama pengguna',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Dark mode'),
          value: _darkMode,
          onChanged: (value) => setState(() => _darkMode = value),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Simpan / Update'),
        ),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Read dari storage'),
        ),
        TextButton.icon(
          onPressed: _clear,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus data'),
        ),
        const Divider(height: 32),
        ListTile(
          title: const Text('Nilai tersimpan'),
          subtitle: Text('Nama: $_savedName\nDark mode: $_darkMode'),
        ),
        ListTile(
          title: const Text('Status'),
          subtitle: Text(_status),
        ),
      ],
    );
  }
}
