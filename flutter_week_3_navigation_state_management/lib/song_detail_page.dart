import 'package:flutter/material.dart';
import 'lagu.dart';

class SongDetailPage extends StatefulWidget {
  final Lagu lagu;
  final ValueChanged<bool> onFavoriteChanged;

  const SongDetailPage({
    super.key,
    required this.lagu,
    required this.onFavoriteChanged,
  });

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  bool _isPlaying = false;
  final double _progress = 0.35; // progres pemutaran tiruan (0.0 - 1.0)
  final TextEditingController _komentarController = TextEditingController();

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);

  void _kirimKomentar() {
    if (_komentarController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komentar tidak boleh kosong.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi'),
        content: Text('Komentar "${_komentarController.text}" berhasil dikirim!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    _komentarController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lagu = widget.lagu;

    return Scaffold(
      appBar: AppBar(
        title: Text('${lagu.judul} - ${lagu.penyanyi}'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(
              lagu.favorit ? Icons.favorite : Icons.favorite_border,
              color: lagu.favorit ? Colors.redAccent : null,
            ),
            onPressed: () {
              setState(() => lagu.favorit = !lagu.favorit);
              widget.onFavoriteChanged(lagu.favorit);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Hero(
                    tag: 'heaven-image',
                    child: Image.asset(
                      'assets/images/heaven.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                lagu.judul,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Center(
              child: Text(
                lagu.penyanyi,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),

            // Chip -- belum ada di katalog PDF
            Center(
              child: Chip(
                avatar: const Icon(Icons.local_offer, size: 18),
                label: Text(lagu.genre),
                backgroundColor: Colors.deepPurple.shade50,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(), // Divider -- belum ada di katalog PDF

            // Simulasi progres pemutaran lagu
            Row(
              children: [
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      key: ValueKey(_isPlaying),
                      size: 36,
                      color: Colors.deepPurple,
                    ),
                  ),
                  onPressed: _togglePlay,
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ExpansionTile -- belum ada di katalog PDF
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.lyrics_outlined),
                title: const Text(
                  'Lihat lirik',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  Text(
                    lagu.lirik,
                    style: const TextStyle(fontStyle: FontStyle.italic, height: 1.6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Tulis komentar tentang lagu ini:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _komentarController,
              decoration: const InputDecoration(
                labelText: 'Komentar',
                hintText: 'Masukkan komentar...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _kirimKomentar,
              icon: const Icon(Icons.send),
              label: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}
