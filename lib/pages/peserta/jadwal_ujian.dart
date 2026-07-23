import 'package:flutter/material.dart';

class JadwalUjianPeserta extends StatelessWidget {
  const JadwalUjianPeserta({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: const Center(
        child: Text('Halaman Jadwal Ujian Peserta'),
      ),
    );
  }
}