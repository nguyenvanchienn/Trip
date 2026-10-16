import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/Profile.dart';

class CacDonDatHangPage extends StatefulWidget {
  const CacDonDatHangPage({super.key});

  @override
  State<CacDonDatHangPage> createState() => _CacDonDatHangPageState();
}

class _CacDonDatHangPageState extends State<CacDonDatHangPage> {
  String _selectedFilter = 'Tất cả';
  DateTimeRange? _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  final Map<String, String> _filterLabels = {
    'Tất cả': 'Tất cả',
    'flight_ticket': 'Vé máy bay',
    'train_ticket': 'Vé tàu hỏa',
    'bus_ticket': 'Vé xe khách',
    'ship_ticket': 'Vé tàu thủy',
    'hotel': 'Khách sạn',
    'guide_rental': 'Hướng dẫn viên',
    'photographer': 'Thợ chụp ảnh',
    'clothes_rental': 'Thuê quần áo',
    'food': 'Ẩm thực',
  };

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAll(reg, '.')} đ';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
      case 'Hoàn thành':
        return 'Hoàn thành';
      case 'cancelled':
      case 'Đã hủy':
        return 'Đã hủy';
      case 'processing':
      case 'Đang xử lý':
        return 'Đang xử lý';
      case 'pending':
      case 'Chờ xác nhận':
        return 'Chờ xác nhận';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'Hoàn thành':
        return const Color(0xFF2E7D32);
      case 'cancelled':
      case 'Đã hủy':
        return const Color(0xFFC62828);
      case 'processing':
      case 'Đang xử lý':
        return const Color(0xFF1565C0);
      case 'pending':
      case 'Chờ xác nhận':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF757575);
    }
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Lọc theo danh mục',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filterLabels.entries.map((entry) {
                  final isSelected = _selectedFilter == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = entry.key);
                        Navigator.pop(context);
                      }
                    },
                    selectedColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                    avatar: isSelected ? const Icon(Icons.check, size: 16, color: Colors.blue) : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showDateFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Lọc theo thời gian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: Colors.blue),
                title: const Text('Tất cả'),
                onTap: () {
                  setState(() => _selectedDateRange = null);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text('Chọn một ngày...'),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet before showing picker
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateRange?.start ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Colors.deepPurple,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = DateTimeRange(
                          start: picked,
                          end: picked,
                        ));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range, color: Colors.blue),
                title: const Text('Chọn khoảng thời gian...'),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet before showing picker
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: _selectedDateRange,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.deepPurple,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseMenuService().streamBusinessOrders(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Các đơn đặt hàng')),
            body: Center(
              child: Text('Không tải được đơn hàng\nLỗi: ${snapshot.error}'),
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        final typeFilteredOrders = _selectedFilter == 'Tất cả'
            ? allOrders
            : allOrders.where((o) => o['type'] == _selectedFilter).toList();
            
        final orders = typeFilteredOrders.where((o) {
          if (_selectedDateRange == null) return true;
          final createdAt = o['createdAt'] as Timestamp?;
          if (createdAt == null) return false;
          final date = createdAt.toDate();
          final dateOnly = DateTime(date.year, date.month, date.day);
          return (dateOnly.isAtSameMomentAs(_selectedDateRange!.start) || dateOnly.isAfter(_selectedDateRange!.start)) &&
                 (dateOnly.isAtSameMomentAs(_selectedDateRange!.end) || dateOnly.isBefore(_selectedDateRange!.end));
        }).toList();
            
        final pendingOrders = orders.where((o) => o['status'] == 'pending' || o['status'] == 'Chờ xác nhận').toList();

        Widget bodyWidget;
        if (snapshot.connectionState == ConnectionState.waiting) {
          bodyWidget = const Center(child: CircularProgressIndicator());
        } else if (allOrders.isEmpty) {
          bodyWidget = const Center(child: Text('Chưa có đơn hàng nào'));
        } else {
          bodyWidget = ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = (order['items'] as List<dynamic>?) ?? [];
              final firstItem = items.isNotEmpty ? items[0] : null;
              final itemName = firstItem != null
                  ? firstItem['name']
                  : 'Đơn hàng';
              final quantity = firstItem != null ? firstItem['quantity'] : 1;
              final status = order['status'] ?? 'unknown';
              final statusColor = _statusColor(status);
              final orderId = order['id'];

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x14000000)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Số lượng: $quantity'),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng tiền: ${_formatCurrency((order['totalPrice'] as num?)?.toDouble() ?? 0)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (order['userId'] != null &&
                          order['userId'].toString().isNotEmpty)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('user_profiles')
                              .doc(order['userId'].toString())
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;
                            if (data == null) return const SizedBox.shrink();

                            final name =
                                data['name'] as String? ?? 'Khách hàng';
                            final media =
                                data['media'] as Map<String, dynamic>? ?? {};
                            final avatar = media['avatar'] as String?;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundImage:
                                      avatar != null && avatar.isNotEmpty
                                      ? getImageProvider(avatar)
                                      : null,
                                  child: (avatar == null || avatar.isEmpty)
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Người đặt',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => Profile(
                                        userId: order['userId'].toString(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'Chờ xác nhận' ||
                              status == 'pending') ...[
                            OutlinedButton(
                              onPressed: () {
                                FirebaseMenuService().updateOrderStatus(
                                  orderId,
                                  'Đã hủy',
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Hủy'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                final storeName = (order['storeName'] ?? '').toString().toLowerCase();
                                final isTicket = storeName.contains('vé') || storeName.contains('máy bay') || storeName.contains('tàu') || storeName.contains('xe khách');
                                if (isTicket) {
                                  final ticketCode = 'TICKET-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                                  FirebaseMenuService().updateOrderStatus(
                                    orderId,
                                    'delivered',
                                    ticketCode: ticketCode,
                                  );
                                } else {
                                  FirebaseMenuService().updateOrderStatus(
                                    orderId,
                                    'processing',
                                  );
                                }
                              },
                              child: const Text('Xác nhận'),
                            ),
                          ] else if (status == 'Đang xử lý' ||
                              status == 'processing') ...[
                            ElevatedButton(
                              onPressed: () {
                                FirebaseMenuService().updateOrderStatus(
                                  orderId,
                                  'Hoàn thành',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Hoàn thành'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Các đơn đặt hàng'),
            actions: [
              TextButton.icon(
                onPressed: pendingOrders.isEmpty
                    ? null
                    : () async {
                        for (final order in pendingOrders) {
                          final orderId = order['id'];
                          final storeName =
                              (order['storeName'] ?? '').toString().toLowerCase();
                          final isTicket = storeName.contains('vé') ||
                              storeName.contains('máy bay') ||
                              storeName.contains('tàu') ||
                              storeName.contains('xe khách');
                          if (isTicket) {
                            final ticketCode =
                                'TICKET-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                            await FirebaseMenuService().updateOrderStatus(
                              orderId,
                              'delivered',
                              ticketCode: ticketCode,
                            );
                          } else {
                            await FirebaseMenuService().updateOrderStatus(
                              orderId,
                              'processing',
                            );
                          }
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Đã phê duyệt tất cả')));
                        }
                      },
                icon: Icon(Icons.done_all,
                    color: pendingOrders.isEmpty ? Colors.grey : Colors.blue),
                label: Text('Duyệt tất cả',
                    style: TextStyle(
                        color: pendingOrders.isEmpty ? Colors.grey : Colors.blue,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: Column(
            children: [
              // Nút bộ lọc và nút chọn ngày
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    // Nút chọn danh mục
                    Expanded(
                      child: GestureDetector(
                        onTap: _showCategoryBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _filterLabels[_selectedFilter] ?? 'Tất cả',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nút chọn ngày
                    Expanded(
                      child: GestureDetector(
                        onTap: _showDateFilterBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  (() {
                                    if (_selectedDateRange == null) return 'Tất cả';
                                    final start = _selectedDateRange!.start;
                                    final end = _selectedDateRange!.end;
                                    final now = DateTime.now();
                                    if (start.year == end.year && start.month == end.month && start.day == end.day) {
                                      if (start.year == now.year && start.month == now.month && start.day == now.day) {
                                        return 'Hôm nay';
                                      }
                                      return _formatDate(start);
                                    }
                                    return '${_formatDate(start)} - ${_formatDate(end)}';
                                  })(),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null 
                      ? FirebaseFirestore.instance.collection('user_profiles').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final isAutoApprove = snapshot.hasData && snapshot.data!.data() != null 
                        ? (snapshot.data!.data() as Map<String, dynamic>)['autoApproveOrders'] == true 
                        : false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tự động duyệt đơn hàng mới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Switch(
                          value: isAutoApprove,
                          activeColor: Colors.deepPurple,
                          onChanged: (val) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              FirebaseFirestore.instance.collection('user_profiles').doc(uid).set({'autoApproveOrders': val}, SetOptions(merge: true));
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(child: bodyWidget),
            ],
          ),
        );
      },
    );
  }
}
