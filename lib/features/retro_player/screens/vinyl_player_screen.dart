import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// Packages
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:google_fonts/google_fonts.dart';

// Spotube Imports
import 'package:spotube/features/retro_player/providers/retro_player_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';
import 'package:spotube/provider/lyrics/synced.dart';

/// **Neo-Retro Vinyl Player - Complete Enhanced Edition**
/// Features: Volume Knob, Audio Visualizer, CRT Overlay, Next Track Peek
@RoutePage()
class VinylPlayerScreen extends HookConsumerWidget {
  const VinylPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // STATE & PROVIDERS
    final playerState = ref.watch(retroPlayerStateProvider);
    final progress = ref.watch(retroPlaybackProgressProvider);
    final playing = ref.watch(retroPlayingProvider);
    final loopMode = ref.watch(retroPlaylistModeProvider);
    final position = ref.watch(retroPositionProvider);
    final size = MediaQuery.of(context).size;

    // Data Extraction
    final currentTrack = playerState.activeTrack;
    final album = currentTrack?.album;
    final albumArtUrl = album?.images?.firstOrNull?.url ?? '';
    final trackTitle = currentTrack?.name ?? 'Unknown Track';
    final artistName =
        currentTrack?.artists?.firstOrNull?.name ?? 'Unknown Artist';

    // Calculate duration
    final duration = currentTrack?.durationMs != null
        ? Duration(milliseconds: currentTrack!.durationMs!)
        : Duration.zero;

    // Next Track Peek
    final nextTrack = playerState.tracks.isNotEmpty &&
            playerState.tracks.length > 1
        ? playerState.tracks[(playerState.tracks.indexOf(currentTrack!) + 1) %
            playerState.tracks.length]
        : null;
    final nextAlbumArt = nextTrack?.album?.images?.firstOrNull?.url ?? '';

    // Lyrics
    final lyricsQuery = ref.watch(syncedLyricsProvider(currentTrack));

    // Layout Logic
    final isLandscape = size.width > size.height;
    final isDesktop = size.width > 800;

    // ANIMATION CONTROLLERS
    final crtFlickerController = useAnimationController(
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);

    final visualizerController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    )..repeat();

    // Volume State
    final volume = useState(audioPlayer.volume);

    return Focus(
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            // 1. DYNAMIC BACKGROUND
            if (albumArtUrl.isNotEmpty)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Image.network(
                    albumArtUrl,
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.5),
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.black),
                  ),
                ),
              ),

            // 2. VIGNETTE
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.3, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // 3. NEXT TRACK PEEK (Desktop only)
            if (isDesktop && nextAlbumArt.isNotEmpty)
              Positioned(
                right: -100,
                top: size.height * 0.3,
                child: Opacity(
                  opacity: 0.25,
                  child: Transform.rotate(
                    angle: 0.1,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          nextAlbumArt,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 4. MAIN LAYOUT
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Content Body
                  Expanded(
                    child: isLandscape
                        ? _LandscapeLayout(
                            progress: progress,
                            playing: playing,
                            albumArtUrl: albumArtUrl,
                            trackTitle: trackTitle,
                            artistName: artistName,
                            position: position,
                            duration: duration,
                            loopMode: loopMode,
                            lyricsQuery: lyricsQuery,
                            visualizerAnim: visualizerController,
                            isDesktop: isDesktop,
                            volume: volume,
                          )
                        : _PortraitLayout(
                            progress: progress,
                            playing: playing,
                            albumArtUrl: albumArtUrl,
                            trackTitle: trackTitle,
                            artistName: artistName,
                            position: position,
                            duration: duration,
                            loopMode: loopMode,
                            lyricsQuery: lyricsQuery,
                            visualizerAnim: visualizerController,
                            volume: volume,
                          ),
                  ),
                ],
              ),
            ),

            // 5. CRT OVERLAY (Scanlines + Flicker)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: crtFlickerController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: CRTOverlayPainter(
                        flickerIntensity:
                            0.03 + (crtFlickerController.value * 0.015),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LAYOUTS
// =============================================================================

