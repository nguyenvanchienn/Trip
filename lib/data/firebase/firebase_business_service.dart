import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseBusinessService {
  static final FirebaseBusinessService _instance =
      FirebaseBusinessService._internal();

  factory FirebaseBusinessService() => _instance;

  FirebaseBusinessService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<({bool success, String? error, String? id})> createService({
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      return (success: false, error: 'Chưa đăng nhập', id: null);
    }

    try {
      final docRef = _firestore.collection(collectionName).doc();
      final payload = <String, dynamic>{
        ...data,
        'ownerId': uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };
      await docRef.set(payload);
      return (success: true, error: null, id: docRef.id);
    } catch (e) {
      return (success: false, error: e.toString(), id: null);
    }
  }

  /// Cập nhật một dịch vụ hiện có.
  Future<({bool success, String? error})> updateService({
    required String collectionName,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final payload = <String, dynamic>{
        ...data,
        'updatedAt': Timestamp.now(),
      };
      await _firestore.collection(collectionName).doc(docId).update(payload);
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Stream<List<Map<String, dynamic>>> streamServices({
    required String collectionName,
  }) {
    return _firestore.collection(collectionName).snapshots().map((snap) {
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Stream chỉ trả về dịch vụ của người dùng hiện tại.
  Stream<List<Map<String, dynamic>>> streamMyServices({
    required String collectionName,
  }) {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection(collectionName)
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .map(
      (snap) {
        final list = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        list.sort((a, b) {
          final ta = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final tb = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return tb.compareTo(ta);
        });
        return list;
      },
    );
  }

  /// Xóa một dịch vụ theo collection và documentId.
  Future<({bool success, String? error})> deleteService({
    required String collectionName,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionName).doc(docId).delete();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  /// Lấy danh sách dịch vụ nổi bật của một doanh nghiệp (ownerId)
  Future<List<Map<String, dynamic>>> getFeaturedServices(String ownerId) async {
    try {
      // Lấy profile để kiểm tra danh mục bị ẩn
      final profileSnap = await _firestore.collection('user_profiles').doc(ownerId).get();
      final hiddenCategories = <String>[];
      if (profileSnap.exists) {
        final data = profileSnap.data();
        if (data != null && data.containsKey('businessProfile')) {
          final bp = data['businessProfile'] as Map<String, dynamic>;
          if (bp.containsKey('hiddenCategories')) {
            hiddenCategories.addAll(List<String>.from(bp['hiddenCategories'] as List));
          }
        }
      }

      final collections = [
        {'name': 'Thuê xe', 'col': 'business_transport_services'},
        {'name': 'Vé máy bay', 'col': 'business_flight_ticket_services'},
        {'name': 'Vé tàu/phà', 'col': 'business_ship_ticket_services'},
        {'name': 'Vé tàu hỏa', 'col': 'business_train_ticket_services'},
        {'name': 'Vé xe khách', 'col': 'business_bus_ticket_services'},
        {'name': 'Khách sạn', 'col': 'business_hotel_services'},
        {'name': 'Hướng dẫn viên', 'col': 'business_guide_services'},
        {'name': 'Chụp ảnh', 'col': 'business_photographer_services'},
        {'name': 'Thuê đồ', 'col': 'business_clothes_services'},
        {'name': 'Ẩm thực', 'col': 'business_food_services'},
      ];

      final futures = collections.map((c) async {
        final colName = c['col']!;
        // if (hiddenCategories.contains(colName)) return <Map<String, dynamic>>[];

        try {
          final snap = await _firestore
              .collection(colName)
              .where('ownerId', isEqualTo: ownerId)
              .limit(5)
              .get();

          return snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            data['categoryLabel'] = c['name'];
            return data;
          }).toList();
        } catch (e) {
          print('Error fetching $colName: $e');
          return <Map<String, dynamic>>[];
        }
      });

      final results = await Future.wait(futures);
      final allServices = results.expand((x) => x).toList();
      
      // Sắp xếp mới nhất
      allServices.sort((a, b) {
        final ta = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final tb = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

      return allServices.take(10).toList();
    } catch (e) {
      return [];
    }
  }
}

