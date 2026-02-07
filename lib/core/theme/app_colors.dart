import 'package:flutter/material.dart';
import 'dart:ui';

class AppColors {
  
  // Backgrounds (Arka Planlar)
  static const background = Color(0xFF0A0E14);      // Uygulamanın ana derin lacivert arka planı
  static const surface = Color(0xFF1A1F2E);         // Kartlar ve paneller için temel yüzey rengi
  static const surfaceElevated = Color(0xFF242938); // Hover durumları veya daha önde duran bileşenler için açık ton
  
  // Brand Accents (Marka Renkleri)
  static const primary = Color(0xFFFF8902);         // Ana aksiyon rengi (Canlı Turuncu)
  static const secondary = Color(0xFF4ECDC4);       // İkincil renk (Turkuaz) - Pozitif durumlar ve bazı içki türleri
  static const tertiary = Color(0xFFFFE66D);        // Üçüncül renk (Yumuşak Sarı) - Dikkat çekici detaylar
  static const accentPrimary = Color(0xFFEE5A6F);   // Turuncuyla birleşen mercan tonu (Gradyanlarda kullanılır)
  
  // Text Colors (Yazı Renkleri)
  static const textPrimary = Color(0xFFFFFFFF);     // Ana başlıklar ve yüksek kontrastlı yazılar (Beyaz)
  static const textSecondary = Color(0xFFF1F5F9);   // Gövde metinleri ve genel okuma alanları (Açık Gri)
  static const textTertiary = Color(0xFFCBD5E1);    // Yardımcı metinler ve daha az önemli bilgiler (Silik Gri)
  
  // Status Colors (Durum Renkleri)
  static const success = Color(0xFF4ECDC4);         // Başarı, onay ve tamamlama durumları
  static const warning = Color(0xFFFFE66D);         // Bekleme veya dikkat gerektiren durumlar
  static const error = Color(0xFFFF3B3B);           // Hatalar ve silme gibi tehlikeli işlemler (Kırmızı)
  
  // Borders (Kenarlıklar)
  static const border = Color(0x1AFFFFFF);           // Hafif ayırıcı çizgiler ve kenarlıklar (%10 Beyaz)
  
  // Component Semantic Colors (Bileşen Renkleri)
  static const cardBackground = surface;            // Kartların arka plan rengi
  static const cardBorder = Color(0x1AFFFFFF);      // Kart kenarlık rengi
  static const buttonPrimary = primary;             // Birincil butonların rengi
  static const buttonOnPrimary = Color(0xFFFFFFFF); // Buton üzerindeki yazı rengi
  
  // Gradients (Gradyanlar)
  static const primaryGradient = [primary, accentPrimary]; // Ana turuncu-mercan geçişi
  static const rank1Gradient = [Color(0xFFFFD700), Color(0xFFFFA500)]; // Liderlik tablosu Altın (1.)
  static const rank2Gradient = [Color(0xFFC0C0C0), Color(0xFFA0A0A0)]; // Liderlik tablosu Gümüş (2.)
  static const rank3Gradient = [Color(0xFFCD7F32), Color(0xFFB87333)]; // Liderlik tablosu Bronz (3.)
}