import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sıralama'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Sıralama Listesi'),
      ),
    );
  }
}
