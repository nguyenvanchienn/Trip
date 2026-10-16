import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị lịch sử các lần được nhắc đến
class LichsunhacdenPage extends StatefulWidget {
  const LichsunhacdenPage({super.key});

  @override
  State<LichsunhacdenPage> createState() => _LichsunhacdenPageState();
}

class _LichsunhacdenPageState extends State<LichsunhacdenPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<ActivityItem> _mentions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final mentions = await _activityService.getMentionHistory(limit: 50);

    if (mounted) {
      setState(() {
        _mentions = mentions;
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return DateFormat('dd/MM/yyyy').format(date);
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'mention_comment':
        return Icons.comment_outlined;
      case 'mention_post':
        return Icons.article_outlined;
      default:
        return Icons.alternate_email;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'mention_comment':
        return 'Bình luận';
      case 'mention_post':
        return 'Bài viết';
      default:
        return 'Nhắc đến';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nhắc đến'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mentions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alternate_email,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa được nhắc đến',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khi ai đó nhắc đến bạn, nội dung sẽ hiển thị ở đây',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _mentions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final mention = _mentions[index];

                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(mention.type),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mention.targetUserName ?? 'Ai đó',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getTypeLabel(mention.type),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          mention.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(mention.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: mention.postPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              mention.postPhotoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          )
                        : null,
                    onTap: () {
                      // Navigate to post/comment
                    },
                  );
                },
              ),
            ),
    );
  }
}
