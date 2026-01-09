# CountSip

Kısa kurulum notları (Flutter + Firebase)

## Önkoşullar
- Flutter 3.38.5 / Dart 3.10.4 (PATH’te `C:\tools\flutter\bin` vb. olmalı)
- Firebase CLI (login: `firebase login`)
- FlutterFire CLI (global)

## Firebase kurulum özeti
- Proje: `countsip-prod`
- Android paket: `com.example.countsip`
- iOS bundle: `com.example.countsip`
- Dosyalar:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.dart` (FlutterFire configure ile üretildi)

## Ortam değişkeni örneği
`env.example` dosyasını kopyalayıp doldurun (gerçek anahtarları eklemeyin):
```
cp env.example .env
```

## Çalıştırma
- Normal: `flutter run`
- Emulator (Firestore/Auth):  
  `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`

## Test
- Widget smoke: `flutter test`
- Emulator smoke (isteğe bağlı, Android/iOS emulator/device + Firebase Emulator Suite):  
  `flutter test test/integration/firebase_emulator_smoke_test.dart --dart-define=RUN_FIREBASE_EMULATOR_TEST=true`
  - Destekli ortam: Android/iOS emulator veya cihaz. Desktop host’ta çalışmaz.