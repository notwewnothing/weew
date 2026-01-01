import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// Packages
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

// Spotube Imports
import 'package:spotube/features/retro_player/providers/retro_player_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/provider/lyrics/synced.dart';
import 'package:spotube/models/lyrics.dart';

@RoutePage()
class CassettePlayerScreen extends HookConsumerWidget {
  const CassettePlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(retroPlayerStateProvider);
    final progress = ref.watch(retroPlaybackProgressProvider);
    final playing = ref.watch(retroPlayingProvider);
    final loopMode = ref.watch(retroPlaylistModeProvider);
    final position = ref.watch(retroPositionProvider);
    final size = MediaQuery.of(context).size;

    final currentTrack = playerState.activeTrack;
    final albumArtUrl = currentTrack?.album?.images?.firstOrNull?.url ?? '';
    final trackTitle = currentTrack?.name ?? 'NO TAPE INSERTED';
    final artistName =
        currentTrack?.artists?.firstOrNull?.name ?? 'Unknown Artist';

    // Validate album art URL
    final validAlbumArtUrl = albumArtUrl.isNotEmpty &&
            Uri.tryParse(albumArtUrl)?.hasAbsolutePath == true
        ? albumArtUrl
        : '';

    // Lyrics
    final lyricsQuery = ref.watch(syncedLyricsProvider(currentTrack));

    // Calculate duration
    final duration = currentTrack?.durationMs != null
        ? Duration(milliseconds: currentTrack!.durationMs!)
        : Duration.zero;

