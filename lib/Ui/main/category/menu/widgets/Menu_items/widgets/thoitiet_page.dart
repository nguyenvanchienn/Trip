import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ThoiTietPage extends StatefulWidget {
  const ThoiTietPage({super.key});

  @override
  State<ThoiTietPage> createState() => _ThoiTietPageState();
}

class _ThoiTietPageState extends State<ThoiTietPage> {
  bool _loading = false;
  String? _error;
  String? _locationName;
  String? _cityName;

  double? _lat;
  double? _lon;

  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _daily = [];
  List<Map<String, dynamic>> _hourly = [];

  final _searchCtrl = TextEditingController();

  // Search suggestions
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Auto-load current location weather on start
    _useCurrentLocation();

    // Listen to search text changes for suggestions
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.trim();
    if (query.length >= 2) {
      _fetchSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) return;

    setState(() => _loadingSuggestions = true);

    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=5&language=vi',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        setState(() {
          _suggestions = results.map((e) => e as Map<String, dynamic>).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    } finally {
      setState(() => _loadingSuggestions = false);
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = (suggestion['latitude'] as num).toDouble();
    final lon = (suggestion['longitude'] as num).toDouble();
    final name = suggestion['name'] ?? '';
    final country = suggestion['country'] ?? '';
    final admin1 = suggestion['admin1'] ?? '';

    setState(() {
      _lat = lat;
      _lon = lon;
      _locationName = 'Kết quả tìm kiếm';
      _cityName = name;
      _suggestions = [];
      _showSuggestions = false;
      _searchCtrl.clear();
    });

    // Hide keyboard
    FocusScope.of(context).unfocus();

    _fetchWeather(lat, lon);
  }

  // Get weather icon URL from Open-Meteo WMO codes
  String _getWeatherIconUrl(int code, {bool isDay = true}) {
    // Using meteocons icons from basmilius/weather-icons
    String iconName;
    if (code == 0) {
      iconName = isDay ? 'clear-day' : 'clear-night';
    } else if (code == 1 || code == 2) {
      iconName = isDay ? 'partly-cloudy-day' : 'partly-cloudy-night';
    } else if (code == 3) {
      iconName = 'cloudy';
    } else if (code >= 45 && code <= 48) {
      iconName = 'fog';
    } else if (code >= 51 && code <= 55) {
      iconName = 'drizzle';
    } else if (code >= 56 && code <= 57) {
      iconName = 'sleet';
    } else if (code >= 61 && code <= 65) {
      iconName = 'rain';
    } else if (code >= 66 && code <= 67) {
      iconName = 'sleet';
    } else if (code >= 71 && code <= 77) {
      iconName = 'snow';
    } else if (code >= 80 && code <= 82) {
      iconName = 'rain';
    } else if (code >= 85 && code <= 86) {
      iconName = 'snow';
    } else if (code >= 95 && code <= 99) {
      iconName = 'thunderstorms';
    } else {
      iconName = 'not-available';
    }
    return 'https://raw.githubusercontent.com/basmilius/weather-icons/dev/production/fill/svg/$iconName.svg';
  }

  // Get weather icon as a widget
  Widget _getWeatherIcon(int code, {double size = 32, bool isDay = true}) {
    IconData iconData;
    Color iconColor;

    if (code == 0) {
      iconData = isDay ? Icons.wb_sunny : Icons.nightlight_round;
      iconColor = isDay ? Colors.orange : Colors.blueGrey;
    } else if (code == 1 || code == 2) {
      iconData = isDay ? Icons.wb_cloudy : Icons.nights_stay;
      iconColor = Colors.grey;
    } else if (code == 3) {
      iconData = Icons.cloud;
      iconColor = Colors.grey;
    } else if (code >= 45 && code <= 48) {
      iconData = Icons.foggy;
      iconColor = Colors.grey[400]!;
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      iconData = Icons.water_drop;
      iconColor = Colors.blue;
    } else if (code >= 71 && code <= 77 || code >= 85 && code <= 86) {
      iconData = Icons.ac_unit;
      iconColor = Colors.lightBlue;
    } else if (code >= 95 && code <= 99) {
      iconData = Icons.thunderstorm;
      iconColor = Colors.deepPurple;
    } else {
      iconData = Icons.help_outline;
      iconColor = Colors.grey;
    }

    return Icon(iconData, size: size, color: iconColor);
  }

  Future<void> _searchCity(String name) async {
    if (name.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _showSuggestions = false;
      _suggestions = [];
    });

    // Hide keyboard
    FocusScope.of(context).unfocus();

    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(name)}&count=5&language=vi',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Geocoding failed');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];
      if (results.isEmpty) throw Exception('Không tìm thấy địa điểm');
      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num).toDouble();
      final lon = (first['longitude'] as num).toDouble();
      final nameFound = first['name'] ?? '';
      setState(() {
        _lat = lat;
        _lon = lon;
        _locationName = 'Kết quả tìm kiếm';
        _cityName = nameFound;
      });
      await _fetchWeather(lat, lon);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: ${e.toString()}')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Quyền vị trí bị từ chối');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lat = pos.latitude;
      _lon = pos.longitude;

      // Reverse geocode to get city name
      await _reverseGeocode(_lat!, _lon!);
      await _fetchWeather(_lat!, _lon!);
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi vị trí: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      // Use nominatim for reverse geocoding with Vietnamese locale
      final nominatimUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=vi',
      );
      final res = await http
          .get(nominatimUrl, headers: {'User-Agent': 'FlutterWeatherApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        debugPrint('Reverse geocode result: $data');
        debugPrint('Lat: $lat, Lon: $lon');

        if (address != null) {
          // Vietnamese addresses use different fields
          _cityName =
              address['city'] ??
              address['town'] ??
              address['municipality'] ??
              address['state'] ??
              address['village'] ??
              address['suburb'] ??
              address['county'] ??
              address['district'] ??
              'Không rõ';
          _locationName = 'Vị trí của tôi';

          debugPrint('City name resolved: $_cityName');
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      _locationName = 'Vị trí của tôi';
      _cityName = 'Vị trí hiện tại';
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current_weather=true'
        '&hourly=temperature_2m,weathercode,is_day'
        '&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max'
        '&timezone=auto&forecast_days=10',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu thời tiết');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      setState(() {
        _currentWeather = (data['current_weather'] as Map<String, dynamic>?);

        // Parse hourly data
        _hourly = [];
        final hourly = data['hourly'] as Map<String, dynamic>?;
        if (hourly != null) {
          final times = (hourly['time'] as List<dynamic>? ?? []).cast<String>();
          final temps = (hourly['temperature_2m'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toDouble())
              .toList();
          final codes = (hourly['weathercode'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toInt())
              .toList();
          final isDays = (hourly['is_day'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toInt() == 1)
              .toList();

          // Get current hour and next 24 hours
          final now = DateTime.now();
          for (var i = 0; i < times.length && _hourly.length < 25; i++) {
            final hourTime = DateTime.tryParse(times[i]);
            if (hourTime != null &&
                hourTime.isAfter(now.subtract(const Duration(hours: 1)))) {
              _hourly.add({
                'time': times[i],
                'temp': temps[i],
                'code': codes[i],
                'isDay': i < isDays.length ? isDays[i] : true,
              });
            }
          }
        }

        // Parse daily data
        _daily = [];
        final daily = data['daily'] as Map<String, dynamic>?;
        if (daily != null) {
          final times = (daily['time'] as List<dynamic>? ?? []).cast<String>();
          final maxs = (daily['temperature_2m_max'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toDouble())
              .toList();
          final mins = (daily['temperature_2m_min'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toDouble())
              .toList();
          final codes = (daily['weathercode'] as List<dynamic>? ?? [])
              .map((e) => (e as num).toInt())
              .toList();
          final precips =
              (daily['precipitation_probability_max'] as List<dynamic>? ?? [])
                  .map((e) => (e as num?)?.toInt() ?? 0)
                  .toList();

          for (var i = 0; i < times.length; i++) {
            _daily.add({
              'date': times[i],
              'max': maxs[i],
              'min': mins[i],
              'code': codes[i],
              'precip': i < precips.length ? precips[i] : 0,
            });
          }
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi thời tiết: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _weatherCodeToText(int code) {
    if (code == 0) return 'Quang đãng';
    if (code == 1) return 'Ít mây';
    if (code == 2) return 'Có mây';
    if (code == 3) return 'Nhiều mây';
    if (code >= 45 && code <= 48) return 'Sương mù';
    if (code >= 51 && code <= 55) return 'Mưa phùn';
    if (code >= 56 && code <= 57) return 'Mưa phùn đóng băng';
    if (code >= 61 && code <= 65) return 'Mưa';
    if (code >= 66 && code <= 67) return 'Mưa đóng băng';
    if (code >= 71 && code <= 77) return 'Tuyết';
    if (code >= 80 && code <= 82) return 'Mưa rào';
    if (code >= 85 && code <= 86) return 'Tuyết rơi';
    if (code >= 95 && code <= 99) return 'Bão';
    return 'Không rõ';
  }

  String _formatHour(String timeStr) {
    final dt = DateTime.tryParse(timeStr);
    if (dt == null) return '';
    final now = DateTime.now();
    if (dt.hour == now.hour && dt.day == now.day) {
      return 'Bây giờ';
    }
    return '${dt.hour} giờ';
  }

  String _formatDay(String dateStr, int index) {
    if (index == 0) return 'Hôm nay';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '';
    final weekdays = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
    return weekdays[dt.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final cw = _currentWeather;
    final currentTemp = cw != null ? (cw['temperature'] as num).toInt() : 0;
    final currentCode = cw != null ? (cw['weathercode'] as num).toInt() : 0;
    final isDay = cw != null ? (cw['is_day'] as num?)?.toInt() == 1 : true;

    // Calculate min/max from today's daily data
    int todayMin = 0;
    int todayMax = 0;
    if (_daily.isNotEmpty) {
      todayMin = (_daily[0]['min'] as double).toInt();
      todayMax = (_daily[0]['max'] as double).toInt();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDay
                ? [
                    const Color(0xFF4A90A4),
                    const Color(0xFF6B8E9B),
                    const Color(0xFF8BA5B5),
                  ]
                : [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with search
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Tìm thành phố...',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            suffixIcon: _loadingSuggestions
                                ? Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  )
                                : _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {
                                        _suggestions = [];
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (v) => _searchCity(v),
                          onTap: () {
                            if (_suggestions.isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      onPressed: _useCurrentLocation,
                    ),
                  ],
                ),
              ),

              // Search suggestions dropdown
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3E50),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        final name = s['name'] ?? '';
                        final country = s['country'] ?? '';
                        final admin1 = s['admin1'] ?? '';
                        final subtitle = [
                          admin1,
                          country,
                        ].where((e) => e.isNotEmpty).join(', ');

                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 20,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: subtitle.isNotEmpty
                              ? Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
                ),

              // Main content
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Hide suggestions when tapping outside
                    if (_showSuggestions) {
                      setState(() => _showSuggestions = false);
                    }
                    FocusScope.of(context).unfocus();
                  },
                  child: _loading && cw == null
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : cw == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có dữ liệu thời tiết',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (_lat != null && _lon != null) {
                              await _fetchWeather(_lat!, _lon!);
                            }
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),

                                // Location name
                                Text(
                                  _locationName ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  _cityName?.toUpperCase() ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 1.5,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Large temperature
                                Text(
                                  '$currentTemp°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 96,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),

                                // Weather condition
                                Text(
                                  _weatherCodeToText(currentCode),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                // High/Low
                                Text(
                                  'C:$todayMax°  T:$todayMin°',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Hourly forecast card
                                _buildHourlyForecast(),

                                const SizedBox(height: 16),

                                // 10-day forecast card
                                _buildDailyForecast(),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    if (_hourly.isEmpty) return const SizedBox.shrink();

    // Get weather description for the description text
    final currentCode = _currentWeather != null
        ? (_currentWeather!['weathercode'] as num).toInt()
        : 0;
    final windSpeed = _currentWeather != null
        ? (_currentWeather!['windspeed'] as num).toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_weatherCodeToText(currentCode)} sẽ tiếp tục đến hết ngày. Gió giật lên đến $windSpeed km/h.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              itemCount: _hourly.length,
              itemBuilder: (context, index) {
                final h = _hourly[index];
                final temp = (h['temp'] as double).toInt();
                final code = h['code'] as int;
                final isDay = h['isDay'] as bool;
                final timeStr = h['time'] as String;

                return Container(
                  width: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        _formatHour(timeStr),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _getWeatherIcon(code, size: 28, isDay: isDay),
                      Text(
                        '$temp°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    if (_daily.isEmpty) return const SizedBox.shrink();

    // Find overall min and max for the temperature bar
    double overallMin = double.infinity;
    double overallMax = double.negativeInfinity;
    for (final d in _daily) {
      final min = d['min'] as double;
      final max = d['max'] as double;
      if (min < overallMin) overallMin = min;
      if (max > overallMax) overallMax = max;
    }
    final range = overallMax - overallMin;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'DỰ BÁO ${_daily.length} NGÀY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _daily.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final d = _daily[index];
              final date = d['date'] as String;
              final max = d['max'] as double;
              final min = d['min'] as double;
              final code = d['code'] as int;
              final precip = d['precip'] as int;

              // Calculate bar positions
              final minPos = range > 0 ? (min - overallMin) / range : 0.0;
              final maxPos = range > 0 ? (max - overallMin) / range : 1.0;

              // Get current temp position if today
              double? currentPos;
              if (index == 0 && _currentWeather != null) {
                final currentTemp = (_currentWeather!['temperature'] as num)
                    .toDouble();
                currentPos = range > 0
                    ? (currentTemp - overallMin) / range
                    : 0.5;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Day name
                    SizedBox(
                      width: 70,
                      child: Text(
                        _formatDay(date, index),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Weather icon with precipitation
                    SizedBox(
                      width: 50,
                      child: Column(
                        children: [
                          _getWeatherIcon(code, size: 24),
                          if (precip > 30)
                            Text(
                              '$precip%',
                              style: const TextStyle(
                                color: Colors.lightBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Min temp
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${min.toInt()}°',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Temperature bar
                    Expanded(
                      child: _buildTemperatureBar(minPos, maxPos, currentPos),
                    ),

                    const SizedBox(width: 8),

                    // Max temp
                    SizedBox(
                      width: 35,
                      child: Text(
                        '${max.toInt()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureBar(
    double minPos,
    double maxPos,
    double? currentPos,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final barStart = width * minPos;
        final barWidth = width * (maxPos - minPos);

        return SizedBox(
          height: 6,
          child: Stack(
            children: [
              // Background track
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Gradient bar
              Positioned(
                left: barStart,
                child: Container(
                  width: barWidth.clamp(4.0, width - barStart),
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4CAF50),
                        Color(0xFFFFEB3B),
                        Color(0xFFFF9800),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Current temperature indicator
              if (currentPos != null)
                Positioned(
                  left: (width * currentPos) - 4,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
