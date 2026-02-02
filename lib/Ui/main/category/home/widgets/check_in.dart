// đây là file chứa code của trang check in bản đồ nằm ở trong phần profile
import 'package:flutter/material.dart';

class CheckIn extends StatelessWidget {
  const CheckIn({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background (use an asset image if you have one).
          // Use Image.asset with errorBuilder to avoid uncaught exceptions
          // when the asset isn't declared in pubspec.yaml or missing.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0E3550), Color(0xFF083146)],
              ),
            ),
            child: Image.asset(
              'asset/images/checkin.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.12),
              colorBlendMode: BlendMode.dstATop,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nguyễn Chiến',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã khám phá 14/64 tỉnh thành tại Việt Nam',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Map area
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Stack(
                          children: [
                            // Map placeholder card
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // If you have a real map image, place it at images/vietnam_map.png
                                    Image.asset(
                                      'asset/images/vietnam.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, err, stack) =>
                                          Container(
                                            color: const Color(0xFF06314A),
                                            child: const Center(
                                              child: Text(
                                                'Bản đồ',
                                                style: TextStyle(
                                                  color: Colors.white54,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),

                                    // Orange highlighted regions placeholder
                                    // In a real implementation you'd overlay a proper SVG or map layer.
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: _HighlightsPainter(),
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
                  ),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _CircleIcon(icon: Icons.explore_outlined, onTap: () {}),
                    const SizedBox(width: 8),
                    _CircleIcon(icon: Icons.zoom_out_map, onTap: () {}),
                    const SizedBox(width: 8),
                    _CircleIcon(icon: Icons.zoom_in, onTap: () {}),
                    const SizedBox(width: 8),
                    _CircleIcon(icon: Icons.share, onTap: () {}),
                  ],
                ),

                const Spacer(),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Thêm điểm đến',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Small white handle at very bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                width: 120,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white10,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _HighlightsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF8A00).withOpacity(0.95);

    // Placeholder highlight blobs roughly positioned for the screenshot.
    // Replace with precise paths or an SVG overlay in a real app.
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.08),
      size.width * 0.06,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.14),
      size.width * 0.045,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.38),
      size.width * 0.12,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.76),
      size.width * 0.14,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.84),
      size.width * 0.18,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
