import 'package:flutter/material.dart';
import 'mahasiswa.dart';
import 'lagu.dart';
import 'song_detail_page.dart';

void main() {
  runApp(const Hafiz());
}

class Hafiz extends StatelessWidget {
  const Hafiz({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Lagu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Mahasiswa _mahasiswa = Mahasiswa(nama: 'Hafiz', umur: 20, kelas: 'TI-3C');

  final List<Lagu> _daftarLagu = [
    Lagu(judul: "Heaven Can't Wait", penyanyi: 'Michael Jackson', genre: 'Pop'),
    Lagu(judul: 'Billie Jean', penyanyi: 'Michael Jackson', genre: 'Pop'),
    Lagu(judul: 'Smooth Criminal', penyanyi: 'Michael Jackson', genre: 'Pop'),
    Lagu(judul: 'Thriller', penyanyi: 'Michael Jackson', genre: 'Pop'),
  ];

  String _kataKunci = '';
  String? _genreTerpilih;
  bool _isPlaying = false;

  List<Lagu> get _lagusFiltered {
    return _daftarLagu.where((lagu) {
      final cocokKataKunci = _kataKunci.isEmpty ||
          lagu.judul.toLowerCase().contains(_kataKunci.toLowerCase()) ||
          lagu.penyanyi.toLowerCase().contains(_kataKunci.toLowerCase());
      final cocokGenre = _genreTerpilih == null || lagu.genre == _genreTerpilih;
      return cocokKataKunci && cocokGenre;
    }).toList();
  }

  List<String> get _semuaGenre => _daftarLagu.map((l) => l.genre).toSet().toList();

  void _tambahLaguBaru() {
    final judulController = TextEditingController();
    final penyanyiController = TextEditingController();
    String genreBaru = _semuaGenre.isNotEmpty ? _semuaGenre.first : 'Pop';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Lagu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: judulController,
                decoration: const InputDecoration(labelText: 'Judul lagu'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              TextFormField(
                controller: penyanyiController,
                decoration: const InputDecoration(labelText: 'Penyanyi'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Penyanyi wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: genreBaru,
                items: ['Pop', 'Rock', 'Jazz', 'R&B', 'Lainnya']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => genreBaru = value ?? genreBaru,
                decoration: const InputDecoration(labelText: 'Genre'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _daftarLagu.add(Lagu(
                    judul: judulController.text.trim(),
                    penyanyi: penyanyiController.text.trim(),
                    genre: genreBaru,
                  ));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lagu baru berhasil ditambahkan!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Lagu'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.orange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 32, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mahasiswa.nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_mahasiswa.kelas} • ${_mahasiswa.umur} tahun',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            // SearchBar
            child: SearchBar(
              hintText: 'Cari judul atau penyanyi...',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _kataKunci = value),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // FilterChip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: _genreTerpilih == null,
                    onSelected: (_) => setState(() => _genreTerpilih = null),
                  ),
                ),
                ..._semuaGenre.map(
                  (genre) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(genre),
                      selected: _genreTerpilih == genre,
                      onSelected: (_) => setState(
                        () => _genreTerpilih = _genreTerpilih == genre ? null : genre,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _lagusFiltered.isEmpty
                ? const Center(child: Text('Lagu tidak ditemukan.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: _lagusFiltered.length,
                    itemBuilder: (context, index) {
                      final lagu = _lagusFiltered[index];
                      return Dismissible(
                        // Dismissible
                        key: ValueKey(lagu.judul),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() => _daftarLagu.remove(lagu));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${lagu.judul} dihapus dari daftar.')),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            // InkWell
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SongDetailPage(
                                    lagu: lagu,
                                    onFavoriteChanged: (_) => setState(() {}),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Hero(
                                    tag: 'cover-${lagu.judul}',
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.deepPurple.shade50,
                                      child: const Icon(Icons.music_note, color: Colors.deepPurple),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lagu.judul,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          lagu.penyanyi,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (lagu.favorit)
                                    // Badge
                                    const Badge(
                                      label: Text('♥'),
                                      backgroundColor: Colors.redAccent,
                                    )
                                  else
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahLaguBaru,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Icon(Icons.skip_previous, color: Colors.white),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _isPlaying = !_isPlaying),
              ),
              const Icon(Icons.skip_next, color: Colors.white),
              const Icon(Icons.volume_up, color: Colors.white),
              Text(
                'Dibuat oleh ${_mahasiswa.nama}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
