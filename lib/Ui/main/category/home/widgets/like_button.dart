import 'package:flutter/material.dart';

/// A small heart icon with a counter that manages its own liked state.
///
/// The widget is intentionally self-contained so that tapping the like
/// button only rebuilds this subtree instead of the entire card. It uses
/// a scale animation on the icon and a color tween for a smooth effect.
class LikeButton extends StatefulWidget {
  final bool initialLiked;
  final int initialCount;
  final ValueChanged<bool>? onChanged;

  const LikeButton({
    super.key,
    required this.initialLiked,
    required this.initialCount,
    this.onChanged,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _count;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _liked = widget.initialLiked;
    _count = widget.initialCount;
  }

  @override
  void didUpdateWidget(covariant LikeButton old) {
    super.didUpdateWidget(old);
    // if parent changed liked state externally, update locally without
    // resetting animation (scale will respond naturally because _liked
    // changes before build)
    if (widget.initialLiked != old.initialLiked) {
      setState(() {
        _liked = widget.initialLiked;
      });
    }
    if (widget.initialCount != old.initialCount) {
      setState(() {
        _count = widget.initialCount;
      });
    }
  }

  void _toggle() {
    setState(() {
      _liked = !_liked;
      _count += _liked ? 1 : -1;
    });
    widget.onChanged?.call(_liked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = _liked ? 1.3 : 1.0),
      onTapCancel: () => setState(() => _scale = _liked ? 1.3 : 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Row(
          children: [
            Icon(
              _liked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: _liked ? Colors.red : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text('$_count'),
          ],
        ),
      ),
    );
  }
}
