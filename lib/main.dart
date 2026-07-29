import 'package:flutter/material.dart';

void main() {
  runApp(const IlacHatirlaticiApp());
}

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

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medication_outlined, size: 96, color: renk.primary),
              const SizedBox(height: 24),
              Text('Hoş geldin!',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text(
                'Henüz ilaç eklemedin.\n'
                'Buraya ilaçlarını ve saatlerini ekleyeceğiz.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İlaç ekleme çok yakında! 💊')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('İlaç Ekle'),
      ),
    );
  }
}
