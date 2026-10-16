import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class DonHangCuaBanPage extends StatefulWidget {
  final String? serviceType;
  const DonHangCuaBanPage({super.key, this.serviceType});

  @override
  State<DonHangCuaBanPage> createState() => _DonHangCuaBanPageState();
}

class _DonHangCuaBanPageState extends State<DonHangCuaBanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Tất cả',
    'Chờ xác nhận',
    'Đang xử lý',
    'Đang giao',
    'Hoàn thành',
    'Đã hủy',
  ];

  final List<String> _statusFilters = [
    '',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _clearDemoData();
  }

  void _clearDemoData() async {
    try {
      final uid = FirebaseMenuService().currentUserId;
      if (uid == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('menu_orders')
          .where('userId', isEqualTo: uid)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final storeName = doc.data()['storeName'] as String?;
        if (storeName != null && storeName.contains('Gian hàng Demo')) {
          await doc.reference.delete();
          count++;
        }
      }
      if (count > 0) {
        print('✅ Đã xóa $count dữ liệu demo cũ');
      }
    } catch (e) {
      print('Lỗi xóa demo data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSingleUtility = widget.serviceType != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của bạn',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: isSingleUtility
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
      ),
      body: isSingleUtility
          ? _OrderListTab(statusFilter: '', serviceType: widget.serviceType)
          : TabBarView(
              controller: _tabController,
              children: _statusFilters.map((filter) {
                return _OrderListTab(
                  statusFilter: filter,
                  serviceType: widget.serviceType,
                );
              }).toList(),
            ),
    );
  }
}

class _OrderListTab extends StatelessWidget {
  final String statusFilter;
  final String? serviceType;

  const _OrderListTab({required this.statusFilter, this.serviceType});

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'processing':
        return 'Đang xử lý';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Chưa rõ';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showRatingDialog(BuildContext context, String orderId) {
    double rating = 5.0;
    String review = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Đánh giá dịch vụ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Nhận xét của bạn (không bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) => review = val,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await FirebaseMenuService().submitOrderReview(
                      orderId,
                      rating,
                      review,
                    );
                  },
                  child: const Text('Gửi đánh giá'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeOrder(
    BuildContext context,
    Map<String, dynamic> order,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Xóa đơn hàng'),
        content: const Text('Bạn có chắc muốn xóa lịch sử đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseMenuService().deleteOrder(order['id']);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa đơn hàng')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseMenuService().streamMyOrders(
        statusFilter: statusFilter,
        typeFilter: serviceType,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có đơn hàng nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            final items = (order['items'] as List<dynamic>?) ?? [];
            final firstItem = items.isNotEmpty ? items.first : null;
            final status = order['status'] ?? 'unknown';

            return Dismissible(
              key: ValueKey(order['id']),
              direction: DismissDirection.startToEnd,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await _removeOrder(context, order);
                return false; // Firebase stream handles the UI update
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tên gian hàng & Trạng thái
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order['storeName'] ?? 'Gian hàng',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Nội dung đơn hàng
                      if (firstItem != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: SmartImage(
                                  imageUrl: firstItem['image']?.toString(),
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                  placeholder: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstItem['name'] ?? 'Sản phẩm',
                                    style: const TextStyle(fontSize: 15),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Phân loại: Mặc định',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text('x${firstItem['quantity'] ?? 1}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${(firstItem['price'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} ₫',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const Divider(height: 24),

                      // Tổng cộng & Nút
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${items.length} sản phẩm',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Thành tiền: ',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${(order['totalPrice'] ?? 0).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} ₫',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (order['ticketCode'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'MÃ VÉ CỦA BẠN',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order['ticketCode'],
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Vui lòng đưa mã này cho nhân viên',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Buttons (Demo)
                      if (status != 'cancelled') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'pending')
                              OutlinedButton(
                                onPressed: () =>
                                    FirebaseMenuService().updateOrderStatus(
                                      order['id'],
                                      'cancelled',
                                    ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                child: const Text(
                                  'Hủy đơn',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            if (status == 'pending') const SizedBox(width: 8),

                            if (status == 'shipped')
                              ElevatedButton(
                                onPressed: () =>
                                    FirebaseMenuService().updateOrderStatus(
                                      order['id'],
                                      'delivered',
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Đã nhận được hàng'),
                              ),

                            if (status == 'delivered') ...[
                              if (order['rating'] != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${order['rating']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                )
                              else
                                ElevatedButton(
                                  onPressed: () {
                                    _showRatingDialog(context, order['id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: const Text('Đánh giá'),
                                ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.blue),
                                ),
                                child: const Text(
                                  'Mua lại',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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
}
