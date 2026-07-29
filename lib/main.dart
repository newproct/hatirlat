import 'package:flutter/material.dart';

void main() => runApp(const IlacHatirlaticiApp());

// Uygulamanın ana renkleri ve gradyanı (caf caf kısmı burada :)
const Color _renk1 = Color(0xFF6A11CB); // mor
const Color _renk2 = Color(0xFF2575FC); // mavi

const LinearGradient anaGradient = LinearGradient(
  colors: [_renk1, _renk2],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class IlacHatirlaticiApp extends StatelessWidget {
  const IlacHatirlaticiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Hatırlatıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _renk1),
        scaffoldBackgroundColor: const Color(0xFFF4F5FB),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

// Bir ilacı temsil eden model: adı ve saati (artık değiştirilebilir).
class Ilac {
  String ad;
  TimeOfDay saat;
  Ilac(this.ad, this.saat);
}

String saatMetni(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final List<Ilac> _ilaclar = [];

  // Hem ekleme hem düzenleme için aynı form. mevcut/index doluysa düzenleme olur.
  Future<void> _formAc({Ilac? mevcut, int? index}) async {
    final sonuc = await Navigator.push<Ilac>(
      context,
      MaterialPageRoute(builder: (_) => IlacFormSayfasi(mevcut: mevcut)),
    );
    if (sonuc != null) {
      setState(() {
        if (index != null) {
          _ilaclar[index] = sonuc;
        } else {
          _ilaclar.add(sonuc);
        }
      });
    }
  }

  void _sil(int index) => setState(() => _ilaclar.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _baslik(),
          Expanded(
            child: _ilaclar.isEmpty
                ? _bosDurum()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _ilaclar.length,
                    itemBuilder: (context, i) => _ilacKarti(_ilaclar[i], i),
                  ),
          ),
        ],
      ),
      floatingActionButton: _gradientFab(),
    );
  }

  Widget _baslik() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      decoration: const BoxDecoration(
        gradient: anaGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medication_rounded, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'İlaç Hatırlatıcı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _ilaclar.isEmpty
                ? 'Hadi ilk ilacını ekleyelim'
                : '${_ilaclar.length} ilaç takip ediliyor',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _ilacKarti(Ilac ilac, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _renk1.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: anaGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ilac.ad,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        saatMetni(ilac.saat),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_rounded, color: _renk2),
              onPressed: () => _formAc(mevcut: ilac, index: i),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: () => _sil(i),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bosDurum() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: anaGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _renk1.withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.medication_rounded,
                  size: 60, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text(
              'Henüz ilaç yok',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Alttaki butona basarak ilk ilacını\n'
              'ekle, saatini seç, gerisini bize bırak.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: anaGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _renk1.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _formAc(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'İlaç Ekle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IlacFormSayfasi extends StatefulWidget {
  final Ilac? mevcut;
  const IlacFormSayfasi({super.key, this.mevcut});

  @override
  State<IlacFormSayfasi> createState() => _IlacFormSayfasiState();
}

class _IlacFormSayfasiState extends State<IlacFormSayfasi> {
  late final TextEditingController _adController;
  TimeOfDay? _secilenSaat;

  @override
  void initState() {
    super.initState();
    // Düzenleme ise mevcut değerlerle başla.
    _adController = TextEditingController(text: widget.mevcut?.ad ?? '');
    _secilenSaat = widget.mevcut?.saat;
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  Future<void> _saatSec() async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: _secilenSaat ?? TimeOfDay.now(),
    );
    if (secilen != null) {
      setState(() => _secilenSaat = secilen);
    }
  }

  void _kaydet() {
    final ad = _adController.text.trim();
    if (ad.isEmpty) {
      _uyari('Lütfen ilaç adını yaz.');
      return;
    }
    if (_secilenSaat == null) {
      _uyari('Lütfen bir saat seç.');
      return;
    }
    Navigator.pop(context, Ilac(ad, _secilenSaat!));
  }

  void _uyari(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final duzenleme = widget.mevcut != null;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: anaGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Text(
                  duzenleme ? 'İlacı Düzenle' : 'Yeni İlaç',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('İlaç adı',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _adController,
                    decoration: InputDecoration(
                      hintText: 'Örn. Tansiyon hapı',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Saat',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _saatSec,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: _renk2),
                          const SizedBox(width: 12),
                          Text(
                            _secilenSaat == null
                                ? 'Saat seç'
                                : saatMetni(_secilenSaat!),
                            style: TextStyle(
                              fontSize: 16,
                              color: _secilenSaat == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _kaydet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: anaGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _renk1.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Kaydet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
