import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpTopicPage extends StatelessWidget {
  final String displayTitle;
  final String topicKey;

  const HelpTopicPage({
    super.key,
    required this.displayTitle,
    required this.topicKey,
  });

  @override
  Widget build(BuildContext context) {
    final titleKey = 'help_topic_${topicKey}_title';
    final bodyKey = 'help_topic_${topicKey}_body';

    final localizedTitle = tr(titleKey);
    final localizedBody = tr(bodyKey);

    // Fallback to displayTitle or generated string when translations are missing
    final title = localizedTitle == titleKey ? displayTitle : localizedTitle;
    final body = localizedBody == bodyKey
        ? 'Giải thích chi tiết cho $displayTitle'
        : localizedBody;

    return Scaffold(
      appBar: AppBar(title: Text(title), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                Text(
                  'help_topic_more_info'.tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('close'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
