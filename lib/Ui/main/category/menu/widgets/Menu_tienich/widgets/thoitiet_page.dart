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
  final String _cityQuery = '';
  String? _locationName;

  double? _lat;
  double? _lon;

  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>> _daily = [];

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCity(String name) async {
    if (name.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(name)}&count=5',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Geocoding failed');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];
      if (results.isEmpty) throw Exception('Không tìm thấy địa điểm');
      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num).toDouble();
      final lon = (first['longitude'] as num).toDouble();
      final nameFound =
          (first['name'] ?? '') +
          (first['country'] != null ? ', ${first['country']}' : '');
      setState(() {
        _lat = lat;
        _lon = lon;
        _locationName = nameFound;
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
      _locationName = 'Vị trí hiện tại';
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

  Future<void> _fetchWeather(double lat, double lon) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw Exception('Không thể lấy dữ liệu thời tiết');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _currentWeather = (data['current_weather'] as Map<String, dynamic>?);
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
          for (
            var i = 0;
            i < times.length &&
                i < maxs.length &&
                i < mins.length &&
                i < codes.length;
            i++
          ) {
            _daily.add({
              'date': times[i],
              'max': maxs[i],
              'min': mins[i],
              'code': codes[i],
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
    // simplified mapping
    if (code == 0) return 'Quang đãng';
    if (code == 1 || code == 2 || code == 3) return 'Nhiều mây';
    if (code >= 45 && code <= 48) return 'Sương mù';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'Mưa nhẹ';
    }
    if (code >= 71 && code <= 77) return 'Tuyết';
    if (code >= 95 && code <= 99) return 'Bão';
    return 'Không rõ';
  }

  IconData _weatherCodeToIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2 || code == 3) return Icons.cloud;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return Icons.grain;
    }
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final cw = _currentWeather;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thời tiết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_lat != null && _lon != null) _fetchWeather(_lat!, _lon!);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm thành phố...',
                    ),
                    onSubmitted: (v) => _searchCity(v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _useCurrentLocation,
                  child: const Text('Vị trí'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (cw != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _weatherCodeToIcon(
                              (cw['weathercode'] as num).toInt(),
                            ),
                            size: 40,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _locationName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${(cw['temperature'] as num).toStringAsFixed(0)}°C • ${_weatherCodeToText((cw['weathercode'] as num).toInt())}',
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              Text(
                                'Gió ${(cw['windspeed'] as num).toStringAsFixed(0)} m/s',
                              ),
                              Text('Thời gian: ${cw['time'] ?? ''}'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _daily.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = _daily[i];
                    final date = d['date'] as String;
                    final max = d['max'] as double;
                    final min = d['min'] as double;
                    final code = d['code'] as int;
                    return Card(
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(_weatherCodeToIcon(code), color: Colors.blue),
                            const SizedBox(height: 8),
                            Text('Max: ${max.toStringAsFixed(0)}°C'),
                            Text('Min: ${min.toStringAsFixed(0)}°C'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (cw == null && !_loading)
              const Expanded(
                child: Center(
                  child: Text('Chưa có dữ liệu. Tìm hoặc dùng vị trí.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
