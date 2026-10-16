import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/map/map_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tourn/data/api/location_service.dart';
import 'package:tourn/models/location_models.dart';
import 'shared/generic_search_page.dart';

class TimbenhviengannhatPage extends StatefulWidget {
  const TimbenhviengannhatPage({super.key});

  @override
  State<TimbenhviengannhatPage> createState() => _TimbenhviengannhatPageState();
}

class _TimbenhviengannhatPageState extends State<TimbenhviengannhatPage> {
  String _selectedFilter = 'Tất cả';

  final List<String> _filters = [
    'Tất cả',
    'Bệnh viện',
    'Phòng khám',
    'Nhà thuốc',
    'Nha khoa',
  ];

  List<Hospital> _hospitals = [];
  bool _loading = true;
  String? _errorMessage;
  String? _locationError;

  String _currentLocationString = 'Đang xác định...';
  Position? _currentPosition; // stored when location is successfully determined

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await LocationService().getCurrentPosition().timeout(
        const Duration(seconds: 5),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _currentLocationString =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        _locationError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLocationString = 'Không xác định';
        _locationError = 'Không thể xác định vị trí: $e';
      });
    }
  }

  Future<void> _loadHospitals({String query = '', String type = ''}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _hospitals = [];
    });
    try {
      _hospitals = await LocationService().fetchHospitals(
        query: query,
        type: type == 'Tất cả' ? '' : type,
      );
      _hospitals.sort((a, b) {
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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Đã có lỗi xảy ra khi tải danh sách: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // filtering is handled by GenericSearchPage

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // location isn't required for data to show; we don't await it
    _getCurrentLocation();
    await _loadHospitals();
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
            'Tìm bệnh viện gần nhất',
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
          'Tìm bệnh viện gần nhất',
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
                    builder: (_) => GenericSearchPage<Hospital>(
                      searchPrefsKey: 'hospital_search_history',
                      searchHint: 'Tìm kiếm bệnh viện, phòng khám...',
                      emptyMessage: 'Không tìm thấy kết quả',
                      suggestionsMessage: 'Đề xuất cho bạn',
                      brandOrange: Colors.blue,
                      brandGreen: Colors.green,
                      pageBg: const Color(0xFFF6F2FA),
                      allItems: _hospitals,
                      onSearchMatch: (items, query) {
                        if (query.isEmpty) return items;
                        final q = query.toLowerCase();
                        return items.where((h) {
                          return h.name.toLowerCase().contains(q) ||
                              h.address.toLowerCase().contains(q);
                        }).toList();
                      },
                      onCustomFilter: (items) {
                        var list = items;
                        if (_selectedFilter != 'Tất cả') {
                          list = list
                              .where((h) => h.type == _selectedFilter)
                              .toList();
                        }
                        final sortedList = List<Hospital>.from(list);
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
                      buildItemCard: (hospital) =>
                          _HospitalCard(hospital: hospital),
                      buildFilterSheet: (context, apply) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Loại cơ sở y tế',
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
                      'Tìm kiếm bệnh viện, phòng khám...',
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
              itemCount: _hospitals.length,
              itemBuilder: (context, index) {
                // Sort the main list dynamically based on current location
                final list = List<Hospital>.from(_hospitals);
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
                return _HospitalCard(hospital: list[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final Hospital hospital;

  const _HospitalCard({required this.hospital});

  IconData _getTypeIcon() {
    switch (hospital.type) {
      case 'Bệnh viện':
        return Icons.local_hospital;
      case 'Phòng khám':
        return Icons.medical_services;
      case 'Nhà thuốc':
        return Icons.medication;
      case 'Nha khoa':
        return Icons.medical_information;
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getTypeColor() {
    switch (hospital.type) {
      case 'Bệnh viện':
        return Colors.red;
      case 'Phòng khám':
        return Colors.blue;
      case 'Nhà thuốc':
        return Colors.green;
      case 'Nha khoa':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: hospital.phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
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
                    _openGoogleMaps();
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
    final destination = '${hospital.name}, ${hospital.address}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => mappage(initialDestination: destination),
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final query = Uri.encodeComponent('${hospital.name}, ${hospital.address}');
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = hospital.isOpen;

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
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getTypeIcon(), color: _getTypeColor(), size: 28),
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
                              hospital.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpen ? 'Đang mở' : 'Đã đóng',
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              hospital.type,
                              style: TextStyle(
                                color: _getTypeColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            hospital.rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, color: Colors.grey, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            hospital.openTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                              hospital.address,
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
                              '${hospital.distance} km',
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
              children: hospital.services.take(4).map((service) {
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

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Builder(
              builder: (context) => Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMapOptions(context),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Chỉ đường'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Gọi ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
