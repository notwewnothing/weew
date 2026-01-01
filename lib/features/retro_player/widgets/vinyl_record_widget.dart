import 'package:flutter/material.dart';
import 'package:spotube/features/retro_player/animations/retro_animations.dart';

/// Retro vinyl record player visualization with tone arm
class VinylRecordWidget extends StatelessWidget {
  final double progress;
  final bool isPlaying;
  final String? albumArtUrl;

  const VinylRecordWidget({
    required this.progress,
    required this.isPlaying,
    this.albumArtUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final recordSize =
        (size.width < size.height ? size.width : size.height) * 0.5;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: recordSize + 80,
            height: recordSize + 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Turntable base
                Container(
                  width: recordSize + 40,
                  height: recordSize + 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[700]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                // Vinyl record animation
                VinylRotationAnimation(
                  progress: progress,
                  isPlaying: isPlaying,
                  builder: (context, rotation) {
                    return Transform.rotate(
                      angle: rotation,
                      child: _buildVinylRecord(
                        size: recordSize,
                        albumArtUrl: albumArtUrl,
                      ),
                    );
                  },
                ),
                // Spindle center (gold/brass color)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber[800]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber[700]!.withOpacity(0.3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Tone arm
                ToneArmAnimation(
                  progress: progress,
                  isPlaying: isPlaying,
                  builder: (context, rotation) {
                    return Transform.rotate(
                      angle: rotation,
                      alignment: Alignment(0.0, -0.2),
                      child: _buildToneArm(recordSize: recordSize),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPlaying ? '🎵 PLAYING' : '⏸ PAUSED',
              style: const TextStyle(
                color: Color(0xFF00FF00),
                fontFamily: 'Courier',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinylRecord({
    required double size,
    required String? albumArtUrl,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[800]!, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Groove pattern (concentric circles)
          CustomPaint(
            size: Size(size, size),
            painter: VinylGroovesPainter(),
          ),
          // Center label with album art
          Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[700]!, width: 1),
              image: albumArtUrl != null
                  ? DecorationImage(
                      image: NetworkImage(albumArtUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: albumArtUrl == null
                ? const Icon(
                    Icons.album,
                    color: Colors.grey,
                    size: 48,
                  )
                : null,
          ),
          // Center spindle hole
          Container(
            width: size * 0.08,
            height: size * 0.08,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneArm({required double recordSize}) {
    return Positioned(
      right: recordSize * 0.1,
      top: recordSize * 0.1,
      child: Container(
        width: recordSize * 0.6,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            // Tone arm needle
            Positioned(
              right: 0,
              top: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red[700]!.withOpacity(0.5),
                      blurRadius: 3,
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

/// Custom painter for vinyl groove pattern
class VinylGroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw concentric circles (grooves)
    for (int i = 1; i < 15; i++) {
      final r = radius * (0.2 + (i * 0.05));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(VinylGroovesPainter oldDelegate) => false;
}
