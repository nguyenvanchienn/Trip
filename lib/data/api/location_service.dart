import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/location_models.dart';

/// Helper nhỏ gói các cuộc gọi đến backend/webservice
/// để tìm địa điểm, cây ATM, bệnh viện, v.v.  Ví dụ dưới đây
/// giả định server của bạn nhận tham số vĩ độ/kinh độ cùng
/// query hoặc bộ lọc loại; điều chỉnh theo endpoint thực tế.
class LocationService {
  final http.Client _client;

  /// Backend HTTP tùy chọn. Nếu bạn chưa có, giữ nguyên giá trị chỗ
  /// này và các phương thức sẽ dùng Firestore (`hospitals`, `atms`).
  static const String baseUrl = 'https://your-api.example.com';

  LocationService({http.Client? client}) : _client = client ?? http.Client();

  /// Trả về vị trí hiện tại, lỗi nếu quá [timeLimit].
  /// Timeout ngắn tránh UI treo vô hạn.
  Future<Position> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 5),
  }) async {
    // Kiểm tra service có được bật không
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí chưa được bật');
    }

    // Kiểm tra và yêu cầu quyền
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: timeLimit,
    );
  }

  Future<List<Hospital>> fetchHospitals({
    String query = '',
    String type = '',
  }) async {
    // ưu tiên backend HTTP nếu đã cấu hình
    if (!baseUrl.contains('your-api.example.com')) {
      try {
        final pos = await getCurrentPosition();
        final uri = Uri.parse(
          '$baseUrl/hospitals?lat=${pos.latitude}&lng=${pos.longitude}&query=$query&type=$type',
        );
        final res = await _client.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          return list.map((e) => Hospital.fromJson(e)).toList();
        }
        // nếu không thì tiếp tục sang Firestore
      } catch (_) {
        // mạng lỗi, tiếp tục dùng Firestore
      }
    }

    // dự phòng Firestore – collection phải tồn tại trong project của bạn
    Query queryRef = FirebaseFirestore.instance.collection('hospitals');
    if (type.isNotEmpty) queryRef = queryRef.where('type', isEqualTo: type);
    if (query.isNotEmpty) {
      // tìm kiếm chữ trong tên/địa chỉ bằng so sánh tiền tố không phân biệt hoa thường
      queryRef = queryRef
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z');
    }
    final snap = await queryRef.get();
    return snap.docs
        .map((d) => Hospital.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Atm>> fetchAtms({String query = '', String bank = ''}) async {
    // thử backend HTTP trước nếu đã cấu hình
    if (!baseUrl.contains('your-api.example.com')) {
      try {
        final pos = await getCurrentPosition();
        final uri = Uri.parse(
          '$baseUrl/atms?lat=${pos.latitude}&lng=${pos.longitude}&query=$query&bank=$bank',
        );
        final res = await _client.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          return list.map((e) => Atm.fromJson(e)).toList();
        }
      } catch (_) {
        // bỏ qua, dùng Firestore thay thế
      }
    }

    // dự phòng Firestore
    Query queryRef = FirebaseFirestore.instance.collection('atms');
    if (bank.isNotEmpty) queryRef = queryRef.where('bank', isEqualTo: bank);
    if (query.isNotEmpty) {
      queryRef = queryRef
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z');
    }
    final snap = await queryRef.get();
    return snap.docs
        .map((d) => Atm.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }
}
