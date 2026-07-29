import 'package:flutter/material.dart';

void main() => runApp(const IlacHatirlaticiApp());

class IlacHatirlaticiApp extends StatelessWidget {
  const IlacHatirlaticiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Hatırlatıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

// Bir ilacı temsil eden basit model: adı ve saati.
class Ilac {
  final String ad;
  final TimeOfDay saat;
  Ilac(this.ad, this.saat);
}

String saatMetni(TimeOfDay t) {
  final s = t.hour.toString().padLeft(2, '0');
  final d = t.minute.toString().padLeft(2, '0');
  return '$s:$d';
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final List<Ilac> _ilaclar = [];

  Future<void> _ilacEkle() async {
    final yeni = await Navigator.push<Ilac>(
      context,
      MaterialPageRoute(builder: (_) => const IlacEkleSayfasi()),
    );
    if (yeni != null) {
      setState(() => _ilaclar.add(yeni));
    }
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: renk.primary,
        foregroundColor: renk.onPrimary,
        title: const Text('İlaç Hatırlatıcı'),
        centerTitle: true,
      ),
      body: _ilaclar.isEmpty
          ? _bosDurum(renk)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _ilaclar.length,
              itemBuilder: (context, i) {
                final ilac = _ilaclar[i];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.medication, color: renk.primary),
                    title: Text(ilac.ad),
                    subtitle: Text('Saat: ${saatMetni(ilac.saat)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _ilaclar.removeAt(i)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ilacEkle,
        icon: const Icon(Icons.add),
        label: const Text('İlaç Ekle'),
      ),
    );
  }

  Widget _bosDurum(ColorScheme renk) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 96, color: renk.primary),
            const SizedBox(height: 24),
            Text('Henüz ilaç yok',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              'Aşağıdaki "İlaç Ekle" butonuna basarak\n'
              'ilk ilacını ekle.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class IlacEkleSayfasi extends StatefulWidget {
  const IlacEkleSayfasi({super.key});

  @override
  State<IlacEkleSayfasi> createState() => _IlacEkleSayfasiState();
}

class _IlacEkleSayfasiState extends State<IlacEkleSayfasi> {
  final _adController = TextEditingController();
  TimeOfDay? _secilenSaat;

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  Future<void> _saatSec() async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (secilen != null) {
      setState(() => _secilenSaat = secilen);
    }
  }

  void _kaydet() {
    final ad = _adController.text.trim();
    if (ad.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ilaç adını yaz.')),
      );
      return;
    }
    if (_secilenSaat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir saat seç.')),
      );
      return;
    }
    Navigator.pop(context, Ilac(ad, _secilenSaat!));
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: renk.primary,
        foregroundColor: renk.onPrimary,
        title: const Text('Yeni İlaç'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _adController,
              decoration: const InputDecoration(
                labelText: 'İlaç adı',
                hintText: 'Örn. Tansiyon hapı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _saatSec,
              icon: const Icon(Icons.access_time),
              label: Text(
                _secilenSaat == null
                    ? 'Saat seç'
                    : 'Saat: ${saatMetni(_secilenSaat!)}',
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _kaydet,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
