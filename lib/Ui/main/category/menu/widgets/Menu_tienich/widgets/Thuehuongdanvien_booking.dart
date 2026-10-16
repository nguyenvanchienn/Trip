import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';
import 'package:tourn/Ui/main/category/menu/widgets/payment/payment_helper.dart';

const String STATUS_UPCOMING = 'Sắp diễn ra';

class GuideBookingPage extends StatefulWidget {
  final Map<String, dynamic> guide;
  final Function(Map<String, dynamic>) onBooked;

  const GuideBookingPage({
    super.key,
    required this.guide,
    required this.onBooked,
  });

  @override
  State<GuideBookingPage> createState() => _GuideBookingPageState();
}

class _GuideBookingPageState extends State<GuideBookingPage> {
  DateTime? _startDate;
  int _days = 1;

  double get pricePerDay => (widget.guide['pricePerDay'] as num?)?.toDouble() ?? 0.0;
  double get total => pricePerDay * _days;

  String _fmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₫';

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (d != null) {
      setState(() => _startDate = d);
    }
  }

  void _goToCheckout() {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuideCheckoutPage(
          guide: widget.guide,
          startDate: _startDate!,
          days: _days,
          onBooked: widget.onBooked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.guide['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
    if (images.isEmpty && widget.guide['avatar'] != null) {
      images.add(widget.guide['avatar'].toString());
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đặt Hướng dẫn viên'),
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
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guide Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.guide['name'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_fmt(pricePerDay)} / ngày',
                              style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (widget.guide['experience'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.work, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.guide['experience'].toString(),
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
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chi tiết đặt lịch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.deepPurple),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Ngày bắt đầu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _startDate == null
                                            ? 'Chọn ngày'
                                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Số ngày thuê', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
                                    onPressed: _days > 1 ? () => setState(() => _days--) : null,
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 12),
                                  Text('$_days', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                                    onPressed: _days < 30 ? () => setState(() => _days++) : null,
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
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

class GuideCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> guide;
  final DateTime startDate;
  final int days;
  final Function(Map<String, dynamic>) onBooked;

  const GuideCheckoutPage({
    super.key,
    required this.guide,
    required this.startDate,
    required this.days,
    required this.onBooked,
  });

  @override
  State<GuideCheckoutPage> createState() => _GuideCheckoutPageState();
}

class _GuideCheckoutPageState extends State<GuideCheckoutPage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();

  double get pricePerDay => (widget.guide['pricePerDay'] as num?)?.toDouble() ?? 0.0;
  double get total => pricePerDay * widget.days;

  String _fmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₫';

  Future<void> _processBooking(double finalPriceResult, String extraInfo) async {
    final String dateStr = '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year}';
    final booking = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'guideId': widget.guide['id'],
      'guideName': widget.guide['name'],
      'start': dateStr,
      'days': widget.days,
      'status': STATUS_UPCOMING,
      'checkoutExtraInfo': extraInfo,
    };

    await _menuService.createOrder(
      storeName: 'Thuê hướng dẫn viên',
      itemName: 'Hướng dẫn viên: ${widget.guide['name']} - Bắt đầu: $dateStr - Số ngày: ${widget.days}',
      itemImage: (widget.guide['images'] != null && widget.guide['images'] is List && (widget.guide['images'] as List).isNotEmpty)
          ? widget.guide['images'][0].toString()
          : (widget.guide['avatar'] != null && widget.guide['avatar'].toString().isNotEmpty)
              ? widget.guide['avatar'].toString()
              : 'https://cdn-icons-png.flaticon.com/512/811/811566.png',
      price: pricePerDay,
      quantity: widget.days,
      status: 'pending',
      ownerId: widget.guide['ownerId']?.toString() ?? '',
      type: 'guide_rental',
    );

    widget.onBooked(booking);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // pop checkout
      Navigator.of(context).pop(); // pop booking
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.startDate.day}/${widget.startDate.month}/${widget.startDate.year}';
    final double subtotal = total;
    
    // Simulate some fees or discounts if needed, here just keeping it simple
    final double finalPrice = subtotal;

    return SharedCheckoutScaffold(
      title: 'Thanh toán thuê HDV',
      ownerId: widget.guide['ownerId']?.toString() ?? '',
      basePrice: finalPrice,
      itemNameSummary: 'Thuê HDV: ${widget.guide['name'] ?? ''}',
      requireAddress: false,
      allowReceiveAtLocation: false,
      content: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chi tiết dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thời gian:', style: TextStyle(color: Colors.grey)),
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Số ngày:', style: TextStyle(color: Colors.grey)),
                  Text('${widget.days} ngày', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giá mỗi ngày:', style: TextStyle(color: Colors.grey)),
                  Text(_fmt(pricePerDay), style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _fmt(finalPrice),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      onSubmit: (finalPriceResult, extraInfo) async {
        await _processBooking(finalPriceResult, extraInfo);
      },
    );
  }
}
