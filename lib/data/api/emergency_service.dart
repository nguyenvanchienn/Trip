/// Dịch vụ lấy số điện thoại khẩn cấp từ API hoặc Firestore.
/// UI có thể gọi `getNumbers()` và hiển thị kết quả trong cùng các widget `_EmergencyCard`
/// thay vì viết cứng dữ liệu.
library;

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class EmergencyNumber {
  final String title;
  final String subtitle;
  final String phone;

  EmergencyNumber({
    required this.title,
    required this.subtitle,
    required this.phone,
  });

  factory EmergencyNumber.fromJson(Map<String, dynamic> json) {
    return EmergencyNumber(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      phone: json['phone'] as String,
    );
  }
}

class EmergencyService {
  final http.Client _client;

  EmergencyService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<EmergencyNumber>> getNumbers() async {
    // thử gọi mạng trước; nếu thất bại thì dùng Firestore
    try {
      final url = Uri.parse('https://your-api.example.com/emergency');
      final res = await _client.get(url);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => EmergencyNumber.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // mã trả về không phải 200 – tiếp tục dùng Firestore
    } catch (_) {
      // lỗi mạng, tiếp tục dùng Firestore
    }

    // fallback: lấy từ Firestore nếu API chưa cấu hình
    final snap = await FirebaseFirestore.instance
        .collection('emergency_numbers')
        .orderBy('priority', descending: false)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Không có dữ liệu khẩn cấp');
    }

    return snap.docs.map((doc) {
      final data = doc.data();
      return EmergencyNumber(
        title: (data['title'] ?? '').toString(),
        subtitle: (data['subtitle'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
      );
    }).toList();
  }
}
