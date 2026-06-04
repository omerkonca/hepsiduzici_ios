import 'package:flutter/material.dart';

class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final Duration duration;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.08);
    final hi = Theme.of(context).dividerColor.withValues(alpha: 0.18);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.2 + (_controller.value * 2.4), -0.3),
              end: Alignment(-0.2 + (_controller.value * 2.4), 0.3),
              colors: [base, hi, base],
              stops: const [0.1, 0.45, 0.9],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: childWithBase(widget.child, base),
        );
      },
    );
  }

  Widget childWithBase(Widget child, Color color) {
    return ColoredBox(color: color, child: child);
  }
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = 12,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

