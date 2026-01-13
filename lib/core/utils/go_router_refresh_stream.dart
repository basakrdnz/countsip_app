import 'dart:async';

import 'package:flutter/foundation.dart';

/// A [Listenable] that notifies listeners when a stream emits a new value.
/// Used with GoRouter's refreshListenable to react to auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