    // CRT Flicker Animation
    final flickerController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);

    // Volume State
    final volume = useState(audioPlayer.volume);

    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: Stack(
        children: [
          // 1. Retro Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
                ),
              ),
            ),
          ),

          // 2. Blurred Album Art
          if (validAlbumArtUrl.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Image.network(
                    validAlbumArtUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).pop()),

                // CASSETTE AREA
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 60 : 20,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _HighFidelityCassette(
                              progress: progress,
                              isPlaying: playing.value ?? false,
                              trackTitle: trackTitle,
                              artistName: artistName,
                              albumArtUrl: validAlbumArtUrl,
                              isDesktop: isDesktop,
                            ),
                            const SizedBox(height: 40),
                            // Lyrics Display
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isDesktop ? 600 : 500,
                              ),
                              child: _DotMatrixLyricsScreen(
                                lyricsQuery: lyricsQuery,
                                position: position,
                                duration: duration,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // CONTROLS
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 600 : 500,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _RetroControls(
                            playing: playing,
                            loopMode: loopMode,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _VolumeKnob(volume: volume),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. CRT OVERLAY
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: flickerController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: CRTScanlinePainter(
                      flickerOpacity: 0.05 + (flickerController.value * 0.02),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HIGH FIDELITY CASSETTE - IMPROVED PROPORTIONS
// =============================================================================

class _HighFidelityCassette extends HookWidget {
  final AsyncValue<double> progress;
  final bool isPlaying;
  final String trackTitle;
  final String artistName;
  final String albumArtUrl;
  final bool isDesktop;

  const _HighFidelityCassette({
    required this.progress,
    required this.isPlaying,
    required this.trackTitle,
    required this.artistName,
    required this.albumArtUrl,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final reelController = useAnimationController(
      duration: const Duration(seconds: 3),
    );

    useEffect(() {
      if (isPlaying) {
        reelController.repeat();
      } else {
        reelController.stop();
      }
      return null;
    }, [isPlaying]);

    final currentProgress = progress.value ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Make cassette much bigger on desktop
        final width = isDesktop
            ? math.min(constraints.maxWidth, 700.0)
            : math.min(constraints.maxWidth, 500.0);
        final height = width * 0.62; // Standard cassette ratio

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF202020),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
            ),
          ),
          child: Stack(
            children: [
              // Screws
              const Positioned(top: 8, left: 8, child: _Screw()),
              const Positioned(top: 8, right: 8, child: _Screw()),
              const Positioned(bottom: 8, left: 8, child: _Screw()),
              const Positioned(bottom: 8, right: 8, child: _Screw()),

              // Label Area - NOW BIGGER (Red takes 70% of cassette)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                height: height * 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[100], // Beige background for bottom 2/3
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      const BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Red top section (1/3 of the container)
                      Container(
                        height: (height * 0.7) /
                            4, // Exactly one third of the container
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F), // Bold red
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Top Info Bar with Album Art
                            Positioned(
                              top: 12,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  // Album Art Box
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: albumArtUrl.isNotEmpty
                                          ? Image.network(
                                              albumArtUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.music_note,
                                                color: Colors.white38,
                                                size: 24,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.music_note,
                                              color: Colors.white38,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Track Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trackTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.permanentMarker(
                                            color: Colors.white,
                                            fontSize: 18,
                                            shadows: [
                                              const Shadow(
                                                color: Colors.black38,
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          artistName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.teko(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Side Indicator
                                  Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "A",
                                        style: GoogleFonts.bebasNeue(
                                          color: Colors.black,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Beige middle section with the window (rest of the space)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color:
                                Colors.transparent, // Already beige from parent
                          ),
                          child: Stack(
                            children: [
                              // Position the window in the beige section
                              Positioned(
                                top:
                                    20, // Adjust this value to position the window in the beige section
                                left: width * 0.15,
                                right: width * 0.15,
                                height: height * 0.35,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151515),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.black54, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      children: [
                                        // Inner background
                                        Positioned.fill(
                                          child: Container(
                                              color: const Color(0xFF222222)),
                                        ),

                                        // Reels - VERTICALLY CENTERED
                                        Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _AnimatedReel(
                                                controller: reelController,
                                                progress: currentProgress,
                                                isSupply: true,
                                                size: width * 0.12,
                                              ),
                                              // Tape between reels
                                              Container(
                                                width: width * 0.15,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF8B4513),
                                                      Color(0xFFD2691E),
                                                      Color(0xFF8B4513),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              _AnimatedReel(
                                                controller: reelController,
                                                progress: currentProgress,
                                                isSupply: false,
                                                size: width * 0.12,
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Glass reflection
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withOpacity(0.1),
                                                  Colors.transparent,
                                                  Colors.transparent,
                                                  Colors.white
                                                      .withOpacity(0.05),
                                                ],
                                                stops: const [
                                                  0.0,
                                                  0.3,
                                                  0.7,
                                                  1.0
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
              // Bottom Grip
              Positioned(
                bottom: 0,
                left: width * 0.2,
                right: width * 0.2,
                height: 35,
                child: CustomPaint(painter: _TrapezoidPainter()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedReel extends StatelessWidget {
  final AnimationController controller;
  final double progress;
  final bool isSupply;
  final double size;

  const _AnimatedReel({
    required this.controller,
    required this.progress,
    required this.isSupply,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate tape pack radius
    final double scale =
        isSupply ? 1.0 - (progress * 0.6) : 0.4 + (progress * 0.6);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.rotate(
          angle: controller.value * 2 * math.pi * (isSupply ? -1 : 1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Brown tape pack
              Container(
                width: size * scale,
                height: size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4E342E),
                  border: Border.all(color: Colors.black45, width: 1),
                ),
              ),
              // White spool hub
              Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEEEEEE),
                ),
                child: CustomPaint(
                  painter: _SpoolTeethPainter(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpoolTeethPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = const Color(0xFF111111);

    for (int i = 0; i < 3; i++) {
      final angle = (i * 120) * (math.pi / 180);
      final dx = center.dx + (size.width * 0.35) * math.cos(angle);
      final dy = center.dy + (size.width * 0.35) * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Screw extends StatelessWidget {
  const _Screw();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF444444),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.black87, size: 10),
    );
  }
}

// =============================================================================
// LYRICS DISPLAY
// =============================================================================

class _DotMatrixLyricsScreen extends StatelessWidget {
  final AsyncValue<dynamic> lyricsQuery;
  final AsyncValue<Duration> position;
  final Duration duration;

  const _DotMatrixLyricsScreen({
    required this.lyricsQuery,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[800]!, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2A1A), Color(0xFF2A3A2A)],
          ),
        ),
        child: Column(
          children: [
            // Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PLAY",
                    style: GoogleFonts.vt323(
                      color: Colors.greenAccent,
                      fontSize: 16,
                    ),
                  ),
                  position.when(
                    data: (pos) => Text(
                      "${_formatDuration(pos)} / ${_formatDuration(duration)}",
                      style: GoogleFonts.vt323(
                        color: Colors.greenAccent,
                        fontSize: 16,
                      ),
                    ),
                    loading: () => const Text(
                      "--:--",
                      style: TextStyle(color: Colors.green),
                    ),
                    error: (_, __) => const Text(
                      "--:--",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.green, height: 1),
            // Lyrics
            Expanded(
              child: Center(
                child: lyricsQuery.when(
                  data: (lyrics) {
                    final List<LyricSlice> list = lyrics?.lyrics ?? [];
                    if (list.isEmpty) {
                      return Text(
                        "NO DATA",
                        style: GoogleFonts.vt323(
                          color: Colors.green.withOpacity(0.5),
                          fontSize: 24,
                        ),
                      );
                    }
                    final currentMs = position.value?.inMilliseconds ?? 0;
                    final currentLine = list.lastWhere(
                      (line) => line.time.inMilliseconds <= currentMs,
                      orElse: () => list.first,
                    );
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        currentLine.text.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.vt323(
                          color: const Color(0xFF44FF44),
                          fontSize: 24,
                          shadows: [
                            const Shadow(
                              color: Colors.green,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

// =============================================================================
// TAPE RECORDER CONTROLS - AUTHENTIC STYLE
// =============================================================================

class _RetroControls extends StatelessWidget {
  final AsyncValue<bool> playing;
  final AsyncValue<PlaylistMode> loopMode;

  const _RetroControls({
    required this.playing,
    required this.loopMode,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playing.value ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TapeRecorderButton(
            icon: Icons.skip_previous_rounded,
            color: const Color(0xFF424242),
            onTap: () => audioPlayer.skipToPrevious(),
          ),
          _TapeRecorderButton(
            icon: Icons.stop_rounded,
            color: const Color(0xFFB71C1C),
            onTap: () => audioPlayer.pause(),
          ),
          _TapeRecorderButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: const Color(0xFF2E7D32),
            onTap: () => isPlaying ? audioPlayer.pause() : audioPlayer.resume(),
            isActive: isPlaying,
          ),
          _TapeRecorderButton(
            icon: Icons.skip_next_rounded,
            color: const Color(0xFF424242),
            onTap: () => audioPlayer.skipToNext(),
          ),
        ],
      ),
    );
  }
}

class _TapeRecorderButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const _TapeRecorderButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_TapeRecorderButton> createState() => _TapeRecorderButtonState();
}

class _TapeRecorderButtonState extends State<_TapeRecorderButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isActive ? Colors.green : Colors.black54,
            width: 2,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    offset: const Offset(0, 4),
                    blurRadius: 6,
                  ),
                  if (widget.isActive)
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                ],
        ),
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Icon(
          widget.icon,
          color: Colors.white.withOpacity(0.9),
          size: 26,
        ),
      ),
    );
  }
}

// =============================================================================
// VOLUME KNOB
// =============================================================================

class _VolumeKnob extends StatelessWidget {
  final ValueNotifier<double> volume;

  const _VolumeKnob({required this.volume});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "VOL",
          style: GoogleFonts.audiowide(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final delta = details.primaryDelta ?? 0;
            final newVal = (volume.value - (delta / 100)).clamp(0.0, 1.0);
            volume.value = newVal;
            audioPlayer.setVolume(newVal);
            HapticFeedback.selectionClick();
          },
          child: ValueListenableBuilder<double>(
            valueListenable: volume,
            builder: (context, vol, _) {
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF333333), Color(0xFF111111)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      painter: _KnobKnurlingPainter(),
                      size: const Size(70, 70),
                    ),
                    Transform.rotate(
                      angle: (vol * 270 - 135) * (math.pi / 180),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              const BoxShadow(
                                color: Colors.orangeAccent,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<double>(
          valueListenable: volume,
          builder: (context, vol, _) {
            return Text(
              '${(vol * 100).toInt()}',
              style: GoogleFonts.orbitron(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _KnobKnurlingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 30; i++) {
      final angle = (i * 12) * (math.pi / 180);
      final p1 = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// =============================================================================
// PAINTERS
// =============================================================================

class CRTScanlinePainter extends CustomPainter {
  final double flickerOpacity;

  CRTScanlinePainter({required this.flickerOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Scanlines
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }

    // Vignette
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.4),
        Colors.black.withOpacity(0.8),
      ],
      stops: const [0.6, 0.85, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = BlendMode.darken;
    canvas.drawRect(rect, paint);

    // Flicker
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white.withOpacity(flickerOpacity)
        ..blendMode = BlendMode.overlay,
    );
  }

  @override
  bool shouldRepaint(CRTScanlinePainter old) =>
      old.flickerOpacity != flickerOpacity;
}

class _TrapezoidPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF181818);
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.1, 0);
    path.lineTo(size.width * 0.9, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, paint);

    // Grip lines
    final linePaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2;
    for (double i = 5; i < size.height - 5; i += 5) {
      canvas.drawLine(
        Offset(size.width * 0.2, i),
        Offset(size.width * 0.8, i),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;

  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            onPressed: onClose,
          ),
          Text(
            "WALKMAN",
            style: GoogleFonts.audiowide(
              color: const Color(0xFF00E5FF),
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
