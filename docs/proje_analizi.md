# CountSip Proje Analizi

## 📱 Uygulama Özeti
**CountSip** - Sosyal içecek takip uygulaması. Arkadaşlarla yarışmalı liderlik tablosu, puan sistemi ve eğlenceli içecek kaydı.

---

## 🗂️ Proje Yapısı

```
lib/
├── main.dart                    # Ana giriş, router, Firebase init
├── firebase_options.dart        # Firebase yapılandırması
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Renk paleti (#4B3126 brand rengi)
│   │   ├── app_icons.dart       # Uygulama ikonları
│   │   ├── app_radius.dart      # Border radius değerleri
│   │   ├── app_spacing.dart     # Spacing değerleri
│   │   ├── app_text_styles.dart # Tipografi
│   │   └── app_theme.dart       # Light tema
│   ├── services/
│   │   ├── analytics_service.dart
│   │   ├── connectivity_service.dart
│   │   └── preferences_service.dart
│   ├── providers/               # Riverpod providers
│   ├── errors/                  # Hata yönetimi
│   └── utils/                   # Yardımcı fonksiyonlar
│
├── features/
│   └── auth/
│       ├── screens/
│       │   ├── onboarding_screen.dart       # 3 slide onboarding
│       │   ├── phone_login_screen.dart      # Telefon ile giriş
│       │   ├── phone_signup_screen.dart     # Telefon ile kayıt
│       │   ├── phone_forgot_password_screen.dart
│       │   └── profile_setup_screen.dart    # Profil kurulumu
│       └── providers/
│
├── ui/
│   ├── screens/
│   │   ├── splash_screen.dart       # Flutter splash (hexagon loading)
│   │   ├── home_screen.dart         # Ana sayfa + feed
│   │   ├── add_entry_screen.dart    # İçecek ekleme
│   │   ├── leaderboard_screen.dart  # Liderlik tablosu
│   │   ├── profile_screen.dart      # Profil
│   │   ├── profile_details_screen.dart
│   │   ├── settings_screen.dart     # Ayarlar
│   │   ├── friends_screen.dart      # Arkadaş listesi
│   │   ├── add_friend_screen.dart   # Arkadaş ekleme
│   │   ├── blocked_users_screen.dart
│   │   ├── notifications_screen.dart
│   │   └── root_shell_page.dart     # Bottom nav shell
│   └── widgets/
│       ├── cached_avatar.dart           # Önbellekli avatar widget (CachedNetworkImage)
│       ├── home_quick_add_section.dart  # Hızlı ekleme kayan listesi (HomeScreen'den ayrıştırıldı)
│       └── custom_drink_request_form.dart # 4 adımlı özel içecek istek formu
│
└── data/
    ├── models/
    │   └── drink_entry_model.dart       # DrinkEntry modeli + copyWith()
    ├── services/
    │   └── drink_data_service.dart
    └── repositories/
        └── auth_repository.dart
```

### Utility Sınıfları (`lib/core/utils/`)

| Dosya | Açıklama |
|---|---|
| `badge_utils.dart` | Rozet hesaplama: streak, max single night, time range — Firebase bağımsız, test edilebilir |
| `text_search.dart` | Levenshtein edit distance + fuzzy arama — UI katmanından bağımsız |

---

## 🧭 Navigation Flow

```
[Uygulama Açılışı]
       ↓
┌─────────────────────────────────────────────────────────────┐
│  Android Native Splash (#4B3126 kahverengi)                 │
│  → Flutter yüklenmeden önce OS tarafından gösteriliyor      │
└─────────────────────────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────────────────────────┐
│  Flutter Splash Screen (splash_screen.dart)                 │
│  → mainbg.png + hexagon loading animasyonu (2 saniye)       │
└─────────────────────────────────────────────────────────────┘
       ↓
 [Kullanıcı giriş yapmış mı?]
       │
       ├── HAYIR → Onboarding (3 slide)
       │              ↓
       │           Login / Signup
       │              ↓
       │           Profile Setup
       │              ↓
       └── EVET → Home (Tab Navigation)
                    │
                    ├── Home (feed)
                    ├── Add (içecek ekle)
                    ├── Leaderboard
                    └── Profile
```

---

## 🎨 Tema ve Renkler

| Renk | Hex | Kullanım |
|------|-----|----------|
| **Brand Dark** | `#4B3126` | Native splash, app icon bg, ana marka rengi |
| **Primary** | `#674739` | Butonlar, vurgular |
| **Primary Light** | `#8E6351` | Loading animasyon, secondary elements |
| **Primary Dark** | `#53362A` | Koyu vurgular |

### Fontlar:
- **Rosaline** - Dekoratif/başlık
- **CalSans** - UI metinleri

---

## 📦 Assets

### Görseller (`assets/images/`)
- `mainbg.png` - Ana arka plan (içecek elleri)
- `mainbgdark.png`, `mainbgempty.png`, `mainbgwemp.png` - Alternatif arka planlar
- `applogo.png`, `applogowname.png`, `countsiplogo.png` - Logolar

### İçecek İkonları (`assets/images/drinks/`)
- beer.png, wine.png, whiskey.png, vodka_enerji.png
- raki.png, gin.png, kokteyl.png, margarita.png, 7.png

