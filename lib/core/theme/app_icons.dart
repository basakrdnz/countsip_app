import 'package:flutter/material.dart';
import 'package:uicons/uicons.dart';

class AppIcons {
  // Common UI Icons (UIcons Regular Straight)
  static final IconData user = UIcons.regularStraight.user;
  static final IconData plus = UIcons.regularStraight.plus;
  static final IconData minus = UIcons.regularStraight.minus_small; // 'minus' not found, usage 'minus_small'
  static final IconData bell = UIcons.regularStraight.bell;
  static final IconData home = UIcons.regularStraight.home;
  static final IconData calendar = UIcons.regularStraight.calendar;
  static final IconData settings = UIcons.regularStraight.settings;
  static final IconData search = UIcons.regularStraight.search;
  static final IconData clock = UIcons.regularStraight.clock;
  static final IconData lock = UIcons.regularStraight.lock;
  static final IconData angleLeft = UIcons.regularStraight.angle_left;
  static final IconData angleRight = UIcons.regularStraight.angle_right;
  static final IconData angleDown = UIcons.regularStraight.angle_small_down;
  static final IconData cross = UIcons.regularStraight.cross;
  static final IconData check = UIcons.regularStraight.check;
  static final IconData ban = UIcons.regularStraight.ban;
  static final IconData envelope = UIcons.regularStraight.envelope;
  static final IconData share = UIcons.regularStraight.share;
  static final IconData copy = UIcons.regularStraight.copy;
  static final IconData paperPlane = UIcons.regularStraight.paper_plane;
  static final IconData at = UIcons.regularStraight.at;
  static final IconData mars = UIcons.regularStraight.mars;
  static final IconData venus = UIcons.regularStraight.venus;
  static final IconData drinkAlt = UIcons.regularStraight.cocktail;
  static final IconData bolt = UIcons.regularStraight.bolt;
  static final IconData phoneCall = UIcons.regularStraight.phone_call;
  static final IconData eyeIcon = UIcons.regularStraight.eye;
  static final IconData eyeCrossed = UIcons.regularStraight.crossed_eye;
  static final IconData exclamation = UIcons.regularStraight.exclamation;
  static final IconData tachometerFast = UIcons.regularStraight.tachometer_fast;
  static const IconData trophyIcon = Icons.workspace_premium_rounded; // Used material icon for stability
  static final IconData addUser = UIcons.regularStraight.user_add;
  static final IconData users = UIcons.regularStraight.users;
  static final IconData settingsSliders = UIcons.regularStraight.settings_sliders;
  static final IconData helpIcon = UIcons.regularStraight.interrogation; // Alias for interrogation/help
  static final IconData exit = UIcons.regularStraight.exit;
  static final IconData menuDotsVertical = UIcons.regularStraight.menu_dots_vertical;
  static final IconData document = UIcons.regularStraight.document;
  static final IconData infoCircle = UIcons.regularStraight.info;
  static final IconData moon = UIcons.regularStraight.moon;
  static final IconData world = UIcons.regularStraight.world;
  static final IconData refresh = UIcons.regularStraight.refresh;
  static final IconData marker = UIcons.regularStraight.marker;
  static final IconData glassCheers = UIcons.regularStraight.glass_cheers;

  // Bold Icons for Auth Screens
  static final IconData exitBold = UIcons.boldStraight.exit;
  static final IconData addUserBold = UIcons.boldStraight.user_add;
  static final IconData lockBold = UIcons.boldStraight.lock;

  // Onboarding Specific Icons (Requested Styles)
  static final IconData onboardingGlass = UIcons.regularRounded.glass_cheers;
  static final IconData onboardingGauge = UIcons.boldRounded.tachometer_fast;
  static final IconData onboardingFollowers = UIcons.regularRounded.users;

  // Fallbacks & Specialized Icons (Material Icons)
  static const IconData checkCircle = Icons.check_circle_outline_rounded;
  static const IconData userRemove = Icons.person_remove_outlined;
  static final IconData userRemoveIcon = Icons.person_remove_outlined; // Alias
  static const IconData glassWhiskey = Icons.local_bar_rounded;
  static const IconData edit = Icons.edit_outlined;
  static const IconData camera = Icons.camera_alt_outlined;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData group = Icons.group_outlined;
  static const IconData logout = Icons.logout_rounded;
  static const IconData trash = Icons.delete_outline_rounded;
  static const IconData addMember = Icons.person_add_outlined;
  static const IconData verticalMenu = Icons.more_vert_rounded;
  static const IconData memoPad = Icons.note_alt_outlined;

  // Drink Icons (Replacing Emojis)
  static const IconData drinkBeer = Icons.sports_bar_rounded;
  static const IconData drinkWine = Icons.wine_bar_rounded;
  static const IconData drinkLiquor = Icons.liquor_rounded;
  static const IconData drinkCocktail = Icons.local_bar_rounded;
  static const IconData drinkGlass = Icons.local_drink_rounded;
  static const IconData drinkWater = Icons.water_drop_rounded;
  static const IconData drinkCustom = Icons.auto_awesome_rounded;

  // Badge & UI Emojis Replacements
  static const IconData emojiParty = Icons.celebration_rounded;
  static const IconData emojiStar = Icons.star_rounded;
  static const IconData emojiFire = Icons.local_fire_department_rounded;
  static const IconData emojiDiamond = Icons.diamond_rounded;
  static const IconData emojiGlobe = Icons.public_rounded;
  static const IconData emojiCrown = Icons.military_tech_rounded;
  static const IconData emojiLeaf = Icons.eco_rounded;
  static const IconData emojiChart = Icons.show_chart_rounded;
  static const IconData emojiHeart = Icons.favorite_rounded;
  static const IconData emojiTarget = Icons.track_changes_rounded;
  // Filled/Rounded Detail Icons (User preferred style)
  static const IconData markerFilled = Icons.location_on_rounded;
  static const IconData peopleFilled = Icons.people_alt_rounded;
  static const IconData documentFilled = Icons.description_rounded;
  static const IconData galleryFilled = Icons.image_rounded;
  static const IconData noteFilled = Icons.sticky_note_2_rounded;
}
