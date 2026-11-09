import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Sweeps a soft highlight across its child (the "loading" shimmer).
/// With [animate] false it draws a still frame (used by golden tests).
class AsShimmer extends StatefulWidget {
  const AsShimmer({super.key, required this.child, this.animate = true});

  final Widget child;
  final bool animate;

  @override
  State<AsShimmer> createState() => _AsShimmerState();
}

class _AsShimmerState extends State<AsShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(AsShimmer old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // Slide a gradient band from left (-1) to right (+2) of the box.
        final t = widget.animate ? _c.value : 0.35;
        final dx = -1.0 + 3.0 * Curves.easeInOut.transform(t);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            colors: [c.skeleton, c.skeletonHighlight, c.skeleton],
            stops: const [0.3, 0.5, 0.7],
            transform: _SlideGradient(dx),
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);
  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * dx, 0, 0);
}

/// One placeholder block.
class AsSkeletonBox extends StatelessWidget {
  const AsSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AsRadius.sm,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.skeleton,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Full-screen placeholder shown while Instagram loads: a header and feed
/// posts (avatar + name, photo, caption lines), shimmering.
class AsFeedSkeleton extends StatelessWidget {
  const AsFeedSkeleton({super.key, this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return ColoredBox(
      color: c.background,
      child: AsShimmer(
        animate: animate,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 400.0;
          return ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeaderSkeleton(),
                  for (var i = 0; i < 2; i++) _PostSkeleton(width: w),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 52,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AsSpacing.lg),
        child: Row(
          children: [
            AsSkeletonBox(width: 24, height: 24, radius: 6),
            Spacer(),
            AsSkeletonBox(width: 110, height: 26),
            Spacer(),
            AsSkeletonBox(width: 24, height: 24, radius: 6),
          ],
        ),
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AsSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AsSpacing.lg, vertical: AsSpacing.md),
            child: Row(
              children: [
                AsSkeletonBox(width: 36, height: 36, circle: true),
                SizedBox(width: AsSpacing.md),
                AsSkeletonBox(width: 140, height: 12, radius: AsRadius.pill),
              ],
            ),
          ),
          AsSkeletonBox(width: width, height: width * 1.1, radius: 0),
          const SizedBox(height: AsSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AsSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AsSkeletonBox(
                    width: width * 0.72, height: 12, radius: AsRadius.pill),
                const SizedBox(height: AsSpacing.sm),
                AsSkeletonBox(
                    width: width * 0.44, height: 12, radius: AsRadius.pill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
