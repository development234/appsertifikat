import 'package:flutter/material.dart';

class Pendaftaran extends StatelessWidget {
  const Pendaftaran({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      ),
      body: const Center(
        child: Text('Halaman Pendaftaran'),
      ),
    );
  }
}