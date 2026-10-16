import 'package:tourn/Ui/main/category/business/business_profile_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/donhangcuaban_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/image_carousel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/generic_search_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_tienich/widgets/shared/shared_checkout_scaffold.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'dart:async';

bool isServiceExpired(String dateStr, List<String> times) {
  if (dateStr.isEmpty) return false; // Show flights with no date

  try {
    int year, month, day;
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      year = int.parse(parts[2]);
      month = int.parse(parts[1]);
      day = int.parse(parts[0]);
    } else {
      // Try parsing standard formats like YYYY-MM-DD
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        year = dt.year;
        month = dt.month;
        day = dt.day;
      } else {
        // Unrecognized format, just show it to be safe
        return false;
      }
    }

    final now = DateTime.now();

    if (times.isEmpty) {
      final tripDate = DateTime(year, month, day, 23, 59);
      return now.isAfter(tripDate);
    }

    bool allTimesPassed = true;
    for (final time in times) {
      final timeParts = time.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0].trim());
        final minute = int.parse(
          timeParts[1].substring(0, 2).trim(),
        ); // In case there are extra chars
        final tripDateTime = DateTime(year, month, day, hour, minute);
        if (tripDateTime.isAfter(now)) {
          allTimesPassed = false;
          break;
        }
      } else {
        // Invalid time format, consider it expired
        return true;
      }
    }
    return allTimesPassed;
  } catch (e) {
    // If parsing fails (e.g. because time contains literal code like `${time.hour}`), hide it
    return true;
  }
}

class MaybayPage extends StatefulWidget {
  const MaybayPage({super.key});

  @override
  State<MaybayPage> createState() => _MaybayPageState();
}

class _MaybayPageState extends State<MaybayPage> {
  List<Map<String, dynamic>> flights = [];
  StreamSubscription<List<Map<String, dynamic>>>? _flightSub;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  void _loadFlights() {
    _flightSub = FirebaseBusinessService()
        .streamServices(collectionName: 'business_flight_ticket_services')
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
                          : 'TP. HCM');
                  final flightType = (extra['flightType'] ?? 'Nội địa')
                      .toString();
                  final timeData = extra['time'];
                  final timeStr = timeData is List
                      ? timeData.join(', ')
                      : (timeData ?? '08:30').toString();
                  final timeList = timeData is List
                      ? timeData.map((e) => e.toString()).toList()
                      : [timeStr];
                  final dateStr = (extra['date'] ?? '').toString();
                  final unitStr = (extra['unit'] ?? extra['duration'] ?? '2h')
                      .toString();
                  final opStr =
                      (extra['airline'] ??
                              extra['carrier'] ??
                              'Hãng hàng không')
                          .toString();

