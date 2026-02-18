
class ThemeService {
  static int calculateLevel(double totalAPS) {
    // PRD 5.1: Her 50 APS 1 seviye kazandırır
    return (totalAPS / 50).floor() + 1;
  }
}
