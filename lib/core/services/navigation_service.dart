import 'package:flutter/foundation.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static NavigationService get instance => _instance;

  NavigationService._internal();

  final ValueNotifier<String?> selectedCategoryNotifier = ValueNotifier<String?>(null);

  void selectCategory(String categoryId) {
    selectedCategoryNotifier.value = categoryId;
  }
}
