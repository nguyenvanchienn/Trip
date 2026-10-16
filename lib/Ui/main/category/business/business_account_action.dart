import 'dart:io';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/models/account_settings_model.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

import 'business_account_screen.dart';
import 'business_onboarding_helper.dart';

class BusinessAccountAction extends StatefulWidget {
  final bool asAvatar;
  final double size;
  final VoidCallback? onTap;

  const BusinessAccountAction({
    super.key,
    this.asAvatar = false,
    this.size = 36,
    this.onTap,
  });

  @override
  State<BusinessAccountAction> createState() => _BusinessAccountActionState();
}

class _BusinessAccountActionState extends State<BusinessAccountAction> {
  @override
  Widget build(BuildContext context) {
    final service = FirebaseAccountService();
    final settingsFuture = service.getAccountSettings();
    final profileFuture = service.getExtendedProfile();
    return FutureBuilder<AccountSettingsModel>(
      future: settingsFuture,
      builder: (context, snapshot) {
        final settings = snapshot.data;
        final isBusiness = settings?.isBusinessAccount ?? false;
        if (!isBusiness) return const SizedBox.shrink();

        if (!widget.asAvatar) {
          return IconButton(
            icon: const Icon(Icons.storefront_outlined),
            onPressed: _handleBusinessPress,
          );
        }

        final colorScheme = Theme.of(context).colorScheme;
        const switchRingColor = Color(0xFFFF7A1A);
        return FutureBuilder<Map<String, dynamic>?>(
          future: profileFuture,
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data ?? {};
            final businessProfile =
                (profile['businessProfile'] as Map<String, dynamic>?) ?? {};
            final media =
                (businessProfile['media'] as Map<String, dynamic>?) ?? {};
            final avatarPath = media['avatarPath'] as String?;
            final ImageProvider? avatarProvider;
            if (avatarPath != null && avatarPath.isNotEmpty) {
              avatarProvider = getImageProvider(avatarPath);
            } else {
              avatarProvider = null;
            }

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleBusinessPress,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(widget.size),
                        painter: _SwitchRingPainter(
                          color: switchRingColor,
                          strokeWidth: 3,
                        ),
                      ),
                      CircleAvatar(
                        radius: (widget.size - 6) / 2,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? Icon(
                                Icons.storefront_outlined,
                                size: widget.size * 0.45,
                                color: colorScheme.primary,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleBusinessPress() async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    widget.onTap?.call();
    final ready = await _ensureBusinessReady(rootContext);
    if (!ready || !rootContext.mounted) return;
    Navigator.of(
      rootContext,
    ).push(MaterialPageRoute(builder: (_) => const BusinessAccountScreen()));
  }

  Future<bool> _ensureBusinessReady(BuildContext dialogContextOrRoot) async {
    final service = FirebaseAccountService();
    final profile = await service.getExtendedProfile() ?? {};
    final businessProfile =
        (profile['businessProfile'] as Map<String, dynamic>?) ?? {};
    final completed = profile['businessSetupCompleted'] == true;

    if (businessProfile.isEmpty || !completed) {
      if (!dialogContextOrRoot.mounted) return false;
      final shouldStart = await showDialog<bool>(
        context: dialogContextOrRoot,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Bắt đầu thiết lập?'),
            content: const Text(
              'Bạn chưa thiết lập tài khoản doanh nghiệp. Bạn có muốn tạo ngay không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Đồng ý'),
              ),
            ],
          );
        },
      );

      if (shouldStart == true) {
        await BusinessOnboardingHelper.ensureBusinessSetup(dialogContextOrRoot);
      }
      return false;
    }

    return true;
  }
}

class _SwitchRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _SwitchRingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final startAngle1 = -2.6;
    final sweepAngle = 2.6;
    final gap = 0.55;
    final startAngle2 = startAngle1 + sweepAngle + gap;

    _drawArcWithArrow(
      canvas,
      center: center,
      radius: radius,
      startAngle: startAngle1,
      sweepAngle: sweepAngle,
      paint: paint,
    );
    _drawArcWithArrow(
      canvas,
      center: center,
      radius: radius,
      startAngle: startAngle2,
      sweepAngle: sweepAngle,
      paint: paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  void _drawArcWithArrow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
    required Paint paint,
  }) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    final arrowAngle = startAngle + sweepAngle;
    final arrowTip = Offset(
      center.dx + radius * Math.cos(arrowAngle),
      center.dy + radius * Math.sin(arrowAngle),
    );
    final tangent = Offset(-Math.sin(arrowAngle), Math.cos(arrowAngle));
    final normal = Offset(Math.cos(arrowAngle), Math.sin(arrowAngle));

    const arrowSize = 5.5;
    final p1 = arrowTip;
    final p2 = arrowTip - tangent * arrowSize + normal * arrowSize;
    final p3 = arrowTip - tangent * arrowSize - normal * arrowSize;

    final arrowPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(path, arrowPaint);
  }
}
