import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapPageController {
  Future<void> Function()? _recenter;

  Future<void> recenterToCurrentLocation() async {
    await _recenter?.call();
  }
}

class mappage extends StatefulWidget {
  final String? initialDestination;
  final MapPageController? controller;

  const mappage({super.key, this.initialDestination, this.controller});

  @override
  State<mappage> createState() => _mappageState();
}

enum MapType { normal, satellite, terrain }

enum TransportMode { driving, motorcycle, walking, cycling }

class _mappageState extends State<mappage> {
  final MapController _mapController = MapController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  LatLng _currentCenter = LatLng(21.0285, 105.8542);
  LatLng? _currentLocation;
  LatLng? _origin;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  MapType _currentMapType = MapType.normal;
  TransportMode _transportMode = TransportMode.driving;
  double? _distanceKm;
  double? _durationMinutes;
  List<Map<String, dynamic>> _alternativeRoutes =
      []; // Danh sách các tuyến đường
  int _selectedRouteIndex = 0; // Tuyến đường được chọn
  bool _isNavigating = false;

  // Separate subscriptions so we can keep updating location when not navigating.
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Position>? _navigationSubscription;
  bool _showAirQuality = false;
  bool _showFloodLayer = false;
  bool _showTrafficLayer = false;
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destinationSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestinationSuggestions = false;
  bool _isPickingOrigin = false;
  bool _isPickingDestination = false;
  Timer? _debounceTimer;
  List<Map<String, String>> _searchHistory = [];
  double _mapRotation = 0.0; // Góc xoay bản đồ
  DateTime? _lastRerouteTime; // Thời gian chờ tính lại đường
  bool _isRerouting = false; // Đang tính lại đường
  double _currentZoom = 15.0; // Mức zoom hiện tại
  bool _isUserInteracting = false; // Người dùng đang tương tác với map

  // Tính điểm giao thông cho một tuyến đường (điểm thấp = tốt hơn)
  double _calculateTrafficScore(Map<String, dynamic> route) {
    final segments = route['trafficSegments'] as List<Map<String, dynamic>>?;
    if (segments == null || segments.isEmpty) {
      return 0; // Không có dữ liệu traffic -> điểm trung bình
    }

    double totalScore = 0;
    for (var segment in segments) {
      final congestion = segment['congestion'] as String;
      // Điểm phạt theo mức độ tắc nghẽn
      switch (congestion) {
        case 'low':
          totalScore += 0; // Thông thoáng - không phạt
          break;
        case 'moderate':
          totalScore += 1; // Vừa phải
          break;
        case 'heavy':
          totalScore += 3; // Đông đúc
          break;
        case 'severe':
          totalScore += 5; // Tắc nghẽn nặng
          break;
      }
    }

    // Tính điểm trung bình trên số đoạn
    return totalScore / segments.length;
  }

