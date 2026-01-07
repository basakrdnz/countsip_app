import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/placeholder_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CheerlogApp()));
}

class CheerlogApp extends StatelessWidget {
  const CheerlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CountSip',
      theme: AppTheme.light,
      home: const PlaceholderScreen(),
    );
  }
}
