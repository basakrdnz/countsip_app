# CheerLog – 14 Günlük Geliştirme Planı

**Proje Kuralları:**
1. Her gün tek ana hedef. Yan hedef yok.
2. Her görev "bitti sayma kriteri" olmadan kapanmaz.
3. Her gün en az 1 test eklenir.
4. UI, data, business logic katmanları ayrı tutulur.
5. Firebase entegrasyonu önce emulator'da test edilir, sonra production.
6. App Store riskli metinler (alcohol, drink) UI içinde kalır, metadata dikkatli yazılır.

---

## Repo Düzeni (Başta Kilitliyoruz)

```
lib/
  core/
    constants/        # Drink types, point values
    errors/           # Custom exceptions
    utils/            # Helpers (date formatting, validators)
    theme/            # App theme, colors
  data/
    models/           # Firestore models (User, Entry, Friendship)
    repositories/     # Firebase data access layer
    datasources/      # Firebase service wrappers
  domain/
    entities/         # Business entities (if needed)
    usecases/         # Business logic (if complex)
  ui/
    screens/          # Home, Leaderboard, Profile, etc.
    widgets/          # Reusable components
  features/
    auth/             # Sign in, sign up screens
    entry/            # Add drink modal
    friends/          # Friend list, requests
    leaderboard/      # Rankings screen
    profile/          # Stats, settings

test/
  unit/
  widget/
  integration/

integration_test/
```

---

## Gün 0.5: Store/Policy Hazırlık (Kod Yok)

### Yapılacaklar
- App Store & Play Store copy kuralları yaz
- Screenshot checklist çıkar (happy people, drinks, no excessive consumption imagery)
- Age rating 17+ kuralını kaydet
- Privacy Policy taslağı (Firebase data usage, ads, friend visibility)
- Terms of Service taslağı (18+ requirement, liability waiver)

### Bitti Sayma Kriteri
- PRD compliance stratejisi güncellendi (Bölüm 15-17)
- Screenshot checklist hazır ve dokümante
- Store metadata kuralları yazıldı
- Privacy Policy + ToS taslakları Google Docs'ta

### Test
- Manual checklist review

---

## Gün 1: Proje İskeleti ve Firebase Setup