class _LandscapeLayout extends StatelessWidget {
  final AsyncValue<double> progress;
  final AsyncValue<bool> playing;
  final String albumArtUrl;
  final String trackTitle;
  final String artistName;
  final AsyncValue<Duration> position;
  final Duration duration;
  final AsyncValue<PlaylistMode> loopMode;
  final AsyncValue<dynamic> lyricsQuery;
  final Animation<double> visualizerAnim;
  final bool isDesktop;
  final ValueNotifier<double> volume;

  const _LandscapeLayout({
    required this.progress,
    required this.playing,
    required this.albumArtUrl,
    required this.trackTitle,
    required this.artistName,
    required this.position,
    required this.duration,
    required this.loopMode,
    required this.lyricsQuery,
    required this.visualizerAnim,
    required this.isDesktop,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final vinylSize = math.min(size.width * 0.45, size.height * 0.85);

    return Row(
      children: [
        // LEFT: Turntable Deck + Visualizer
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              progress.when(
                data: (progressValue) => _VinylVisualization(
                  progressValue: progressValue,
                  isPlaying:
                      playing.maybeWhen(data: (p) => p, orElse: () => false),
                  albumArtUrl: albumArtUrl,
                  size: vinylSize,
                ),
                loading: () =>
                    CircularProgressIndicator(color: Colors.amber[400]),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 30),
              // Audio Visualizer
              SizedBox(
                height: 80,
                width: vinylSize * 0.8,
                child: _AudioVisualizer(
                  playing: playing,
                  animation: visualizerAnim,
                ),
              ),
            ],
          ),
        ),

        // RIGHT: Info & Controls
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 40, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrackMetadata(
                    title: trackTitle, artist: artistName, centered: false),
                const SizedBox(height: 20),
                _NeonSlider(
                    progress: progress, position: position, duration: duration),
                const SizedBox(height: 20),
                Expanded(
                  child: _GlassLyricsPanel(
                    lyricsQuery: lyricsQuery,
                    position: position,
                    isDesktop: isDesktop,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final AsyncValue<double> progress;
  final AsyncValue<bool> playing;
  final String albumArtUrl;
  final String trackTitle;
  final String artistName;
  final AsyncValue<Duration> position;
  final Duration duration;
  final AsyncValue<PlaylistMode> loopMode;
  final AsyncValue<dynamic> lyricsQuery;
  final Animation<double> visualizerAnim;
  final ValueNotifier<double> volume;

  const _PortraitLayout({
    required this.progress,
    required this.playing,
    required this.albumArtUrl,
    required this.trackTitle,
    required this.artistName,
    required this.position,
    required this.duration,
    required this.loopMode,
    required this.lyricsQuery,
    required this.visualizerAnim,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final vinylSize = math.min(size.width * 0.82, size.height * 0.42);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            progress.when(
              data: (progressValue) => _VinylVisualization(
                progressValue: progressValue,
                isPlaying:
                    playing.maybeWhen(data: (p) => p, orElse: () => false),
                albumArtUrl: albumArtUrl,
                size: vinylSize,
              ),
              loading: () => SizedBox(
                width: vinylSize,
                height: vinylSize,
                child: Center(
                    child: CircularProgressIndicator(color: Colors.amber[400])),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 55,
              width: vinylSize * 0.8,
              child: _AudioVisualizer(
                playing: playing,
                animation: visualizerAnim,
              ),
            ),
            const SizedBox(height: 20),
            _TrackMetadata(
                title: trackTitle, artist: artistName, centered: true),
            const SizedBox(height: 18),
            _NeonSlider(
                progress: progress, position: position, duration: duration),
            const SizedBox(height: 18),
            SizedBox(
              height: 110,
              child: _GlassLyricsPanel(
                lyricsQuery: lyricsQuery,
                position: position,
                isDesktop: false,
              ),
            ),
            const SizedBox(height: 18),
            _RetroControls(
              playing: playing,
              loopMode: loopMode,
            ),
            const SizedBox(height: 16),
            _VolumeKnob(volume: volume),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// VINYL VISUALIZATION (TURNTABLE)
// =============================================================================

class _VinylVisualization extends StatelessWidget {
  final double progressValue;
  final bool isPlaying;
  final String albumArtUrl;
  final double size;

  const _VinylVisualization({
    required this.progressValue,
    required this.isPlaying,
    required this.albumArtUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 40,
      height: size + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Plinth (Base)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF111111),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  blurRadius: 60,
                  spreadRadius: -10,
                ),
              ],
            ),
          ),

          // 2. Rotating Record
          Transform.rotate(
            angle: progressValue * 2 * math.pi * (isPlaying ? 5 : 0),
            child: SizedBox(
              width: size * 0.95,
              height: size * 0.95,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vinyl Grooves
                  CustomPaint(
                    size: Size(size * 0.95, size * 0.95),
                    painter: HighFidelityVinylPainter(
                        playbackProgress: progressValue),
                  ),

                  // Album Art Label
                  Container(
                    width: size * 0.38,
                    height: size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.9),
                            blurRadius: 8),
                      ],
                    ),
                    child: ClipOval(
                      child: albumArtUrl.isNotEmpty
                          ? Image.network(albumArtUrl, fit: BoxFit.cover)
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0xFFE6C86F),
                                    Color(0xFFB8935C)
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Color(0xFF3D2F1F), size: 40),
                            ),
                    ),
                  ),

                  // Spindle
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0E0E0), Color(0xFF808080)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.black54, width: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Tone Arm (Using reference implementation)
          Positioned(
            top: size * 0.05,
            right: size * 0.05,
            child: _ToneArm(progress: progressValue, recordSize: size),
          ),
        ],
      ),
    );
  }
}

