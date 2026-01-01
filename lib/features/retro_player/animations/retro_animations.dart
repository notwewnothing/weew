import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math';

/// Widget that animates a reel spinning at speed proportional to playback progress
class ReelSpinAnimation extends HookWidget {
  final double progress;
  final bool isPlaying;
  final Widget Function(BuildContext, double) builder;
  final bool spinClockwise;

  const ReelSpinAnimation({
    required this.progress,
    required this.isPlaying,
    required this.builder,
    this.spinClockwise = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 30),
    );

    useEffect(() {
      if (isPlaying) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [isPlaying]);

    useListenable(controller);

    // Calculate rotation based on progress
    // Each full rotation = 2π, multiply by progress for position-based rotation
    final baseRotation =
        progress * 2 * pi * 10; // 10x multiplier for visual effect
    final spinRotation =
        spinClockwise ? controller.value * 2 * pi : -controller.value * 2 * pi;
    final totalRotation = baseRotation + spinRotation;

    return builder(context, totalRotation);
  }
}

/// Widget that animates vinyl record rotation based on playback progress
class VinylRotationAnimation extends HookWidget {
  final double progress;
  final bool isPlaying;
  final Widget Function(BuildContext, double) builder;

  const VinylRotationAnimation({
    required this.progress,
    required this.isPlaying,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 50),
    );

    useEffect(() {
      if (isPlaying) {
        controller.repeat();
      } else {
        controller.stop();
      }
      return null;
    }, [isPlaying]);

    useListenable(controller);

    // Vinyl spins based on progress through the song
    final baseRotation = progress * 2 * pi;
    final continuousSpin =
        controller.value * 2 * pi * 5; // continuous spinning effect
    final totalRotation = baseRotation + continuousSpin;

    return builder(context, totalRotation);
  }
}

/// Widget that animates tone arm movement from edge to center of vinyl
class ToneArmAnimation extends HookWidget {
  final double progress;
  final bool isPlaying;
  final Widget Function(BuildContext, double) builder;

  const ToneArmAnimation({
    required this.progress,
    required this.isPlaying,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 100),
    );

    useEffect(() {
      if (isPlaying) {
        controller.forward();
      } else {
        controller.reverse();
      }
      return null;
    }, [isPlaying]);

    useListenable(controller);

    // Tone arm rotates from ~45° at start to ~0° at center
    // totalRotationDegrees = 45° (from edge to center)
    const totalRotationDegrees = 45.0;
    final toneArmRotation = (1.0 - progress) * totalRotationDegrees;

    return builder(context, toneArmRotation);
  }
}

/// Animated marquee text scroller for LED display
class MarqueeText extends HookWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const MarqueeText({
    required this.text,
    required this.style,
    this.duration = const Duration(seconds: 10),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);

    useEffect(() {
      controller.repeat();
      return null;
    }, []);

    useListenable(controller);

    final offset = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(-1.0, 0.0),
    ).evaluate(controller);

    return ClipRect(
      child: Transform.translate(
        offset: Offset(offset.dx * 100, 0),
        child: Text(
          text,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}

/// Button press animation with spring effect
class RetroButtonAnimation extends HookWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Duration duration;

  const RetroButtonAnimation({
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration);

    final scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    useListenable(controller);

    return GestureDetector(
      onTapDown: (_) async {
        await controller.forward();
        await controller.reverse();
        onPressed();
      },
      child: Transform.scale(
        scale: scale.value,
        child: child,
      ),
    );
  }
}
