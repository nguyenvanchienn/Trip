import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';

class VehicleBookingPage extends StatefulWidget {
  final Map<String, dynamic> rawService;
  final String mappedName;
  final String mappedPrice;
  final String imageUrl;

  const VehicleBookingPage({
    super.key,
    required this.rawService,
    required this.mappedName,
    required this.mappedPrice,
    required this.imageUrl,
  });

  @override
  State<VehicleBookingPage> createState() => _VehicleBookingPageState();
}

class _VehicleBookingPageState extends State<VehicleBookingPage> {
  int _quantity = 1;
  int _duration = 1;
  final TextEditingController _noteController = TextEditingController();

  int get maxQuantity => (widget.rawService['quantity'] as num?)?.toInt() ?? 5;
  double get unitPrice =>
      (widget.rawService['price'] as num?)?.toDouble() ?? 0.0;

  double get basePrice => unitPrice * _quantity * _duration;
  String get durationUnit {
    final durations =
        (widget.rawService['durationOptions'] as List?)?.cast<String>() ?? [];
    final unit = durations.isNotEmpty ? durations.first : '';
    if (unit.toLowerCase().contains('ngày')) return 'ngày';
    if (unit.toLowerCase().contains('giờ')) return 'giờ';
    if (unit.toLowerCase().contains('tháng')) return 'tháng';
    return unit.isNotEmpty ? unit : 'đơn vị';
  }

  Future<void> _submitBooking(double finalPrice, String extraInfo) async {
    final ownerId = widget.rawService['ownerId']?.toString() ?? '';
    final note = _noteController.text.trim();

    String completeExtraInfo = extraInfo;
    if (note.isNotEmpty)
      completeExtraInfo = ' - Ghi chú: $note$completeExtraInfo';

    final itemName =
        '${widget.mappedName} (Thuê $_quantity xe x $_duration $durationUnit)$completeExtraInfo';

    await FirebaseMenuService().createOrder(
      storeName: 'Dịch vụ thuê xe',
      itemName: itemName,
      price: finalPrice,
      itemImage: widget.imageUrl,
      quantity: 1,
      status: 'Chờ xác nhận',
      ownerId: ownerId,
      type: 'vehicle_rental',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đặt thuê xe thành công!')),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return SharedCheckoutScaffold(
      title: 'Xác nhận đặt thuê',
      ownerId: widget.rawService['ownerId']?.toString() ?? '',
      basePrice: basePrice,
      itemNameSummary: '($_quantity xe x $_duration ngày)',
      requireAddress: true,
      allowReceiveAtLocation: true,
      onSubmit: _submitBooking,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.imageUrl.isNotEmpty
                      ? Image(
                          image:
                              getImageProvider(widget.imageUrl) ??
                              const AssetImage('asset/images/anhdemo.jpeg')
                                  as ImageProvider,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mappedName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.mappedPrice,
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Booking Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết thuê',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Quantity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số lượng xe', style: TextStyle(fontSize: 15)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _quantity > 1
                              ? Colors.deepPurple
                              : Colors.grey,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: _quantity < maxQuantity
                              ? Colors.deepPurple
                              : Colors.grey,
                          onPressed: _quantity < maxQuantity
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),

                // Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thời gian thuê (số $durationUnit)',
                      style: const TextStyle(fontSize: 15),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _duration > 1
                              ? Colors.deepPurple
                              : Colors.grey,
                          onPressed: _duration > 1
                              ? () => setState(() => _duration--)
                              : null,
                        ),
                        Text(
                          '$_duration',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.deepPurple,
                          onPressed: () => setState(() => _duration++),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Note
                const Text(
                  'Ghi chú cho chủ xe (Tuỳ chọn)',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'VD: Tôi muốn nhận xe lúc 8h sáng...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
