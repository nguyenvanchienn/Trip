import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/widgets/thoitiet_page.dart';

/// Compact weather indicator widget for app bar
class WeatherIndicator extends StatefulWidget {
  const WeatherIndicator({super.key});

  @override
  State<WeatherIndicator> createState() => _WeatherIndicatorState();
}

class _WeatherIndicatorState extends State<WeatherIndicator> {
  int? _temperature;
  int? _weatherCode;
  bool _isDay = true;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      // Try to get current location
      double lat = 21.0285; // Default to Hanoi
      double lon = 105.8542;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.deniedForever &&
            permission != LocationPermission.denied) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          ).timeout(const Duration(seconds: 5));
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {
        // Use default location if can't get current position
      }

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&timezone=auto',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final current = data['current_weather'] as Map<String, dynamic>?;

        if (current != null && mounted) {
          setState(() {
            _temperature = (current['temperature'] as num).toInt();
            _weatherCode = (current['weathercode'] as num).toInt();
            _isDay = (current['is_day'] as num?)?.toInt() == 1;
            _loading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _getWeatherIcon(int code, {double size = 20}) {
    IconData iconData;
    Color iconColor;

    if (code == 0) {
      iconData = _isDay ? Icons.wb_sunny : Icons.nightlight_round;
      iconColor = _isDay ? Colors.orange : Colors.blueGrey;
    } else if (code == 1 || code == 2) {
      iconData = _isDay ? Icons.wb_cloudy : Icons.nights_stay;
      iconColor = Colors.grey[600]!;
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
      iconData = Icons.wb_sunny;
      iconColor = Colors.orange;
    }

    return Icon(iconData, size: size, color: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }

    if (_hasError || _temperature == null) {
      return IconButton(
        icon: Icon(Icons.wb_sunny_outlined, color: Colors.grey[400]),
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ThoiTietPage()));
        },
        tooltip: 'Thời tiết',
      );
    }

    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ThoiTietPage()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getWeatherIcon(_weatherCode ?? 0, size: 18),
            const SizedBox(width: 4),
            Text(
              '$_temperature°',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
