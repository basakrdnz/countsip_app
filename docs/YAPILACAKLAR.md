# CountSip - TODO Listesi

> Son güncelleme: 11 Şubat 2026

---

## 🏆 1. Skor Tablosu (Leaderboard) Geliştirmeleri

### 1.1 Haftalık Sıfırlama Sistemi
- [ ] **Haftalık sıfırlama bilgisi gösterimi**
  - Kullanıcıya sıralamanın haftalık olduğunu açıkça belirt
  - Countdown timer: "Yeni haftaya X gün Y saat kaldı"
  - Haftalık kazanan badge/crown gösterimi
  
- [ ] **Backend: Haftalık reset mekanizması**
  - Her hafta pazartesi 00:00'da otomatik sıfırlama
  - Cloud Functions ile scheduled task
  - `weeklyPoints` ve `totalPoints` ayrımı
  
- [ ] **İki farklı görünüm modu**
  - Toggle: "Bu Hafta" / "Tüm Zamanlar"
  - Haftalık: `weeklyPoints` göster
  - Tüm zamanlar: `totalPoints` göster
  - Geçmiş haftaların kazananları arşivi (opsiyonel)

### 1.2 Ek Geliştirmeler
- [ ] Haftalık kazanana özel badge
- [ ] "Geçen hafta X. oldun" bildirimi
- [ ] Haftalık ilerleme grafiği

---

## 🍹 2. Alkol Ekleme - İçecek Çeşitleri

### 2.1 Yeni Kokteyl Kategorileri
En az 10 ekstra kokteyl eklenecek:

**Klasik Kokteyller:**
- [ ] Mojito
- [ ] Margarita (mevcut, detaylandır)
- [ ] Cosmopolitan
- [ ] Long Island Iced Tea
- [ ] Piña Colada
- [ ] Negroni
- [ ] Aperol Spritz
- [ ] Bloody Mary

**Popüler Kokteyller:**
- [ ] Sex on the Beach
- [ ] Mai Tai
- [ ] Caipirinha
- [ ] Moscow Mule
- [ ] Espresso Martini
- [ ] Old Fashioned

**Şot ve Diğer:**
- [ ] Jägerbomb
- [ ] B52
- [ ] Tequila Shot
- [ ] Sambuca

### 2.2 Her İçecek İçin Detaylar
- Standart hacim ve ABV bilgileri
- İkon/görsel (varsa 3D ikonlar)
- Açıklama metni (opsiyonel)

---

## 📍 3. Konum Özellikleri

### 3.1 Konum Ekleme (Temel)
- [ ] **Konum alma butonu**
  - "Konum Ekle" butonu (opsiyonel)
  - GPS ile mevcut konumu al
  - İzin yönetimi (location permission)
  
- [ ] **Mekan seçimi**
  - Kütüphane: `google_places_flutter` veya `geolocator` + `geocoding`
  - Yakındaki mekanları listele (bar, restoran, kafe)
  - Kullanıcı mekan seçebilsin
  - Manuel mekan ismi girişi de olsun
  
- [x] **Konum verisi saklama**
  - Firestore'da entry ile birlikte:
    - `locationName` (string)
    - `locationLat` (double) (Gelecek)
    - `locationLng` (double) (Gelecek)
    - `placeId` (opsiyonel, Google Places ID)

### 3.2 Konum Özellikleri (Advanced - Gelecek)
- [ ] **Yakındaki arkadaş önerisi**
  - İki kullanıcı yakın konumda (örn. 100m içinde) + uygulama aktif
  - "Kimle içiyorsun?" önerisi
  - Privacy: Kullanıcı onayı gerekli
  - Konum paylaşımını açık/kapalı yapma
  
- [ ] **Konum bazlı istatistikler**
  - En çok gittiğin mekanlar
  - Harita görünümü (Heat map)

---

## 📸 4. Anlık Fotoğraf Ekleme

### 4.1 Görsel Ekleme
- [x] **Fotoğraf çekme butonu**
  - Hızlı ekleme modunda olmasın
  - Normal eklemede opsiyonel
  - Kamera açma (image_picker paketi)
  - Galeri seçimi de ekle
  
- [x] **Fotoğraf önizleme**
  - Çekilen fotoyu göster
  - Yeniden çek / iptal seçenekleri
  
- [x] **Firebase Storage'a yükleme**
  - Sıkıştırma (max 1MB, 1024x1024)
  - Unique dosya adı (userId_timestamp.jpg)
  - Download URL'yi Firestore'da sakla
  
- [x] **Gösterim**
  - Home ekranında gün detaylarında foto thumb
  - Tıklayınca fullscreen görüntüleme

---

## 📝 5. Not Ekleme

