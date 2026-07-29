import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _bildirimPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _bildirimSistemBaslat() async {
  tzdata.initializeTimeZones();

  const androidAyarlari = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ayarlar = InitializationSettings(android: androidAyarlari);
  await _bildirimPlugin.initialize(ayarlar);

  final androidUygulama = _bildirimPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidUygulama?.requestNotificationsPermission();
  await androidUygulama?.requestExactAlarmsPermission();
}

String _tarihMetni(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const List<String> _ayAdlari = [
  '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String _gununMetni(DateTime d) => 'Bugün, ${d.day} ${_ayAdlari[d.month]}';

// Bir ilaç için bir sonraki hatırlatmayı planlar.
// Bugün zaten "içtim" işaretlenmişse veya saat geçmişse, yarına planlar.
Future<void> _bildirimAyarla(Ilac ilac) async {
  await _bildirimPlugin.cancel(ilac.id);

  final simdi = tz.TZDateTime.now(tz.local);
  final bugun = _tarihMetni(DateTime.now());
  var hedef = tz.TZDateTime(
      tz.local, simdi.year, simdi.month, simdi.day, ilac.saat.hour, ilac.saat.minute);

  final bugunAlindiMi = ilac.sonIcildiTarih == bugun;
  if (hedef.isBefore(simdi) || bugunAlindiMi) {
    hedef = hedef.add(const Duration(days: 1));
  }

  await _bildirimPlugin.zonedSchedule(
    ilac.id,
    'İlaç zamanı!',
    '${ilac.ad} ilacını içmeyi unutma.',
    hedef,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'ilac_hatirlatici_kanal',
        'İlaç Hatırlatmaları',
        channelDescription: 'İlaç saatini hatırlatan bildirimler',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bildirimSistemBaslat();
  runApp(const IlacHatirlaticiApp());
}

// Durum renkleri: alındı = yeşil, bekliyor = mavi, yaklaşıyor = turuncu
const Color _renkAlindi = Color(0xFF2E9F5B);
const Color _renkBekliyor = Color(0xFF3B82F6);
const Color _renkYaklasiyor = Color(0xFFF0A020);
const Color _sayfaArkaPlan = Color(0xFFF7F7F5);

const String _kayitAnahtari = 'ilaclar_listesi';

class IlacHatirlaticiApp extends StatelessWidget {
  const IlacHatirlaticiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Hatırlatıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _renkBekliyor),
        scaffoldBackgroundColor: _sayfaArkaPlan,
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

// Bir ilacı temsil eden model: adı, saati ve son içildiği tarih.
// Kalıcı kayıt için JSON'a çevrilip geri okunabiliyor.
// id: bildirim planlamak için sabit ve benzersiz bir numara.
class Ilac {
  int id;
  String ad;
  TimeOfDay saat;
  String? sonIcildiTarih; // "yyyy-M-d" formatında, o gün içildiyse dolu olur

  Ilac({
    required this.id,
    required this.ad,
    required this.saat,
    this.sonIcildiTarih,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'saat': saat.hour * 60 + saat.minute,
        'sonIcildiTarih': sonIcildiTarih,
      };

  factory Ilac.fromJson(Map<String, dynamic> json) {
    final dakika = json['saat'] as int;
    return Ilac(
      id: json['id'] as int,
      ad: json['ad'] as String,
      saat: TimeOfDay(hour: dakika ~/ 60, minute: dakika % 60),
      sonIcildiTarih: json['sonIcildiTarih'] as String?,
    );
  }
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
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _kayitliListeyiYukle();
  }

  Future<void> _kayitliListeyiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliMetin = prefs.getString(_kayitAnahtari);
    if (kayitliMetin != null) {
      final List<dynamic> liste = jsonDecode(kayitliMetin);
      setState(() {
        _ilaclar.clear();
        _ilaclar.addAll(liste.map((e) => Ilac.fromJson(e)));
        _yukleniyor = false;
      });
    } else {
      setState(() => _yukleniyor = false);
    }
    for (final ilac in _ilaclar) {
      await _bildirimAyarla(ilac);
    }
  }

  Future<void> _listeyiKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    final metin = jsonEncode(_ilaclar.map((e) => e.toJson()).toList());
    await prefs.setString(_kayitAnahtari, metin);
  }

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
      _listeyiKaydet();
      _bildirimAyarla(sonuc);
    }
  }

  void _sil(int index) {
    _bildirimPlugin.cancel(_ilaclar[index].id);
    setState(() => _ilaclar.removeAt(index));
    _listeyiKaydet();
  }

  void _icildiIsaretle(int index) {
    setState(() {
      _ilaclar[index].sonIcildiTarih = _tarihMetni(DateTime.now());
    });
    _listeyiKaydet();
    _bildirimAyarla(_ilaclar[index]);
  }

  bool _yaklasiyorMu(Ilac ilac) {
    final simdi = DateTime.now();
    final hedef = DateTime(
        simdi.year, simdi.month, simdi.day, ilac.saat.hour, ilac.saat.minute);
    final farkDakika = hedef.difference(simdi).inMinutes;
    return farkDakika >= 0 && farkDakika <= 60;
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: _sayfaArkaPlan,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _gununMetni(DateTime.now()),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'İlaçlarım',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ilaclar.isEmpty
                  ? _bosDurum()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _ilaclar.length,
                      itemBuilder: (context, i) => _ilacKarti(_ilaclar[i], i),
                    ),
            ),
            _altEkleButonu(),
          ],
        ),
      ),
    );
  }

  Widget _ilacKarti(Ilac ilac, int i) {
    final bugun = _tarihMetni(DateTime.now());
    final alindiMi = ilac.sonIcildiTarih == bugun;
    final yaklasiyor = !alindiMi && _yaklasiyorMu(ilac);

    final Color durumRengi =
        alindiMi ? _renkAlindi : (yaklasiyor ? _renkYaklasiyor : _renkBekliyor);
    final IconData durumIkon = alindiMi
        ? Icons.medication_rounded
        : (yaklasiyor ? Icons.notifications_rounded : Icons.medication_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yaklasiyor ? _renkYaklasiyor : const Color(0xFFECECEA),
          width: yaklasiyor ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 18,
                icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                onPressed: () => _formAc(mevcut: ilac, index: i),
              ),
              const SizedBox(width: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 18,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                onPressed: () => _sil(i),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: durumRengi.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(durumIkon, color: durumRengi, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ilac.ad,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          yaklasiyor
                              ? '${saatMetni(ilac.saat)} · yaklaşıyor'
                              : saatMetni(ilac.saat),
                          style: TextStyle(
                            color: yaklasiyor ? _renkYaklasiyor : Colors.grey,
                            fontSize: 13,
                            fontWeight:
                                yaklasiyor ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: alindiMi ? null : () => _icildiIsaretle(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: alindiMi ? _renkAlindi.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: alindiMi ? Colors.transparent : durumRengi,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (alindiMi)
                        Icon(Icons.check_rounded, size: 15, color: _renkAlindi),
                      if (alindiMi) const SizedBox(width: 4),
                      Text(
                        alindiMi ? 'İçtim' : 'İçtim mi?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: alindiMi ? _renkAlindi : durumRengi,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _renkBekliyor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_rounded,
                  size: 48, color: _renkBekliyor),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz ilaç yok',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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

  Widget _altEkleButonu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: GestureDetector(
        onTap: () => _formAc(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'İlaç ekle',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
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
    final id = widget.mevcut?.id ??
        DateTime.now().millisecondsSinceEpoch.remainder(1000000000);
    Navigator.pop(
      context,
      Ilac(
        id: id,
        ad: ad,
        saat: _secilenSaat!,
        sonIcildiTarih: widget.mevcut?.sonIcildiTarih,
      ),
    );
  }

  void _uyari(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final duzenleme = widget.mevcut != null;
    return Scaffold(
      backgroundColor: _sayfaArkaPlan,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duzenleme ? 'İlacı düzenle' : 'Yeni ilaç',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
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
                          borderSide: BorderSide(color: Colors.grey.shade200),
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
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: _renkBekliyor),
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
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }
}
