import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/audio/audio_player_service.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/palette_helper.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/marquee_text.dart';
import 'sleep_timer_dialog.dart';

class FullScreenPlayer extends ConsumerStatefulWidget {
  const FullScreenPlayer({super.key});

  @override
  ConsumerState<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends ConsumerState<FullScreenPlayer> {
  Color dynamicBgColor = AppColors.racingGreenDeepest;
  late bool isFav;
  double _volume = 1.0;
  bool _initializedPalette = false;

  @override
  void initState() {
    super.initState();
    final radio = ref.read(playerProvider).currentRadio;
    if (radio != null) {
      isFav = HiveStorage.isFavorite(radio.id);
    } else {
      isFav = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedPalette) {
      _initializedPalette = true;
      final playerState = ref.read(playerProvider);
      final radio = playerState.currentRadio;
      if (radio != null) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final targetArt = playerState.albumArtUrl ?? radio.corsSafeFavicon;
        _updatePalette(targetArt, isDark);
      }
    }
  }

  Future<void> _updatePalette(String? imageUrl, bool isDark) async {
    final color = await PaletteHelper.extractDominantColor(imageUrl, isDark: isDark);
    if (mounted) {
      setState(() {
        dynamicBgColor = color;
      });
    }
  }

  List<RadioModel> _getSimilarRadios(RadioModel current) {
    final allRadios = HiveStorage.getCachedRadios();
    return allRadios.where((r) {
      if (r.id == current.id) return false;
      bool sameCity = (r.city != null && r.city == current.city);
      bool sameTag = r.tags.any((t) => current.tags.contains(t));
      return sameCity || sameTag;
    }).take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerState = ref.watch(playerProvider);
    final radio = playerState.currentRadio;

    if (radio == null) return const SizedBox.shrink();

    final isFav = ref.watch(favoritesProvider).contains(radio.id);
    final similarRadios = _getSimilarRadios(radio);
    final displayArt = playerState.albumArtUrl ?? radio.corsSafeFavicon;
    final rawSongTitle = playerState.songTitle;
    final isActualSong = rawSongTitle != null &&
        rawSongTitle.trim().isNotEmpty &&
        rawSongTitle.trim().toLowerCase() != radio.name.trim().toLowerCase();

    final songTitle = isActualSong ? rawSongTitle!.trim() : 'Canlı Yayın';

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              dynamicBgColor,
              AppColors.racingGreenDeepest,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(AppTokens.padMd, 12, AppTokens.padMd, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 34, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      children: [
                        const Text(
                          'ŞU AN ÇALINIYOR',
                          style: TextStyle(
                            color: AppColors.goldHighlight,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          radio.city ?? 'Türkiye Canlı',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.wineRedAccent : Colors.white,
                      ),
                      onPressed: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(radio.id);
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Radio / Song Artwork Card with Small HepsiRadyo Watermark Badge
              Hero(
                tag: 'radio_logo_${radio.id}',
                child: Stack(
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        boxShadow: AppTokens.glowShadowGold,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        child: displayArt != null && displayArt.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: displayArt,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _buildFallbackLogo(radio.name),
                              )
                            : _buildFallbackLogo(radio.name),
                      ),
                    ),

                    // Small HepsiRadyo Watermark Overlay Badge on Bottom-Right
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radio_rounded, size: 12, color: AppColors.wineRedAccent),
                            SizedBox(width: 4),
                            Text(
                              'HepsiRadyo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: const Duration(milliseconds: 400)),

              const Spacer(),

              // Radio Name & Clean Frameless Marquee Song Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.padLg),
                child: Column(
                  children: [
                    Text(
                      radio.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 24,
                      width: double.infinity,
                      child: MarqueeText(
                        text: songTitle,
                        alwaysScroll: true,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Controls Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.padLg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bedtime_outlined, color: Colors.white70, size: 26),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const SleepTimerDialog(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                      onPressed: () {
                        ref.read(playerProvider.notifier).playPreviousRadio();
                      },
                    ),
                    // Main Play/Pause Button
                    GestureDetector(
                      onTap: () {
                        ref.read(playerProvider.notifier).togglePlayPause();
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.wineRedAccent,
                          boxShadow: AppTokens.glowShadowGold,
                        ),
                        child: playerState.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : Icon(
                                playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                      onPressed: () {
                        ref.read(playerProvider.notifier).playNextRadio();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 24),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Volume Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.padLg),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 20),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        activeColor: AppColors.wineRedAccent,
                        inactiveColor: Colors.white24,
                        onChanged: (v) {
                          setState(() {
                            _volume = v;
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                  ],
                ),
              ),

              // Similar Radios Carousel (Benzer Radyolar)
              if (similarRadios.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTokens.padLg, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Benzer Radyolar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd),
                    itemCount: similarRadios.length,
                    itemBuilder: (context, index) {
                      final item = similarRadios[index];
                      final itemLogoUrl = item.corsSafeFavicon;
                      return GestureDetector(
                        onTap: () {
                          ref.read(playerProvider.notifier).playRadio(item);
                          _updatePalette(itemLogoUrl, isDark);
                        },
                        child: Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 10),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(6),
                            borderRadius: AppTokens.radiusMd,
                            color: Colors.white10,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: itemLogoUrl != null && itemLogoUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: itemLogoUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => _buildFallbackLogo(item.name),
                                          )
                                        : _buildFallbackLogo(item.name),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(String name) {
    return Container(
      color: AppColors.wineRedAccent,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'R',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
    );
  }
}
