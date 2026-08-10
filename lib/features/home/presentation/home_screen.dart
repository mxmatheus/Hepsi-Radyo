import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/audio/audio_player_service.dart';
import '../../../core/network/supabase_client.dart';
import '../../../core/storage/hive_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/models/banner_model.dart';
import '../../../shared/models/radio_model.dart';
import '../../../shared/widgets/custom_search_bar.dart';
import '../../../shared/widgets/radio_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const HomeScreen({super.key, this.scrollController});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  RealtimeChannel? _radioRealtimeChannel;

  List<RadioModel> _radios = [];
  List<RadioModel> _filteredRadios = [];
  List<RadioModel> _recentlyPlayed = [];
  String _searchQuery = '';

  final List<BannerModel> _sampleBanners = [
    BannerModel(
      id: 'b1',
      title: 'Kral FM Canlı Dinle',
      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
      actionType: 'radio',
      targetValue: 'seed-kral-fm',
    ),
    BannerModel(
      id: 'b2',
      title: '90\'lar Pop Nostalji Fırtınası',
      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800&q=80',
      actionType: 'category',
      targetValue: 'Nostalji & 90\'lar',
    ),
    BannerModel(
      id: 'b3',
      title: 'Kesintisiz Yabancı Pop Hits',
      imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80',
      actionType: 'radio',
      targetValue: 'seed-power-fm',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBannerAutoPlay();
    _setupSupabaseRealtime();
  }

  void _setupSupabaseRealtime() {
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        _radioRealtimeChannel = SupabaseService.client!
            .channel('public:radios')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'radios',
              callback: (payload) {
                _loadData();
              },
            )
            .subscribe();
      } catch (_) {}
    }
  }

  Future<void> _loadData() async {
    List<RadioModel> cached = HiveStorage.getCachedRadios();

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final response = await SupabaseService.client!.from('radios').select().order('name');
        if (response != null && (response as List).isNotEmpty) {
          cached = (response as List).map((e) => RadioModel.fromJson(e)).toList();
          await HiveStorage.cacheRadios(cached);
        }
      } catch (_) {}
    }

    final recents = HiveStorage.getRecentlyPlayed();
    if (mounted) {
      setState(() {
        _radios = cached;
        _filteredRadios = cached;
        _recentlyPlayed = recents;
      });
    }
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _sampleBanners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRadios = _radios;
      } else {
        _filteredRadios = _radios.where((r) {
          final nameMatch = r.name.toLowerCase().contains(query.toLowerCase());
          final cityMatch = r.city?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final tagMatch = r.tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
          return nameMatch || cityMatch || tagMatch;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _radioRealtimeChannel?.unsubscribe();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.racingGreenPrimary,
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              // Top Bar App Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.racingGreenPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.radio_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'HepsiRadyo',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.wineRedAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'CANLI',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: CustomSearchBar(onChanged: _onSearchChanged),
              ),

              if (_searchQuery.isEmpty) ...[
                // Sponsor / Highlight Banners Carousel
                SliverToBoxAdapter(
                  child: Container(
                    height: 160,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    child: PageView.builder(
                      controller: _bannerController,
                      itemCount: _sampleBanners.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final banner = _sampleBanners[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppTokens.padMd),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: banner.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(color: AppColors.racingGreenPrimary),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    padding: const EdgeInsets.all(AppTokens.padLg),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.85),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        banner.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Recently Played Section
                if (_recentlyPlayed.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd, vertical: 8),
                      child: Text(
                        'Son Dinlenenler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd),
                        itemCount: _recentlyPlayed.length,
                        itemBuilder: (context, index) {
                          final radio = _recentlyPlayed[index];
                          return GestureDetector(
                            onTap: () {
                              ref.read(playerProvider.notifier).playRadio(radio);
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.racingGreenPrimary,
                                    child: Text(
                                      radio.name.isNotEmpty ? radio.name[0] : 'R',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    radio.name,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isEmpty ? 'Tüm Radyo Kanalları' : 'Arama Sonuçları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${_filteredRadios.length} Radyo',
                        style: const TextStyle(fontSize: 12, color: AppColors.wineRedAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Radio List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.padMd),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final radio = _filteredRadios[index];
                      return RadioCard(radio: radio);
                    },
                    childCount: _filteredRadios.length,
                  ),
                ),
              ),

              // Bottom Scroll Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 170),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
