import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/radio_card.dart';

class Top50Screen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const Top50Screen({super.key, this.scrollController});

  @override
  ConsumerState<Top50Screen> createState() => _Top50ScreenState();
}

class _Top50ScreenState extends ConsumerState<Top50Screen> {
  String selectedPeriod = 'all_time'; // 'daily' | 'weekly' | 'all_time'
  List<RadioModel> topRadios = [];

  @override
  void initState() {
    super.initState();
    _loadTopRadios();
  }

  void _loadTopRadios() {
    final top = HiveStorage.getTopRadios();
    setState(() {
      if (selectedPeriod == 'daily') {
        topRadios = List.from(top)..shuffle();
      } else if (selectedPeriod == 'weekly') {
        topRadios = List.from(top);
      } else {
        topRadios = top;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top 50 Dinlenme Sıralaması',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Segment Control (Günlük / Haftalık / Tüm Zamanlar)
            GlassContainer(
              borderRadius: AppTokens.radiusPill,
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildSegmentButton('daily', 'Günlük'),
                  _buildSegmentButton('weekly', 'Haftalık'),
                  _buildSegmentButton('all_time', 'Tüm Zamanlar'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (topRadios.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Henüz dinlenme verisi bulunamadı.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topRadios.length,
                itemBuilder: (context, index) {
                  final radio = topRadios[index];
                  final rank = index + 1;

                  if (rank <= 3) {
                    return _buildPodiumMetallicCard(radio: radio, rank: rank);
                  }

                  return Row(
                    children: [
                      // Normal Rank Number Badge
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.racingGreenPrimary.withOpacity(0.15),
                        ),
                        child: Text(
                          '$rank',
                          style: const TextStyle(
                            color: AppColors.racingGreenPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RadioCard(radio: radio),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 170),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumMetallicCard({required RadioModel radio, required int rank}) {
    List<Color> gradientColors;
    Color borderColor;
    Color textColor;
    String badgeTitle;
    IconData medalIcon;

    if (rank == 1) {
      // Metallic Gold #1
      gradientColors = [
        const Color(0xFFFFD700),
        const Color(0xFFD4AF37),
        const Color(0xFFB8860B),
      ];
      borderColor = const Color(0xFFFFF8DC);
      textColor = Colors.black;
      badgeTitle = '#1 ŞAMPİYON';
      medalIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      // Metallic Silver #2
      gradientColors = [
        const Color(0xFFE6E8FA),
        const Color(0xFFC0C0C0),
        const Color(0xFF708090),
      ];
      borderColor = Colors.white;
      textColor = Colors.black;
      badgeTitle = '#2 GÜMÜŞ DERECE';
      medalIcon = Icons.military_tech_rounded;
    } else {
      // Metallic Bronze #3
      gradientColors = [
        const Color(0xFFEDC9AF),
        const Color(0xFFCD7F32),
        const Color(0xFF8B4513),
      ];
      borderColor = const Color(0xFFFFE4C4);
      textColor = Colors.white;
      badgeTitle = '#3 BRONZ DERECE';
      medalIcon = Icons.workspace_premium_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.padSm),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd + 4),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                Icon(medalIcon, size: 16, color: textColor),
                const SizedBox(width: 6),
                Text(
                  badgeTitle,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${HiveStorage.getClickCount(radio.id)} Dinlenme',
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          RadioCard(radio: radio),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String periodKey, String label) {
    final isSelected = selectedPeriod == periodKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = periodKey;
            _loadTopRadios();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.wineRedAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
