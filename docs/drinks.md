# CountSip - Alkol ve Puanlama Sistemi (APS)

**Son Güncelleme:** 2026-02-07
**Sürüm:** 1.0.0

## 📊 APS Formülü
APS, içilen alkolün kana karışma miktarını temsil eden basitleştirilmiş bir puandır.
```
APS = (Alkol Oranı (%) × Miktar (ml)) / 100
```
*Not: Kullanıcı dökümanında /10 olarak belirtilse de, örnek hesaplamalar (25.0 APS gibi) matematiksel olarak /100 olduğunu doğrulamaktadır.*

---

## 🍺 1. BİRAlar (BEER)
| İçecek | Miktar | Alkol % | APS |
|--------|--------|---------|-----|
| Standart Bira | 330ml / 500ml | 5.0% | 16.5 - 25.0 |
| Filtresiz Bira | 330ml / 500ml | 6.0% | 19.8 - 30.0 |
| Güçlü (Strong) Bira | 330ml / 500ml | 8.5% | 28.0 - 42.5 |

## 🍷 2. ŞARAPLAR (WINE)
| İçecek | Miktar | Alkol % | APS |
|--------|--------|---------|-----|
| Kırmızı Şarap | 150ml / 200ml | 13.0% | 19.5 - 26.0 |
| Beyaz Şarap | 150ml / 200ml | 11.0% | 16.5 - 22.0 |
| Rosé | 150ml / 200ml | 12.0% | 18.0 - 24.0 |

## 🥃 3. RAKI & SPIRITS
| İçecek | Tek (50ml) APS | Çift (100ml) APS | Alkol % |
|--------|----------------|------------------|---------|
| Rakı | 22.5 | 45.0 | 45% |
| Viski | 16.0 | 32.0 | 40% (40ml/80ml) |
| Votka | 16.0 | 32.0 | 40% (40ml/80ml) |
| Gin | 16.0 | 32.0 | 40% (40ml/80ml) |
| Tekila | 16.0 | 32.0 | 40% (40ml/80ml) |
| Rom | 16.0 | 32.0 | 40% (40ml/80ml) |

## 🍸 4. KOKTEYLLER (COCKTAILS)
### Efsaneler (Yüksek Alkol)
- **AMF (Adios Motherfucker):** 300ml, %26 -> **78.0 APS**
- **Long Island Iced Tea:** 300ml, %25 -> **75.0 APS**
- **Zombie:** 300ml, %22 -> **66.0 APS**

### Klasikler
- **Margarita:** 200ml, %17 -> **34.0 APS**
- **Mojito:** 300ml, %12 -> **36.0 APS**
- **Old Fashioned:** 100ml, %35 -> **35.0 APS**
- **Negroni:** 100ml, %26 -> **26.0 APS**
- **Martini:** 120ml, %32 -> **38.4 APS**

*(Tam liste uygulama içerisinde 'Kokteyller' kategorisinde mevcuttur)*
