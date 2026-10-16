import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// A simple "About" page showing the application name, a short
/// description and the current version/build number taken from
/// the pubspec.yaml file at runtime.
class IntroAppPage extends StatelessWidget {
  const IntroAppPage({super.key});

  /// Read the version string from the pubspec.yaml file. This is a
  /// lightweight way to avoid adding an external dependency such as
  /// `package_info_plus` just for a single label.
  Future<String> _loadVersion() async {
    try {
      final yaml = await rootBundle.loadString('pubspec.yaml');
      final match = RegExp(
        r'^version:\s*(\S+)',
        multiLine: true,
      ).firstMatch(yaml);
      return match?.group(1) ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    const appName = 'Trip';
    const description =
        'Trip giúp bạn lên kế hoạch và quản lý những chuyến đi dễ dàng, '
        'từ việc tìm chỗ ở tới khám phá địa điểm mới.';

    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu')),
      body: FutureBuilder<String>(
        future: _loadVersion(),
        builder: (context, snapshot) {
          final version = snapshot.data ?? '...';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                // show app logo instead of placeholder
                Image.asset(
                  'asset/icon/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  appName,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  'Phiên bản: $version',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 Trip',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
