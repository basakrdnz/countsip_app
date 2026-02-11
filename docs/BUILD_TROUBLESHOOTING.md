# 🔧 Flutter Build Sorunları Çözüm Rehberi

Bu rehber, CountSip projesinde karşılaşılan build hatalarını çözmek için adım adım talimatlar içerir.

---

## 🚨 Seviye 1: Basit Temizlik (İlk Dene)

Herhangi bir build hatası aldığında **önce bunu dene**:

```powershell
flutter clean
flutter pub get
flutter run
```

---

## 🔄 Seviye 2: Derin Temizlik (Seviye 1 Çalışmazsa)

```powershell
flutter clean
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
flutter pub get
cd android
.\gradlew clean
cd ..
flutter run
```

---

## 🛠️ Seviye 3: Flutter Cache Onarımı

"Dart compiler exited unexpectedly" veya "PathNotFoundException" hatası alırsan:

```powershell
flutter clean
flutter pub cache repair
flutter run
```

---

## 💥 Seviye 4: Nükleer Seçenek (Her Şey Başarısız Olursa)

Android klasörünü sıfırdan oluştur:

```powershell
# 1. google-services.json'ı yedekle
Copy-Item android\app\google-services.json . -Force

# 2. Android klasörünü sil ve yeniden oluştur
Remove-Item -Recurse -Force android
flutter create --platform=android .

# 3. google-services.json'ı geri koy
Copy-Item google-services.json android\app\ -Force

# 4. Firebase plugin'ini ekle (settings.gradle.kts ve app/build.gradle.kts'ye)
# settings.gradle.kts plugins bloğuna ekle:
#   id("com.google.gms.google-services") version "4.4.2" apply false

# app/build.gradle.kts plugins bloğuna ekle:
#   id("com.google.gms.google-services")

# 5. Çalıştır
flutter run
```

---

## 📋 Sık Karşılaşılan Hatalar ve Çözümleri

### "APK bulunamadı" Hatası
```powershell
flutter clean
Remove-Item -Recurse -Force android\.gradle
flutter run
```

### "AGP Version Mismatch" Hatası
`android/build.gradle` ve `android/settings.gradle` (veya `.kts` versiyonları) içindeki AGP sürümlerinin aynı olduğundan emin ol.

### "Kotlin Metadata Incompatible" Hatası
Kotlin sürümünü güncelle:
- `settings.gradle.kts`: `id("org.jetbrains.kotlin.android") version "X.X.X"`

### "Gradle Wrapper Version" Hatası
`android/gradle/wrapper/gradle-wrapper.properties` dosyasındaki `distributionUrl`'i güncelle.

---

## 🔑 Altın Kural

> **Her build hatasında önce Seviye 1'i dene. İşe yaramazsa sırayla Seviye 2, 3, 4'e geç.**

---

## 📞 Son Çare

Hiçbir şey çalışmazsa:
1. Projeyi Git'e commit et
2. Tüm projeyi sil
3. Git'ten tekrar clone et
4. `flutter pub get` ve `flutter run`
