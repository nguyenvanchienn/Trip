import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/generic_search_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'dart:async';

bool isServiceExpired(String dateStr, List<String> times) {
  if (dateStr.isEmpty) return false;
  try {
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      final year = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[0]);

      final now = DateTime.now();

      if (times.isEmpty) {
        final tripDate = DateTime(year, month, day, 23, 59);
        return now.isAfter(tripDate);
      }

      bool allTimesPassed = true;
      for (final time in times) {
        final timeParts = time.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1].substring(0, 2));
          final tripDateTime = DateTime(year, month, day, hour, minute);
          if (tripDateTime.isAfter(now)) {
            allTimesPassed = false;
            break;
          }
        } else {
          allTimesPassed = false;
        }
      }
      return allTimesPassed;
    }
  } catch (e) {
    // pass
  }
  return false;
}

class XekhachPage extends StatefulWidget {
  const XekhachPage({super.key});

  @override
  State<XekhachPage> createState() => _XekhachPageState();
}

class _XekhachPageState extends State<XekhachPage> {
  List<Map<String, dynamic>> routes = [];
  StreamSubscription<List<Map<String, dynamic>>>? _routeSub;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  void _loadRoutes() {
    _routeSub = FirebaseBusinessService()
        .streamServices(collectionName: 'business_bus_ticket_services')
        .listen((services) {
          final list = services
              .map((service) {
                final extra = (service['extra'] as Map<String, dynamic>?) ?? {};
                final route = (extra['route'] ?? '').toString();
                final routeParts = route.split('-');
                final fromStr =
                    extra['from']?.toString() ??
                    (routeParts.isNotEmpty ? routeParts[0].trim() : 'Hà Nội');
                final toStr =
                    extra['to']?.toString() ??
                    (routeParts.length > 1
                        ? routeParts[1].trim()
                        : 'Ninh Bình');

                final timeData = extra['time'];
                final timeStr = timeData is List
                    ? timeData.join(', ')
                    : (timeData ?? '06:00 - 08:30').toString();
                final timeList = timeData is List
                    ? timeData.map((e) => e.toString()).toList()
                    : [timeStr];
                final scheduleStr = (extra['schedule'] ?? 'Hàng ngày')
                    .toString();
                final unitStr = (extra['unit'] ?? extra['duration'] ?? '2h30m')
                    .toString();
                final opStr =
                    (extra['busCompany'] ??
                            extra['operator'] ??
                            extra['company'] ??
                            'VIPBus')
                        .toString();

                return {
                  'id': service['id']?.toString() ?? '',
                  'from': fromStr.isEmpty ? 'Hà Nội' : fromStr,
                  'to': toStr.isEmpty ? 'Ninh Bình' : toStr,
                  'time': timeStr,
                  'timeList': timeList,
                  'duration': unitStr,
                  'schedule': scheduleStr,
                  'price': (service['price'] as num?)?.toInt() ?? 0,
                  'company': opStr,
                  'ownerId': (service['ownerId'] ?? '').toString(),
                  'image': (extra['imageUrl'] ?? '').toString(),
                  'images': extra['images'] is List
                      ? (extra['images'] as List)
                            .map((e) => e.toString())
                            .toList()
                      : [],
                  'busType': (extra['busType'] ?? '').toString(),
                  'description': (service['description'] ?? '').toString(),
                };
              })
              .where(
                (item) => !isServiceExpired(
                  item['schedule'] as String,
                  item['timeList'] as List<String>,
                ),
              )
              .toList();
          if (mounted) {
            setState(() {
              routes = list;
            });
          }
        });
  }

