/// Typed model for a drink portion (e.g., "Standart 330ml", "Shot 40ml").
class DrinkPortion {
  final String name;
  final String? variety;
  final int volume;
  final double abv;

  const DrinkPortion({
    required this.name,
    this.variety,
    required this.volume,
    required this.abv,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (variety != null) 'variety': variety,
        'volume': volume,
        'abv': abv,
      };

  factory DrinkPortion.fromJson(Map<String, dynamic> json) => DrinkPortion(
        name: json['name'] as String,
        variety: json['variety'] as String?,
        volume: (json['volume'] as num).toInt(),
        abv: (json['abv'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrinkPortion &&
          name == other.name &&
          variety == other.variety &&
          volume == other.volume &&
          abv == other.abv;

  @override
  int get hashCode => Object.hash(name, variety, volume, abv);
}

/// Typed model for a drink category (e.g., Beer, Wine, Raki).
class DrinkCategory {
  final String id;
  final String name;
  final String emoji;
  final String? image;
  final List<DrinkPortion> portions;

  const DrinkCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.image,
    required this.portions,
  });
}