  // Tìm tuyến đường tốt nhất dựa trên mật độ giao thông
  int _findBestRoute() {
    if (_alternativeRoutes.isEmpty) return 0;

    int bestIndex = 0;
    double bestScore = double.infinity;

    for (int i = 0; i < _alternativeRoutes.length; i++) {
      final route = _alternativeRoutes[i];
      final trafficScore = _calculateTrafficScore(route);
      final distance = route['distance'] as double;
      final duration = route['duration'] as double;

      // Công thức tính điểm tổng hợp:
      // - trafficScore: điểm tắc nghẽn (càng thấp càng tốt)
      // - duration: thời gian (phút)
      // - distance: khoảng cách (km)
      // Trọng số: traffic (40%), duration (40%), distance (20%)
      final totalScore =
          (trafficScore * 4) + (duration * 0.4) + (distance * 0.2);

      if (totalScore < bestScore) {
        bestScore = totalScore;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  // Gợi ý đường tốt hơn nếu có
  void _suggestBetterRoute() {
    if (!mounted || _alternativeRoutes.length < 2) return;

    // Tìm route tốt nhất
    int bestIndex = 0;
    double bestScore = double.infinity;

    for (int i = 0; i < _alternativeRoutes.length; i++) {
      final route = _alternativeRoutes[i];
      final trafficScore = _calculateTrafficScore(route);
      final duration = route['duration'] as double;
      final distance = route['distance'] as double;
      final totalScore =
          (trafficScore * 4) + (duration * 0.4) + (distance * 0.2);

      if (totalScore < bestScore) {
        bestScore = totalScore;
        bestIndex = i;
      }
    }

    // Chỉ gợi ý nếu có route tốt hơn route đang chọn
    if (bestIndex != _selectedRouteIndex) {
      final currentRoute = _alternativeRoutes[_selectedRouteIndex];
      final betterRoute = _alternativeRoutes[bestIndex];

      final currentTrafficScore = _calculateTrafficScore(currentRoute);
      final betterTrafficScore = _calculateTrafficScore(betterRoute);
      final currentDuration = currentRoute['duration'] as double;
      final betterDuration = betterRoute['duration'] as double;
      final timeSaved = currentDuration - betterDuration;

      // Mô tả mật độ giao thông
      String getTrafficDescription(double score) {
        if (score < 0.5) return 'Rất thông thoáng';
        if (score < 1) return 'Thông thoáng';
        if (score < 2) return 'Bình thường';
        if (score < 3) return 'Đông đúc';
        return 'Tắc nghẽn';
      }

      Color getTrafficColor(double score) {
        if (score < 1) return Colors.green;
        if (score < 2) return Colors.yellow.shade700;
        if (score < 3) return Colors.orange;
        return Colors.red;
      }

      final currentTrafficDesc = getTrafficDescription(currentTrafficScore);
      final betterTrafficDesc = getTrafficDescription(betterTrafficScore);
      final currentTrafficColor = getTrafficColor(currentTrafficScore);
      final betterTrafficColor = getTrafficColor(betterTrafficScore);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text('Gợi ý đường đi'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phát hiện tuyến đường tốt hơn!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Mật độ giao thông:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, color: currentTrafficColor, size: 12),
                  SizedBox(width: 6),
                  Text('Hiện tại: '),
                  Text(
                    currentTrafficDesc,
                    style: TextStyle(
                      color: currentTrafficColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.circle, color: betterTrafficColor, size: 12),
                  SizedBox(width: 6),
                  Text('Gợi ý: '),
                  Text(
                    betterTrafficDesc,
                    style: TextStyle(
                      color: betterTrafficColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Thời gian:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Hiện tại: ${currentDuration.toInt()} phút'),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.blue),
                  SizedBox(width: 6),
                  Text('Gợi ý: ${betterDuration.toInt()} phút'),
                  if (timeSaved > 0)
                    Text(
                      ' (-${timeSaved.toInt()} phút)',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Giữ nguyên'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedRouteIndex = bestIndex;
                  _routePoints =
                      _alternativeRoutes[bestIndex]['points'] as List<LatLng>;
                  _distanceKm =
                      _alternativeRoutes[bestIndex]['distance'] as double;
                  _durationMinutes =
                      _alternativeRoutes[bestIndex]['duration'] as double;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text('Đổi đường', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._recenter = _recenterToCurrentLocation;
    _loadSearchHistory();
    // kick off location fetching right away
    _initLocation();

    // nếu có destination ban đầu thì tìm kiếm
    if (widget.initialDestination != null &&
        widget.initialDestination!.isNotEmpty) {
      _searchInitialDestination(widget.initialDestination!);
    }

    // start stream to keep _currentLocation up to date even when not navigating
    _startLocationStream();

    // Add listeners to cancel picking mode when focusing text fields
    _originFocusNode.addListener(() {
      if (_originFocusNode.hasFocus) {
        setState(() {
          _isPickingOrigin = false;
          _isPickingDestination = false;
        });
      }
    });

    _destinationFocusNode.addListener(() {
      if (_destinationFocusNode.hasFocus) {
        setState(() {
          _isPickingOrigin = false;
          _isPickingDestination = false;
        });
      }
    });
  }

  Future<void> _recenterToCurrentLocation() async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
    }
    if (!mounted || _currentLocation == null) return;

    setState(() {
      _isUserInteracting = false;
    });
    if (_isNavigating) {
      _mapController.moveAndRotate(
        _currentLocation!,
        _currentZoom,
        -_mapRotation,
      );
    } else {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  Future<void> _searchInitialDestination(String query) async {
    try {
      String urlString =
          'https://nominatim.openstreetmap.org/search?'
          'q=$query&'
          'format=json&'
          'limit=1&'
          'addressdetails=1&'
          'countrycodes=vn&'
          'accept-language=vi';

      final url = Uri.parse(urlString);
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TournApp/1.0',
          'Accept-Language': 'vi,en;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (results.isNotEmpty && mounted) {
          final result = results[0];
          final suggestion = {
            'display_name': result['display_name'] as String,
            'lat': result['lat'] as String,
            'lon': result['lon'] as String,
          };
          _selectDestinationSuggestion(suggestion);
        }
      }
    } catch (e) {
      print('Lỗi tìm kiếm địa điểm: $e');
    }
  }

  /// Try to acquire the current device location once and update state.
  Future<void> _getCurrentLocation() async {
    try {
      // ensure service and permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _currentLocation = _currentCenter;
        if (_origin == null) {
          _origin = _currentCenter;
          _originController.text = 'Vị trí hiện tại';
        }
      });

      if (_isNavigating) {
        _mapController.moveAndRotate(_currentCenter, 18.0, -_mapRotation);
      } else {
        _mapController.move(_currentCenter, 15.0);
      }
    } catch (e) {
      // ignore errors
    }
  }

  /// Called during initState to make an initial location request
  /// and update the UI even before the user interacts with the map.
  Future<void> _initLocation() async {
    await _getCurrentLocation();
  }

  /// Keeps listening to position changes and updates [_currentLocation]
  /// when not navigating. This helps the map reflect the real location
  /// immediately as soon as the device moves.
  Future<void> _startLocationStream() async {
    try {
      // Check permission before starting stream
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Don't start stream if permission denied
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      // cancel any existing stream
      _locationSubscription?.cancel();
      _locationSubscription =
          Geolocator.getPositionStream(locationSettings: settings).listen(
            (pos) {
              if (!mounted) return;
              final newLoc = LatLng(pos.latitude, pos.longitude);
              setState(() {
                _currentLocation = newLoc;
                _currentCenter = newLoc;
              });
              if (!_isNavigating) {
                _mapController.move(_currentCenter, _currentZoom);
              }
            },
            onError: (error) {
              // Ignore location errors (permission denied, service disabled, etc.)
              debugPrint('Location stream error: $error');
            },
          );
    } catch (e) {
      // Ignore any errors during stream setup
      debugPrint('Failed to start location stream: $e');
    }
  }

  Future<void> _fetchOriginSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _originSuggestions = [];
        _showOriginSuggestions = false;
      });
      return;
    }

    try {
      String urlString =
          'https://nominatim.openstreetmap.org/search?'
          'q=$query&'
          'format=json&'
          'limit=10&'
          'addressdetails=1&'
          'countrycodes=vn&'
          'accept-language=vi';

      if (_currentLocation != null) {
        urlString +=
            '&lat=${_currentLocation!.latitude}&lon=${_currentLocation!.longitude}';
      }

      final url = Uri.parse(urlString);
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TournApp/1.0',
          'Accept-Language': 'vi,en;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (mounted) {
          setState(() {
            _originSuggestions = results.map((result) {
              return {
                'display_name': result['display_name'] as String,
                'lat': result['lat'] as String,
                'lon': result['lon'] as String,
              };
            }).toList();
            _showOriginSuggestions = _originSuggestions.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('Lỗi lấy gợi ý điểm đi: $e');
    }
  }

  Future<void> _fetchDestinationSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _destinationSuggestions = [];
        _showDestinationSuggestions = false;
      });
      return;
    }

