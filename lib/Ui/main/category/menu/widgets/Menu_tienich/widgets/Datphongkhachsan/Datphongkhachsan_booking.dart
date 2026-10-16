import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/Ui/main/category/menu/widgets/payment/payment_helper.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';

class HotelBookingPage extends StatefulWidget {
  const HotelBookingPage({super.key, required this.hotel});

  final Map<String, dynamic> hotel;

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();
  DateTimeRange? _range;
  int _rooms = 1;
  int _guests = 1;

  String _fmt(int v) =>
      '${v.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')} ₫';

  int get nights {
    if (_range == null) return 1;
    return _range!.end.difference(_range!.start).inDays;
  }

  int get total {
    final price = widget.hotel['price'] as int;
    return price * (nights == 0 ? 1 : nights) * _rooms;
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  void _goToCheckout() {
    if (_range == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày')));
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HotelCheckoutPage(
          hotel: widget.hotel,
          range: _range!,
          rooms: _rooms,
          guests: _guests,
          total: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.hotel['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (images.isEmpty && widget.hotel['image'] != null) {
      images.add(widget.hotel['image'].toString());
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Đặt phòng khách sạn'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: ImageCarousel(images: images),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.hotel, size: 50, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hotel['name'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_fmt(widget.hotel['price'] ?? 0)} / đêm',
                              style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (widget.hotel['address'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.hotel['address'].toString(),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Selection Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết đặt phòng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Thời gian lưu trú', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _range == null
                                            ? 'Chọn ngày nhận - trả phòng'
                                            : '${_range!.start.toLocal().toString().split(' ').first} → ${_range!.end.toLocal().toString().split(' ').first} (${nights == 0 ? 1 : nights} đêm)',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Số phòng', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
                                          onPressed: _rooms > 1 ? () => setState(() => _rooms--) : null,
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        Text('$_rooms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                                          onPressed: _rooms < 10 ? () => setState(() => _rooms++) : null,
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Số khách', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
                                          onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        Text('$_guests', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                                          onPressed: _guests < 20 ? () => setState(() => _guests++) : null,
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    _fmt(total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _goToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HotelCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final DateTimeRange range;
  final int rooms;
  final int guests;
  final int total;

  const HotelCheckoutPage({
    super.key,
    required this.hotel,
    required this.range,
    required this.rooms,
    required this.guests,
    required this.total,
  });

  @override
  State<HotelCheckoutPage> createState() => _HotelCheckoutPageState();
}

class _HotelCheckoutPageState extends State<HotelCheckoutPage> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String dateVal =
        '${widget.range.start.toLocal().toString().split(' ').first} → ${widget.range.end.toLocal().toString().split(' ').first}';
    final int nights = widget.range.end.difference(widget.range.start).inDays;

    return SharedCheckoutScaffold(
      title: 'Thanh toán đặt phòng',
      ownerId: widget.hotel['ownerId']?.toString() ?? '',
      basePrice: widget.total.toDouble(),
      itemNameSummary: '${widget.hotel['name']} | $dateVal (${nights == 0 ? 1 : nights} đêm) - ${widget.rooms} phòng, ${widget.guests} khách',
      requireAddress: false,
      content: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.hotel['name'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Thời gian: $dateVal'),
              Text('Số đêm: ${nights == 0 ? 1 : nights}'),
              Text('Số phòng: ${widget.rooms}'),
              Text('Số khách: ${widget.guests}'),
              const SizedBox(height: 16),
              const Text(
                'Ghi chú cho khách sạn (Tuỳ chọn)',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'VD: Cần nhận phòng muộn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${widget.total.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} ₫',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      onSubmit: (finalPrice, extraInfo) async {
        final note = _noteController.text.trim();
        String completeExtraInfo = extraInfo;
        if (note.isNotEmpty) {
          completeExtraInfo = ' - Ghi chú: $note$completeExtraInfo';
        }

        final booking = await FirebaseMenuService().addBooking(
          type: 'hotel',
          serviceName: widget.hotel['name'],
          serviceId: widget.hotel['id']?.toString(),
          businessId: widget.hotel['ownerId']?.toString(),
          startDate: widget.range.start,
          endDate: widget.range.end,
          quantity: widget.rooms,
          totalPrice: finalPrice,
          metadata: {
            'rooms': widget.rooms,
            'guests': widget.guests,
            'hotelData': widget.hotel,
            'checkoutExtraInfo': completeExtraInfo,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        await FirebaseMenuService().createOrder(
          storeName: 'Khách sạn ${widget.hotel['name']}',
          itemName: 'Phòng ($dateVal)$completeExtraInfo',
          itemImage: (widget.hotel['images'] != null && (widget.hotel['images'] as List).isNotEmpty)
              ? widget.hotel['images'][0]
              : 'https://cdn-icons-png.flaticon.com/512/3009/3009489.png',
          price: widget.rooms > 0 ? (finalPrice / widget.rooms).toDouble() : finalPrice,
          quantity: widget.rooms,
          status: 'pending',
          ownerId: widget.hotel['ownerId']?.toString(),
          type: 'hotel',
        );

        if (context.mounted) {
          try {
            final repo = context.read<NotificationRepository>();
            final uid = repo.currentUserId;
            if (uid != null) {
              await repo.sendSystemNotification(
                recipientId: uid,
                senderName: 'Trip',
                message: 'Đặt phòng "${widget.hotel['name']}" thành công!',
                bookingId: booking?.id,
                bookingType: 'hotel',
              );
            }
          } catch (_) {}
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đặt phòng thành công!')),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
    );
  }
}
