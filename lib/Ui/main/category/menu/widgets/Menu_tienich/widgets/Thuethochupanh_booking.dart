import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/Thuethochupanh_Page.dart';

class PhotographerBookingPage extends StatefulWidget {
  final Photographer photographer;
  final VoidCallback onSuccess;

  const PhotographerBookingPage({
    super.key,
    required this.photographer,
    required this.onSuccess,
  });

  @override
  State<PhotographerBookingPage> createState() => _PhotographerBookingPageState();
}

class _PhotographerBookingPageState extends State<PhotographerBookingPage> {
  DateTime? _date;
  TimeOfDay? _time;
  int _hours = 1;

  double get pricePerHour => widget.photographer.pricePerHour.toDouble();
  double get total => pricePerHour * _hours;

  String _fmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₫';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
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
      setState(() => _date = d);
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
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
    if (t != null) {
      setState(() => _time = t);
    }
  }

  void _goToCheckout() {
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và giờ')),
      );
      return;
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt lịch')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotographerCheckoutPage(
          photographer: widget.photographer,
          date: _date!,
          time: _time!,
          hours: _hours,
          onSuccess: widget.onSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đặt Thợ chụp ảnh'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.photographer.images.isNotEmpty)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: ImageCarousel(images: widget.photographer.images),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photographer Info Card
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
                          widget.photographer.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.deepOrange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_fmt(pricePerHour)} / giờ',
                              style: const TextStyle(fontSize: 16, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.work, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${widget.photographer.experienceYears} năm kinh nghiệm',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
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
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Ngày chụp', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _date == null
                                            ? 'Chọn ngày'
                                            : '${_date!.day}/${_date!.month}/${_date!.year}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Giờ bắt đầu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _time == null ? 'Chọn giờ' : _time!.format(context),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                  Text('Số giờ thuê', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
                                    onPressed: _hours > 1 ? () => setState(() => _hours--) : null,
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 12),
                                  Text('$_hours', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                                    onPressed: _hours < 12 ? () => setState(() => _hours++) : null,
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

class PhotographerCheckoutPage extends StatefulWidget {
  final Photographer photographer;
  final DateTime date;
  final TimeOfDay time;
  final int hours;
  final VoidCallback onSuccess;

  const PhotographerCheckoutPage({
    super.key,
    required this.photographer,
    required this.date,
    required this.time,
    required this.hours,
    required this.onSuccess,
  });

  @override
  State<PhotographerCheckoutPage> createState() => _PhotographerCheckoutPageState();
}

class _PhotographerCheckoutPageState extends State<PhotographerCheckoutPage> {
  final FirebaseMenuService _menuService = FirebaseMenuService();

  double get pricePerHour => widget.photographer.pricePerHour.toDouble();
  double get total => pricePerHour * widget.hours;

  String _fmt(double v) =>
      '${v.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₫';

  Future<void> _processBooking(double finalPriceResult, String extraInfo) async {
    final datetime = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      widget.time.hour,
      widget.time.minute,
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('photographer_orders').add({
      'photographerId': widget.photographer.id,
      'photographerName': widget.photographer.name,
      'ownerId': widget.photographer.ownerId,
      'userId': currentUser.uid,
      'bookingDate': datetime.toIso8601String(),
      'hours': widget.hours,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'checkoutExtraInfo': extraInfo,
    });

    await _menuService.createOrder(
      storeName: 'Thuê thợ chụp ảnh',
      itemName: 'Thợ ảnh: ${widget.photographer.name} - Ngày: ${datetime.day}/${datetime.month}/${datetime.year} ${widget.time.format(context)}',
      itemImage: widget.photographer.imageUrl,
      price: pricePerHour,
      quantity: widget.hours,
      status: 'pending',
      ownerId: widget.photographer.ownerId,
      type: 'photographer_rental',
    );

    widget.onSuccess();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt lịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.date.day}/${widget.date.month}/${widget.date.year}';
    final timeStr = widget.time.format(context);
    final double subtotal = total;
    final double finalPrice = subtotal;

    return SharedCheckoutScaffold(
      title: 'Thanh toán thuê Thợ ảnh',
      ownerId: widget.photographer.ownerId,
      basePrice: finalPrice,
      itemNameSummary: 'Thợ ảnh: ${widget.photographer.name}',
      requireAddress: true,
      allowReceiveAtLocation: true,
      addressLabel: 'Địa chỉ chụp ảnh',
      addressPlaceholder: 'Chọn hoặc thêm địa chỉ chụp ảnh',
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
                  const Text('Ngày chụp:', style: TextStyle(color: Colors.grey)),
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giờ bắt đầu:', style: TextStyle(color: Colors.grey)),
                  Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thời gian thuê:', style: TextStyle(color: Colors.grey)),
                  Text('${widget.hours} giờ', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giá mỗi giờ:', style: TextStyle(color: Colors.grey)),
                  Text(_fmt(pricePerHour), style: const TextStyle(fontWeight: FontWeight.w500)),
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
