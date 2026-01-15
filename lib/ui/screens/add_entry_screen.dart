import 'package:flutter/material.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İçecek Ekle'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('İçecek ekleme ekranı'),
      ),
    );
  }
}
