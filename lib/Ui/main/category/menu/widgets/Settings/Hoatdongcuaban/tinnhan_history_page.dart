import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị lịch sử tin nhắn
class TinnhanHistoryPage extends StatefulWidget {
  const TinnhanHistoryPage({super.key});

  @override
  State<TinnhanHistoryPage> createState() => _TinnhanHistoryPageState();
}

class _TinnhanHistoryPageState extends State<TinnhanHistoryPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<ActivityItem> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final messages = await _activityService.getMessages(limit: 50);

    if (mounted) {
      setState(() {
        _messages = messages;
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

  Widget _buildMessageTile(ActivityItem item) {
    final isSent = item.metadata?['isSent'] ?? false;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: item.targetUserPhotoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  item.targetUserPhotoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.targetUserName ?? 'Người dùng',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (isSent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Đã gửi',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(item.timestamp),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
      onTap: () {
        // Navigate to conversation
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) =>
                    _buildMessageTile(_messages[index]),
              ),
            ),
    );
  }
}
