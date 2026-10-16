import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/map/map_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tourn/data/api/location_service.dart';
import 'package:tourn/models/location_models.dart';
import 'shared/generic_search_page.dart';

class TimkiematmgannhatPage extends StatefulWidget {
  const TimkiematmgannhatPage({super.key});

  @override
  State<TimkiematmgannhatPage> createState() => _TimkiematmgannhatPageState();
}

class _TimkiematmgannhatPageState extends State<TimkiematmgannhatPage> {
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = [
    'Tất cả',
    'Vietcombank',
    'BIDV',
    'Techcombank',
    'Agribank',
    'MB Bank',
    'VPBank',
  ];

  // ATM list loaded from API
  List<Atm> _atms = [];
  bool _loading = true;
  String? _errorMessage;
  String? _locationError;

  String _currentLocationString = 'Đang xác định...';
  Position? _currentPosition; // stored when location is successfully determined

  Future<void> _getCurrentLocation() async {
    try {
      // enforce our own timeout in case plugin doesn't respect timeLimit
      final pos = await LocationService().getCurrentPosition().timeout(
        const Duration(seconds: 5),
      );
      setState(() {
        _currentPosition = pos;
        _currentLocationString =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        _locationError = null;
      });
    } catch (e) {
      setState(() {
        _currentLocationString = 'Không xác định';
        _locationError = 'Không thể xác định vị trí: $e';
      });
    }
  }

  Future<void> _loadAtms({String query = '', String bank = ''}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _atms = [];
    });
    try {
      _atms = await LocationService().fetchAtms(
        query: query,
        bank: (bank == 'Tất cả') ? '' : bank,
      );
      // sort result by distance to make sure the nearest are at the top
      _atms.sort((a, b) {
        if (_currentPosition != null) {
          final da =
              Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                a.latitude,
                a.longitude,
              ) /
              1000;
          final db =
              Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                b.latitude,
                b.longitude,
              ) /
              1000;
          return da.compareTo(db);
        }
        return a.distance.compareTo(b.distance);
      });
    } catch (e) {
      // only treat as error if it isn’t a location failure
      final msg = e.toString();
      if (!msg.contains('TimeoutException') &&
          !msg.contains('permission') &&
          !msg.contains('current location')) {
        _errorMessage = msg;
      } else {
        // location failure; keep loading data anyway
        _locationError ??= msg;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // filtering is handled by GenericSearchPage

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // start loading and location separately; we only need to wait for data
    _getCurrentLocation(); // fire‑and‑forget
    await _loadAtms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tìm ATM gần nhất',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lỗi tải dữ liệu',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _init,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tìm ATM gần nhất',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenericSearchPage<Atm>(
                      searchPrefsKey: 'atm_search_history',
                      searchHint: 'Tìm kiếm ATM, ngân hàng...',
                      emptyMessage: 'Không tìm thấy kết quả',
                      suggestionsMessage: 'Đề xuất cho bạn',
                      brandOrange: Colors.blue,
                      brandGreen: Colors.green,
                      pageBg: const Color(0xFFF6F2FA),
                      allItems: _atms,
                      onSearchMatch: (items, query) {
                        if (query.isEmpty) return items;
                        final q = query.toLowerCase();
                        return items.where((a) {
                          return a.name.toLowerCase().contains(q) ||
                              a.address.toLowerCase().contains(q);
                        }).toList();
                      },
                      onCustomFilter: (items) {
                        var list = items;
                        if (_selectedFilter != 'Tất cả') {
                          list = list
                              .where((a) => a.bank == _selectedFilter)
                              .toList();
                        }
                        final sortedList = List<Atm>.from(list);
                        sortedList.sort((a, b) {
                          double da = a.distance;
                          double db = b.distance;
                          if (_currentPosition != null) {
                            da =
                                Geolocator.distanceBetween(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                  a.latitude,
                                  a.longitude,
                                ) /
                                1000;
                            db =
                                Geolocator.distanceBetween(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                  b.latitude,
                                  b.longitude,
                                ) /
                                1000;
                          }
                          return da.compareTo(db);
                        });
                        return sortedList;
                      },
                      getKeywordName: (t) => t.name,
                      buildItemCard: (atm) => _AtmCard(atm: atm),
                      buildFilterSheet: (context, apply) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ngân hàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: _filters.map((t) {
                                  return ChoiceChip(
                                    label: Text(t),
                                    selected: _selectedFilter == t,
                                    onSelected: (v) {
                                      _selectedFilter = t;
                                      apply();
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Tìm kiếm ATM, ngân hàng...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vị trí hiện tại: $_currentLocationString',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _getCurrentLocation,
                      child: const Text(
                        'Thay đổi',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _locationError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _atms.length,
              itemBuilder: (context, index) {
                // Sort the main list dynamically based on current location
                final list = List<Atm>.from(_atms);
                list.sort((a, b) {
                  double da = a.distance;
                  double db = b.distance;
                  if (_currentPosition != null) {
                    da =
                        Geolocator.distanceBetween(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                          a.latitude,
                          a.longitude,
                        ) /
                        1000;
                    db =
                        Geolocator.distanceBetween(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                          b.latitude,
                          b.longitude,
                        ) /
                        1000;
                  }
                  return da.compareTo(db);
                });
                return _AtmCard(atm: list[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmCard extends StatelessWidget {
  final Atm atm;

  const _AtmCard({required this.atm});

  Color _getBankColor() {
    switch (atm.bank) {
      case 'Vietcombank':
        return const Color(0xFF00843D);
      case 'BIDV':
        return const Color(0xFF005BAA);
      case 'Techcombank':
        return const Color(0xFFED1C24);
      case 'Agribank':
        return const Color(0xFF00529B);
      case 'MB Bank':
        return const Color(0xFF004A98);
      case 'VPBank':
        return const Color(0xFF00703C);
      default:
        return Colors.blue;
    }
  }

  void _showMapOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn ứng dụng bản đồ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.map, color: Colors.blue, size: 28),
                  ),
                  title: const Text(
                    'Bản đồ trong ứng dụng',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Sử dụng bản đồ tích hợp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _openInAppMap(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions,
                      color: Colors.green,
                      size: 28,
                    ),
                  ),
                  title: const Text(
                    'Google Maps',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Mở ứng dụng Google Maps'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    _openGoogleMaps(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openInAppMap(BuildContext context) {
    final destination = '${atm.name}, ${atm.address}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => mappage(initialDestination: destination),
      ),
    );
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    final query = Uri.encodeComponent('${atm.name}, ${atm.address}');
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở Google Maps trên thiết bị này.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool is24h = atm.is24h;
    final bool hasDeposit = atm.hasDeposit;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getBankColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.atm, color: _getBankColor(), size: 28),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              atm.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getBankColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              atm.bank,
                              style: TextStyle(
                                color: _getBankColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: is24h
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: is24h ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  is24h ? '24/7' : 'Giờ hành chính',
                                  style: TextStyle(
                                    color: is24h ? Colors.green : Colors.orange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasDeposit) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.savings,
                                    size: 12,
                                    color: Colors.purple,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Nạp tiền',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              atm.address,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${atm.distance} km',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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

          // Services
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: atm.services.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    service,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Builder(
              builder: (context) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMapOptions(context),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Chỉ đường'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getBankColor(),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