    try {
      String urlString =
          'https://nominatim.openstreetmap.org/search?'
          'q=$query&'
          'format=json&'
          'limit=10&'
          'addressdetails=1&'
          'countrycodes=vn&'
          'accept-language=vi';

      if (_currentLocation != null) {
        urlString +=
            '&lat=${_currentLocation!.latitude}&lon=${_currentLocation!.longitude}';
      }

      final url = Uri.parse(urlString);
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TournApp/1.0',
          'Accept-Language': 'vi,en;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        if (mounted) {
          setState(() {
            _destinationSuggestions = results.map((result) {
              return {
                'display_name': result['display_name'] as String,
                'lat': result['lat'] as String,
                'lon': result['lon'] as String,
              };
            }).toList();
            _showDestinationSuggestions = _destinationSuggestions.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('Lỗi lấy gợi ý điểm đến: $e');
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    setState(() {
      _searchHistory = history
          .map((item) {
            try {
              final decoded = json.decode(item) as Map<String, dynamic>;
              return {
                'name': decoded['name']?.toString() ?? '',
                'lat': decoded['lat']?.toString() ?? '',
                'lon': decoded['lon']?.toString() ?? '',
              };
            } catch (e) {
              return null;
            }
          })
          .where((item) => item != null)
          .cast<Map<String, String>>()
          .toList();
    });
  }

  Future<void> _saveToHistory(String name, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final newItem = {
      'name': name,
      'lat': lat.toString(),
      'lon': lon.toString(),
    };

    // Remove if already exists to avoid duplicates
    _searchHistory.removeWhere(
      (item) =>
          item['name'] == name ||
          (item['lat'] == lat.toString() && item['lon'] == lon.toString()),
    );

    // Add to beginning
    _searchHistory.insert(0, newItem);

    // Keep only last 10 items
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }

    // Save to SharedPreferences
    final historyStrings = _searchHistory
        .map((item) => json.encode(item))
        .toList();
    await prefs.setStringList('search_history', historyStrings);

    setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory.clear();
    });
  }

  void _selectOriginSuggestion(Map<String, dynamic> suggestion) {
    final lat = double.parse(suggestion['lat']);
    final lon = double.parse(suggestion['lon']);
    final origin = LatLng(lat, lon);
    final name = suggestion['display_name'];

    setState(() {
      _origin = origin;
      _originController.text = name;
      _showOriginSuggestions = false;
      _showDestinationSuggestions = false;
    });

    _originFocusNode.unfocus();
    _saveToHistory(name, lat, lon);

    if (_destination != null) {
      _getRoute(origin, _destination!);
    }
  }

  void _selectDestinationSuggestion(Map<String, dynamic> suggestion) {
    final lat = double.parse(suggestion['lat']);
    final lon = double.parse(suggestion['lon']);
    final destination = LatLng(lat, lon);
    final name = suggestion['display_name'];

    setState(() {
      _destination = destination;
      _destinationController.text = name;
      _showDestinationSuggestions = false;
      _showOriginSuggestions = false;

      // Tự động set origin là vị trí hiện tại nếu chưa có
      if (_origin == null && _currentLocation != null) {
        _origin = _currentLocation;
        _originController.text = 'Vị trí hiện tại';
      }
    });

    _destinationFocusNode.unfocus();
    _saveToHistory(name, lat, lon);

    _moveToLocation(destination);
    final startPoint = _origin ?? _currentLocation;
    if (startPoint != null) {
      _getRoute(startPoint, destination);
    }
  }

  void _swapOriginDestination() async {
    // Lưu lại giá trị trước khi swap
    final tempLocation = _origin;
    final tempText = _originController.text;

    // Nếu origin đang là vị trí hiện tại (chưa được set cụ thể), dùng _currentLocation
    final originToSwap = tempLocation ?? _currentLocation;
    final originTextToSwap =
        (tempLocation == null || tempText == 'Vị trí hiện tại')
        ? 'Vị trí hiện tại'
        : tempText;

    // Lưu destination cũ trước khi thay đổi
    final newOrigin = _destination;
    final newOriginText = _destinationController.text;

    // Nếu điểm mới là "Vị trí hiện tại" thì luôn lấy tọa độ GPS hiện tại
    LatLng? newDestination;
    String newDestinationText;
    if (originTextToSwap == 'Vị trí hiện tại') {
      newDestination = _currentLocation;
      newDestinationText = 'Vị trí hiện tại';
    } else {
      newDestination = originToSwap;
      newDestinationText = originTextToSwap;
    }

    setState(() {
      // Swap locations - origin mới là destination cũ
      _origin = newOrigin;
      // Destination mới là origin cũ (hoặc vị trí hiện tại nếu origin null)
      _destination = newDestination;

      // Swap text fields
      _originController.text = newOriginText;
      _destinationController.text = newDestinationText;

      // Clear route để tính lại
      _routePoints = [];
      _distanceKm = null;
      _durationMinutes = null;

      // Clear suggestions
      _showOriginSuggestions = false;
      _showDestinationSuggestions = false;
    });

    // Nếu hai điểm trùng nhau thì reset destination về null, xóa route
    if (_origin != null &&
        _destination != null &&
        _origin!.latitude == _destination!.latitude &&
        _origin!.longitude == _destination!.longitude) {
      setState(() {
        _destination = null;
        _destinationController.text = '';
        _routePoints = [];
        _distanceKm = null;
        _durationMinutes = null;
      });
      return;
    }

    // Di chuyển map đến vị trí origin mới sau khi swap
    if (_origin != null) {
      _moveToLocation(_origin!);
    }

    // Recalculate route if both points exist
    if (_origin != null && _destination != null) {
      await _getRoute(_origin!, _destination!);
    }
  }

  Future<void> _setAsDestination(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&'
        'lat=${point.latitude}&'
        'lon=${point.longitude}&'
        'zoom=18&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'TournApp/1.0'},
      );

      String locationText;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        final name = data['name'] as String?;
        locationText =
            name ??
            displayName ??
            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      } else {
        locationText =
            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      }

      setState(() {
        _destination = point;
        _destinationController.text = locationText;

        // Tự động set origin là vị trí hiện tại nếu chưa có
        if (_origin == null && _currentLocation != null) {
          _origin = _currentLocation;
          _originController.text = 'Vị trí hiện tại';
        }
      });

      _moveToLocation(point);
      final startPoint = _origin ?? _currentLocation;
      if (startPoint != null) {
        _getRoute(startPoint, point);
      }
    } catch (e) {
      print('Lỗi lấy thông tin địa điểm: $e');
      setState(() {
        _destination = point;
        _destinationController.text =
            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      });
      _moveToLocation(point);
      final startPoint = _origin ?? _currentLocation;
      if (startPoint != null) {
        _getRoute(startPoint, point);
      }
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    try {
      // Chuyển đổi transport mode sang OSRM profile
      // Note: OSRM public API chỉ hỗ trợ 3 profiles: driving, foot, bike
      // Xe máy tạm dùng profile 'driving' (tương tự ô tô)
      String profile;
      double speedMultiplier = 1.0; // Điều chỉnh thời gian dự kiến

      switch (_transportMode) {
        case TransportMode.driving:
          profile = 'driving';
          speedMultiplier = 1.15; // Thêm 15% cho đèn đỏ, tắc đường
          break;
        case TransportMode.motorcycle:
          profile = 'driving'; // Xe máy dùng chung profile với ô tô
          speedMultiplier = 0.95; // Xe máy linh hoạt hơn trong thành phố
          break;
        case TransportMode.walking:
          profile = 'foot';
          speedMultiplier = 1.1; // Thêm 10% cho nghỉ ngơi, vượt vật
          break;
        case TransportMode.cycling:
          profile = 'bike';
          speedMultiplier = 1.08; // Thêm 8% cho đèn đỏ, địa hình
          break;
      }

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&alternatives=true&steps=true&annotations=true',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          // Process all alternative routes
          final routes = data['routes'] as List;
          List<Map<String, dynamic>> processedRoutes = [];

          for (int i = 0; i < routes.length; i++) {
            final route = routes[i];
            final coordinates = route['geometry']['coordinates'] as List;
            final distance = route['distance'] as num;
            final duration = route['duration'] as num;

            // Process traffic annotations if available
            List<Map<String, dynamic>> segments = [];
            if (route['legs'] != null) {
              for (var leg in route['legs']) {
                if (leg['annotation'] != null) {
                  final speeds = leg['annotation']['speed'] as List?;

                  if (speeds != null) {
                    for (
                      int j = 0;
                      j < speeds.length && j < coordinates.length - 1;
                      j++
                    ) {
                      final speed = (speeds[j] as num).toDouble();
                      // Tính mức độ tắc nghẽn dựa trên tốc độ (m/s -> km/h)
                      final speedKmh = speed * 3.6;
                      String congestion;
                      if (speedKmh >= 50) {
                        congestion = 'low'; // Thông thoáng
                      } else if (speedKmh >= 25) {
                        congestion = 'moderate'; // Vừa phải
                      } else if (speedKmh >= 10) {
                        congestion = 'heavy'; // Đông đúc
                      } else {
                        congestion = 'severe'; // Tắc nghẽn
                      }

                      segments.add({
                        'start': LatLng(
                          coordinates[j][1] as double,
                          coordinates[j][0] as double,
                        ),
                        'end': LatLng(
                          coordinates[j + 1][1] as double,
                          coordinates[j + 1][0] as double,
                        ),
                        'speed': speedKmh,
                        'congestion': congestion,
                      });
                    }
                  }
                }
              }
            }

            processedRoutes.add({
              'points': coordinates
                  .map(
                    (coord) => LatLng(coord[1] as double, coord[0] as double),
                  )
                  .toList(),
              'distance': distance / 1000,
              'duration': (duration / 60) * speedMultiplier,
              'index': i,
              'trafficSegments': segments,
            });
          }

          // Sort routes: ưu tiên đường ít tắc nghẽn, sau đó ngắn nhất
          processedRoutes.sort((a, b) {
            // Tính điểm traffic cho mỗi route
            final aTraffic = _calculateTrafficScore(a);
            final bTraffic = _calculateTrafficScore(b);

            // Nếu một đường tắc nghẽn nặng (score >= 3), ưu tiên đường kia
            if (aTraffic >= 3 && bTraffic < 3) return 1;
            if (bTraffic >= 3 && aTraffic < 3) return -1;

            // Nếu traffic tương đương, so sánh khoảng cách
            final distanceCompare = (a['distance'] as double).compareTo(
              b['distance'] as double,
            );
            if (distanceCompare != 0) return distanceCompare;
            return (a['duration'] as double).compareTo(b['duration'] as double);
          });

          // Tìm route tốt nhất theo thuật toán thông minh
          final bestRouteIndex = _findBestRoute();

          if (mounted) {
            setState(() {
              _alternativeRoutes = processedRoutes;
              _selectedRouteIndex = bestRouteIndex; // Chọn tuyến tối ưu
              _routePoints =
                  processedRoutes[bestRouteIndex]['points'] as List<LatLng>;
              _distanceKm =
                  processedRoutes[bestRouteIndex]['distance'] as double;
              _durationMinutes =
                  processedRoutes[bestRouteIndex]['duration'] as double;
            });

            print('=== ROUTE UPDATED ===');
            print('Transport Mode: $_transportMode');
            print('Profile: $profile');
            print('Distance: $_distanceKm km');
            print('Duration: $_durationMinutes minutes');
            print('Routes found: ${processedRoutes.length}');
            print('Best route index: $bestRouteIndex');
            print('====================');
          }

          if (mounted && _alternativeRoutes.length > 1) {
            // Gợi ý đường tốt hơn nếu có
            _suggestBetterRoute();
          }
        }
      }
    } catch (e) {
      print('Lỗi tìm đường: $e');
    }
  }

  void _clearRoute() {
    setState(() {
      _origin = null;
      _destination = null;
      _routePoints.clear();
      _distanceKm = null;
      _durationMinutes = null;
      _alternativeRoutes.clear();
      _selectedRouteIndex = 0;
      _showOriginSuggestions = false;
      _showDestinationSuggestions = false;
    });
    _originController.clear();
    _destinationController.clear();
  }

  void _selectRoute(int index) {
    if (index >= 0 && index < _alternativeRoutes.length) {
      setState(() {
        _selectedRouteIndex = index;
        _routePoints = _alternativeRoutes[index]['points'] as List<LatLng>;
        _distanceKm = _alternativeRoutes[index]['distance'] as double;
        _durationMinutes = _alternativeRoutes[index]['duration'] as double;
      });
    }
  }

  void _moveToLocation(LatLng location) {
    setState(() {
      _currentCenter = location;
    });
    _mapController.move(location, 15.0);
  }

  String _getMapTileUrl() {
    switch (_currentMapType) {
      case MapType.normal:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapType.terrain:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  void _changeMapType(MapType type) {
    setState(() {
      _currentMapType = type;
    });
  }

  // Get icon for current transport mode
  IconData _getTransportIcon() {
    switch (_transportMode) {
      case TransportMode.driving:
        return Icons.directions_car;
      case TransportMode.motorcycle:
        return Icons.two_wheeler;
      case TransportMode.walking:
        return Icons.directions_walk;
      case TransportMode.cycling:
        return Icons.directions_bike;
    }
  }

  // Tính góc hướng giữa hai điểm GPS
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (3.141592653589793 / 180);
    final startLng = start.longitude * (3.141592653589793 / 180);
    final endLat = end.latitude * (3.141592653589793 / 180);
    final endLng = end.longitude * (3.141592653589793 / 180);

    final dLng = endLng - startLng;

    final y = sin(dLng) * cos(endLat);
    final x =
        cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    final bearing = atan2(y, x);

    // Convert from radians to degrees
    return (bearing * (180 / 3.141592653589793) + 360) % 360;
  }

  // Cập nhật tiến trình điều hướng
  Timer? _navigationUpdateTimer;
  DateTime? _lastNavigationUpdate;

  // Tính khoảng cách từ điểm đến tuyến đường
  double _distanceToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;

    double minDistance = double.infinity;

    for (int i = 0; i < route.length - 1; i++) {
      final p1 = route[i];
      final p2 = route[i + 1];

      // Tính khoảng cách từ điểm đến đoạn đường
      final d = _pointToSegmentDistance(point, p1, p2);
      if (d < minDistance) {
        minDistance = d;
      }
    }

    return minDistance;
  }

  // Tính khoảng cách từ điểm đến đoạn đường (mét)
  double _pointToSegmentDistance(LatLng point, LatLng p1, LatLng p2) {
    const Distance distanceCalc = Distance();
    final lat1 = p1.latitude;
    final lon1 = p1.longitude;
    final lat2 = p2.latitude;
    final lon2 = p2.longitude;
    final lat = point.latitude;
    final lon = point.longitude;

    // Nếu đoạn đường là 1 điểm
    final dx = lat2 - lat1;
    final dy = lon2 - lon1;

    if (dx == 0 && dy == 0) {
      return distanceCalc.as(LengthUnit.Meter, point, p1);
    }

    // Tính tham số chiếu
    double t = ((lat - lat1) * dx + (lon - lon1) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    // Tìm điểm gần nhất trên đoạn
    final nearestLat = lat1 + t * dx;
    final nearestLon = lon1 + t * dy;
    final nearestPoint = LatLng(nearestLat, nearestLon);

    return distanceCalc.as(LengthUnit.Meter, point, nearestPoint);
  }

  // Tự động tính lại đường khi người dùng đi chệch
  Future<void> _checkAndReroute(LatLng currentLocation) async {
    if (!_isNavigating || _destination == null || _routePoints.isEmpty) return;
    if (_isRerouting) return;

    // Chờ 15 giây giữa các lần tính lại
    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!).inSeconds < 15) {
      return;
    }

    // Calculate distance from current location to route
    final distanceToRoute = _distanceToRoute(currentLocation, _routePoints);

    // If user is more than 50 meters away from route, reroute
    if (distanceToRoute > 50) {
      print('=== OFF ROUTE DETECTED ===');
      print('Distance to route: ${distanceToRoute.toStringAsFixed(0)} meters');
      print('Recalculating route...');

      _isRerouting = true;
      _lastRerouteTime = now;

      // Recalculate route from current location
      await _getRoute(currentLocation, _destination!);

      _isRerouting = false;
    }
  }

  void _updateNavigationProgress(LatLng currentLocation) async {
    if (_destination == null || !_isNavigating) return;

    // Check if user is off-route and needs rerouting
    _checkAndReroute(currentLocation);

    // Throttle updates - only update every 10 seconds to avoid too many API calls
    final now = DateTime.now();
    if (_lastNavigationUpdate != null &&
        now.difference(_lastNavigationUpdate!).inSeconds < 10) {
      return;
    }
    _lastNavigationUpdate = now;

    // Recalculate route from current location to destination
    try {
      String profile;
      double speedMultiplier = 1.0;

      switch (_transportMode) {
        case TransportMode.driving:
          profile = 'driving';
          speedMultiplier = 1.15;
          break;
        case TransportMode.motorcycle:
          profile = 'driving';
          speedMultiplier = 0.95;
          break;
        case TransportMode.walking:
          profile = 'foot';
          speedMultiplier = 1.1;
          break;
        case TransportMode.cycling:
          profile = 'bike';
          speedMultiplier = 1.08;
          break;
      }

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/$profile/${currentLocation.longitude},${currentLocation.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final distance = route['distance'] as num;
          final duration = route['duration'] as num;

          if (mounted) {
            setState(() {
              _routePoints = coordinates
                  .map(
                    (coord) => LatLng(coord[1] as double, coord[0] as double),
                  )
                  .toList();
              _distanceKm = distance / 1000;
              _durationMinutes = (duration / 60) * speedMultiplier;
            });

            print('=== NAVIGATION UPDATE ===');
            print('Remaining distance: ${_distanceKm!.toStringAsFixed(2)} km');
            print(
              'Remaining time: ${_durationMinutes!.toStringAsFixed(0)} min',
            );
            print('========================');
          }
        }
      }
    } catch (e) {
      print('Lỗi cập nhật tiến trình: $e');
    }
  }

  void _startNavigation() async {
    if (_origin == null || _destination == null) {
      return;
    }

    // Tính route từ origin đang chọn đến destination
    await _getRoute(_origin!, _destination!);

    // Calculate initial bearing from origin to destination
    final initialBearing = _calculateBearing(_origin!, _destination!);

    setState(() {
      _isNavigating = true;
      _isPickingOrigin = false;
      _isPickingDestination = false;
      _mapRotation = initialBearing;
      _currentZoom = 18.0; // Reset zoom khi bắt đầu
      _isUserInteracting = false;
    });

    // Di chuyển camera về origin và xoay theo hướng đi
    _mapController.moveAndRotate(_origin!, _currentZoom, -initialBearing);

    // Chỉ lắng nghe GPS nếu origin là vị trí hiện tại
    bool isOriginCurrent = false;
    if (_origin != null && _currentLocation != null) {
      isOriginCurrent =
          _origin!.latitude == _currentLocation!.latitude &&
          _origin!.longitude == _currentLocation!.longitude;
    }

    if (isOriginCurrent) {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // More sensitive to movement
      );

      _navigationSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              if (mounted && _isNavigating && _destination != null) {
                final newLocation = LatLng(
                  position.latitude,
                  position.longitude,
                );

                // Calculate remaining distance and update route
                _updateNavigationProgress(newLocation);

                // Calculate bearing from current position TO destination
                double bearing = _calculateBearing(newLocation, _destination!);

                // Use device heading if moving fast enough (more accurate)
                if (position.heading >= 0 && position.speed > 0.5) {
                  bearing = position.heading;
                }

                setState(() {
                  _currentLocation = newLocation;
                  _currentCenter = newLocation;
                  _mapRotation = bearing;
                });

                // Chỉ di chuyển camera nếu người dùng không đang tương tác
                if (!_isUserInteracting) {
                  _mapController.moveAndRotate(
                    newLocation,
                    _currentZoom,
                    -bearing,
                  );
                }
              }
            },
            onError: (error) {
              // Handle location errors gracefully during navigation
              debugPrint('Navigation stream error: $error');
            },
          );
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _isPickingOrigin = false;
      _isPickingDestination = false;
      _mapRotation = 0.0; // Reset rotation
      _lastNavigationUpdate = null; // Reset navigation update timer
      _lastRerouteTime = null; // Reset reroute timer
      _isRerouting = false;
    });
    // stop only navigation-specific stream, keep the general location stream alive
    _navigationSubscription?.cancel();
    _navigationSubscription = null;
    _navigationUpdateTimer?.cancel();
    _navigationUpdateTimer = null;

    // Reset map to north and zoom out
    _mapController.moveAndRotate(_currentCenter, 15.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!_isNavigating)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // Show origin field only when destination exists
                    if (_destination != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _originController,
                              focusNode: _originFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Từ đâu...',
                                prefixIcon: Icon(
                                  Icons.trip_origin,
                                  color: Colors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _showOriginSuggestions = true;
                                  _showDestinationSuggestions = false;
                                });
                              },
                              onChanged: (value) {
                                setState(() {
                                  _showDestinationSuggestions = false;
                                });
                                _debounceTimer?.cancel();
                                if (value.length > 2) {
                                  _debounceTimer = Timer(
                                    Duration(milliseconds: 500),
                                    () {
                                      _fetchOriginSuggestions(value);
                                    },
                                  );
                                } else {
                                  setState(() {
                                    _showOriginSuggestions = true;
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.my_location, color: Colors.blue),
                            onPressed: () {
                              if (_currentLocation != null) {
                                setState(() {
                                  _origin = _currentLocation;
                                  _originController.text = 'Vị trí hiện tại';
                                  _showOriginSuggestions = false;
                                });
                                if (_destination != null) {
                                  _getRoute(_currentLocation!, _destination!);
                                }
                              }
                            },
                            tooltip: 'Dùng vị trí hiện tại',
                          ),
                        ],
                      ),
                      // Origin suggestions
                      if (_showOriginSuggestions)
                        Container(
                          margin: EdgeInsets.only(top: 8),
                          constraints: BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount:
                                1 +
                                (_searchHistory.isNotEmpty &&
                                        _originSuggestions.isEmpty
                                    ? _searchHistory.length + 1
                                    : 0) +
                                _originSuggestions.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1),
                            itemBuilder: (context, index) {
                              // "Chọn trên bản đồ" option
                              if (index == 0) {
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.map,
                                    size: 20,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    'Chọn trên bản đồ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _isPickingOrigin = true;
                                      _isPickingDestination = false;
                                      _showOriginSuggestions = false;
                                    });
                                    _originFocusNode.unfocus();
                                  },
                                );
                              }

                              // Show history if no API suggestions
                              if (_originSuggestions.isEmpty &&
                                  _searchHistory.isNotEmpty) {
                                if (index == 1) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Lịch sử tìm kiếm',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: _clearSearchHistory,
                                          child: Text(
                                            'Xóa tất cả',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                final historyItem = _searchHistory[index - 2];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.history,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  title: Text(
                                    historyItem['name'] ?? '',
                                    style: TextStyle(fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    _selectOriginSuggestion({
                                      'lat': historyItem['lat'],
                                      'lon': historyItem['lon'],
                                      'display_name': historyItem['name'],
                                    });
                                  },
                                );
                              }

                              // Show API suggestions
                              final suggestion = _originSuggestions[index - 1];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on, size: 20),
                                title: Text(
                                  suggestion['display_name'],
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () =>
                                    _selectOriginSuggestion(suggestion),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 2),
                      // Swap button
                      Center(
                        child: IconButton(
                          icon: Icon(Icons.swap_vert, color: Colors.blue),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: (_origin != null || _destination != null)
                              ? _swapOriginDestination
                              : null,
                          tooltip: 'Đảo ngược',
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                    // Destination search field (always show when not navigating)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _destinationController,
                            focusNode: _destinationFocusNode,
                            decoration: InputDecoration(
                              hintText: _destination == null
                                  ? 'Tìm điểm đến...'
                                  : 'Đến đâu...',
                              prefixIcon: Icon(
                                _destination == null
                                    ? Icons.search
                                    : Icons.location_on,
                                color: _destination == null
                                    ? Colors.blue
                                    : Colors.red,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _showDestinationSuggestions = true;
                                _showOriginSuggestions = false;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _showOriginSuggestions = false;
                              });
                              _debounceTimer?.cancel();
                              if (value.length > 2) {
                                _debounceTimer = Timer(
                                  Duration(milliseconds: 500),
                                  () {
                                    _fetchDestinationSuggestions(value);
                                  },
                                );
                              } else {
                                setState(() {
                                  _showDestinationSuggestions = true;
                                });
                              }
                            },
                          ),
                        ),
                        if (_destination != null) ...[
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.red),
                            onPressed: _clearRoute,
                            tooltip: 'Xóa đường đi',
                          ),
                        ],
                      ],
                    ),
                    // Destination suggestions
                    if (_showDestinationSuggestions)
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        constraints: BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount:
                              1 +
                              (_searchHistory.isNotEmpty &&
                                      _destinationSuggestions.isEmpty
                                  ? _searchHistory.length + 1
                                  : 0) +
                              _destinationSuggestions.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1),
                          itemBuilder: (context, index) {
                            // "Chọn trên bản đồ" option
                            if (index == 0) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.map,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  'Chọn trên bản đồ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _isPickingDestination = true;
                                    _isPickingOrigin = false;
                                    _showDestinationSuggestions = false;
                                  });
                                  _destinationFocusNode.unfocus();
                                },
                              );
                            }

                            // Show history if no API suggestions
                            if (_destinationSuggestions.isEmpty &&
                                _searchHistory.isNotEmpty) {
                              if (index == 1) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Lịch sử tìm kiếm',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _clearSearchHistory,
                                        child: Text(
                                          'Xóa tất cả',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final historyItem = _searchHistory[index - 2];
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  Icons.history,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                title: Text(
                                  historyItem['name'] ?? '',
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  _selectDestinationSuggestion({
                                    'lat': historyItem['lat'],
                                    'lon': historyItem['lon'],
                                    'display_name': historyItem['name'],
                                  });
                                },
                              );
                            }

                            // Show API suggestions
                            final suggestion =
                                _destinationSuggestions[index - 1];
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.location_on, size: 20),
                              title: Text(
                                suggestion['display_name'],
                                style: TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () =>
                                  _selectDestinationSuggestion(suggestion),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            // Transport mode and distance display
            if (_destination != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isNavigating) ...[
                      Text(
                        'Phương tiện:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_car, size: 16),
                                SizedBox(width: 4),
                                Text('Xe hơi'),
                              ],
                            ),
                            selected: _transportMode == TransportMode.driving,
                            onSelected: (selected) {
                              if (selected) {
                                final startPoint = _origin ?? _currentLocation;
                                if (startPoint != null &&
                                    _destination != null) {
                                  setState(() {
                                    _transportMode = TransportMode.driving;
                                  });
                                  _getRoute(startPoint, _destination!);
                                }
                              }
                            },
                          ),
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.two_wheeler, size: 16),
                                SizedBox(width: 4),
                                Text('Xe máy'),
                              ],
                            ),
                            selected:
                                _transportMode == TransportMode.motorcycle,
                            onSelected: (selected) {
                              if (selected) {
                                final startPoint = _origin ?? _currentLocation;
                                if (startPoint != null &&
                                    _destination != null) {
                                  setState(() {
                                    _transportMode = TransportMode.motorcycle;
                                  });
                                  _getRoute(startPoint, _destination!);
                                }
                              }
                            },
                          ),
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_walk, size: 16),
                                SizedBox(width: 4),
                                Text('Đi bộ'),
                              ],
                            ),
                            selected: _transportMode == TransportMode.walking,
                            onSelected: (selected) {
                              if (selected) {
                                final startPoint = _origin ?? _currentLocation;
                                if (startPoint != null &&
                                    _destination != null) {
                                  setState(() {
                                    _transportMode = TransportMode.walking;
                                  });
                                  _getRoute(startPoint, _destination!);
                                }
                              }
                            },
                          ),
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_bike, size: 16),
                                SizedBox(width: 4),
                                Text('Xe đạp'),
                              ],
                            ),
                            selected: _transportMode == TransportMode.cycling,
                            onSelected: (selected) {
                              if (selected) {
                                final startPoint = _origin ?? _currentLocation;
                                if (startPoint != null &&
                                    _destination != null) {
                                  setState(() {
                                    _transportMode = TransportMode.cycling;
                                  });
                                  _getRoute(startPoint, _destination!);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                    if (_distanceKm != null && _durationMinutes != null)
                      Container(
                        key: ValueKey(
                          '${_transportMode}_${_distanceKm}_${_durationMinutes}_$_selectedRouteIndex',
                        ),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTransportIcon(),
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${_distanceKm!.toStringAsFixed(2)} km',
                              key: ValueKey('distance_$_distanceKm'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_durationMinutes!.toStringAsFixed(0)} phút',
                              key: ValueKey('duration_$_durationMinutes'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    // Alternative routes section - Hide when navigating
                    if (_alternativeRoutes.length > 1 && !_isNavigating) ...[
                      Text(
                        'Lựa chọn đường đi:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _alternativeRoutes.length,
                          itemBuilder: (context, index) {
                            final route = _alternativeRoutes[index];
                            final isSelected = _selectedRouteIndex == index;
                            final distance = route['distance'] as double;
                            final duration = route['duration'] as double;

                            String routeLabel;
                            if (index == 0) {
                              routeLabel = 'Ngắn nhất';
                            } else if (duration <
                                _alternativeRoutes[0]['duration']) {
                              routeLabel = 'Nhanh nhất';
                            } else {
                              routeLabel = 'Lựa chọn ';
                            }

                            return GestureDetector(
                              onTap: () => _selectRoute(index),
                              child: Container(
                                width: 140,
                                margin: EdgeInsets.only(right: 8),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue.shade900
                                        : Colors.grey.shade400,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      routeLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.route,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${distance.toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.grey.shade700,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${duration.toStringAsFixed(0)} phút',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            // Picking mode banner
            if (_isPickingOrigin || _isPickingDestination)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.orange.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isPickingOrigin
                            ? 'Chạm vào bản đồ để chọn điểm đi'
                            : 'Chạm vào bản đồ để chọn điểm đến',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isPickingOrigin = false;
                          _isPickingDestination = false;
                        });
                      },
                      child: Text(
                        'HỦY',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Start/Stop navigation button
            if (_destination != null &&
                _distanceKm != null &&
                _durationMinutes != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: _isNavigating
                        ? _stopNavigation
                        : _startNavigation,
                    icon: Icon(
                      _isNavigating ? Icons.close : Icons.navigation,
                      size: 18,
                    ),
                    label: Text(_isNavigating ? 'HUỶ' : 'BẮT ĐẦU'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating
                          ? Colors.red
                          : Colors.green,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: FlutterMap(
                key: ValueKey('map_${_isNavigating}_$_mapRotation'),
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentCenter,
                  initialZoom: 13.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  keepAlive: true,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag
                        .all, // Cho phép tất cả tương tác kể cả khi đang điều hướng
                  ),
                  onPositionChanged: (position, hasGesture) {
                    // Lưu lại zoom level khi người dùng thay đổi
                    if (hasGesture && _isNavigating) {
                      setState(() {
                        _currentZoom = position.zoom;
                        _isUserInteracting = true;
                      });
                      // Reset sau 3 giây để camera tiếp tục theo dõi
                      Future.delayed(Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            _isUserInteracting = false;
                          });
                        }
                      });
                    }
                  },
                  onTap: (tapPosition, point) {
                    // If suggestions are showing, close them first and don't process location selection
                    if (_showOriginSuggestions || _showDestinationSuggestions) {
                      setState(() {
                        _showOriginSuggestions = false;
                        _showDestinationSuggestions = false;
                      });
                      _originFocusNode.unfocus();
                      _destinationFocusNode.unfocus();
                      return;
                    }

                    // Handle map selection based on mode
                    if (_isPickingOrigin) {
                      setState(() {
                        _origin = point;
                        _originController.text =
                            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                        _isPickingOrigin =
                            false; // Exit picking mode after selection
                      });
                      if (_destination != null) {
                        _getRoute(point, _destination!);
                      }
                    } else if (_isPickingDestination) {
                      setState(() {
                        _destination = point;
                        _destinationController.text =
                            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
                        _isPickingDestination =
                            false; // Exit picking mode after selection
                      });
                      final startPoint = _origin ?? _currentLocation;
                      if (startPoint != null) {
                        _getRoute(startPoint, point);
                      }
                      _moveToLocation(point);
                    } else if (!_isNavigating) {
                      // In normal mode (not searching, not picking), allow setting destination by tapping map
                      _setAsDestination(point);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getMapTileUrl(),
                    userAgentPackageName: 'com.example.tourn',
                  ),
                  // Lớp chất lượng không khí
                  if (_showAirQuality)
                    TileLayer(
                      urlTemplate:
                          'https://tiles.waqi.info/tiles/usepa-aqi/{z}/{x}/{y}.png?token=demo',
                      userAgentPackageName: 'com.example.tourn',
                      tileProvider: NetworkTileProvider(),
                    ),
                  // Lớp thời tiết/mưa - RainViewer (Miễn phí)
                  if (_showFloodLayer)
                    TileLayer(
                      urlTemplate:
                          'https://tilecache.rainviewer.com/v2/radar/nowcast/256/{z}/{x}/{y}/2/1_1.png',
                      userAgentPackageName: 'com.example.tourn',
                      tileProvider: NetworkTileProvider(),
                    ),
                  // Lớp mật độ giao thông toàn bản đồ
                  if (_showTrafficLayer)
                    TileLayer(
                      // Sử dụng Google Traffic Tiles (hiển thị màu giao thông thực tế)
                      urlTemplate:
                          'https://mt1.google.com/vt/lyrs=m@221097413,traffic&x={x}&y={y}&z={z}',
                      userAgentPackageName: 'com.example.tourn',
                      tileProvider: NetworkTileProvider(),
                    ),
                  // Vẽ đường đi nếu có - hiển thị tất cả alternatives
                  if (_alternativeRoutes.isNotEmpty)
                    PolylineLayer(
                      polylines: _alternativeRoutes.asMap().entries.expand((
                        entry,
                      ) {
                        final index = entry.key;
                        final route = entry.value;
                        final isSelected = _selectedRouteIndex == index;
                        final points = route['points'] as List<LatLng>;

                        // Luôn vẽ đường màu xanh dương
                        return [
                          Polyline(
                            points: points,
                            strokeWidth: isSelected ? 5.0 : 3.0,
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.withValues(alpha: 0.5),
                            borderStrokeWidth: isSelected ? 1.0 : 0,
                            borderColor: isSelected
                                ? Colors.blue.shade900
                                : Colors.transparent,
                          ),
                        ];
                      }).toList(),
                    ),
                  MarkerLayer(
                    markers: [
                      // Marker vị trí hiện tại - mũi tên điều hướng khi đang đi
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 60,
                          height: 60,
                          rotate: true, // Rotate with map
                          child: _isNavigating
                              ? Transform.rotate(
                                  // Compensate for map rotation so arrow always points UP on screen
                                  angle:
                                      _mapRotation * (3.141592653589793 / 180),
                                  child: Icon(
                                    Icons.navigation,
                                    color: Colors.blue,
                                    size: 50,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 10,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 35,
                                  ),
                                ),
                        ),
                      // Marker điểm đến
                      if (_destination != null)
                        Marker(
                          point: _destination!,
                          width: 80,
                          height: 80,
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút quay về vị trí hiện tại
          FloatingActionButton(
            heroTag: 'myLocation',
            mini: true,
            backgroundColor: Colors.blue,
            onPressed: () {
              if (_currentLocation != null) {
                setState(() {
                  _isUserInteracting = false; // Reset để camera theo dõi lại
                });
                if (_isNavigating) {
                  _mapController.moveAndRotate(
                    _currentLocation!,
                    _currentZoom,
                    -_mapRotation,
                  );
                } else {
                  _mapController.move(_currentLocation!, 15.0);
                }
              } else {
                _getCurrentLocation();
              }
            },
            tooltip: 'Vị trí của tôi',
            child: Icon(Icons.my_location),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'floodLayer',
            mini: true,
            backgroundColor: _showFloodLayer
                ? Colors.blue.shade700
                : Colors.grey,
            onPressed: () {
              setState(() {
                _showFloodLayer = !_showFloodLayer;
              });
            },
            tooltip: 'Ngập úng/Thiên tai',
            child: Icon(Icons.water_damage),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'trafficLayer',
            mini: true,
            backgroundColor: _showTrafficLayer
                ? const Color.fromARGB(255, 67, 103, 250)
                : Colors.grey,
            onPressed: () {
              setState(() {
                _showTrafficLayer = !_showTrafficLayer;
                // Tắt air quality khi bật traffic
                if (_showTrafficLayer) {
                  _showAirQuality = false;
                }
              });
            },
            tooltip: 'Mật độ giao thông',
            child: Icon(Icons.traffic),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'airQuality',
            mini: true,
            backgroundColor: _showAirQuality ? Colors.green : Colors.grey,
            onPressed: () {
              setState(() {
                _showAirQuality = !_showAirQuality;
                // Tắt traffic khi bật air quality
                if (_showAirQuality) {
                  _showTrafficLayer = false;
                }
              });
            },
            tooltip: 'Chất lượng không khí',
            child: Icon(Icons.air),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'mapType',
            mini: true,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Chọn kiểu bản đồ'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.map),
                        title: Text('Bản đồ thường'),
                        trailing: _currentMapType == MapType.normal
                            ? Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          _changeMapType(MapType.normal);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.satellite),
                        title: Text('Bản đồ vệ tinh'),
                        trailing: _currentMapType == MapType.satellite
                            ? Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          _changeMapType(MapType.satellite);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.terrain),
                        title: Text('Bản đồ địa hình'),
                        trailing: _currentMapType == MapType.terrain
                            ? Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          _changeMapType(MapType.terrain);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Chọn kiểu bản đồ',
            child: Icon(Icons.layers),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?._recenter = null;
    _debounceTimer?.cancel();
    _navigationUpdateTimer?.cancel();
    _originController.dispose();
    _destinationController.dispose();
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    _locationSubscription?.cancel();
    _navigationSubscription?.cancel();
    super.dispose();
  }
}
