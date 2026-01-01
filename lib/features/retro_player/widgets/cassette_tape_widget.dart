import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:spotube/features/retro_player/providers/retro_player_provider.dart';
import 'package:spotube/services/audio_player/audio_player.dart';

/// **Realistic Retro Cassette Tape Player**
/// Features: LED Display, Mechanical Buttons, VU Meter, Auto-Reverse
class CassetteTapeWidget extends HookConsumerWidget {
  const CassetteTapeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(retroPlayerStateProvider);
    final progress = ref.watch(retroPlaybackProgressProvider);
    final playing = ref.watch(retroPlayingProvider);
    final position = ref.watch(retroPositionProvider);

    final currentTrack = playerState.activeTrack;
    final trackTitle = currentTrack?.name ?? 'Unknown Track';
    final artistName =
        currentTrack?.artists?.firstOrNull?.name ?? 'Unknown Artist';
    final albumArtUrl = currentTrack?.album?.images?.firstOrNull?.url ?? '';
    final duration = currentTrack?.durationMs != null
        ? Duration(milliseconds: currentTrack!.durationMs!)
        : Duration.zero;

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isDesktop = size.width > 800;

    // Animation controllers
    final reelController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final vuMeterController = useAnimationController(
      duration: const Duration(milliseconds: 100),
    );

