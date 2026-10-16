import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseMarketingService {
  static final FirebaseMarketingService _instance =
      FirebaseMarketingService._internal();

  factory FirebaseMarketingService() => _instance;

  FirebaseMarketingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _campaignsCollection =>
      _firestore.collection('business_campaigns');

  CollectionReference<Map<String, dynamic>> get _vouchersCollection =>
      _firestore.collection('business_vouchers');

  CollectionReference<Map<String, dynamic>> get _adsCollection =>
      _firestore.collection('business_ads');

  Stream<List<Map<String, dynamic>>> streamCampaigns() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _campaignsCollection
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> streamVouchers() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _vouchersCollection
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getVouchersByOwner(String ownerId) async {
    try {
      final snap = await _vouchersCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();
      final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      return docs.where((d) => d['status'] == 'Dang hoat dong').toList();
    } catch (e) {
      print('Error fetching vouchers: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamAds() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _adsCollection
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> createCampaign({
    required String name,
    required double budget,
    required String duration,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Chua dang nhap');
    await _campaignsCollection.add({
      'ownerId': uid,
      'name': name,
      'budget': budget,
      'duration': duration,
      'status': 'Dang chay',
      'reach': 0,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> createVoucher({
    required String code,
    required String discount,
    required int quantity,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Chua dang nhap');
    await _vouchersCollection.add({
      'ownerId': uid,
      'code': code,
      'discount': discount,
      'quantity': quantity,
      'used': 0,
      'status': 'Dang hoat dong',
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> createAd({
    required String content,
    required double budget,
    required String duration,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Chua dang nhap');
    await _adsCollection.add({
      'ownerId': uid,
      'name': content,
      'budget': budget,
      'duration': duration,
      'status': 'Dang chay',
      'clicks': 0,
      'createdAt': Timestamp.now(),
    });
  }
}
