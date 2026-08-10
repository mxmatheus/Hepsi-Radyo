import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class HepsiRadyoAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  HepsiRadyoAudioHandler() {
    _initPlayerListeners();
  }

  void _initPlayerListeners() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  Future<void> playRadio(String streamUrl, String title, String? logoUrl, {String? artist}) async {
    final item = MediaItem(
      id: streamUrl,
      album: 'HepsiRadyo Canlı Broadcast',
      title: title,
      artist: artist ?? 'Canlı Yayın',
      artUri: (!kIsWeb && logoUrl != null && logoUrl.startsWith('https://')) ? Uri.parse(logoUrl) : null,
    );
    mediaItem.add(item);

    try {
      await _player.stop();
      await _player.setUrl(streamUrl);
      _player.play();
      playbackState.add(playbackState.value.copyWith(
        playing: true,
        processingState: AudioProcessingState.ready,
      ));
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
      ));
    }
  }

  void updateMetadataTitle(String songTitle, String? artistName) {
    final current = mediaItem.value;
    if (current != null) {
      mediaItem.add(current.copyWith(
        title: songTitle.isNotEmpty ? songTitle : current.title,
        artist: artistName ?? current.artist,
      ));
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    playbackState.add(playbackState.value.copyWith(
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.ready,
    ));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
  }

  AudioPlayer get player => _player;
}
