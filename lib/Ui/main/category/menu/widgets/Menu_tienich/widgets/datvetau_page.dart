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

class DatvetauPage extends StatefulWidget {
  const DatvetauPage({super.key});

  @override
  State<DatvetauPage> createState() => _DatvetauPageState();
}

class _DatvetauPageState extends State<DatvetauPage> {
  List<Map<String, dynamic>> ships = [];
  StreamSubscription<List<Map<String, dynamic>>>? _shipSub;

  @override
  void initState() {
    super.initState();
    _loadShips();
  }

  void _loadShips() {
    _shipSub = FirebaseBusinessService()
        .streamServices(collectionName: 'business_ship_ticket_services')
        .listen(
          (services) {
            final list = services
                .map((service) {
                  final extra =
                      (service['extra'] as Map<String, dynamic>?) ?? {};
                  final route = (extra['route'] ?? '').toString();
                  final routeParts = route.split('-');
                  final fromStr =
                      extra['from']?.toString() ??
                      (routeParts.isNotEmpty ? routeParts[0].trim() : 'Hà Nội');
                  final toStr =
                      extra['to']?.toString() ??
                      (routeParts.length > 1
                          ? routeParts[1].trim()
                          : 'Sài Gòn');

                  final timeData = extra['time'];
                  final timeStr = timeData is List
                      ? timeData.join(', ')
                      : (timeData ?? '06:00 - 14:30').toString();
                  final timeList = timeData is List
                      ? timeData.map((e) => e.toString()).toList()
                      : [timeStr];
                  final scheduleStr = (extra['schedule'] ?? 'Hàng ngày')
                      .toString();
                  final unitStr = (extra['unit'] ?? extra['duration'] ?? '8h')
                      .toString();
                  final opStr =
                      (extra['shipType'] ??
                              extra['operator'] ??
                              'Hãng tàu thủy')
                          .toString();

                  return {
                    'id': service['id']?.toString() ?? '',
                    'from': fromStr.isEmpty ? 'Hà Nội' : fromStr,
                    'to': toStr.isEmpty ? 'Sài Gòn' : toStr,
                    'time': timeStr,
                    'timeList': timeList,
                    'duration': unitStr,
                    'price': (service['price'] as num?)?.toInt() ?? 0,
                    'operator': opStr,
                    'ownerId': (service['ownerId'] ?? '').toString(),
                    'image': (extra['imageUrl'] ?? '').toString(),
                    'images': extra['images'] is List
                        ? (extra['images'] as List)
                              .map((e) => e.toString())
                              .toList()
                        : [],
                    'description': (service['description'] ?? '').toString(),
                    'schedule': scheduleStr,
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
                ships = list;
              });
            }
          },
          onError: (error) {
            print('[DatvetauPage] Firestore error: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi tải dữ liệu: $error')),
              );
            }
          },
        );
  }

  @override
  void dispose() {
    _shipSub?.cancel();
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
                      const DonHangCuaBanPage(serviceType: 'ship_ticket'),
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
                  searchPrefsKey: 'search_tauhoa',
                  searchHint: 'Tìm chuyến tàu...',
                  brandOrange: Colors.orange,
                  pageBg: Colors.white,
                  allItems: ships,
                  onSearchMatch: (items, query) {
                    final q = query.toLowerCase();
                    return items.where((item) {
                      return item['from'].toString().toLowerCase().contains(
                            q,
                          ) ||
                          item['to'].toString().toLowerCase().contains(q) ||
                          item['operator'].toString().toLowerCase().contains(q);
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
                              builder: (_) => ShipBookingPage(ship: item),
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
                                      Icons.directions_boat,
                                      color: Colors.brown,
                                      size: 30,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.directions_boat,
                                      color: Colors.brown,
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
                                        fontSize: 13,
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
                                                ShipBookingPage(ship: item),
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
              cardWidget = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('user_profiles')
                            .doc(ownerId)
                            .snapshots(),
                        builder: (context, profileSnap) {
                          final profileData = profileSnap.data?.data() ?? {};
                          final businessProfile = (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
                          final isOpen = businessProfile['isOpen'] as bool? ?? true;
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
                  'Tìm chuyến tàu...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.directions_boat,
                          size: 36,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Tàu thủy',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tìm chuyến, kiểm tra giờ và đặt vé tàu thuận tiện',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Chuyến nổi bật',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              if (ships.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_boat,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hiện chưa có chuyến tàu nào được cập nhật.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ships.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = ships[index];
                    Widget cardWidget = Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShipBookingPage(ship: t),
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
                                    imageUrl: t['image'].toString(),
                                    fit: BoxFit.cover,
                                    placeholder: const Icon(
                                      Icons.directions_boat,
                                      color: Colors.brown,
                                      size: 30,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.directions_boat,
                                      color: Colors.brown,
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
                                      '${t['from']} → ${t['to']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${t['time']} • ${t['duration']}',
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
                                    '${(t['price'] as int).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} ₫',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (FirebaseAuth.instance.currentUser?.uid !=
                                      (t['ownerId'] ?? '').toString())
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ShipBookingPage(ship: t),
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

                    final ownerId = (t['ownerId'] ?? '').toString();
                    if (ownerId.isNotEmpty) {
                      Widget currentCard = cardWidget;
              cardWidget = StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('user_profiles')
                            .doc(ownerId)
                            .snapshots(),
                        builder: (context, profileSnap) {
                          final profileData = profileSnap.data?.data() ?? {};
                          final businessProfile = (profileData['businessProfile'] as Map<String, dynamic>?) ?? {};
                          final isOpen = businessProfile['isOpen'] as bool? ?? true;
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

              const SizedBox(height: 20),
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
                      Text('- Kiểm tra số toa và giờ làm thủ tục.'),
                      Text('- Giữ vé điện tử hoặc in vé khi cần.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShipBookingPage extends StatefulWidget {
  const ShipBookingPage({super.key, required this.ship});

  final Map<String, dynamic> ship;

  @override
  State<ShipBookingPage> createState() => _ShipBookingPageState();
}

class _ShipBookingPageState extends State<ShipBookingPage> {
  late String seatMapType;
  Set<String> selectedSeats = {};
  Set<String> bookedSeats = {};
  StreamSubscription<DocumentSnapshot>? _seatSub;
  String? selectedTime;
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    final rawType = (widget.ship['operator'] as String?) ?? '';
    if (rawType == 'Tàu cao tốc (100 chỗ)') {
      seatMapType = 'Tàu cao tốc (100 chỗ)';
    } else {
      seatMapType = 'Phà (50 chỗ)';
    }
    _listenToSeats();
  }

  void _listenToSeats() {
    _seatSub?.cancel();
    final docId = '${widget.ship['id']}_$seatMapType';
    _seatSub = FirebaseFirestore.instance
        .collection('ship_seat_locks')
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

  @override
  Widget build(BuildContext context) {
    final price = widget.ship['price'] as int;
    final total = price * (selectedSeats.isEmpty ? 0 : selectedSeats.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt vé: ${widget.ship['from']} → ${widget.ship['to']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const DonHangCuaBanPage(serviceType: 'ship_ticket'),
                ),
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
                  if ((widget.ship['images'] as List? ?? []).isNotEmpty ||
                      (widget.ship['image'] as String).isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: () {
                        final images =
                            (widget.ship['images'] as List? ?? []).isNotEmpty
                            ? widget.ship['images'] as List
                            : [widget.ship['image']];
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
                    '${widget.ship['from']} → ${widget.ship['to']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((widget.ship['schedule'] as String?)?.isNotEmpty ==
                          true &&
                      widget.ship['schedule'] != 'Hàng ngày') ...[
                    Text('Ngày chạy: ${widget.ship['schedule']}'),
                    const SizedBox(height: 4),
                  ] else if (widget.ship['schedule'] == 'Hàng ngày') ...[
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
                  if ((widget.ship['timeList'] as List?)?.isNotEmpty == true &&
                      (widget.ship['timeList'] as List).length > 1) ...[
                    const Text(
                      'Giờ khởi hành: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (widget.ship['timeList'] as List).map((t) {
                          final tStr = t.toString();
                          final isSelected =
                              (selectedTime ??
                                  (widget.ship['timeList'] as List).first
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
                    Text('Giờ khởi hành: ${widget.ship['time']}'),
                  ],
                  if (widget.ship['ownerId'] != null &&
                      widget.ship['ownerId'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('user_profiles')
                          .doc(widget.ship['ownerId'])
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
                                  ownerId: widget.ship['ownerId'].toString(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn ghế',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        selectedSeats.isEmpty
                            ? 'Chưa chọn'
                            : '${selectedSeats.length} chỗ',
                        style: const TextStyle(
                          color: Colors.blue,
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
                        'Đã chọn: ${(selectedSeats.toList()..sort()).join(", ")}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ShipSeatMap(
                    seatMapType: seatMapType,
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
                  onPressed:
                      selectedSeats.isEmpty ||
                          (widget.ship['schedule'] == 'Hàng ngày' &&
                              selectedDate == null)
                      ? null
                      : () async {
                          if (FirebaseAuth.instance.currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng đăng nhập'),
                              ),
                            );
                            return;
                          }

                          try {
                            final docId = '${widget.ship['id']}_$seatMapType';
                            final docRef = FirebaseFirestore.instance
                                .collection('ship_seat_locks')
                                .doc(docId);

                            final success = await FirebaseFirestore.instance
                                .runTransaction((tx) async {
                                  final snap = await tx.get(docRef);
                                  List<String> currentBooked = [];
                                  if (snap.exists) {
                                    currentBooked =
                                        (snap.data()?['bookedSeats'] as List?)
                                            ?.map((e) => e.toString())
                                            .toList() ??
                                        [];
                                  }

                                  final conflict = selectedSeats.any(
                                    (s) => currentBooked.contains(s),
                                  );
                                  if (conflict) return false;

                                  final newBooked = [
                                    ...currentBooked,
                                    ...selectedSeats,
                                  ];
                                  tx.set(docRef, {
                                    'bookedSeats': newBooked,
                                    'lastUpdated': FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));

                                  return true;
                                });

                            if (!success) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Rất tiếc, ghế bạn chọn đã bị người khác đặt mất. Vui lòng chọn ghế khác!',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShipCheckoutPage(
                                    ship: widget.ship,
                                    seatMapType: seatMapType,
                                    selectedSeats: selectedSeats,
                                    selectedDate: selectedDate,
                                    selectedTime: selectedTime,
                                    total: total,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShipSeatMap extends StatelessWidget {
  final String seatMapType;
  final Set<String> selectedSeats;
  final Set<String> bookedSeats;
  final Function(String) onSeatToggled;

  const ShipSeatMap({
    super.key,
    required this.seatMapType,
    required this.selectedSeats,
    required this.bookedSeats,
    required this.onSeatToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (seatMapType == 'Tàu cao tốc (100 chỗ)') {
      return _buildShip(context, rows: 10, colsConfig: [3, 4, 3]);
    } else {
      return _buildShip(context, rows: 10, colsConfig: [5]);
    }
  }

  Widget _buildShip(
    BuildContext context, {
    required int rows,
    required List<int> colsConfig,
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
                // Mũi tàu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.directions_boat, color: Colors.blue, size: 40),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(rows, (rowIndex) {
                  final rowNumber = rowIndex + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _buildRowSeats(rowNumber, colsConfig),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRowSeats(int rowNumber, List<int> colsConfig) {
    List<Widget> rowChildren = [];
    int charCode = 65; // 'A'

    for (int groupIdx = 0; groupIdx < colsConfig.length; groupIdx++) {
      int colsInGroup = colsConfig[groupIdx];
      List<Widget> groupSeats = [];
      for (int i = 0; i < colsInGroup; i++) {
        final seatId = '${rowNumber}${String.fromCharCode(charCode)}';
        groupSeats.add(_buildSeat(seatId));
        charCode++;
      }
      rowChildren.add(
        Row(mainAxisSize: MainAxisSize.min, children: groupSeats),
      );

      if (groupIdx < colsConfig.length - 1) {
        rowChildren.add(const SizedBox(width: 24)); // Lối đi
      }
    }
    return rowChildren;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.white, Colors.grey.shade400, 'Trống'),
        const SizedBox(width: 16),
        _buildLegendItem(Colors.blue.shade100, Colors.blue, 'Đang chọn'),
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

  Widget _buildSeat(String seatId) {
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
      bgColor = Colors.blue.shade100;
      borderColor = Colors.blue.shade700;
      textColor = Colors.blue.shade900;
    }

    return GestureDetector(
      onTap: isBooked ? null : () => onSeatToggled(seatId),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          seatId,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class ShipCheckoutPage extends StatefulWidget {
  final Map<String, dynamic> ship;
  final String seatMapType;
  final Set<String> selectedSeats;
  final String? selectedDate;
  final String? selectedTime;
  final int total;

  const ShipCheckoutPage({
    super.key,
    required this.ship,
    required this.seatMapType,
    required this.selectedSeats,
    this.selectedDate,
    this.selectedTime,
    required this.total,
  });

  @override
  State<ShipCheckoutPage> createState() => _ShipCheckoutPageState();
}

class _ShipCheckoutPageState extends State<ShipCheckoutPage> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seatList = widget.selectedSeats.toList()..sort();
    final String dateVal = (widget.ship['schedule'] == 'Hàng ngày')
        ? (widget.selectedDate ?? 'Chưa chọn ngày')
        : (widget.ship['schedule'] ?? '');
    final String timeVal = widget.selectedTime ??
        (widget.ship['timeList'] as List?)?.firstOrNull?.toString() ??
        widget.ship['time']?.toString() ??
        '';

    return SharedCheckoutScaffold(
      title: 'Thanh toán vé tàu phà',
      ownerId: widget.ship['ownerId']?.toString() ?? '',
      basePrice: widget.total.toDouble(),
      itemNameSummary:
          '${widget.ship['from']} → ${widget.ship['to']} | $dateVal $timeVal (${widget.seatMapType}) - Ghế: ${seatList.join(', ')}',
      requireAddress: false,
      content: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.ship['from']} → ${widget.ship['to']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Ngày: $dateVal'),
              Text('Giờ: $timeVal'),
              Text('Loại ghế: ${widget.seatMapType}'),
              Text('Ghế: ${seatList.join(', ')}'),
              const SizedBox(height: 16),
              const Text(
                'Ghi chú cho hãng tàu (Tuỳ chọn)',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'VD: Cần hỗ trợ xe đẩy...',
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
          storeName: 'Vé Tàu/Phà ${widget.ship['operator']}',
          itemName:
              '${widget.ship['from']} → ${widget.ship['to']} - $dateVal, Giờ: $timeVal (${widget.seatMapType}) (Ghế: ${seatList.join(', ')})$completeExtraInfo',
          itemImage: (widget.ship['image'] as String? ?? '').isNotEmpty
              ? widget.ship['image'] as String
              : 'https://cdn-icons-png.flaticon.com/512/811/811566.png',
          price: widget.selectedSeats.isNotEmpty
              ? finalPrice / widget.selectedSeats.length
              : finalPrice,
          quantity: widget.selectedSeats.isEmpty ? 1 : widget.selectedSeats.length,
          status: 'pending',
          ownerId: widget.ship['ownerId']?.toString(),
          type: 'ship_ticket',
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