### Yapılacaklar
- Flutter projesi oluştur: `flutter create cheerlog`
- Klasör yapısını kur (yukarıdaki şemaya göre)
- `pubspec.yaml` düzenle (Tech Stack'e göre)
- `.env` dosyası hazırla (template)
- Firebase projesi oluştur (Console'da)
- iOS + Android app'leri Firebase'e ekle
- `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) indir
- Firebase Emulator Suite kur (local development için)
- Analyzer, lints ayarla
- Basit error handling standardı (`AppException`)

### Bitti Sayma Kriteri
- Uygulama açılıyor, boş ekran gösteriyor
- Firebase initialized (test connection)
- Test klasörü ve ilk test dosyası var
- `.env.example` dosyası commit edildi (gerçek keys gitignore'da)

### Test
- 1 adet "smoke test" (app launches)
- Firebase connection test (Firestore read/write test collection)

---

## Gün 2: UI Tema ve Navigation İskeleti

### Yapılacaklar
- Light theme (white/colorful) ayarla
- Color palette kilitle (primary: cheerful orange/blue, secondary: vibrant green)
- Bottom tab bar oluştur (Home, Add, Leaderboard, Profile)
- Go Router ile routing yapısını kur
- Tab bar icon'ları ekle (Material Icons veya custom SVG)

### Bitti Sayma Kriteri
- Bottom tab bar 4 sekme arasında geçiş yapıyor
- Her sekme placeholder ekran gösteriyor ("Home", "Leaderboard", vb.)
- Light theme tüm ekranlarda aktif
- Go Router ile navigation çalışıyor

### Test
- Widget test: "Tab bar doğru icon'ları gösteriyor"
- Widget test: "Tab selection değiştiriyor"
- Widget test: "Light theme doğru uygulanıyor"

---

## Gün 3: Firebase Auth Setup (Email + Google)

### Yapılacaklar
- Firebase Auth entegrasyonu
- Email/password sign up ekranı
- Email/password login ekranı
- Google Sign In entegrasyonu (iOS + Android)
- Form validasyonları (email format, password min 6 char)
- Auth state provider (Riverpod)

### Bitti Sayma Kriteri
- Email ile sign up çalışıyor (Firebase Console'da user görünüyor)
- Email ile login çalışıyor
- Google Sign In çalışıyor (iOS + Android)
- Auth state değişince app Home'a yönlendiriyor

### Test
- Integration test: email sign up flow
- Integration test: email login flow
- Widget test: form validation (empty email, invalid email)

---

## Gün 4: Apple Sign In + Profile Setup

### Yapılacaklar
- Apple Sign In entegrasyonu (iOS only, Android'de button gizli)
- Profile setup ekranı (ilk giriş sonrası)
  - Username input (unique check)
  - Display name input
  - Age verification checkbox (18+ confirm)
- Firestore `users` collection'a profile kaydet
- Username uniqueness check (Firestore query)

### Bitti Sayma Kriteri
- Apple Sign In çalışıyor (iOS)
- İlk giriş sonrası profile setup ekranı açılıyor
- Username unique kontrolü çalışıyor (aynı username girilince hata)
- Profile oluşturulduktan sonra Home'a gidiyor

### Test
- Integration test: Apple Sign In flow (iOS simulator)
- Unit test: username uniqueness check
- Widget test: age verification checkbox required

---

## Gün 5: Firestore Models + Repositories

### Yapılacaklar
- `User` model (Firestore serialization)
- `Entry` model (Firestore serialization)
- `Friendship` model (Firestore serialization)
- Repository pattern:
  - `UserRepository` (CRUD)
  - `EntryRepository` (CRUD + query by user)
  - `FriendshipRepository` (CRUD + friendship status checks)
- Riverpod providers (repositories)

### Bitti Sayma Kriteri
- Firestore'a dummy user yazıp okuyabiliyorsun
- Firestore'a dummy entry yazıp okuyabiliyorsun
- Model serialization (toJson, fromJson) çalışıyor

### Test
- Unit test: User model serialization
- Unit test: Entry model serialization
- Unit test: Repository save/fetch roundtrip

---

## Gün 6: Add Drink Entry Modal (UI + Logic)

### Yapılacaklar
- "Add" tab modal ekranı tasarla (iOS Calendar style - minimal, clean)
- **Drink type icon grid:**
  - 3x3 grid layout (GridView)
  - Each cell: emoji (48px) + name + points (e.g., "Beer • 1pt")
  - Selected: border highlight (primary color)
  - Bottom: "Request New Drink" text button
- **"Request New Drink" button:**
  - Opens email compose (url_launcher)
  - To: `cheerlog.feedback@gmail.com`
  - Subject: "New Drink Request"
  - Body: "I'd like to add: [your drink here]"
- Quantity stepper (iOS-style: - | number | +), default: 1, max: 20
- Venue text input (optional, max 50 chars)
- Note text input (optional, max 200 chars)
- Time picker (defaults to now, iOS date+time picker)
- "Log It!" button (primary color, bottom of modal)
- Point calculation logic (drinkType × quantity)

### Bitti Sayma Kriteri
- Modal açılıyor (Add tab'e basınca)
- Icon grid 3x3 düzende görünüyor
- Drink type seçince border highlight oluyor
- "Request New Drink" basınca email açılıyor (test edildi)
- Quantity stepper çalışıyor (- ve + butonları)
- Venue ve note yazılabiliyor
- Time picker çalışıyor (iOS native picker)
- "Log It!" basınca modal kapanıyor (henüz kaydetmiyor)

### Test
- Widget test: drink type icon grid rendering (9 icons görünüyor)
- Widget test: icon selection highlights border
- Widget test: quantity stepper (increase/decrease, max 20 enforcement)
- Widget test: note max 200 char validation
- Integration test: "Request New Drink" email launch (mock url_launcher)

---

## Gün 7: Entry Submission + AdMob Integration

### Yapılacaklar
- "Log It!" butonuna entry kaydetme logic'i ekle
- Firestore'a entry kaydet (EntryRepository kullan)
- User'ın `totalPoints` ve `totalDrinks` güncelle (Firestore transaction)
- AdMob setup:
  - `google_mobile_ads` initialize
  - Interstitial ad yükle
  - Entry submit sonrası ad göster
- Test ad ID kullan (development)

### Bitti Sayma Kriteri
- Entry kaydediliyor, Firestore'da görünüyor
- User stats güncelleniyor (totalPoints +X, totalDrinks +1)
- Entry submit sonrası interstitial ad gösteriliyor (test ad)
- Ad kapanınca modal kapanıyor

### Test
- Integration test: entry submission flow
- Unit test: point calculation logic
- Manual test: AdMob test ad görünüyor

---

## Gün 8: Home Feed (Friends' Entries)

### Yapılacaklar
- Home screen tasarla
- Firestore query: son 24 saatin entries (friendUIDs listesinden)
- Entry card widget (avatar, username, drinkType, venue, points, timeago)
- Empty state (henüz arkadaş yok veya entry yok)
- Pull-to-refresh

### Bitti Sayma Kriteri
- Home'da kendi entry'lerin görünüyor (şimdilik, friends henüz yok)
- Entry card güzel görünüyor (emoji, venue, time)
- Pull-to-refresh çalışıyor
- Empty state gösteriliyor (entry yoksa)

### Test
- Widget test: entry card rendering
- Widget test: empty state shows when no entries
- Integration test: submit entry, appears in Home feed

---

## Gün 9: Friend System (Search + Request)

### Yapılacaklar
- Friends screen (Profile tab altında buton veya ayrı tab)
- Friend search bar (username prefix query)
- Friend request buton (send request)
- Firestore `friendships` collection:
  - Status: "pending" or "accepted"
  - `requestedBy` field
- Friend request list (pending incoming requests)
- Accept/decline buttons

### Bitti Sayma Kriteri
- Username ile arkadaş aranıyor
- Friend request gönderiliyor (Firestore'da "pending" status)
- Gelen requests listeleniyorr
- Accept/decline çalışıyor (status "accepted" oluyor)

### Test
- Integration test: send friend request
- Integration test: accept friend request
- Unit test: username search query

---

## Gün 10: Friend List + Feed Filter

### Yapılacaklar
- Friends list ekranı (accepted friends)
- Home feed logic'i güncelle:
  - Sadece accepted friends'lerin entries göster
  - Firestore compound query (userIds in friends list + last 24h)
- Friend count badge (Profile'da: "X Friends")

### Bitti Sayma Kriteri
- Friends list sadece accepted friends gösteriyor
- Home feed sadece friends'lerin entries gösteriyor
- Kendi entries de görünüyor
- Friend count doğru hesaplanıyor

### Test
- Integration test: accept friend, see their entries in Home
- Unit test: friends list query

---

## Gün 11: Leaderboard (Weekly)

### Yapılacaklar
- Leaderboard screen tasarla
- Time filter: "This Week" (default)
- Firestore query:
  - Tüm friends'lerin entries (son 7 gün)
  - User'a göre groupBy, sum(points)
  - Sort by points desc
- Leaderboard list:
  - Rank, avatar, username, total points
  - Top 3: trophy icons (🥇🥈🥉)
  - Current user highlighted (different color)

### Bitti Sayma Kriteri
- Leaderboard son 7 günün toplamını gösteriyor
- Friends + kendisi listelenmiş
- Top 3 trophy icon var
- Current user highlight edilmiş

### Test
- Unit test: leaderboard calculation (mock data)
- Widget test: trophy icons top 3'te görünüyor
- Integration test: submit entry, leaderboard güncelleniyor

---

## Gün 12: Leaderboard (Monthly + All Time)

### Yapılacaklar
- Time filter toggle (Week / Month / All Time)
- Month query: son 30 gün
- All time query: tüm zamanlar
- Tiebreaker logic: aynı puan varsa en son entry sahibi üstte

### Bitti Sayma Kriteri
- Time filter değişince query güncelleniyor
- Month ve All Time leaderboard doğru hesaplanıyor
- Tiebreaker çalışıyor

### Test
- Unit test: tiebreaker logic
- Widget test: time filter toggle

---

## Gün 13: Profile Stats Screen

### Yapılacaklar
- Profile tab tasarla
- Stats display:
  - Total drinks logged
  - Total points
  - Favorite drink (most logged type)
  - Favorite venue (most logged location, if filled)
  - Streak (consecutive days with ≥1 entry)
- Settings button (gear icon)

### Bitti Sayma Kriteri
- Stats ekranı doğru data gösteriyor
- Favorite drink hesaplanıyor (en çok hangi type)
- Favorite venue hesaplanıyor (en çok hangi venue)
- Streak hesaplanıyor (consecutive days)

### Test
- Unit test: favorite drink calculation
- Unit test: streak calculation
- Widget test: stats rendering

---

## Gün 14: Settings + Delete Account

### Yapılacaklar
- Settings ekranı (Profile'dan açılır)
- Edit profile (username, display name - photo future)
- Friend management link (Friends list'e git)
- Notifications toggle (future, şimdilik placeholder)
- Delete account:
  - Confirmation dialog (2-step: "Are you sure?" + "Type DELETE to confirm")
  - Firestore'dan user + entries + friendships sil
  - Firebase Auth user sil
  - Logout + login screen'e dön

### Bitti Sayma Kriteri
- Settings ekranı açılıyor
- Edit profile çalışıyor (username değişikliği kaydediliyor)
- Delete account confirmation dialog gösteriyor
- Delete account sonrası tüm data siliniyor (Firestore'da yok)
- User logout oluyor, login screen açılıyor

### Test
- Integration test: delete account flow
- Unit test: confirmation text validation ("DELETE" yazmalı)

---

## Bonus (Eğer Zaman Kalırsa)

### Gün 15 (Optional): Polish + Bug Fixes
- Loading states (shimmer, skeletons)
- Error handling (network failure, Firestore errors)
- Offline mode message ("No internet connection")
- Dark mode support (future premium feature)

### Gün 16 (Optional): Beta Testing + Store Submission
- TestFlight / Internal Testing build
- 5 kişiyle beta test
- Bug fixes
- Store screenshots çek (iPhone 15 Pro Max + Pixel 8)
- App Store Connect'e submit
- Play Console'a submit

---

## Günlük Rutinler

### Her Gün Başında (10 dakika)
Şu 3 soruya cevap ver:
1. Bugün tek ana hedef ne?
2. Bugünkü hedefi bitince uygulamada hangi ekran/özellik değişmiş olacak?
3. Test neyi kanıtlayacak?

Cevabı 2 cümle yaz, sonra koda geç.

### Her Gün Sonunda (Kontrol Listesi)
1. App açılıyor mu? (smoke test)
2. Auth state doğru mu? (login flow çalışıyor mu)
3. Yeni eklenen feature çalışıyor mu? (happy path)
4. En az 1 test geçti mi? (unit/widget/integration)
5. Firebase Emulator'da test edildi mi? (production'a push etmeden önce)

---

## Notlar
- Her gün tek ana hedef. Yan hedef yok.
- "Bitti sayma kriteri" olmadan gün kapanmaz.
- Test yazmadan feature bitmez.
- Firebase Emulator Suite kullan (local test için, production quota harcama).
- AdMob test ad ID'leri kullan (development'ta), production'da gerçek ad unit'leri aktif et.

---

**End of 14-Day Plan**