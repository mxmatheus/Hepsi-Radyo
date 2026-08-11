import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/audio/audio_player_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/player/presentation/full_screen_player.dart';
import 'glass_container.dart';
import 'marquee_text.dart';

class DynamicIslandMiniPlayer extends ConsumerWidget {
  const DynamicIslandMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final radio = playerState.currentRadio;

    if (radio == null) return const SizedBox.shrink();

    final logoUrl = playerState.albumArtUrl ?? radio.corsSafeFavicon;
    final songOrCity = playerState.songTitle ?? radio.city ?? 'Canlı Yayın';

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd, vertical: AppTokens.padSm),
        child: GlassContainer(
          useBlur: true,
          borderRadius: AppTokens.radiusPill,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: AppColors.racingGreenDark.withOpacity(0.92),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const FullScreenPlayer(),
            );
          },
          child: Row(
            children: [
              // Radio Favicon / Album Artwork
              Hero(
                tag: 'radio_logo_${radio.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            memCacheWidth: 100,
                            memCacheHeight: 100,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _buildFallbackLogo(radio.name),
                          )
                        : _buildFallbackLogo(radio.name),
                  ),
                ),
              ),
            const SizedBox(width: 12),

            // Radio & Marquee Song Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    radio.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 16,
                    child: MarqueeText(
                      text: songOrCity,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Animated Equalizer Indicator
            if (playerState.isPlaying)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => Container(
                    width: 3,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.wineRedAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleY(
                        begin: 0.3,
                        end: 1.0,
                        duration: Duration(milliseconds: 300 + index * 150),
                      ),
                ),
              ),
            const SizedBox(width: 12),

            // Play / Pause Button
            IconButton(
              onPressed: () {
                ref.read(playerProvider.notifier).togglePlayPause();
              },
              icon: playerState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
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
          fontSize: 18,
        ),
      ),
    );
  }
}
