import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Centralised UI feedback utilities for consistent toast and snack-bar messages.
///
/// Prefer these helpers over raw [Fluttertoast] / [ScaffoldMessenger] calls so
/// that styles and durations are uniform across the app.
class AppFeedback {
  AppFeedback._();

  // ── Toast helpers ──────────────────────────────────────────────────────────

  static Future<void> showSuccess(String message) {
    return Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green.shade700,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  static Future<void> showError(String message) {
    return Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  static Future<void> showInfo(String message) {
    return Fluttertoast.showToast(
      msg: message,
      backgroundColor: const Color(0xFFFF8902),
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  // ── SnackBar helpers ───────────────────────────────────────────────────────

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red.shade700);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green.shade700);
  }
}