### 3D İkonlar (`assets/images/3d/`)
- `glass3d.png` - Onboarding slide 1
- `people3d.png` - Onboarding slide 2
- `lock3d.png` - Onboarding slide 3
- Ve diğer 3D ikonlar

---

## 🔥 Firebase Yapılandırması

- **Firebase Auth** - Telefon ile kimlik doğrulama
- **Cloud Firestore** - Veritabanı
- **Firebase Storage** - Profil fotoğrafları
- **Firebase Analytics** - Kullanım takibi

### Firestore Collections:
- `users` - Kullanıcı profilleri (`totalPoints`, `weeklyPoints`, `createdAt`)
- `entries` - İçecek kayıtları (`DrinkEntry` modeli)
- `friendships` - Arkadaşlık ilişkileri
- `blocks` - Engellenen kullanıcılar (`blockerUid`, `blockedUid`, `createdAt`)
- `phoneNumbers` - SHA-256 hash ile telefon numarası kayıt kaydı
- `badges` - Rozet tanımları
- `userBadges` - Kazanılan rozetler
- `drink_requests` - Özel içecek talepleri
- `notifications` - Bildirimler

---

## 📱 Ekranlar Özeti (15 Ekran)

| Ekran | Dosya | Açıklama |
|-------|-------|----------|
| Splash | `splash_screen.dart` | Flutter loading ekranı |
| Onboarding | `onboarding_screen.dart` | 3 slide tanıtım |
| Login | `phone_login_screen.dart` | Telefon ile giriş |
| Signup | `phone_signup_screen.dart` | Telefon ile kayıt |
| Forgot Password | `phone_forgot_password_screen.dart` | Şifre sıfırlama |
| Profile Setup | `profile_setup_screen.dart` | İsim/kullanıcı adı kurulumu |
| Home | `home_screen.dart` | Ana feed + takvim |
| Add Entry | `add_entry_screen.dart` | İçecek ekleme (fuzzy arama, CachedAvatar) |
| Leaderboard | `leaderboard_screen.dart` | Sıralama tablosu |
| Profile | `profile_screen.dart` | Kullanıcı profili |
| Settings | `settings_screen.dart` | Uygulama ayarları |
| Friends | `friends_screen.dart` | Arkadaş listesi (CachedAvatar) |
| Add Friend | `add_friend_screen.dart` | Arkadaş arama (CachedAvatar) |
| Blocked Users | `blocked_users_screen.dart` | Engellenen kullanıcılar (CachedAvatar) |
| Notifications | `notifications_screen.dart` | Bildirimler |

---

## 🚀 Android Native Splash Yapılandırması

**Konum:** `android/app/src/main/res/values-v31/styles.xml`

```xml
<item name="android:windowSplashScreenBackground">#4B3126</item>
<item name="android:windowSplashScreenAnimatedIcon">@drawable/background</item>
<item name="android:windowSplashScreenIconBackgroundColor">#4B3126</item>
```

**Paket:** `flutter_native_splash: ^2.4.0` (pubspec.yaml satır 78)

---

## 📋 Önemli Belgeler

| Dosya | İçerik |
|-------|--------|
| `siptracker_prd.md` | Ürün gereksinimleri (PRD) |
| `siptracker_plan.md` | Geliştirme planı |
| `siptracker_techstack.md` | Teknoloji yığını |
| `siptracker_ui_guide.md` | UI tasarım rehberi |
| `progress_log.md` | Yapılan işler günlüğü |

---

## ✅ Mevcut Durum

### Tamamlananlar:
- ✅ Firebase entegrasyonu (Auth, Firestore, Storage, Analytics, App Check)
- ✅ Auth akışı — telefon numarası + SHA-256 hash ile unique email, profil kurulumu
- ✅ Onboarding ekranları (3D ikonlar + glassmorphism animasyonu)
- ✅ Tab navigation yapısı (GoRouter 17 + StatefulNavigationShell)
- ✅ Native splash screen
- ✅ Tema sistemi
- ✅ Home feed (arkadaş aktiviteleri, sosyal beslemeleri)
- ✅ İçecek ekleme formu (fuzzy arama, porsiyon seçimi, fotoğraf, not, konum)
- ✅ Leaderboard (haftalık + all-time, aggregate count sorguları)
- ✅ Arkadaşlık sistemi (ekle, kabul et, engelle, kaldır)
- ✅ BAC hesaplama (Watson formülü, cinsiyet bazlı TBW, 45 dk emilim eğrisi)
- ✅ Rozet sistemi (14 koşul tipi, 5 nadirlık seviyesi, TR/EN lokalizasyonu)
- ✅ Görsel önbellekleme (`CachedAvatar` widget, tüm ekranlarda standartlaştırıldı)
- ✅ Unit test kapsamı (~90 test, 6 test dosyası)

### Teknik Borç:
- 🔄 98 doğrudan Firestore çağrısı UI ekranlarında — `EntriesRepository` katmanı eksik
- 🔄 `feed_screen.dart` ve `notifications_screen.dart` özdeş pagination kodu taşıyor
- 🔄 Firestore koleksiyon isimleri string literal olarak dağılmış durumda
- 🔄 `widget_test.dart` yalnızca 1 trivial test içeriyor

---

> **Bu analiz, projenin mevcut durumunu ve yapısını kapsamlı bir şekilde özetlemektedir.**
