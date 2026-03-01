import 'package:flutter/foundation.dart';
import '../../data/models/drink_category_model.dart';

class NavigationEvent {
  final String categoryId;
  final String? variety;
  final DrinkPortion? portion;

  NavigationEvent({required this.categoryId, this.variety, this.portion});
}

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static NavigationService get instance => _instance;

  NavigationService._internal();

  final ValueNotifier<NavigationEvent?> navigationEventNotifier = ValueNotifier<NavigationEvent?>(null);

  // Notifier for Quick Add changes
  final ValueNotifier<int> quickAddUpdateNotifier = ValueNotifier<int>(0);

  void selectCategory(String categoryId, {String? variety, DrinkPortion? portion}) {
    navigationEventNotifier.value = NavigationEvent(
      categoryId: categoryId,
      variety: variety,
      portion: portion,
    );
  }

  void notifyQuickAddUpdated() {
    quickAddUpdateNotifier.value++;
  }
}
