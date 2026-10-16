import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị các hoạt động được gắn thẻ hoặc nhắc đến
class HoatdongGanThePage extends StatefulWidget {
  const HoatdongGanThePage({super.key});

  @override
  State<HoatdongGanThePage> createState() => _HoatdongGanThePageState();
}

class _HoatdongGanThePageState extends State<HoatdongGanThePage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<ActivityItem> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final activities = await _activityService.getTaggedActivities(limit: 50);

    if (mounted) {
      setState(() {
        _activities = activities;
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

  Widget _buildActivityTile(ActivityItem item) {
    final isTag = item.type == 'tag';
    final icon = isTag ? Icons.local_offer_outlined : Icons.alternate_email;
    final label = isTag ? 'Đã gắn thẻ bạn' : 'Đã nhắc đến bạn';

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        item.targetUserName ?? label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.content.isNotEmpty)
            Text(
              item.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          const SizedBox(height: 2),
          Text(
            _formatDate(item.timestamp),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
      trailing: item.postPhotoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.postPhotoUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            )
          : null,
      onTap: () {
        // Navigate to post detail
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoạt động có gắn thẻ bạn'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có hoạt động gắn thẻ nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _activities.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) =>
                    _buildActivityTile(_activities[index]),
              ),
            ),
    );
  }
}
