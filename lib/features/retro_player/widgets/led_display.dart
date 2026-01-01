import 'package:flutter/material.dart';
import 'package:spotube/features/retro_player/animations/retro_animations.dart';

/// Pixelated LED display widget for retro player screens
class RetroLEDDisplay extends StatelessWidget {
  final String trackTitle;
  final String artistName;
  final String timecode; // Format: "MM:SS"
  final double progress;
  final bool isPlaying;

  const RetroLEDDisplay({
    required this.trackTitle,
    required this.artistName,
    required this.timecode,
    required this.progress,
    required this.isPlaying,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final displayWidth = isSmall ? 280.0 : 400.0;

    return Container(
      width: displayWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[700]!, width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main display area (green monochrome)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              border: Border.all(color: Colors.grey[700]!, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marquee text for track title
                SizedBox(
                  height: 24,
                  child: MarqueeText(
                    text: trackTitle,
                    duration: Duration(
                        milliseconds:
                            (trackTitle.length * 100).clamp(2000, 6000)),
                    style: const TextStyle(
                      color: Color(0xFF00FF00),
                      fontFamily: 'Courier',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Artist name
                Text(
                  artistName.length > 20
                      ? '${artistName.substring(0, 17)}...'
                      : artistName,
                  style: const TextStyle(
                    color: Color(0xFF00DD00),
                    fontFamily: 'Courier',
                    fontSize: 12,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar (LED style)
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                // Progress fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF00),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FF00).withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status line with timecode and mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status indicator
              Text(
                isPlaying ? '▶ REC' : '⏸ STD',
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Timecode display (pixelated style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  timecode,
                  style: const TextStyle(
                    color: Color(0xFF00FF00),
                    fontFamily: 'Courier',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple LED style button for cassette/vinyl controls
class RetroLEDButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final bool isActive;
  final double? width;

  const RetroLEDButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    this.isActive = false,
    this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Transform.scale(
        scale: 1.0,
        child: Container(
          width: width ?? 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? Colors.amber[700] : Colors.grey[800],
            border: Border.all(
              color: isActive ? Colors.amber[600]! : Colors.grey[600]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              if (isActive)
                BoxShadow(
                  color: Colors.amber[700]!.withOpacity(0.3),
                  blurRadius: 8,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.grey[900] : Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive ? Colors.grey[900] : Colors.grey[400],
                      fontFamily: 'Courier',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
