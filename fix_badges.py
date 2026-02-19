import re

with open('lib/core/services/badge_service.dart', 'r') as f:
    content = f.read()

# Make sure imports exist
if "import '../../core/theme/app_icons.dart';" not in content:
    content = content.replace("import '../../data/models/badge_model.dart';", "import '../../data/models/badge_model.dart';\nimport '../../core/theme/app_icons.dart';\nimport 'package:flutter/material.dart';")

# Map of emojis to IconData
emoji_map = {
    "'🍺'": "AppIcons.drinkBeer",
    "'🍺✨'": "Icons.sports_bar_outlined",
    "'��🏆'": "Icons.emoji_events_rounded",
    "'🍷'": "AppIcons.drinkGlass",
    "'🍷👑'": "AppIcons.emojiCrown",
    "'🥃'": "AppIcons.drinkWhiskey",
    "'🥃⭐'": "AppIcons.emojiStar",
    "'🥃👑'": "AppIcons.emojiCrown",
    "'🍸'": "AppIcons.drinkCocktail",
    "'🍸🏆'": "Icons.emoji_events_rounded",
    "'🎯'": "Icons.track_changes_rounded",
    "'��'": "Icons.eco_rounded",
    "'💯'": "Icons.workspace_premium_rounded",
    "'🚀'": "Icons.rocket_launch_rounded",
    "'⭐'": "AppIcons.emojiStar",
    "'💎'": "Icons.diamond_rounded",
    "'👑'": "AppIcons.emojiCrown",
    "'🎉'": "AppIcons.emojiParty",
    "'🥳'": "Icons.celebration_rounded",
    "'🌟'": "Icons.stars_rounded",
    "'🔥'": "Icons.local_fire_department_rounded",
    "'🌈'": "Icons.palette_rounded",
    "'🗺️'": "Icons.map_rounded",
    "'🏆'": "Icons.emoji_events_rounded",
    "'🍹'": "AppIcons.drinkCocktail", # Placeholder, actually tropical drink
    "'🍹⭐'": "AppIcons.emojiStar",
    "'🍹👑'": "AppIcons.emojiCrown",
    "'👥'": "Icons.people_rounded",
    "'👥✨'": "Icons.people_outline_rounded",
    "'👥⭐'": "Icons.group_add_rounded",
    "'🍻'": "AppIcons.drinkBeer",
    "'📍'": "Icons.location_on_rounded",
    "'🌍'": "Icons.public_rounded",
    "'📸'": "Icons.photo_camera_rounded",
    "'📷'": "Icons.camera_alt_rounded",
    "'🎨'": "Icons.color_lens_rounded",
    "'📅'": "Icons.calendar_month_rounded",
    "'��'": "Icons.fitness_center_rounded",
    "'🌙'": "Icons.nights_stay_rounded",
    "'🎇'": "Icons.celebration_rounded",
    "'🎆'": "Icons.celebration_rounded",
    "'🌆'": "Icons.location_city_rounded",
    "'☀️'": "Icons.wb_sunny_rounded",
    "'💘'": "Icons.favorite_rounded",
    "'🎃'": "Icons.sentiment_very_satisfied_rounded",
    "'⚡'": "Icons.bolt_rounded",
    "'✈️'": "Icons.flight_takeoff_rounded",
}

for emoji, replacement in emoji_map.items():
    content = content.replace(f"icon: {emoji},", f"icon: {replacement},")

with open('lib/core/services/badge_service.dart', 'w') as f:
    f.write(content)

print('Done replacing emojis in BadgeService')
