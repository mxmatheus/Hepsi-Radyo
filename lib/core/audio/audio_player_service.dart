import 'dart:async';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../../shared/models/radio_model.dart';
import '../network/image_url_helper.dart';
import '../network/supabase_client.dart';
import '../services/gamification_service.dart';
import '../storage/hive_storage.dart';
import 'audio_player_handler.dart';

class PlayerStateModel {
  final RadioModel? currentRadio;
  final bool isPlaying;
  final bool isLoading;
  final String? songTitle;
  final String? artistName;
  final String? albumArtUrl;
  final int? sleepTimerMinutesRemaining;

  PlayerStateModel({
    this.currentRadio,
    this.isPlaying = false,
    this.isLoading = false,
    this.songTitle,
    this.artistName,
    this.albumArtUrl,
    this.sleepTimerMinutesRemaining,
  });

  PlayerStateModel copyWith({
    RadioModel? currentRadio,
    bool? isPlaying,
    bool? isLoading,
    String? songTitle,
    String? artistName,
    String? albumArtUrl,
    bool clearAlbumArt = false,
    int? sleepTimerMinutesRemaining,
    bool clearSleepTimer = false,
  }) {
    return PlayerStateModel(
      currentRadio: currentRadio ?? this.currentRadio,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      songTitle: songTitle ?? this.songTitle,
      artistName: artistName ?? this.artistName,
      albumArtUrl: clearAlbumArt ? null : (albumArtUrl ?? this.albumArtUrl),
      sleepTimerMinutesRemaining: clearSleepTimer ? null : (sleepTimerMinutesRemaining ?? this.sleepTimerMinutesRemaining),
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<PlayerStateModel> {
  final Ref _ref;
  HepsiRadyoAudioHandler? _audioHandler;
  Timer? _metadataTimer;
  Timer? _sleepTimer;
  Timer? _connectionTimeoutTimer;
  Timer? _listenTimer;

  AudioPlayerNotifier(this._ref) : super(_initialState()) {
    _initAudioService();
  }

  static PlayerStateModel _initialState() {
    final lastRadio = HiveStorage.getLastPlayedRadio();
    if (lastRadio != null) {
      return PlayerStateModel(
        currentRadio: lastRadio,
        isPlaying: false,
        isLoading: false,
        songTitle: lastRadio.name,
        artistName: lastRadio.city ?? 'Canlı Yayın',
      );
    }
    return PlayerStateModel();
  }

  Future<void> _initAudioService() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => HepsiRadyoAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.hepsiradyo.channel.audio',
          androidNotificationChannelName: 'HepsiRadyo Canlı Yayın',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

      _audioHandler?.player.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;

        final isLoading = !isPlaying && (processingState == ProcessingState.loading || processingState == ProcessingState.buffering);

        if (isPlaying) {
          _connectionTimeoutTimer?.cancel();
          _startListenTimer();
        } else {
          _listenTimer?.cancel();
        }

        state = state.copyWith(
          isPlaying: isPlaying,
          isLoading: isLoading,
        );
      });
    } catch (_) {}
  }

  void _startListenTimer() {
    _listenTimer?.cancel();
    _listenTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (state.isPlaying) {
        await _ref.read(gamificationProvider.notifier).addListenMinutes(1);
      }
    });
  }

  Future<void> playRadio(RadioModel radio) async {
    _connectionTimeoutTimer?.cancel();
    await HiveStorage.saveLastPlayedRadio(radio);
    state = state.copyWith(
      currentRadio: radio,
      isLoading: true,
      songTitle: radio.name,
      artistName: 'Canlı Yayın',
      clearAlbumArt: true,
    );

    _connectionTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && state.isLoading && !state.isPlaying) {
        state = state.copyWith(
          isLoading: false,
          isPlaying: false,
          songTitle: 'Yayın Bağlantısı Sağlanamadı',
        );
      }
    });

    await HiveStorage.addRecentlyPlayed(radio);
    await HiveStorage.incrementClickCount(radio.id);
    _trackRadioClick(radio.id);

    // Check Radio Count Badges & Notify Riverpod State
    final recents = HiveStorage.getRecentlyPlayed();
    final uniqueCount = recents.map((e) => e.id).toSet().length;
    await _ref.read(gamificationProvider.notifier).checkRadioListenCount(uniqueCount);

    if (_audioHandler != null) {
      await _audioHandler!.playRadio(
        radio.streamUrl,
        radio.name,
        radio.faviconUrl,
        artist: radio.city ?? 'Canlı Yayın',
      );
    }

    _startMetadataPolling(radio);
  }

  void playNextRadio() {
    final current = state.currentRadio;
    final radios = HiveStorage.getCachedRadios();
    if (radios.isEmpty) return;

    if (current == null) {
      playRadio(radios.first);
      return;
    }

    final index = radios.indexWhere((r) => r.id == current.id);
    final nextIndex = (index == -1 || index >= radios.length - 1) ? 0 : index + 1;
    playRadio(radios[nextIndex]);
  }

  void playPreviousRadio() {
    final current = state.currentRadio;
    final radios = HiveStorage.getCachedRadios();
    if (radios.isEmpty) return;

    if (current == null) {
      playRadio(radios.last);
      return;
    }

    final index = radios.indexWhere((r) => r.id == current.id);
    final prevIndex = (index <= 0) ? radios.length - 1 : index - 1;
    playRadio(radios[prevIndex]);
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      if (_audioHandler != null) {
        await _audioHandler!.pause();
      }
      state = state.copyWith(isPlaying: false, isLoading: false);
    } else {
      final radio = state.currentRadio;
      if (radio != null) {
        final currentUrl = _audioHandler?.mediaItem.value?.id;
        if (currentUrl == null || currentUrl.isEmpty || currentUrl != radio.streamUrl) {
          await playRadio(radio);
        } else {
          if (_audioHandler != null) {
            await _audioHandler!.play();
          }
          state = state.copyWith(isPlaying: true, isLoading: false);
        }
      }
    }
  }

  Future<void> stop() async {
    if (_audioHandler == null) return;
    await _audioHandler!.stop();
    _metadataTimer?.cancel();
    _sleepTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    state = PlayerStateModel();
  }

  void _startMetadataPolling(RadioModel radio) {
    _metadataTimer?.cancel();
    if (!radio.isMetadataSupported) return;

    _fetchMetadata(radio);
    _metadataTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchMetadata(radio);
    });
  }

  Future<void> _fetchMetadata(RadioModel radio) async {
    try {
      Map<String, dynamic>? data;

      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        final res = await SupabaseService.client!.functions.invoke(
          'get-stream-metadata',
          body: {'stream_url': radio.streamUrl},
        );
        if (res.data is Map<String, dynamic>) {
          data = res.data as Map<String, dynamic>;
        }
      } else {
        const edgeFunctionUrl = 'https://stcgvfwyzojgndricgob.supabase.co/functions/v1/get-stream-metadata';
        final response = await http.post(
          Uri.parse(edgeFunctionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'stream_url': radio.streamUrl}),
        );
        if (response.statusCode == 200) {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        }
      }

      if (data != null && data['supported'] == true) {
        final rawTitle = _cleanMojibake(data['raw_title']?.toString());
        final song = _cleanMojibake(data['song']?.toString());
        final artist = _cleanMojibake(data['artist']?.toString());

        String displayTitle = radio.name;
        String queryForArt = '';

        if (artist != null && song != null && artist.isNotEmpty && song.isNotEmpty) {
          displayTitle = '$artist - $song';
          queryForArt = '$artist $song';
        } else if (song != null && song.isNotEmpty) {
          displayTitle = song;
          queryForArt = song;
        } else if (rawTitle != null && rawTitle.isNotEmpty) {
          displayTitle = rawTitle;
          queryForArt = rawTitle;
        }

        displayTitle = _cleanMojibake(displayTitle) ?? displayTitle;

        String? albumArt;
        if (queryForArt.isNotEmpty && queryForArt.length > 3) {
          albumArt = await _fetchiTunesArtwork(queryForArt);
        }

        state = state.copyWith(
          songTitle: displayTitle,
          artistName: artist ?? 'Canlı Yayın',
          albumArtUrl: albumArt,
          clearAlbumArt: (albumArt == null || albumArt.isEmpty),
        );
        _audioHandler?.updateMetadataTitle(displayTitle, artist ?? 'Canlı Yayın');
      }
    } catch (_) {}
  }

  Future<String?> _fetchiTunesArtwork(String query) async {
    try {
      final url = Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=1');
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json['results'] != null && (json['results'] as List).isNotEmpty) {
          final art = json['results'][0]['artworkUrl100']?.toString();
          if (art != null && art.startsWith('http')) {
            final highResArt = art.replaceAll('100x100bb', '600x600bb');
            return ImageUrlHelper.getCorsSafeUrl(highResArt);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    state = state.copyWith(sleepTimerMinutesRemaining: minutes);

    _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final current = state.sleepTimerMinutesRemaining ?? 0;
      if (current <= 1) {
        timer.cancel();
        _audioHandler?.pause();
        state = state.copyWith(clearSleepTimer: true, isPlaying: false);
      } else {
        state = state.copyWith(sleepTimerMinutesRemaining: current - 1);
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    state = state.copyWith(clearSleepTimer: true);
  }

  Future<void> _trackRadioClick(String radioId) async {
    // Local click tracking is handled in HiveStorage.incrementClickCount(radioId)
  }

  String? _cleanMojibake(String? text) {
    if (text == null || text.isEmpty) return text;
    var s = text;
    s = s.replaceAll('Ä±', 'ı');
    s = s.replaceAll('Ä°', 'İ');
    s = s.replaceAll('ÅŸ', 'ş');
    s = s.replaceAll('ÅŞ', 'Ş');
    s = s.replaceAll('Ã§', 'ç');
    s = s.replaceAll('Ã‡', 'Ç');
    s = s.replaceAll('Ã¼', 'ü');
    s = s.replaceAll('Ãœ', 'Ü');
    s = s.replaceAll('Ã¶', 'ö');
    s = s.replaceAll('Ã–', 'Ö');
    s = s.replaceAll('ÄŸ', 'ğ');
    s = s.replaceAll('ÄĞ', 'Ğ');
    return s;
  }

  @override
  void dispose() {
    _metadataTimer?.cancel();
    _sleepTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<AudioPlayerNotifier, PlayerStateModel>((ref) {
  return AudioPlayerNotifier(ref);
});
