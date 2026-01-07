import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CountSip'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('CountSip is ready'),
      ),
    );
  }
}

