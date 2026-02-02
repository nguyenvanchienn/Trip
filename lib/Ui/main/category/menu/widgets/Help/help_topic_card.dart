import 'package:flutter/material.dart';

class HelpTopicCard extends StatelessWidget {
  final String topic;
  final VoidCallback? onTap;
  const HelpTopicCard({super.key, required this.topic, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Use min so the card adapts to the constrained height of the list
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(topic, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              // Make the description flexible and clamp lines to avoid overflow
              const Text(
                'Giải thích ngắn về chủ đề',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