// Tone Arm - Reference Implementation
class _ToneArm extends StatelessWidget {
  final double progress;
  final double recordSize;

  const _ToneArm({required this.progress, required this.recordSize});

  @override
  Widget build(BuildContext context) {
    final angleRotation = progress * 30; // 0-30 degrees

    return Transform.rotate(
      angle: angleRotation * 0.0174533, // Convert to radians
      alignment: Alignment.topCenter,
      child: Container(
        width: 16,
        height: recordSize * 0.55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF2B2B2B),
              Color(0xFF454545),
              Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Counterweight (Top)
            Positioned(
              top: 5,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF555555),
                  border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.3),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),

            // Headshell (Bottom)
            Positioned(
              bottom: 0,
              child: Container(
                width: 20,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(4)),
                  border: Border.all(color: const Color(0xFF444444)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Needle (Cyan LED)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// AUDIO VISUALIZER
// =============================================================================

class _AudioVisualizer extends StatelessWidget {
  final AsyncValue<bool> playing;
  final Animation<double> animation;

  const _AudioVisualizer({
    required this.playing,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playing.maybeWhen(data: (p) => p, orElse: () => false);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _VisualizerPainter(
            animation.value,
            isPlaying,
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double animValue;
  final bool isPlaying;

  _VisualizerPainter(this.animValue, this.isPlaying);

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 40;
    final barWidth = size.width / barCount * 0.7;
    final spacing = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final seed = i * 0.1 + animValue * 5;
      final height = isPlaying
          ? (math.sin(seed) * 0.5 + 0.5) * size.height * 0.8
          : size.height * 0.1;

      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height),
          Offset(0, size.height - height),
          [
            const Color(0xFF00E5FF).withOpacity(0.3),
            const Color(0xFF00E5FF),
          ],
        )
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      canvas.drawLine(
        Offset(i * spacing + spacing / 2, size.height),
        Offset(i * spacing + spacing / 2, size.height - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) => true;
}

// =============================================================================
// VOLUME KNOB
// =============================================================================

class _VolumeKnob extends StatefulWidget {
  final ValueNotifier<double> volume;

  const _VolumeKnob({required this.volume});

  @override
  State<_VolumeKnob> createState() => _VolumeKnobState();
}

class _VolumeKnobState extends State<_VolumeKnob> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'VOLUME',
          style: GoogleFonts.rajdhani(
            color: const Color(0xFF00E5FF),
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onPanUpdate: (details) {
            final delta = details.delta.dy;
            final newVolume =
                (widget.volume.value - delta / 100).clamp(0.0, 1.0);
            widget.volume.value = newVolume;
            audioPlayer.setVolume(newVolume);
          },
          child: ValueListenableBuilder<double>(
            valueListenable: widget.volume,
            builder: (context, vol, _) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
                    center: Alignment(-0.3, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      offset: const Offset(6, 6),
                      blurRadius: 12,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      offset: const Offset(-3, -3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Knob markings
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _KnobMarkingsPainter(),
                    ),
                    // Indicator
                    Transform.rotate(
                      angle: -2.4 + (vol * 4.8),
                      child: Container(
                        width: 4,
                        height: 30,
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Center dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<double>(
          valueListenable: widget.volume,
          builder: (context, vol, _) {
            return Text(
              '${(vol * 100).toInt()}',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00E5FF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _KnobMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 10; i++) {
      final angle = -2.4 + (i * 4.8 / 10);
      final x1 = center.dx + radius * math.cos(angle);
      final y1 = center.dy + radius * math.sin(angle);
      final x2 = center.dx + (radius - 8) * math.cos(angle);
      final y2 = center.dy + (radius - 8) * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// NEON SLIDER - INTERACTIVE & FIXED
// =============================================================================

class _NeonSlider extends StatefulWidget {
  final AsyncValue<double> progress;
  final AsyncValue<Duration> position;
  final Duration duration;

  const _NeonSlider({
    required this.progress,
    required this.position,
    required this.duration,
  });

  @override
  State<_NeonSlider> createState() => _NeonSliderState();
}

class _NeonSliderState extends State<_NeonSlider> {
  bool _isDragging = false;
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    final progressValue = widget.progress.maybeWhen(
      data: (d) => _dragProgress ?? d,
      orElse: () => 0.0,
    );
    final currentPos = widget.position.maybeWhen(
      data: (d) => d,
      orElse: () => Duration.zero,
    );

    return Column(
      children: [
        // Proper padding to prevent overflow
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  final dragProgress =
                      (details.localPosition.dx / width).clamp(0.0, 1.0);
                  setState(() {
                    _isDragging = true;
                    _dragProgress = dragProgress;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  final dragProgress =
                      (details.localPosition.dx / width).clamp(0.0, 1.0);
                  setState(() {
                    _dragProgress = dragProgress;
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_dragProgress != null) {
                    final newPosition = widget.duration * _dragProgress!;
                    audioPlayer.seek(newPosition);
                  }
                  setState(() {
                    _isDragging = false;
                    _dragProgress = null;
                  });
                },
                onTapDown: (details) {
                  final tapProgress =
                      (details.localPosition.dx / width).clamp(0.0, 1.0);
                  final newPosition = widget.duration * tapProgress;
                  audioPlayer.seek(newPosition);
                },
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background track
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Progress track with glow
                      Container(
                        height: 4,
                        width: width * progressValue,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00E5FF),
                              Color(0xFF00E5FF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),

                      // Thumb
                      Positioned(
                        left: (width * progressValue).clamp(0.0, width) - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
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

        // Time labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_isDragging && _dragProgress != null
                    ? widget.duration * _dragProgress!
                    : currentPos),
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00E5FF).withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDuration(widget.duration),
                style: GoogleFonts.orbitron(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// CRT OVERLAY
// =============================================================================

class CRTOverlayPainter extends CustomPainter {
  final double flickerIntensity;

  CRTOverlayPainter({required this.flickerIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    // Scanlines
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(flickerIntensity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // RGB Chromatic aberration effect (very subtle)
    final aberrationPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.015)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), aberrationPaint);
  }

  @override
  bool shouldRepaint(CRTOverlayPainter old) =>
      old.flickerIntensity != flickerIntensity;
}

// =============================================================================
// PAINTERS
// =============================================================================

class HighFidelityVinylPainter extends CustomPainter {
  final double playbackProgress;

  HighFidelityVinylPainter({required this.playbackProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Base Vinyl Black
    final bgPaint = Paint()..color = const Color(0xFF0D0D0D);
    canvas.drawCircle(center, radius, bgPaint);

    // Micro-Grooves
    final groovePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double r = radius * 0.4; r < radius * 0.98; r += 2.2) {
      canvas.drawCircle(center, r, groovePaint);
    }

    // Played Area Highlight (Cyan tint)
    if (playbackProgress > 0) {
      final startR = radius * 0.98;
      final endR =
          radius * 0.98 - ((radius * 0.98 - radius * 0.4) * playbackProgress);

      final playedPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (double r = startR; r > endR; r -= 2.5) {
        canvas.drawCircle(center, r, playedPaint);
      }
    }

    // Anisotropic Sheen (Enhanced with cyan)
    final sheenPaint = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        [
          Colors.white.withOpacity(0.0),
          const Color(0xFF00E5FF).withOpacity(0.15),
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.0),
          const Color(0xFF00E5FF).withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
        [0.0, 0.15, 0.3, 0.5, 0.65, 0.8],
        TileMode.clamp,
        math.pi / 3,
        math.pi * 2,
      );
    canvas.drawCircle(center, radius, sheenPaint);
  }

  @override
  bool shouldRepaint(HighFidelityVinylPainter old) =>
      old.playbackProgress != playbackProgress;
}

// =============================================================================
// INFO & CONTROLS
// =============================================================================

class _TrackMetadata extends StatelessWidget {
  final String title;
  final String artist;
  final bool centered;

  const _TrackMetadata({
    required this.title,
    required this.artist,
    required this.centered,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.orbitron(
            color: const Color(0xFFF5F5F5),
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: const Color(0xFF00E5FF).withOpacity(0.4),
                blurRadius: 12,
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          artist.toUpperCase(),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.rajdhani(
            color: const Color(0xFF00E5FF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }
}

class _GlassLyricsPanel extends StatelessWidget {
  final AsyncValue<dynamic> lyricsQuery;
  final AsyncValue<Duration> position;
  final bool isDesktop;

  const _GlassLyricsPanel({
    required this.lyricsQuery,
    required this.position,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final double lyricFontSize = isDesktop ? 48.0 : 22.0;
    final double lyricLineHeight = isDesktop ? 1.3 : 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: lyricsQuery.when(
        data: (lyrics) {
          final list = lyrics?.lyrics ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text(
                'NO LYRICS AVAILABLE',
                style: GoogleFonts.rajdhani(
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 3,
                  fontSize: 14,
                ),
              ),
            );
          }

          final currentMs = position.maybeWhen(
              data: (d) => d.inMilliseconds, orElse: () => 0);

          int currentIndex = 0;
          for (int i = 0; i < list.length; i++) {
            if (list[i].time.inMilliseconds <= currentMs) {
              currentIndex = i;
            } else {
              break;
            }
          }

          return Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                list[currentIndex].text,
                key: ValueKey(currentIndex),
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerif(
                  color: const Color(0xFFFFFFFF),
                  fontSize: lyricFontSize,
                  height: lyricLineHeight,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.6),
                      blurRadius: 20,
                    ),
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF00E5FF),
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => const SizedBox(),
      ),
    );
  }
}

class _RetroControls extends StatelessWidget {
  final AsyncValue<bool> playing;
  final AsyncValue<PlaylistMode> loopMode;

  const _RetroControls({
    required this.playing,
    required this.loopMode,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playing.maybeWhen(data: (p) => p, orElse: () => false);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TactileButton(
            icon: Icons.skip_previous_rounded,
            onTap: () => audioPlayer.skipToPrevious(),
          ),

          // Play/Pause
          GestureDetector(
            onTap: () => isPlaying ? audioPlayer.pause() : audioPlayer.resume(),
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF0D0D0D),
                  ],
                  center: const Alignment(-0.2, -0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.7),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                  if (isPlaying)
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 3,
                    ),
                ],
                border: Border.all(
                  color: isPlaying
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF333333),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isPlaying ? const Color(0xFF00E5FF) : Colors.grey[600],
                  size: 42,
                ),
              ),
            ),
          ),

          _TactileButton(
            icon: Icons.skip_next_rounded,
            onTap: () => audioPlayer.skipToNext(),
          ),
        ],
      ),
    );
  }
}

class _TactileButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TactileButton({required this.icon, required this.onTap});

  @override
  State<_TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<_TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isPressed
                ? [const Color(0xFF0D0D0D), const Color(0xFF1A1A1A)]
                : [const Color(0xFF2A2A2A), const Color(0xFF0D0D0D)],
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.7),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
        ),
        child: Icon(
          widget.icon,
          color: const Color(0xFF00E5FF).withOpacity(0.7),
          size: 28,
        ),
      ),
    );
  }
}