                  return {
                    'id': service['id']?.toString() ?? '',
                    'from': fromStr.isEmpty ? 'Hà Nội' : fromStr,
                    'to': toStr.isEmpty ? 'TP. HCM' : toStr,
                    'time': timeStr,
                    'timeList': timeList,
                    'duration': unitStr,
                    'price': (service['price'] as num?)?.toInt() ?? 0,
                    'carrier': opStr,
                    'ownerId': (service['ownerId'] ?? '').toString(),
                    'image': (extra['imageUrl'] ?? '').toString(),
                    'images': extra['images'] is List
                        ? (extra['images'] as List)
                              .map((e) => e.toString())
                              .toList()
                        : [],
                    'description': (service['description'] ?? '').toString(),
                    'ticketClass': (extra['ticketClass'] ?? '').toString(),
                    'airplaneName': (extra['airplaneName'] ?? '').toString(),
                    'flightType': flightType,
                    'date': dateStr,
                    'extra': extra,
                  };
                })
                .where(
                  (item) => !isServiceExpired(
                    item['date'] as String,
                    item['timeList'] as List<String>,
                  ),
                )
                .toList();
            if (mounted) {
              setState(() {
                flights = list;
              });
            }
          },
          onError: (error) {
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
    _flightSub?.cancel();
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
                      const DonHangCuaBanPage(serviceType: 'flight_ticket'),
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
                  searchPrefsKey: 'search_maybay',
                  searchHint: 'Tìm chuyến bay...',
                  brandOrange: Colors.blue,
                  pageBg: Colors.white,
                  allItems: flights,
                  onSearchMatch: (items, query) {
                    final q = query.toLowerCase();
                    return items.where((item) {
                      return item['from'].toString().toLowerCase().contains(
                            q,
                          ) ||
                          item['to'].toString().toLowerCase().contains(q) ||
                          item['carrier'].toString().toLowerCase().contains(
                            q,
                          ) ||
                          item['airplaneName']
                              .toString()
                              .toLowerCase()
                              .contains(q);
                    }).toList();
                  },
                  getKeywordName: (item) => '${item['from']} đi ${item['to']}',
                  buildItemCard: (item) {
                    final extra = item['extra'] as Map<String, dynamic>? ?? {};
                    final classes =
                        extra['ticketClasses'] as Map<String, dynamic>? ?? {};


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
                              builder: (_) => BookingPage(flight: item),
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
                                      Icons.airplanemode_active,
                                      color: Colors.indigo,
                                      size: 30,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.airplanemode_active,
                                      color: Colors.indigo,
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
                                      (item['date'] as String?)?.isNotEmpty ==
                                              true
                                          ? '${item['date']} • ${item['time']} • ${item['duration']}'
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
                                  // Ẩn giá vé hiển thị bên ngoài
                                  // const SizedBox(height: 6),
                                  if (FirebaseAuth.instance.currentUser?.uid !=
                                      (item['ownerId'] ?? '').toString())
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BookingPage(flight: item),
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
                      final originalCard = cardWidget;
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
                                child: originalCard,
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
                  'Tìm chuyến bay...',
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.flight,
                          size: 36,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Máy bay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tìm chuyến bay, so sánh giá và đặt vé nhanh chóng',
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

              if (flights.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hiện chưa có chuyến bay nào được cập nhật.',
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
                  itemCount: flights.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final f = flights[index];
                    final extra = f['extra'] as Map<String, dynamic>? ?? {};
                    final classes =
                        extra['ticketClasses'] as Map<String, dynamic>? ?? {};


                    Widget cardWidget = Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingPage(flight: f),
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
                                    imageUrl: f['image'].toString(),
                                    fit: BoxFit.cover,
                                    placeholder: const Icon(
                                      Icons.airplanemode_active,
                                      color: Colors.indigo,
                                      size: 30,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.airplanemode_active,
                                      color: Colors.indigo,
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
                                      '${f['from']} → ${f['to']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${f['time']} • Hãng: ${f['carrier']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    if ((f['airplaneName'] as String?)
                                            ?.isNotEmpty ==
                                        true)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Máy bay: ${f['airplaneName']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Ẩn giá vé hiển thị bên ngoài
                                  // const SizedBox(height: 6),
                                  if (FirebaseAuth.instance.currentUser?.uid !=
                                      (f['ownerId'] ?? '').toString())
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  BookingPage(flight: f),
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

                    final ownerId = (f['ownerId'] ?? '').toString();
                    if (ownerId.isNotEmpty) {
                      final originalCard = cardWidget;
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
                                child: originalCard,
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
                      Text(
                        '- Kiểm tra giờ làm thủ tục và hành lý trước khi ra sân bay.',
                      ),
                      Text('- So sánh giá nhiều hãng để tìm lựa chọn phù hợp.'),
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

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.flight});

  final Map<String, dynamic> flight;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late String seatMapType;
  Set<String> selectedSeats = {};
  Set<String> bookedSeats = {};
  StreamSubscription<DocumentSnapshot>? _seatSub;
  String? selectedTime;

  Map<String, int> get ticketClasses {
    final extra = widget.flight['extra'] as Map<String, dynamic>? ?? {};
    final classes = extra['ticketClasses'] as Map<String, dynamic>? ?? {};
    return classes.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Map<String, String> get seatClassesConfig {
    final extra = widget.flight['extra'] as Map<String, dynamic>? ?? {};
    final config = extra['seatClassesConfig'] as Map<String, dynamic>? ?? {};
    return config.map((k, v) => MapEntry(k, v.toString()));
  }

  Set<String> get availableClasses {
    final set = ticketClasses.keys.toSet();
    set.addAll(seatClassesConfig.values);
    return set;
  }

  int getPriceForSeat(String seatId) {
    if (ticketClasses.isEmpty) return widget.flight['price'] as int;
    final seatClass = getClassForSeat(seatId);
    return ticketClasses[seatClass] ?? (widget.flight['price'] as int);
  }

  String getClassForSeat(String seatId) {
    final config = seatClassesConfig;
    if (config.containsKey(seatId)) {
      return config[seatId]!;
    }
    if (availableClasses.isEmpty) return '';
    if (availableClasses.contains('Phổ thông')) return 'Phổ thông';
    return availableClasses.first;
  }

  @override
  void initState() {
    super.initState();
    final planeName =
        (widget.flight['airplaneName'] as String?)?.toLowerCase() ?? '';
    final rawType =
        (widget.flight['ticketClass'] as String?)?.toLowerCase() ?? '';

    if (planeName.contains('350') ||
        planeName.contains('340') ||
        planeName.contains('330') ||
        planeName.contains('380') ||
        planeName.contains('787') ||
        planeName.contains('777') ||
        planeName.contains('767') ||
        planeName.contains('747') ||
        planeName.contains('lớn') ||
        rawType.contains('lớn') ||
        rawType.contains('3x4x3')) {
      seatMapType = 'Máy bay lớn (3x4x3)';
    } else {
      seatMapType = 'Máy bay nhỏ (3x3)';
    }

    _listenToSeats();
  }

  void _listenToSeats() {
    _seatSub?.cancel();
    final docId = '${widget.flight['id']}_$seatMapType';
    _seatSub = FirebaseFirestore.instance
        .collection('flight_seat_locks')
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
    int total = 0;
    if (ticketClasses.isEmpty) {
      final price = widget.flight['price'] as int;
      total = price * selectedSeats.length;
    } else {
      for (final seat in selectedSeats) {
        total += getPriceForSeat(seat);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt vé máy bay')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if ((widget.flight['images'] as List? ?? []).isNotEmpty ||
                      (widget.flight['image'] as String).isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: () {
                        final images =
                            (widget.flight['images'] as List? ?? []).isNotEmpty
                            ? widget.flight['images'] as List
                            : [widget.flight['image']];
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
                    '${widget.flight['from']} → ${widget.flight['to']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((widget.flight['date'] as String?)?.isNotEmpty ==
                      true) ...[
                    Text('Ngày đi: ${widget.flight['date']}'),
                    const SizedBox(height: 4),
                  ],
                  if ((widget.flight['timeList'] as List?)?.isNotEmpty ==
                          true &&
                      (widget.flight['timeList'] as List).length > 1) ...[
                    const Text(
                      'Giờ khởi hành: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (widget.flight['timeList'] as List).map((t) {
                          final tStr = t.toString();
                          final isSelected =
                              (selectedTime ??
                                  (widget.flight['timeList'] as List).first
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
                    Text('Giờ khởi hành: ${widget.flight['time']}'),
                    const SizedBox(height: 4),
                  ],
                  Text('Hãng bay: ${widget.flight['carrier']}'),
                  if (widget.flight['ownerId'] != null &&
                      widget.flight['ownerId'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('user_profiles')
                          .doc(widget.flight['ownerId'])
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

                        String getValidString(
                          List<String?> values,
                          String defaultValue,
                        ) {
                          for (final v in values) {
                            if (v != null && v.trim().isNotEmpty) {
                              return v.trim();
                            }
                          }
                          return defaultValue;
                        }

                        final storeName = getValidString([
                          businessProfile['name'] as String?,
                          ownerProfile['name'] as String?,
                          data['fullName'] as String?,
                        ], 'Người đăng');

                        final media =
                            businessProfile['media'] as Map<String, dynamic>? ??
                            {};
                        final avatar = getValidString([
                          media['avatarPath'] as String?,
                          media['avatar'] as String?,
                          data['avatar'] as String?,
                          data['photoURL'] as String?,
                          data['photoUrl'] as String?,
                        ], '');

                        final address = getValidString([
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
                            (businessProfile['reviewsCount'] as num?)
                                ?.toInt() ??
                            0;
                        final rating = reviewsCount == 0
                            ? 0.0
                            : ((businessProfile['rating'] as num?)
                                      ?.toDouble() ??
                                  0.0);

                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusinessProfilePage(
                                  ownerId: widget.flight['ownerId'].toString(),
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
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating > 0
                                        ? '${rating.toStringAsFixed(1)} ($reviewsCount đánh giá)'
                                        : 'Chưa có đánh giá',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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
                            : '${selectedSeats.length} ghế',
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
                        'Ghế đã chọn: ${(selectedSeats.toList()..sort()).join(", ")}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  FlightSeatMap(
                    seatMapType: seatMapType,
                    selectedSeats: selectedSeats,
                    bookedSeats: bookedSeats,
                    availableClasses: availableClasses,
                    getClassForSeat: getClassForSeat,
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
                  color: Colors.grey.withValues(alpha: 0.2),
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
                  onPressed: selectedSeats.isEmpty
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
                              builder: (_) => FlightCheckoutPage(
                                flight: widget.flight,
                                seatMapType: seatMapType,
                                selectedSeats: selectedSeats,
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

class FlightSeatMap extends StatelessWidget {
  final String seatMapType;
  final Set<String> selectedSeats;
  final Set<String> bookedSeats;
  final Set<String> availableClasses;
  final String Function(String) getClassForSeat;
  final Function(String) onSeatToggled;

  const FlightSeatMap({
    super.key,
    required this.seatMapType,
    required this.selectedSeats,
    required this.bookedSeats,
    required this.availableClasses,
    required this.getClassForSeat,
    required this.onSeatToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (seatMapType == 'Máy bay lớn (3x4x3)') {
      return _buildAirplane(context, rows: 15, colsConfig: [3, 4, 3]);
    } else {
      return _buildAirplane(context, rows: 10, colsConfig: [3, 3]);
    }
  }

  Widget _buildAirplane(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.flight_takeoff, color: Colors.grey, size: 40),
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
        final seatId = '$rowNumber${String.fromCharCode(charCode)}';
        groupSeats.add(_buildSeat(seatId));
        charCode++;
      }
      rowChildren.add(
        Row(mainAxisSize: MainAxisSize.min, children: groupSeats),
      );

      // Add aisle if not last group
      if (groupIdx < colsConfig.length - 1) {
        rowChildren.add(const SizedBox(width: 24)); // Lối đi
      }
    }
    return rowChildren;
  }

  Widget _buildLegend() {
    List<Widget> legends = [];
    if (availableClasses.isEmpty) {
      legends = [
        _buildLegendItem(
          Colors.white,
          Colors.grey.shade400,
          'Trống',
          Colors.black87,
        ),
        _buildLegendItem(
          Colors.blue.shade50,
          Colors.blue,
          'Đang chọn',
          Colors.blue,
        ),
        _buildLegendItem(
          Colors.red.shade100,
          Colors.red,
          'Đã bán',
          Colors.red.shade900,
        ),
      ];
    } else {
      if (availableClasses.contains('Thương gia')) {
        legends.add(
          _buildLegendItem(
            Colors.orange.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.5),
            'Thương gia',
            Colors.orange,
          ),
        );
      }
      if (availableClasses.contains('Phổ thông cao cấp')) {
        legends.add(
          _buildLegendItem(
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.5),
            'PTCC',
            Colors.purple,
          ),
        );
      }
      if (availableClasses.contains('Phổ thông')) {
        legends.add(
          _buildLegendItem(
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.5),
            'Phổ thông',
            Colors.blue,
          ),
        );
      }
      legends.add(
        _buildLegendItem(Colors.green, Colors.green, 'Đang chọn', Colors.white),
      );
      legends.add(
        _buildLegendItem(
          Colors.red.shade100,
          Colors.red,
          'Đã bán',
          Colors.red.shade900,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: legends,
    );
  }

  Widget _buildLegendItem(
    Color bgColor,
    Color borderColor,
    String label,
    Color textColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
      bgColor = Colors.green;
      borderColor = Colors.green;
      textColor = Colors.white;
    } else {
      if (availableClasses.isNotEmpty) {
        final seatClass = getClassForSeat(seatId);
        Color classColor = Colors.blue;
        if (seatClass == 'Thương gia') {
          classColor = Colors.orange;
        } else if (seatClass == 'Phổ thông cao cấp') {
          classColor = Colors.purple;
        }

        bgColor = classColor.withValues(alpha: 0.1);
        borderColor = classColor.withValues(alpha: 0.5);
        textColor = classColor;
      }
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

class FlightCheckoutPage extends StatelessWidget {
  final Map<String, dynamic> flight;
  final String seatMapType;
  final Set<String> selectedSeats;
  final int total;

  const FlightCheckoutPage({
    super.key,
    required this.flight,
    required this.seatMapType,
    required this.selectedSeats,
    required this.total,
  });

  Future<void> _saveBooking(Map<String, dynamic> record) async {
    final seatInfo = record['seats'] as List<String>? ?? [];
    final seatStr = seatInfo.isNotEmpty ? ' (Ghế: ${seatInfo.join(", ")})' : '';
    final extraInfo = record['extraInfo'] as String? ?? '';

    await FirebaseMenuService().createOrder(
      storeName: 'Hãng Bay ${record['carrier']}',
      itemName:
          '${record['route']} - Giờ: ${record['time']} (${record['seatMapType']})$seatStr$extraInfo',
      itemImage: (flight['image'] as String).isNotEmpty
          ? flight['image'] as String
          : 'https://cdn-icons-png.flaticon.com/512/316/316091.png',
      price: record['total'] > 0 && record['passengers'] > 0
          ? (record['total'] as num).toDouble() / (record['passengers'] as num)
          : 0.0,
      quantity: record['passengers'] as int,
      status: 'pending',
      ownerId: flight['ownerId']?.toString(),
      type: 'flight_ticket',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedCheckoutScaffold(
      title: 'Xác nhận thanh toán',
      ownerId: flight['ownerId']?.toString() ?? '',
      basePrice: total.toDouble(),
      itemNameSummary: '(${selectedSeats.length} vé)',
      requireAddress: false,
      onSubmit: (finalPrice, extraInfo) async {
        final docId = '${flight['id']}_$seatMapType';
        final docRef = FirebaseFirestore.instance
            .collection('flight_seat_locks')
            .doc(docId);

        final success = await FirebaseFirestore.instance.runTransaction((
          tx,
        ) async {
          final snap = await tx.get(docRef);
          List<String> currentBooked = [];
          if (snap.exists) {
            currentBooked =
                (snap.data()?['bookedSeats'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
          }

          final conflict = selectedSeats.any((s) => currentBooked.contains(s));
          if (conflict) return false;

          final newBooked = [...currentBooked, ...selectedSeats];
          tx.set(docRef, {
            'bookedSeats': newBooked,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return true;
        });

        if (!success) {
          throw 'Rất tiếc, ghế bạn chọn đã bị người khác đặt mất. Vui lòng chọn ghế khác!';
        }

        if (!context.mounted) return;

        final record = {
          'type': 'Máy bay',
          'route': '${flight['from']} → ${flight['to']}',
          'time': flight['time'],
          'carrier': flight['carrier'],
          'seatMapType': seatMapType,
          'passengers': selectedSeats.length,
          'total': finalPrice,
          'seats': selectedSeats.toList(),
          'timestamp': DateTime.now().toIso8601String(),
          'extraInfo': extraInfo,
        };

        await _saveBooking(record);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt vé máy bay thành công (Chờ xác nhận)'),
            ),
          );
          Navigator.of(context).pop(); // pop FlightCheckoutPage
          Navigator.of(context).pop(); // pop FlightPassengerBookingPage
        }
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  child: flight['image'].toString().isNotEmpty
                      ? Image(
                          image:
                              getImageProvider(flight['image'].toString()) ??
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
                          child: const Icon(Icons.flight, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${flight['from']} → ${flight['to']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ghế đã chọn: ${(selectedSeats.toList()..sort()).join(", ")}',
                        style: const TextStyle(
                          color: Colors.blue,
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
        ],
      ),
    );
  }
}
