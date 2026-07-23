import 'package:flutter/material.dart';

class DaftarPeserta extends StatelessWidget {
  const DaftarPeserta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FC),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: const Center(
        child: Text('Halaman Daftar Peserta'),
      ),
    );
  }
}