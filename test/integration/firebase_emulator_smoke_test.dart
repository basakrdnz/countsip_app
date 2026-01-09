import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:countsip/firebase_options.dart';

const bool _runEmulatorTest =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TEST', defaultValue: false);
const String _emulatorHost =
    String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: 'localhost');
const int _firestoreEmulatorPort =
    int.fromEnvironment('FIREBASE_FIRESTORE_EMULATOR_PORT', defaultValue: 8080);
const int _authEmulatorPort =
    int.fromEnvironment('FIREBASE_AUTH_EMULATOR_PORT', defaultValue: 9099);

void main() {
  if (!_runEmulatorTest) {
    test('Firebase emulator smoke test (skipped)', () {}, skip: true);
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  test('writes and reads from Firestore emulator', () async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAuth.instance.useAuthEmulator(
      _emulatorHost,
      _authEmulatorPort,
    );

    FirebaseFirestore.instance.useFirestoreEmulator(
      _emulatorHost,
      _firestoreEmulatorPort,
    );

    final doc = FirebaseFirestore.instance.collection('emulator_smoke').doc();
    await doc.set({
      'ok': true,
      'ts': FieldValue.serverTimestamp(),
    });

    final snap = await doc.get();
    expect(snap.exists, isTrue);
    expect(snap.data()?['ok'], isTrue);
  });
}
