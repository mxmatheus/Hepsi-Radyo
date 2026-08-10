import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/audio/audio_player_service.dart';
import '../../core/storage/hive_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../models/radio_model.dart';
import 'glass_container.dart';

class RadioCard extends ConsumerStatefulWidget {
  final RadioModel radio;
  final VoidCallback? onTap;

  const RadioCard({
    super.key,
    required this.radio,
    this.onTap,
  });

  @override
  ConsumerState<RadioCard> createState() => _RadioCardState();
}

class _RadioCardState extends ConsumerState<RadioCard> {
  late bool isFav;

  @override
  void initState() {
    super.initState();
    isFav = HiveStorage.isFavorite(widget.radio.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playerState = ref.watch(playerProvider);
    final isCurrentRadio = playerState.currentRadio?.id == widget.radio.id;
    final isPlaying = isCurrentRadio && playerState.isPlaying;
    final logoUrl = widget.radio.corsSafeFavicon;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: AppTokens.padSm),
      padding: const EdgeInsets.all(12),
      borderRadius: AppTokens.radiusMd,
      color: isCurrentRadio
          ? (isDark ? AppColors.racingGreenDark : AppColors.lightCard)
          : null,
      border: isCurrentRadio
          ? Border.all(color: AppColors.wineRedAccent, width: 1.5)
          : null,
      onTap: () {
        ref.read(playerProvider.notifier).playRadio(widget.radio);
        widget.onTap?.call();
      },
      child: Row(
        children: [
          // Logo Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.radio.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCurrentRadio
                        ? AppColors.wineRedAccent
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        widget.radio.city ?? 'Türkiye',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.radio.tags.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.racingGreenPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.radio.tags.first,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.racingGreenPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Favorite Heart Button
          IconButton(
            onPressed: () async {
              await HiveStorage.toggleFavorite(widget.radio.id);
              setState(() {
                isFav = !isFav;
              });
            },
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isFav ? AppColors.wineRedAccent : (isDark ? Colors.white54 : Colors.black38),
              size: 22,
            ),
          ),

          // Play / Equalizer Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCurrentRadio ? AppColors.wineRedAccent : AppColors.racingGreenPrimary,
              shape: BoxShape.circle,
            ),
            child: isPlaying
                ? const Icon(Icons.pause_rounded, color: Colors.white, size: 22)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1))
                : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.racingGreenPrimary,
      alignment: Alignment.center,
      child: Text(
        widget.radio.name.isNotEmpty ? widget.radio.name[0].toUpperCase() : 'R',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}