### 5.1 Not Alanı
- [x] **Not input alanı**
  - Opsiyonel, expandable TextField
  - Placeholder: "Nasıl hissettin? Neler oldu?"
  - Max karakter: 500
  
- [x] **Not gösterimi**
  - Home ekranında gün detaylarında not varsa küçük ikon
  - Tıklayınca full notu göster
  - Emoji desteği

---

## 👤 6. Profil - Doğum Günü Değişikliği

### 6.1 Yaş → Doğum Günü
- [ ] **Veri modeli değişikliği**
  - `age` (int) → `birthDate` (Timestamp)
  - Firestore migration script
  
- [ ] **Profil setup ekranı**
  - DatePicker ile doğum günü seç
  - Yaş hesaplama: Auto-calculate from birthDate
  
- [ ] **Profil ekranı**
  - Doğum günü göster
  - Yaşı otomatik hesapla ve göster
  - "Yaş: 25 (Doğum günün: 15 Mart)"
  
- [ ] **Doğum günü bildirimi** (opsiyonel)
  - Arkadaşlarına doğum günü bildirimi
  - Özel badge/kutlama

### 6.2 Tüm Ekranlarda Güncelleme
- [ ] Signup ekranı
- [ ] Profile setup ekranı
- [ ] Profile edit ekranı
- [ ] Profile görüntüleme

---

## ⏰ 7. Alkol Ekleme - Saat Seçici İyileştirmesi

### 7.1 Mevcut Sorunlar
- Çerçeveler görünmüyor
- Kullanışlı değil

### 7.2 Çözümler
- [ ] **Time picker tasarımı**
  - Daha belirgin border ve shadow ekle
  - Cupertino DatePicker yerine Custom wheel picker dene
  - Ya da Material TimePicker kullan
  
- [ ] **Hızlı seçenekler**
  - "Şimdi", "30 dk önce", "1 saat önce" butonları
  - Daha pratik erişim
  
- [ ] **Görsel iyileştirme**
  - Time selector kartına border ekle (diğer kartlar gibi)
  - Background color ve shadow ayarla
  - Icon ekle (saat ikonu)

---

## 🎨 8. UI/UX İyileştirmeleri

### 8.1 Alkol Ekleme Ekranı - Renkler ve Gösterim
**Sorunlar** (görsele göre):
- Tahmini puan, alkol %, hacim gösterim kartları soluk
- Renkler ve kontrast zayıf
- "KAYDET" butonu daha belirgin olmalı

**Çözümler:**
- [ ] **Bilgi kartlarını belirginleştir**
  - Border ve shadow ekle (diğer kartlar gibi)
  - Renkler daha canlı
  - Typography: Bold değerler
  
- [ ] **Puan gösterimini vurgula**
  - "+1.5 pt" metni: Daha büyük, bold, turuncu/yeşil renk
  - Animasyonlu artış efekti
  - Daha dikkat çekici
  
- [ ] **KAYDET butonu**
  - Daha büyük
  - Gradient arka plan
  - Shadow/elevation ekle
  - Disabled state (içecek seçilmeden pasif)

### 8.2 Genel UI Tutarlılığı
- [ ] Tüm kartlarda aynı border/shadow stili
- [ ] Color palette standardizasyonu
- [ ] Typography scale kontrolü

---

## 🚀 9. Gelecek Geliştirmeler (Backlog)

### 9.1 Sosyal Özellikler
- [ ] Arkadaş aktivite feed'i iyileştirmesi
- [ ] Grup içme seansları (aynı anda birlikte ekleme)
- [ ] Challenge'lar (haftalık hedefler)

### 9.2 İstatistikler ve Analiz
- [ ] Haftalık/aylık grafikler
- [ ] En çok içilen içecek tipi
- [ ] Mekan bazlı istatistikler

### 9.3 Gamification
- [ ] Achievement system
- [ ] Level sistemi
- [ ] Streak (ardışık günler)

---

## 📋 Öncelik Sıralaması

### 🔴 Yüksek Öncelik (Hemen yapılacak)
1. Alkol ekleme - Saat seçici iyileştirmesi
2. UI renkler ve gösterim (alkol ekleme)
3. Doğum günü değişikliği (yaş → birthDate)

### 🟡 Orta Öncelik (Yakın gelecek)
4. İçecek çeşitleri genişletme (10+ kokteyl)
5. Not ekleme özelliği
6. Fotoğraf ekleme
7. Leaderboard haftalık/tüm zamanlar

### 🟢 Düşük Öncelik (Gelecek)
8. Konum özellikleri
9. Yakındaki arkadaş önerisi
10. Advanced sosyal özellikler

---

## 📝 Notlar
- Her bir özellik için ayrı PR açılacak
- Kullanıcı testleri yapılacak
- Firebase quota limitlerini kontrol et (özellikle storage ve geocoding)
