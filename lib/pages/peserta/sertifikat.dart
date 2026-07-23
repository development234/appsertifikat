import 'package:flutter/material.dart';

class SertifikatPeserta extends StatelessWidget {
  const SertifikatPeserta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: const Center(
        child: Text('Halaman Sertifikat Peserta'),
      ),
    );
  }
}