  @override
  void dispose() {
    _routeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DonHangCuaBanPage(serviceType: 'bus_ticket'),
                ),
              );
            },
          ),
        ],
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenericSearchPage<Map<String, dynamic>>(
                  searchPrefsKey: 'search_xekhach',
                  searchHint: 'Tìm tuyến xe khách...',
                  brandOrange: Colors.deepPurple,
                  pageBg: Colors.white,
                  allItems: routes,
                  onSearchMatch: (items, query) {
                    final q = query.toLowerCase();
                    return items.where((item) {
                      return item['from'].toString().toLowerCase().contains(
                            q,
                          ) ||
                          item['to'].toString().toLowerCase().contains(q) ||
                          item['company'].toString().toLowerCase().contains(q);
                    }).toList();
                  },
                  getKeywordName: (item) => '${item['from']} đi ${item['to']}',
                  buildItemCard: (item) {
                    Widget cardWidget = Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BusPassengerBookingPage(route: item),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SmartImage(
                                    imageUrl: item['image'].toString(),
                                    fit: BoxFit.cover,
                                    placeholder: const Icon(
                                      Icons.directions_bus_filled,
                                      color: Colors.deepPurple,
                                      size: 30,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.directions_bus_filled,
                                      color: Colors.deepPurple,
                                      size: 30,
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
                                      '${item['from']} → ${item['to']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (item['schedule'] as String?)
                                                      ?.isNotEmpty ==
                                                  true &&
                                              item['schedule'] != 'Hàng ngày'
                                          ? '${item['schedule']} • ${item['time']} • ${item['duration']}'
                                          : '${item['time']} • ${item['duration']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${(item['price'] as int).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} ₫',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (FirebaseAuth.instance.currentUser?.uid !=
                                      (item['ownerId'] ?? '').toString())
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BusPassengerBookingPage(
                                                  route: item,
                                                ),
                                          ),
                                        );
                                      },
                                      child: const Text('Đặt vé'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    final ownerId = (item['ownerId'] ?? '').toString();
                    if (ownerId.isNotEmpty) {
                      Widget currentCard = cardWidget;
                      cardWidget =
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('user_profiles')
                                .doc(ownerId)
                                .snapshots(),
                            builder: (context, profileSnap) {
                              final profileData =
                                  profileSnap.data?.data() ?? {};
                              final businessProfile =
                                  (profileData['businessProfile']
                                      as Map<String, dynamic>?) ??
                                  {};
                              final isOpen =
                                  businessProfile['isOpen'] as bool? ?? true;
                              return Opacity(
                                opacity: isOpen ? 1.0 : 0.5,
                                child: currentCard,
                              );
                            },
                          );
                    }

                    return cardWidget;
                  },
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16, left: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tìm tuyến xe...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.chair,
                              size: 36,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Xe khách',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Xe giường nằm, xe ghế ngồi liên tỉnh — đặt vé nhanh chóng và an toàn',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tuyến nổi bật',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final r = routes[index];
                Widget cardWidget = Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BusPassengerBookingPage(route: r),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SmartImage(
                                imageUrl: r['image'].toString(),
                                fit: BoxFit.cover,
                                placeholder: const Icon(
                                  Icons.directions_bus_filled,
                                  color: Colors.deepPurple,
                                  size: 30,
                                ),
                                errorWidget: const Icon(
                                  Icons.directions_bus_filled,
                                  color: Colors.deepPurple,
                                  size: 30,
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
                                  '${r['from']} → ${r['to']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${r['time']} • ${r['duration']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(r['price'] as int).toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ".")} ₫',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (FirebaseAuth.instance.currentUser?.uid !=
                                  (r['ownerId'] ?? '').toString())
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BusPassengerBookingPage(route: r),
                                    ),
                                  ),
                                  child: const Text('Đặt vé'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final ownerId = (r['ownerId'] ?? '').toString();
                if (ownerId.isNotEmpty) {
                  Widget currentCard = cardWidget;
                  cardWidget =
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('user_profiles')
                            .doc(ownerId)
                            .snapshots(),
                        builder: (context, profileSnap) {
                          final profileData = profileSnap.data?.data() ?? {};
                          final businessProfile =
                              (profileData['businessProfile']
                                  as Map<String, dynamic>?) ??
                              {};
                          final isOpen =
                              businessProfile['isOpen'] as bool? ?? true;
                          return Opacity(
                            opacity: isOpen ? 1.0 : 0.5,
                            child: currentCard,
                          );
                        },
                      );
                }
                return cardWidget;
              }, childCount: routes.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    color: Colors.grey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Lưu ý',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('- Đến trước giờ xe khởi hành ít nhất 20 phút.'),
                          Text('- Kiểm tra loại ghế (ngồi/giường) khi đặt vé.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusPassengerBookingPage extends StatefulWidget {
  const BusPassengerBookingPage({super.key, required this.route});

  final Map<String, dynamic> route;

  @override
  State<BusPassengerBookingPage> createState() =>
      _BusPassengerBookingPageState();
}

