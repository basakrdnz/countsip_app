import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/drink_data_service.dart';
import '../../core/services/navigation_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/drink_category_model.dart';

class HomeQuickAddSection extends StatefulWidget {
  final List<Map<String, dynamic>> quickAddConfigs;

  const HomeQuickAddSection({super.key, required this.quickAddConfigs});

  @override
  State<HomeQuickAddSection> createState() => _HomeQuickAddSectionState();
}

class _HomeQuickAddSectionState extends State<HomeQuickAddSection> {
  late final ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        try {
          _scrollController.jumpTo(1000 * 167.0);
          _startAutoScroll();
        } catch (e) {
          debugPrint('QuickAdd scroll init error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!_isAutoScrolling) return;
    const double scrollSpeed = 0.15;
    const Duration tick = Duration(milliseconds: 16);

    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(tick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        double nextScroll = _scrollController.offset + scrollSpeed;
        if (nextScroll >= maxScroll) {
          nextScroll = 1000 * 167.0;
          _scrollController.jumpTo(nextScroll);
        } else {
          _scrollController.jumpTo(nextScroll);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayOptions = widget.quickAddConfigs.map((config) {
      final data = DrinkDataService.instance.resolve(config);
      return {
        'id': data.id,
        'name': data.name,
        'emoji': data.emoji,
        'imagePath': data.imagePath,
        'subtitle': data.subtitle,
        'config': config,
      };
    }).toList();

    if (displayOptions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HIZLI EKLE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF8902).withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: Listener(
            onPointerDown: (_) {
              _isAutoScrolling = false;
              _scrollTimer?.cancel();
            },
            onPointerUp: (_) {
              _isAutoScrolling = true;
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted && _isAutoScrolling) _startAutoScroll();
              });
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 100000,
              itemBuilder: (context, index) {
                final option = displayOptions[index % displayOptions.length];
                final hasImage = option['imagePath'] != null;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final config = option['config'] as Map<String, dynamic>;
                      final portionMap = config['portion'] as Map<String, dynamic>?;
                      NavigationService.instance.selectCategory(
                        option['id']! as String,
                        variety: config['variety'] as String?,
                        portion: portionMap != null ? DrinkPortion.fromJson(portionMap) : null,
                      );
                      StatefulNavigationShell.of(context).goBranch(1);
                    },
                    child: Container(
                      width: 155,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFF8902).withOpacity(0.08),
                                    const Color(0xFFFF8902).withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.02),
                                      Colors.black.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: const Alignment(-1.5, -1.2),
                                  end: const Alignment(1.5, 1.2),
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.3, 0.45, 0.6],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -35,
                            top: -15,
                            bottom: -15,
                            child: hasImage
                                ? Image.asset(
                                    option['imagePath']! as String,
                                    width: 120,
                                    fit: BoxFit.contain,
                                    opacity: const AlwaysStoppedAnimation(0.8),
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 40),
                                      child: Text(
                                        option['emoji']! as String,
                                        style: const TextStyle(fontSize: 60),
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            right: 12,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    (option['name']! as String).toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  if (option['subtitle'] != null) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      option['subtitle']! as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: (option['subtitle'] as String).length > 12 ? 8 : 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.6),
                                        letterSpacing: 0.1,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'EKLE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF8902).withOpacity(0.7),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
