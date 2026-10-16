import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị lịch sử tìm kiếm
class LichsutimkiemPage extends StatefulWidget {
  const LichsutimkiemPage({super.key});

  @override
  State<LichsutimkiemPage> createState() => _LichsutimkiemPageState();
}

class _LichsutimkiemPageState extends State<LichsutimkiemPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<SearchHistoryItem> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final history = await _activityService.getSearchHistory(limit: 100);

    if (mounted) {
      setState(() {
        _history = history;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử tìm kiếm'),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ lịch sử tìm kiếm? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _activityService.clearSearchHistory();
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lịch sử tìm kiếm')),
        );
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    await _activityService.deleteSearchHistoryItem(itemId);
    setState(() {
      _history.removeWhere((item) => item.id == itemId);
    });
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
      case 'user':
        return Icons.person_outline;
      case 'post':
        return Icons.article_outlined;
      case 'trip':
        return Icons.map_outlined;
      case 'location':
        return Icons.location_on_outlined;
      default:
        return Icons.search;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử tìm kiếm'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            TextButton(onPressed: _clearAll, child: const Text('Xóa tất cả')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Không có lịch sử tìm kiếm',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Các tìm kiếm gần đây sẽ hiển thị ở đây',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];

                  return Dismissible(
                    key: Key(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _deleteItem(item.id),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: item.resultPhotoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.network(
                                  item.resultPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _getTypeIcon(item.type),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                _getTypeIcon(item.type),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      ),
                      title: Text(
                        item.resultTitle ?? item.query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatDate(item.timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _deleteItem(item.id),
                      ),
                      onTap: () {
                        // Perform search again or navigate to result
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
