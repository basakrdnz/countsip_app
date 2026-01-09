import 'package:flutter/material.dart';

class AddEntryScreen extends StatelessWidget {
  const AddEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Drink'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Add entry modal placeholder'),
      ),
    );
  }
}
