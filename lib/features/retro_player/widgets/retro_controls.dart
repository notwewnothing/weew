import 'package:flutter/material.dart';
import 'package:spotube/features/retro_player/widgets/led_display.dart';

/// Retro-styled control buttons for cassette/vinyl players
class RetroControlsPanel extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isPlaying;
  final VoidCallback? onEject;

  const RetroControlsPanel({
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onNext,
    required this.onPrevious,
    required this.isPlaying,
    this.onEject,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final buttonSize = isSmall ? 50.0 : 60.0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous/Rewind
              RetroLEDButton(
                onPressed: onPrevious,
                label: '<<',
                icon: Icons.skip_previous,
                width: buttonSize,
              ),
              SizedBox(width: isSmall ? 8 : 12),
              // Stop
              RetroLEDButton(
                onPressed: onStop,
                label: 'STOP',
                icon: Icons.stop,
                width: buttonSize,
              ),
              SizedBox(width: isSmall ? 8 : 12),
              // Play/Pause toggle
              RetroLEDButton(
                onPressed: isPlaying ? onPause : onPlay,
                label: isPlaying ? '⏸' : '▶',
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                isActive: isPlaying,
                width: buttonSize,
              ),
              SizedBox(width: isSmall ? 8 : 12),
              // Next/Forward
              RetroLEDButton(
                onPressed: onNext,
                label: '>>',
                icon: Icons.skip_next,
                width: buttonSize,
              ),
            ],
          ),
          if (onEject != null) ...[
            const SizedBox(height: 16),
            // Eject button (separate row)
            RetroLEDButton(
              onPressed: onEject!,
              label: 'EJECT',
              icon: Icons.eject,
              width: buttonSize * 1.5,
            ),
          ],
        ],
      ),
    );
  }
}

/// Advanced controls panel with volume, shuffle, repeat mode
class RetroAdvancedControls extends StatelessWidget {
  final bool isShuffled;
  final int loopMode; // 0: no repeat, 1: repeat all, 2: repeat one
  final double volume;
  final VoidCallback onShuffleToggle;
  final VoidCallback onLoopModeChange;
  final ValueChanged<double> onVolumeChange;

  const RetroAdvancedControls({
    required this.isShuffled,
    required this.loopMode,
    required this.volume,
    required this.onShuffleToggle,
    required this.onLoopModeChange,
    required this.onVolumeChange,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Mode indicators row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Shuffle indicator
              GestureDetector(
                onTap: onShuffleToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isShuffled ? Colors.amber[700] : Colors.grey[800],
                    border: Border.all(
                      color:
                          isShuffled ? Colors.amber[600]! : Colors.grey[700]!,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shuffle,
                        color: isShuffled ? Colors.grey[900] : Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SHUFFLE',
                        style: TextStyle(
                          color:
                              isShuffled ? Colors.grey[900] : Colors.grey[500],
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Loop mode indicator
              GestureDetector(
                onTap: onLoopModeChange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: loopMode > 0 ? Colors.amber[700] : Colors.grey[800],
                    border: Border.all(
                      color:
                          loopMode > 0 ? Colors.amber[600]! : Colors.grey[700]!,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        loopMode == 2 ? Icons.repeat_one : Icons.repeat,
                        color:
                            loopMode > 0 ? Colors.grey[900] : Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loopMode == 0
                            ? 'NO REP'
                            : loopMode == 2
                                ? 'REP 1'
                                : 'REP ALL',
                        style: TextStyle(
                          color: loopMode > 0
                              ? Colors.grey[900]
                              : Colors.grey[500],
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Volume control
          Column(
            children: [
              Text(
                'VOLUME',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.volume_down,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                  Expanded(
                    child: Slider(
                      value: volume,
                      onChanged: onVolumeChange,
                      min: 0,
                      max: 1,
                      activeColor: const Color(0xFF00FF00),
                      inactiveColor: Colors.grey[800],
                    ),
                  ),
                  Icon(
                    Icons.volume_up,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                ],
              ),
              Text(
                '${(volume * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFF00FF00),
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
