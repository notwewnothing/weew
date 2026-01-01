import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:spotube/provider/audio_player/audio_player.dart';
import 'package:spotube/provider/audio_player/state.dart';
import 'package:spotube/services/audio_player/audio_player.dart';

/// Provides the current audio player state for retro screens to listen to
final retroPlayerStateProvider = Provider<AudioPlayerState>((ref) {
  return ref.watch(audioPlayerProvider);
});

/// Provides the current playback position as a stream
final retroPositionProvider = StreamProvider<Duration>((ref) {
  return audioPlayer.positionStream;
});

/// Provides the current playlist mode
final retroPlaylistModeProvider = StreamProvider<PlaylistMode>((ref) {
  return audioPlayer.loopModeStream;
});

/// Provides the shuffle state
final retroShuffleProvider = StreamProvider<bool>((ref) {
  return audioPlayer.shuffledStream;
});

/// Provides the playing state
final retroPlayingProvider = StreamProvider<bool>((ref) {
  return audioPlayer.playingStream;
});

/// Provides the duration of the current track
final retroCurrentTrackDurationProvider = Provider<Duration>((ref) {
  final state = ref.watch(retroPlayerStateProvider);
  final activeTrack = state.activeTrack;

  if (activeTrack == null) return Duration.zero;

  return Duration(milliseconds: activeTrack.durationMs);
});

/// Provides progress between 0 and 1
final retroPlaybackProgressProvider = StreamProvider<double>((ref) async* {
  final duration = ref.watch(retroCurrentTrackDurationProvider);

  if (duration.inMilliseconds <= 0) {
    yield 0.0;
    return;
  }

  await for (final position in audioPlayer.positionStream) {
    final progress = position.inMilliseconds / duration.inMilliseconds;
    yield (progress).clamp(0.0, 1.0);
  }
});

/// Helper to get player notifier for calling control methods
final retroPlayerNotifierProvider = Provider<AudioPlayerNotifier>((ref) {
  return ref.watch(audioPlayerProvider.notifier);
});