class _BusPassengerBookingPageState extends State<BusPassengerBookingPage> {
  late String vehicleType;
  Set<String> selectedSeats = {};
  Set<String> bookedSeats = {};
  StreamSubscription<DocumentSnapshot>? _seatSub;
  String? selectedTime;
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    final rawType = (widget.route['busType'] as String?) ?? '';
    final validTypes = [
      'Ghế ngồi 40 chỗ',
      'Ghế ngồi 45 chỗ',
      'Giường nằm 36 chỗ',
      'Giường nằm 45 chỗ',
      'Limousine 9 chỗ',
      'Limousine 34 phòng',
    ];

    if (validTypes.contains(rawType)) {
      vehicleType = rawType;
    } else {
      if (rawType.toLowerCase().contains('giường')) {
        vehicleType = 'Giường nằm 36 chỗ';
      } else if (rawType.toLowerCase().contains('limousine')) {
        vehicleType = 'Limousine 9 chỗ';
      } else {
        vehicleType = 'Ghế ngồi 45 chỗ';
      }
    }
    _listenToSeats();
  }

  void _listenToSeats() {
    _seatSub?.cancel();
    final docId = '${widget.route['id']}_$vehicleType';
    _seatSub = FirebaseFirestore.instance
        .collection('bus_seat_locks')
        .doc(docId)
        .snapshots()
        .listen(
          (snap) {
            if (!snap.exists) {
              if (mounted) setState(() => bookedSeats = {});
              return;
            }
            final data = snap.data() as Map<String, dynamic>;
            final locks =
                (data['bookedSeats'] as List?)
                    ?.map((e) => e.toString())
                    .toSet() ??
                {};
            if (mounted) {
              setState(() {
                bookedSeats = locks;
                selectedSeats.removeWhere((s) => bookedSeats.contains(s));
              });
            }
          },
          onError: (error) {
            print('Error listening to seats: $error');
          },
        );
  }

  @override
  void dispose() {
    _seatSub?.cancel();
    super.dispose();
  }

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final seatInfo = record['seats'] as List<String>? ?? [];
    final seatStr = seatInfo.isNotEmpty ? ' (Ghế: ${seatInfo.join(", ")})' : '';
    final timeVal =
        selectedTime ??
        (widget.route['timeList'] as List?)?.firstOrNull?.toString() ??
        widget.route['time'];
    final dateVal = (widget.route['schedule'] == 'Hàng ngày')
        ? (selectedDate ?? 'Chưa chọn ngày')
        : widget.route['schedule'];
    final extraInfo = record['extraInfo'] as String? ?? '';
    await FirebaseMenuService().createOrder(
      storeName: 'Nhà Xe ${record['company']}',
      itemName:
          '${record['route']} - $dateVal, Giờ: $timeVal (${record['vehicleType']})$seatStr$extraInfo',
      itemImage: (widget.route['image'] as String).isNotEmpty
          ? widget.route['image'] as String
          : 'https://cdn-icons-png.flaticon.com/512/3448/3448339.png', // bus icon
      price: record['total'] > 0 && record['passengers'] > 0
          ? (record['total'] as num).toDouble() / (record['passengers'] as num)
          : 0.0,
      quantity: record['passengers'] as int,
      status: 'pending',
      ownerId: widget.route['ownerId']?.toString(),
      type: 'bus_ticket',
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.route['price'] as int;
    final vehicleModifier = vehicleType.contains('Giường')
        ? 25000
        : (vehicleType.contains('Limousine') ? 80000 : 0);
    final total =
        (price + vehicleModifier) *
        (selectedSeats.isEmpty ? 0 : selectedSeats.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt vé: ${widget.route['from']} → ${widget.route['to']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const DonHangCuaBanPage(serviceType: 'bus_ticket')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((widget.route['images'] as List? ?? []).isNotEmpty ||
                      (widget.route['image'] as String).isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: () {
                        final images =
                            (widget.route['images'] as List? ?? []).isNotEmpty
                            ? widget.route['images'] as List
                            : [widget.route['image']];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ImageCarousel(
                            images: images.map((e) => e.toString()).toList(),
                          ),
                        );
                      }(),
                    ),
                  const SizedBox(height: 16),
          Text(
            '${widget.route['from']} → ${widget.route['to']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if ((widget.route['schedule'] as String?)?.isNotEmpty ==
                  true &&
              widget.route['schedule'] != 'Hàng ngày') ...[
            Text('Ngày chạy: ${widget.route['schedule']}'),
            const SizedBox(height: 4),
          ] else if (widget.route['schedule'] == 'Hàng ngày') ...[
            Row(
              children: [
                const Text('Chọn ngày đi: '),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate =
                              "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(selectedDate ?? 'Bấm để chọn ngày'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if ((widget.route['timeList'] as List?)?.isNotEmpty == true &&
              (widget.route['timeList'] as List).length > 1) ...[
            const Text(
              'Giờ khởi hành: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: (widget.route['timeList'] as List).map((t) {
                  final tStr = t.toString();
                  final isSelected =
                      (selectedTime ??
                          (widget.route['timeList'] as List).first
                              .toString()) ==
                      tStr;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tStr),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedTime = tStr);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 4),
          ] else ...[
            Text('Giờ khởi hành: ${widget.route['time']}'),
            const SizedBox(height: 4),
          ],
          if (widget.route['ownerId'] != null &&
              widget.route['ownerId'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('user_profiles')
                  .doc(widget.route['ownerId'])
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ??
                    {};
                final businessProfile =
                    data['businessProfile'] as Map<String, dynamic>? ??
                    {};
                final ownerProfile =
                    data['ownerProfile'] as Map<String, dynamic>? ?? {};

                String _getValidString(
                  List<String?> values,
                  String defaultValue,
                ) {
                  for (final v in values) {
                    if (v != null && v.trim().isNotEmpty)
                      return v.trim();
                  }
                  return defaultValue;
                }

                final storeName = _getValidString([
                  businessProfile['name'] as String?,
                  ownerProfile['name'] as String?,
                  data['fullName'] as String?,
                ], 'Người đăng');

                final media =
                    businessProfile['media'] as Map<String, dynamic>? ??
                    {};
                final avatar = _getValidString([
                  media['avatarPath'] as String?,
                  media['avatar'] as String?,
                  data['avatar'] as String?,
                  data['photoURL'] as String?,
                  data['photoUrl'] as String?,
                ], '');

                final address = _getValidString([
                  businessProfile['address'] as String?,
                ], 'Người đăng');

                String displayAddress = address;
                if (address != 'Người đăng') {
                  final parts = address
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                  if (parts.length >= 2) {
                    displayAddress =
                        '${parts[parts.length - 2]}, ${parts.last}';
                  }
                }

                final reviewsCount =
                    (businessProfile['reviewsCount'] as num?)?.toInt() ?? 0;
                final rating = reviewsCount == 0
                    ? 0.0
                    : ((businessProfile['rating'] as num?)?.toDouble() ?? 0.0);

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusinessProfilePage(
                          ownerId: widget.route['ownerId'].toString(),
                        ),
                      ),
                    );
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: avatar.isNotEmpty
                        ? getImageProvider(avatar)
                        : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    storeName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0 ? '${rating.toStringAsFixed(1)} ($reviewsCount đánh giá)' : 'Chưa có đánh giá',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),
          Text('Thời gian: ${widget.route['time']}'),
          const SizedBox(height: 4),
          Text('Hãng xe: ${widget.route['company']}'),
          const SizedBox(height: 4),
          if (widget.route['duration'] != null &&
              (widget.route['duration'] as String).isNotEmpty)
            Text('Thời gian dự kiến: ${widget.route['duration']}'),
          const SizedBox(height: 16),

          if ((widget.route['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Mô tả:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.route['description'] as String),
          ],
          const SizedBox(height: 16),

          const Text('Loại xe'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepPurple.shade200),
            ),
            child: Text(
              vehicleType,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn ghế / giường',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                selectedSeats.isEmpty
                    ? 'Chưa chọn'
                    : '${selectedSeats.length} ghế',
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (selectedSeats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Ghế đã chọn: ${(selectedSeats.toList()..sort()).join(", ")}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          BusSeatMap(
            vehicleType: vehicleType,
            selectedSeats: selectedSeats,
            bookedSeats: bookedSeats,
            onSeatToggled: (seatId) {
              setState(() {
                if (selectedSeats.contains(seatId)) {
                  selectedSeats.remove(seatId);
                } else {
                  selectedSeats.add(seatId);
                }
              });
            },
          ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng: ${total.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} ₫',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedSeats.isEmpty || (widget.route['schedule'] == 'Hàng ngày' && selectedDate == null)
                      ? null
                      : () {
                          if (FirebaseAuth.instance.currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng đăng nhập'),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusCheckoutPage(
                                route: widget.route,
                                vehicleType: vehicleType,
                                selectedSeats: selectedSeats,
                                selectedDate: selectedDate,
                                selectedTime: selectedTime,
                                total: total,
                              ),
                            ),
                          );
                        },
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BusSeatMap extends StatelessWidget {
  final String vehicleType;
  final Set<String> selectedSeats;
  final Set<String> bookedSeats;
  final Function(String) onSeatToggled;

  const BusSeatMap({
    super.key,
    required this.vehicleType,
    required this.selectedSeats,
    required this.bookedSeats,
    required this.onSeatToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicleType == 'Ghế ngồi 40 chỗ') {
      return _buildSeating(
        context,
        rows: 10,
        leftCols: 2,
        rightCols: 2,
        hasBackRow: false,
      );
    } else if (vehicleType == 'Ghế ngồi 45 chỗ') {
      return _buildSeating(
        context,
        rows: 10,
        leftCols: 2,
        rightCols: 2,
        hasBackRow: true,
      );
    } else if (vehicleType == 'Giường nằm 36 chỗ') {
      return _buildSleeper(
        context,
        normalRows: 6,
        bottomBackRow: 0,
        topBackRow: 0,
      );
    } else if (vehicleType == 'Giường nằm 45 chỗ') {
      // 6 normal rows (18) + 5 back row = 23 (bottom)
      // 6 normal rows (18) + 4 back row = 22 (top) -> 45 total
      return _buildSleeper(
        context,
        normalRows: 6,
        bottomBackRow: 5,
        topBackRow: 4,
      );
    } else if (vehicleType == 'Limousine 34 phòng') {
      // 34 rooms => usually 6 normal rows * 3 = 18 per floor? Or 3 cols * 5 normal rows + 2 back row = 17 per floor = 34 total
      return _buildSleeper(
        context,
        normalRows: 5,
        bottomBackRow: 2,
        topBackRow: 2,
      );
    } else if (vehicleType == 'Limousine 9 chỗ') {
      return _buildLimousine9(context);
    } else {
      // Fallbacks
      if (vehicleType.contains('Giường')) {
        return _buildSleeper(
          context,
          normalRows: 6,
          bottomBackRow: 0,
          topBackRow: 0,
        );
      } else if (vehicleType.contains('Limousine')) {
        return _buildLimousine9(context);
      }
      return _buildSeating(
        context,
        rows: 10,
        leftCols: 2,
        rightCols: 2,
        hasBackRow: true,
      );
    }
  }

  Widget _buildLimousine9(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegend(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.trip_origin, color: Colors.grey, size: 30),
                  const SizedBox(width: 8),
                  const Text(
                    'Tài xế',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildSeat('A1'),
                  const SizedBox(width: 8),
                  _buildSeat('B1'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildSeat('A2'), _buildSeat('B2')],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildSeat('A3'), _buildSeat('B3')],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSeat('A4'),
                  _buildSeat('B4'),
                  _buildSeat('C4'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeating(
    BuildContext context, {
    required int rows,
    required int leftCols,
    required int rightCols,
    bool hasBackRow = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegend(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Icon(Icons.trip_origin, color: Colors.grey, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'Tài xế',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(rows, (rowIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(leftCols, (colIndex) {
                            final seatId =
                                '${String.fromCharCode(65 + colIndex)}${rowIndex + 1}';
                            return _buildSeat(seatId);
                          }),
                        ),
                        const SizedBox(width: 20), // Lối đi
                        Row(
                          children: List.generate(rightCols, (colIndex) {
                            final seatId =
                                '${String.fromCharCode(65 + leftCols + colIndex)}${rowIndex + 1}';
                            return _buildSeat(seatId);
                          }),
                        ),
                      ],
                    ),
                  );
                }),
                if (hasBackRow)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(leftCols + rightCols + 1, (
                        colIndex,
                      ) {
                        final seatId =
                            '${String.fromCharCode(65 + colIndex)}${rows + 1}';
                        return _buildSeat(seatId);
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleeper(
    BuildContext context, {
    required int normalRows,
    required int bottomBackRow,
    required int topBackRow,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLegend(),
        const SizedBox(height: 16),
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                tabs: [
                  Tab(text: 'Tầng dưới'),
                  Tab(text: 'Tầng trên'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    _buildSleeperFloor('T', normalRows, bottomBackRow),
                    _buildSleeperFloor('L', normalRows, topBackRow),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSleeperFloor(
    String floorPrefix,
    int normalRows,
    int backRowSeats,
  ) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const [
                  Icon(Icons.trip_origin, color: Colors.grey, size: 30),
                  SizedBox(width: 8),
                  Text(
                    'Tài xế',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(normalRows, (rowIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSeat('${floorPrefix}A${rowIndex + 1}', isBed: true),
                      const SizedBox(width: 20),
                      _buildSeat('${floorPrefix}B${rowIndex + 1}', isBed: true),
                      const SizedBox(width: 20),
                      _buildSeat('${floorPrefix}C${rowIndex + 1}', isBed: true),
                    ],
                  ),
                );
              }),
              if (backRowSeats > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(backRowSeats, (colIndex) {
                      return _buildSeat(
                        '${floorPrefix}${String.fromCharCode(65 + colIndex)}${normalRows + 1}',
                        isBed: true,
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.white, Colors.grey.shade400, 'Trống'),
        const SizedBox(width: 16),
        _buildLegendItem(
          Colors.deepPurple.shade50,
          Colors.deepPurple,
          'Đang chọn',
        ),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.red.shade100, Colors.red, 'Đã bán'),
      ],
    );
  }

  Widget _buildLegendItem(Color bgColor, Color borderColor, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSeat(String seatId, {bool isBed = false}) {
    final isSelected = selectedSeats.contains(seatId);
    final isBooked = bookedSeats.contains(seatId);

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade400;
    Color textColor = Colors.black87;

    if (isBooked) {
      bgColor = Colors.red.shade100;
      borderColor = Colors.red;
      textColor = Colors.red.shade900;
    } else if (isSelected) {
      bgColor = Colors.deepPurple.shade50;
      borderColor = Colors.deepPurple;
      textColor = Colors.deepPurple;
    }

    return GestureDetector(
      onTap: isBooked ? null : () => onSeatToggled(seatId),
      child: Container(
        width: 45,
        height: isBed ? 60 : 45,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          seatId,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class BusCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> route;
  final String vehicleType;
  final Set<String> selectedSeats;
  final String? selectedDate;
  final String? selectedTime;
  final int total;

  const BusCheckoutPage({
    super.key,
    required this.route,
    required this.vehicleType,
    required this.selectedSeats,
    this.selectedDate,
    this.selectedTime,
    required this.total,
  });

  @override
  State<BusCheckoutPage> createState() => _BusCheckoutPageState();
}

class _BusCheckoutPageState extends State<BusCheckoutPage> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seatList = widget.selectedSeats.toList()..sort();
    final String dateVal = (widget.route['schedule'] == 'Hàng ngày')
        ? (widget.selectedDate ?? 'Chưa chọn ngày')
        : (widget.route['schedule'] ?? '');
    final String timeVal = widget.selectedTime ??
        (widget.route['timeList'] as List?)?.firstOrNull?.toString() ??
        widget.route['time']?.toString() ??
        '';

    return SharedCheckoutScaffold(
      title: 'Thanh toán vé xe khách',
      ownerId: widget.route['ownerId']?.toString() ?? '',
      basePrice: widget.total.toDouble(),
      itemNameSummary:
          '${widget.route['from']} → ${widget.route['to']} | $dateVal $timeVal (${widget.vehicleType}) - Ghế: ${seatList.join(', ')}',
      requireAddress: false,
      content: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.route['from']} → ${widget.route['to']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Ngày: $dateVal'),
              Text('Giờ: $timeVal'),
              Text('Loại xe: ${widget.vehicleType}'),
              Text('Ghế: ${seatList.join(', ')}'),
              const SizedBox(height: 16),
              const Text(
                'Ghi chú cho nhà xe (Tuỳ chọn)',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'VD: Đón tôi ở ngã tư...',
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

        await FirebaseMenuService().createOrder(
          storeName: 'Nhà Xe ${widget.route['company'] ?? ''}',
          itemName:
              '${widget.route['from']} → ${widget.route['to']} - $dateVal, Giờ: $timeVal (${widget.vehicleType}) - Ghế: ${seatList.join(', ')}$completeExtraInfo',
          itemImage: (widget.route['image'] as String? ?? '').isNotEmpty
              ? widget.route['image'] as String
              : 'https://cdn-icons-png.flaticon.com/512/3448/3448339.png',
          price: widget.selectedSeats.isNotEmpty
              ? finalPrice / widget.selectedSeats.length
              : finalPrice,
          quantity: widget.selectedSeats.isEmpty ? 1 : widget.selectedSeats.length,
          status: 'pending',
          ownerId: widget.route['ownerId']?.toString(),
          type: 'bus_ticket',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đặt vé thành công!')),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      },
    );
  }
}