    final ledScrollController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // Control reel animation
    useEffect(() {
      final isPlaying = playing.maybeWhen(data: (p) => p, orElse: () => false);
      if (isPlaying) {
        reelController.repeat();
        vuMeterController.repeat(reverse: true);
      } else {
        reelController.stop();
        vuMeterController.stop();
      }
      return null;
    }, [playing]);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Background texture
          Positioned.fill(
            child: CustomPaint(
              painter: _FabricTexturePainter(),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 60 : 20,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main cassette player
                    Center(
                      child: Container(
                        width: isDesktop ? 600 : math.min(size.width - 40, 500),
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children: [
                            // Cassette Tape
                            _CassetteTape(
                              progress: progress,
                              playing: playing,
                              albumArtUrl: albumArtUrl,
                              reelAnimation: reelController,
                              isDesktop: isDesktop,
                            ),

                            const SizedBox(height: 30),

                            // Tape Deck Body
                            _TapeDeckBody(
                              trackTitle: trackTitle,
                              artistName: artistName,
                              position: position,
                              duration: duration,
                              playing: playing,
                              progress: progress,
                              vuAnimation: vuMeterController,
                              ledScrollAnimation: ledScrollController,
                              isDesktop: isDesktop,
                            ),
                          ],
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
    );
  }
}

// =============================================================================
// CASSETTE TAPE
// =============================================================================

class _CassetteTape extends StatelessWidget {
  final AsyncValue<double> progress;
  final AsyncValue<bool> playing;
  final String albumArtUrl;
  final AnimationController reelAnimation;
  final bool isDesktop;

  const _CassetteTape({
    required this.progress,
    required this.playing,
    required this.albumArtUrl,
    required this.reelAnimation,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.maybeWhen(data: (d) => d, orElse: () => 0.0);
    final isPlaying = playing.maybeWhen(data: (p) => p, orElse: () => false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label area (top sticker)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5DC), // Beige paper
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                // Album art
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: albumArtUrl.isNotEmpty
                        ? Image.network(
                            albumArtUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.music_note,
                                    color: Colors.black38),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.music_note,
                                color: Colors.black38),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Handwritten style text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIDE A',
                        style: GoogleFonts.caveat(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Colors.black12,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      Text(
                        'Type: Chrome',
                        style: GoogleFonts.courierPrime(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transparent window showing reels
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Stack(
              children: [
                // Tape visibility window
                Row(
                  children: [
                    // Left reel hub
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: reelAnimation,
                          builder: (context, child) {
                            return _buildReel(
                              rotation: isPlaying
                                  ? reelAnimation.value * 2 * math.pi
                                  : 0,
                              tapeAmount: 1.0 - progressValue,
                            );
                          },
                        ),
                      ),
                    ),

                    // Center tape section
                    Container(
                      width: 100,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B4513),
                            Color(0xFFD2691E),
                            Color(0xFF8B4513),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Right reel hub
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: reelAnimation,
                          builder: (context, child) {
                            return _buildReel(
                              rotation: isPlaying
                                  ? -reelAnimation.value * 2 * math.pi
                                  : 0,
                              tapeAmount: progressValue,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Tape guides (posts)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTapeGuide(),
                        _buildTapeGuide(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Screw details (aesthetic)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScrew(),
              _buildScrew(),
              _buildScrew(),
              _buildScrew(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReel({required double rotation, required double tapeAmount}) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center hub
            Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[700],
                  border: Border.all(color: Colors.grey[600]!, width: 1),
                ),
              ),
            ),
            // Tape wound on reel
            Center(
              child: Container(
                width: 50 * (0.3 + tapeAmount * 0.5),
                height: 50 * (0.3 + tapeAmount * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4A2511),
                ),
              ),
            ),
            // Reel spokes
            Center(
              child: CustomPaint(
                size: const Size(50, 50),
                painter: _ReelSpokesPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapeGuide() {
    return Container(
      width: 6,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildScrew() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.grey[600]!,
            Colors.grey[800]!,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 1,
          color: Colors.grey[900],
        ),
      ),
    );
  }
}

// =============================================================================
// TAPE DECK BODY
// =============================================================================

class _TapeDeckBody extends StatelessWidget {
  final String trackTitle;
  final String artistName;
  final AsyncValue<Duration> position;
  final Duration duration;
  final AsyncValue<bool> playing;
  final AsyncValue<double> progress;
  final AnimationController vuAnimation;
  final AnimationController ledScrollAnimation;
  final bool isDesktop;

  const _TapeDeckBody({
    required this.trackTitle,
    required this.artistName,
    required this.position,
    required this.duration,
    required this.playing,
    required this.progress,
    required this.vuAnimation,
    required this.ledScrollAnimation,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3A3A3A),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // LED Display
          _LEDDisplay(
            trackTitle: trackTitle,
            artistName: artistName,
            position: position,
            duration: duration,
            scrollAnimation: ledScrollAnimation,
          ),

          const SizedBox(height: 20),

          // VU Meters
          Row(
            children: [
              Expanded(
                child: _VUMeter(
                  label: 'L',
                  animation: vuAnimation,
                  playing: playing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VUMeter(
                  label: 'R',
                  animation: vuAnimation,
                  playing: playing,
                  offset: 0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Mechanical Transport Controls
          _TransportControls(
              playing: playing, progress: progress, duration: duration),
        ],
      ),
    );
  }
}

// =============================================================================
// LED DISPLAY
// =============================================================================

class _LEDDisplay extends StatelessWidget {
  final String trackTitle;
  final String artistName;
  final AsyncValue<Duration> position;
  final Duration duration;
  final AnimationController scrollAnimation;

  const _LEDDisplay({
    required this.trackTitle,
    required this.artistName,
    required this.position,
    required this.duration,
    required this.scrollAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final currentPos =
        position.maybeWhen(data: (d) => d, orElse: () => Duration.zero);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red[900]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Track title (scrolling if long)
          SizedBox(
            height: 24,
            child: Center(
              child: Text(
                trackTitle.toUpperCase(),
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFF3333),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFF3333).withOpacity(0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Artist name
          Text(
            artistName.toUpperCase(),
            style: GoogleFonts.orbitron(
              color: const Color(0xFFFF6666),
              fontSize: 10,
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Time display (7-segment style)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SevenSegmentDisplay(text: _formatTime(currentPos)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFFF3333),
                    fontSize: 20,
                  ),
                ),
              ),
              _SevenSegmentDisplay(text: _formatTime(duration)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class _SevenSegmentDisplay extends StatelessWidget {
  final String text;

  const _SevenSegmentDisplay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sevenSegment(
        color: const Color(0xFFFF3333),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: const Color(0xFFFF3333).withOpacity(0.8),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VU METER
// =============================================================================

class _VUMeter extends StatelessWidget {
  final String label;
  final AnimationController animation;
  final AsyncValue<bool> playing;
  final double offset;

  const _VUMeter({
    required this.label,
    required this.animation,
    required this.playing,
    this.offset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playing.maybeWhen(data: (p) => p, orElse: () => false);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.courierPrime(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final level = isPlaying
                  ? (math.sin((animation.value + offset) * 2 * math.pi) * 0.5 +
                      0.5)
                  : 0.0;

              return SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _VUMeterPainter(level: level),
                  size: const Size(double.infinity, 80),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VUMeterPainter extends CustomPainter {
  final double level;

  _VUMeterPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 15;
    final barHeight = size.height / barCount;
    final barWidth = size.width - 8;

    for (int i = 0; i < barCount; i++) {
      final isLit = (i / barCount) < level;
      Color barColor;

      if (i < 8) {
        barColor = isLit ? Colors.green : Colors.green.withOpacity(0.2);
      } else if (i < 12) {
        barColor = isLit ? Colors.yellow : Colors.yellow.withOpacity(0.2);
      } else {
        barColor = isLit ? Colors.red : Colors.red.withOpacity(0.2);
      }

      final paint = Paint()..color = barColor;
      final rect = Rect.fromLTWH(
        4,
        size.height - (i + 1) * barHeight + 2,
        barWidth,
        barHeight - 4,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_VUMeterPainter old) => old.level != level;
}

// =============================================================================
// TRANSPORT CONTROLS
// =============================================================================

class _TransportControls extends StatelessWidget {
  final AsyncValue<bool> playing;
  final AsyncValue<double> progress;
  final Duration duration;

  const _TransportControls({
    required this.playing,
    required this.progress,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = playing.maybeWhen(data: (p) => p, orElse: () => false);

    return Column(
      children: [
        // Main transport buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MechanicalButton(
              icon: Icons.fast_rewind_rounded,
              onPressed: () => audioPlayer.skipToPrevious(),
            ),
            const SizedBox(width: 8),
            _MechanicalButton(
              icon: Icons.stop_rounded,
              onPressed: () => audioPlayer.pause(),
              color: Colors.red[900],
            ),
            const SizedBox(width: 8),
            _MechanicalButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: () =>
                  isPlaying ? audioPlayer.pause() : audioPlayer.resume(),
              isActive: isPlaying,
              color: Colors.green[900],
            ),
            const SizedBox(width: 8),
            _MechanicalButton(
              icon: Icons.fast_forward_rounded,
              onPressed: () => audioPlayer.skipToNext(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Progress bar (tape counter style)
        _TapeCounter(progress: progress, duration: duration),
      ],
    );
  }
}

class _MechanicalButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? color;

  const _MechanicalButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.color,
  });

  @override
  State<_MechanicalButton> createState() => _MechanicalButtonState();
}

class _MechanicalButtonState extends State<_MechanicalButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: widget.color ?? const Color(0xFF4A4A4A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isActive ? Colors.green : Colors.grey[700]!,
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
          color: widget.isActive ? Colors.green[300] : Colors.grey[300],
          size: 28,
        ),
      ),
    );
  }
}

class _TapeCounter extends StatelessWidget {
  final AsyncValue<double> progress;
  final Duration duration;

  const _TapeCounter({
    required this.progress,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = progress.maybeWhen(data: (d) => d, orElse: () => 0.0);
    final counterValue = (progressValue * 9999).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'COUNTER',
            style: GoogleFonts.courierPrime(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
          Text(
            counterValue.toString().padLeft(4, '0'),
            style: GoogleFonts.sevenSegment(
              color: const Color(0xFF00FF00),
              fontSize: 20,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FF00).withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PAINTERS
// =============================================================================

class _ReelSpokesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2 / 6);
      final x1 = center.dx + math.cos(angle) * 6;
      final y1 = center.dy + math.sin(angle) * 6;
      final x2 = center.dx + math.cos(angle) * (radius - 2);
      final y2 = center.dy + math.sin(angle) * (radius - 2);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FabricTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    for (double i = 0; i < size.width; i += 4) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
