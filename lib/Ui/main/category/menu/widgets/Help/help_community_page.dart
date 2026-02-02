import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpCommunityPage extends StatelessWidget {
  const HelpCommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('help_community'.tr()), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'help_community'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Tham gia cộng đồng để trao đổi, hỏi đáp và kết nối với người dùng khác.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đang mở cộng đồng...')),
                  );
                },
                child: Text('Mở cộng đồng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
