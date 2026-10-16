import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/menu_models.dart';

/// Dịch vụ Firebase cho tính năng menu - lưu dữ liệu theo từng tài khoản người dùng
class FirebaseMenuService {
  // Singleton pattern
  static final FirebaseMenuService _instance = FirebaseMenuService._internal();
  factory FirebaseMenuService() => _instance;
  FirebaseMenuService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random();

  // Lấy ID người dùng hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  /// Tạo mã chuyến đi 6 chữ số độc nhất
  Future<String> _generateUniqueTripCode() async {
    String code;
    bool isUnique = false;

    do {
      // Tạo mã 6 chữ số ngẫu nhiên
      code = (100000 + _random.nextInt(900000)).toString();

      // Kiểm tra mã đã tồn tại chưa
      final existing = await _tripsCollection
          .where('tripCode', isEqualTo: code)
          .limit(1)
          .get();

      isUnique = existing.docs.isEmpty;
    } while (!isUnique);

    return code;
  }

  /// Tìm chuyến đi theo mã 6 chữ số hoặc ID tài liệu (để tương thích cũ)
  Future<TripModel?> getTripByCode(String code) async {
    // Trước tiên tìm bằng trường tripCode
    final snap = await _tripsCollection
        .where('tripCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return TripModel.fromFirestore(snap.docs.first);
    }

    // Dự phòng: nếu mã dài hơn 6 ký tự, tìm bằng ID tài liệu
    // (for backwards compatibility with old trips)
    if (code.length > 6) {
      final doc = await _tripsCollection.doc(code).get();
      if (doc.exists) {
        return TripModel.fromFirestore(doc);
      }
    }

    return null;
  }

  // Tham chiếu collection - dữ liệu lưu dưới subcollection của người dùng
  CollectionReference<Map<String, dynamic>> get _notesCollection =>
      _firestore.collection('menu_notes');

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('menu_expenses');

  CollectionReference<Map<String, dynamic>> get _tripsCollection =>
      _firestore.collection('menu_trips');

  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _firestore.collection('menu_budgets');

  CollectionReference<Map<String, dynamic>> get _paymentSplitsCollection =>
      _firestore.collection('menu_payment_splits');

  CollectionReference<Map<String, dynamic>> get _savedPlacesCollection =>
      _firestore.collection('menu_saved_places');

  CollectionReference<Map<String, dynamic>> get _itinerariesCollection =>
      _firestore.collection('menu_itineraries');

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('menu_orders');

  // ==================== GHI CHÚ (NOTES) ====================

  /// Luồng (stream) tất cả ghi chú của người dùng hiện tại
  Stream<List<NoteModel>> getNotesStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _notesCollection
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => NoteModel.fromFirestore(d)).toList(),
        );
  }

  /// Lấy tất cả ghi chú của người dùng (fetch một lần)
  Future<List<NoteModel>> getNotes() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snap = await _notesCollection
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .get();

    return snap.docs.map((d) => NoteModel.fromFirestore(d)).toList();
  }

  /// Thêm ghi chú mới
  Future<NoteModel?> addNote({
    required String title,
    required String content,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final now = DateTime.now();
    final docRef = _notesCollection.doc();
    final note = NoteModel(
      id: docRef.id,
      userId: uid,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(note.toFirestore());
    return note;
  }

  /// Cập nhật ghi chú hiện có
  Future<void> updateNote(NoteModel note) async {
    final uid = currentUserId;
    if (uid == null || note.userId != uid) return;

    await _notesCollection.doc(note.id).update({
      'title': note.title,
      'content': note.content,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Xóa ghi chú
  Future<void> deleteNote(String noteId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _notesCollection.doc(noteId).delete();
  }

  // ==================== CHI PHÍ (EXPENSES) ====================

  /// Luồng tất cả chi phí của người dùng hiện tại
  Stream<List<ExpenseModel>> getExpensesStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _expensesCollection
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList(),
        );
  }

  /// Lấy chi phí với bộ lọc ngày
  Future<List<ExpenseModel>> getExpenses({DateTime? startDate}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    Query<Map<String, dynamic>> query = _expensesCollection.where(
      'userId',
      isEqualTo: uid,
    );

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    final snap = await query.orderBy('date', descending: true).get();
    return snap.docs.map((d) => ExpenseModel.fromFirestore(d)).toList();
  }

  /// Thêm chi phí mới
  Future<ExpenseModel?> addExpense({
    required double amount,
    required String category,
    required String note,
    required DateTime date,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _expensesCollection.doc();
    final expense = ExpenseModel(
      id: docRef.id,
      userId: uid,
      amount: amount,
      category: category,
      note: note,
      date: date,
      createdAt: DateTime.now(),
    );

    await docRef.set(expense.toFirestore());
    return expense;
  }

  /// Xóa chi phí
  Future<void> deleteExpense(String expenseId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _expensesCollection.doc(expenseId).delete();
  }

  // ==================== CHUYẾN ĐI (TRIPS) ====================

  /// Stream of all trips for current user (owned or as member)
  Stream<List<TripModel>> getTripsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    // Lấy tất cả chuyến đi và lọc theo thành viên hoặc chủ sở hữu (bao gồm cả tạo và tham gia)
    return _tripsCollection.snapshots().map((snap) {
      final trips = snap.docs
          .map((d) => TripModel.fromFirestore(d))
          .where((t) => t.members.contains(uid) || t.userId == uid)
          .toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    });
  }

  /// Stream of trips owned by current user only
  Stream<List<TripModel>> getOwnedTripsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    // sự cố chỉ mục hợp nhất tương tự có thể xảy ra với stream; thử
    // the straightforward query and fall back to client sorting if it fails
    try {
      return _tripsCollection
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs.map((d) => TripModel.fromFirestore(d)).toList(),
          );
    } catch (e) {
      return _tripsCollection.where('userId', isEqualTo: uid).snapshots().map((
        snap,
      ) {
        final trips = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
        trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return trips;
      });
    }
  }

  /// Stream of active trips (pending or active status) for current user
  /// Includes trips user created AND trips user joined as member
  Stream<List<TripModel>> getActiveTripsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    // Lấy tất cả chuyến đi và lọc theo thành viên hoặc chủ sở hữu
    return _tripsCollection.snapshots().map((snap) {
      final trips = snap.docs
          .map((d) => TripModel.fromFirestore(d))
          .where(
            (t) =>
                (t.status == TripStatus.pending ||
                    t.status == TripStatus.gathering ||
                    t.status == TripStatus.active) &&
                (t.members.contains(uid) || t.userId == uid),
          )
          .toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    });
  }

  /// Get all trips for current user (owned or joined as member)
  Future<List<TripModel>> getTrips() async {
    final uid = currentUserId;
    if (uid == null) {
      debugPrint('getTrips: currentUserId is null');
      return [];
    }

    debugPrint('getTrips: fetching trips for user $uid');

    try {
      // Lần đầu: lấy chuyến đi mà người dùng là thành viên
      final memberSnap = await _tripsCollection
          .where('members', arrayContains: uid)
          .get();
      final memberTrips = memberSnap.docs
          .map((d) => TripModel.fromFirestore(d))
          .toList();
      debugPrint('getTrips: found ${memberTrips.length} trips as member');

      // Cũng lấy chuyến đi mà người dùng là chủ (trường hợp mảng thành viên chưa đầy đủ)
      final ownerSnap = await _tripsCollection
          .where('userId', isEqualTo: uid)
          .get();
      final ownerTrips = ownerSnap.docs
          .map((d) => TripModel.fromFirestore(d))
          .toList();
      debugPrint('getTrips: found ${ownerTrips.length} trips as owner');

      // Kết hợp và loại trùng
      final allTrips = <String, TripModel>{};
      for (final t in memberTrips) {
        allTrips[t.id] = t;
      }
      for (final t in ownerTrips) {
        allTrips[t.id] = t;
      }

      final trips = allTrips.values.toList();
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('getTrips: returning ${trips.length} total trips');
      return trips;
    } catch (e) {
      debugPrint('getTrips error: $e');
      // fallback: try getting owned trips only
      try {
        final snap = await _tripsCollection
            .where('userId', isEqualTo: uid)
            .get();
        final trips = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
        trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return trips;
      } catch (_) {
        return [];
      }
    }
  }

  /// Add a new trip with enhanced features
  Future<TripModel?> addTrip({
    required String name,
    required String location,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? locations,
    int maxMembers = 10,
    double? estimatedCost,
    DateTime? departureTime,
    DateTime? gatheringTime,
    String startingLocation = '',
    String? password,
    Map<String, double>? costBreakdown,
    String? conversationId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _tripsCollection.doc();
    final allLocations = locations ?? (location.isNotEmpty ? [location] : []);

    // Tạo mã chuyến đi 6 chữ số độc nhất
    final tripCode = await _generateUniqueTripCode();

    final trip = TripModel(
      id: docRef.id,
      tripCode: tripCode,
      userId: uid,
      name: name,
      location: location,
      locations: allLocations,
      description: description,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      members: [uid], // Creator is automatically a member
      maxMembers: maxMembers,
      status: TripStatus.pending,
      notificationSent: false,
      estimatedCost: estimatedCost,
      departureTime: departureTime,
      gatheringTime: gatheringTime,
      startingLocation: startingLocation,
      password: password,
      costBreakdown: costBreakdown ?? {},
      conversationId: conversationId,
    );

    await docRef.set(trip.toFirestore());
    return trip;
  }

  /// Update a trip (only owner can update)
  /// Returns the updated trip if successful
  Future<TripModel?> updateTrip(TripModel trip) async {
    final uid = currentUserId;
    if (uid == null || trip.userId != uid) return null;

    await _tripsCollection.doc(trip.id).update(trip.toFirestore());
    return trip;
  }

  /// Update a trip with edit history tracking
  /// [changes] is a list of change descriptions, e.g. ["Đổi tên chuyến đi", "Đổi ngày bắt đầu"]
  Future<TripModel?> updateTripWithHistory({
    required TripModel oldTrip,
    required TripModel newTrip,
    required List<String> changes,
    String? editorName,
  }) async {
    final uid = currentUserId;
    if (uid == null || oldTrip.userId != uid) return null;

    if (changes.isEmpty) {
      // No changes, just update normally
      return updateTrip(newTrip);
    }

    // Create edit history entry
    final editEntry = TripEditHistory(
      editedAt: DateTime.now(),
      editedBy: uid,
      editedByName: editorName ?? '',
      changes: changes,
    );

    // Append to existing edit history
    final updatedEditHistory = [...oldTrip.editHistory, editEntry];
    final tripWithHistory = newTrip.copyWith(editHistory: updatedEditHistory);

    await _tripsCollection
        .doc(tripWithHistory.id)
        .update(tripWithHistory.toFirestore());
    return tripWithHistory;
  }

  /// Compare two trips and return a list of changes
  List<String> compareTripChanges(TripModel oldTrip, TripModel newTrip) {
    final changes = <String>[];

    if (oldTrip.name != newTrip.name) {
      changes.add('Đổi tên: "${oldTrip.name}" → "${newTrip.name}"');
    }
    if (oldTrip.description != newTrip.description) {
      changes.add('Cập nhật mô tả');
    }
    if (oldTrip.startDate != newTrip.startDate) {
      changes.add(
        'Đổi ngày bắt đầu: ${_formatDate(oldTrip.startDate)} → ${_formatDate(newTrip.startDate)}',
      );
    }
    if (oldTrip.endDate != newTrip.endDate) {
      changes.add(
        'Đổi ngày kết thúc: ${_formatDate(oldTrip.endDate)} → ${_formatDate(newTrip.endDate)}',
      );
    }
    if (oldTrip.maxMembers != newTrip.maxMembers) {
      changes.add(
        'Đổi số thành viên tối đa: ${oldTrip.maxMembers} → ${newTrip.maxMembers}',
      );
    }
    if (oldTrip.estimatedCost != newTrip.estimatedCost) {
      final oldCost = oldTrip.estimatedCost?.toStringAsFixed(0) ?? 'N/A';
      final newCost = newTrip.estimatedCost?.toStringAsFixed(0) ?? 'N/A';
      changes.add('Đổi chi phí ước tính: $oldCost → $newCost VNĐ');
    }
    if (oldTrip.departureTime != newTrip.departureTime) {
      changes.add('Đổi giờ xuất phát');
    }
    if (oldTrip.gatheringTime != newTrip.gatheringTime) {
      changes.add('Đổi giờ tập trung');
    }
    if (oldTrip.startingLocation != newTrip.startingLocation) {
      changes.add(
        'Đổi điểm tập trung: "${oldTrip.startingLocation}" → "${newTrip.startingLocation}"',
      );
    }

    // Compare locations
    final oldLocs = oldTrip.allLocations.join(', ');
    final newLocs = newTrip.allLocations.join(', ');
    if (oldLocs != newLocs) {
      changes.add('Đổi địa điểm');
    }

    return changes;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Update trip status
  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _tripsCollection.doc(tripId).update({'status': status.name});
  }

  /// Cancel a trip
  Future<void> cancelTrip(String tripId) async {
    await updateTripStatus(tripId, TripStatus.cancelled);
  }

  /// Complete a trip
  Future<void> completeTrip(String tripId) async {
    await updateTripStatus(tripId, TripStatus.completed);
  }

  /// Add a member to trip using 6-digit code
  /// Returns a tuple: (success, errorType, trip data)
  /// errorType: 'not_found', 'full', 'wrong_password', 'already_member', 'already_started', 'completed', 'cancelled', null
  Future<(bool success, String? errorType, TripModel? trip)> joinTripByCode(
    String tripCode, {
    String? password,
  }) async {
    final uid = currentUserId;
    if (uid == null) return (false, 'not_logged_in', null);

    // Find trip by code
    final trip = await getTripByCode(tripCode);
    if (trip == null) return (false, 'not_found', null);

    // Check if user can join this trip based on status
    if (!trip.canJoin) {
      if (trip.status == TripStatus.active) {
        return (false, 'already_started', trip);
      }
      if (trip.status == TripStatus.completed) {
        return (false, 'completed', trip);
      }
      if (trip.status == TripStatus.cancelled) {
        return (false, 'cancelled', trip);
      }
    }

    // Check password if trip requires it
    if (trip.hasPassword && trip.password != password) {
      return (false, 'wrong_password', trip);
    }

    if (trip.isFull) return (false, 'full', trip);
    if (trip.members.contains(uid)) {
      return (false, 'already_member', trip); // Already a member - show error
    }

    final updatedMembers = [...trip.members, uid];
    await _tripsCollection.doc(trip.id).update({'members': updatedMembers});

    final updatedTrip = trip.copyWith(members: updatedMembers);
    return (true, null, updatedTrip);
  }

  /// Add a member to trip by document ID (legacy support)
  /// Returns a tuple: (success, wasFull after joining, trip data)
  Future<(bool success, bool isFull, TripModel? trip)> joinTrip(
    String tripId,
  ) async {
    final uid = currentUserId;
    if (uid == null) return (false, false, null);

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return (false, false, null);

    final trip = TripModel.fromFirestore(doc);

    // Check if trip has already started, completed or cancelled
    if (trip.status == TripStatus.active ||
        trip.status == TripStatus.completed ||
        trip.status == TripStatus.cancelled) {
      return (false, false, trip);
    }

    if (trip.isFull) return (false, true, trip);
    if (trip.members.contains(uid)) {
      return (true, trip.isFull, trip); // Already a member
    }

    final updatedMembers = [...trip.members, uid];
    await _tripsCollection.doc(tripId).update({'members': updatedMembers});

    final updatedTrip = trip.copyWith(members: updatedMembers);
    return (true, updatedTrip.isFull, updatedTrip);
  }

  /// Get trip by ID
  Future<TripModel?> getTripById(String tripId) async {
    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return null;
    return TripModel.fromFirestore(doc);
  }

  /// Stream of a single trip by ID (real-time updates)
  Stream<TripModel?> getTripStreamById(String tripId) {
    return _tripsCollection.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TripModel.fromFirestore(doc);
    });
  }

  /// Remove a member from trip
  Future<void> leaveTrip(String tripId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return;

    final trip = TripModel.fromFirestore(doc);
    if (!trip.members.contains(uid)) return;
    if (trip.userId == uid) return; // Owner cannot leave

    final updatedMembers = trip.members.where((m) => m != uid).toList();
    await _tripsCollection.doc(tripId).update({'members': updatedMembers});
  }

  /// Owner removes a member from trip (kick)
  /// Returns true if successful
  Future<bool> removeMemberFromTrip(
    String tripId,
    String memberIdToRemove,
  ) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return false;

    final trip = TripModel.fromFirestore(doc);

    // Only owner can remove members
    if (trip.userId != uid) return false;

    // Cannot remove self (owner)
    if (memberIdToRemove == uid) return false;

    // cannot remove when trip is already active
    if (trip.status == TripStatus.active) return false;

    // Check if member exists
    if (!trip.members.contains(memberIdToRemove)) return false;

    final updatedMembers = trip.members
        .where((m) => m != memberIdToRemove)
        .toList();
    await _tripsCollection.doc(tripId).update({'members': updatedMembers});
    return true;
  }

  /// Transfer trip ownership to another member
  /// Returns true if successful
  Future<bool> transferOwnership(String tripId, String newOwnerId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return false;

    final trip = TripModel.fromFirestore(doc);

    // Only current owner can transfer
    if (trip.userId != uid) return false;

    // New owner must be a member
    if (!trip.members.contains(newOwnerId)) return false;

    // Cannot transfer to self
    if (newOwnerId == uid) return false;

    await _tripsCollection.doc(tripId).update({'userId': newOwnerId});
    return true;
  }

  /// Link a conversation (group chat) to the trip
  /// Any member can link if trip doesn't have a conversation yet
  Future<void> linkConversationToTrip(
    String tripId,
    String conversationId,
  ) async {
    final uid = currentUserId;
    if (uid == null) return;

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return;

    final trip = TripModel.fromFirestore(doc);

    // Must be a member
    if (!trip.members.contains(uid)) return;

    // Only link if no conversation exists yet
    if (trip.conversationId != null && trip.conversationId!.isNotEmpty) return;

    await _tripsCollection.doc(tripId).update({
      'conversationId': conversationId,
    });
  }

  /// Add a location to trip
  Future<void> addLocationToTrip(String tripId, String location) async {
    final uid = currentUserId;
    if (uid == null) return;

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return;

    final trip = TripModel.fromFirestore(doc);
    if (trip.userId != uid) return; // Only owner can add locations

    final updatedLocations = [...trip.locations, location];
    await _tripsCollection.doc(tripId).update({'locations': updatedLocations});
  }

  /// Remove a location from trip
  Future<void> removeLocationFromTrip(String tripId, int index) async {
    final uid = currentUserId;
    if (uid == null) return;

    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return;

    final trip = TripModel.fromFirestore(doc);
    if (trip.userId != uid) return;

    final updatedLocations = [...trip.locations];
    if (index >= 0 && index < updatedLocations.length) {
      updatedLocations.removeAt(index);
      await _tripsCollection.doc(tripId).update({
        'locations': updatedLocations,
      });
    }
  }

  /// Mark notification as sent for trip
  Future<void> markTripNotificationSent(String tripId) async {
    await _tripsCollection.doc(tripId).update({'notificationSent': true});
  }

  /// Get member names for a trip
  /// Returns a map of userId -> displayName
  Future<Map<String, String>> getMemberNames(List<String> memberIds) async {
    if (memberIds.isEmpty) return {};

    final Map<String, String> names = {};

    for (final uid in memberIds) {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        names[uid] = data?['displayName'] ?? data?['name'] ?? 'Người dùng';
      } else {
        names[uid] = 'Người dùng';
      }
    }

    return names;
  }

  /// Get trips that need notification (starting within 10 hours and notification not sent)
  /// Only returns trips owned by current user (owner triggers the notification)
  Future<List<TripModel>> getTripsNeedingNotification() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final now = DateTime.now();
    final tenHoursLater = now.add(const Duration(hours: 10));

    // Get pending trips owned by user where startDate is within 10 hours
    final snap = await _tripsCollection
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: TripStatus.pending.name)
        .where('notificationSent', isEqualTo: false)
        .get();

    return snap.docs
        .map((d) => TripModel.fromFirestore(d))
        .where(
          (trip) =>
              trip.startDate.isAfter(now) &&
              trip.startDate.isBefore(tenHoursLater),
        )
        .toList();
  }

  /// Update trip status based on current date
  Future<void> updateTripsStatusByDate() async {
    final uid = currentUserId;
    if (uid == null) return;

    final now = DateTime.now();
    // Get today's date at midnight for comparison
    final today = DateTime(now.year, now.month, now.day);

    final snap = await _tripsCollection.where('userId', isEqualTo: uid).get();

    for (final doc in snap.docs) {
      final trip = TripModel.fromFirestore(doc);

      // Skip already completed or cancelled trips
      if (trip.status == TripStatus.completed ||
          trip.status == TripStatus.cancelled) {
        continue;
      }

      // Get end date at the end of the day (23:59:59)
      final endDateEnd = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
        23,
        59,
        59,
      );

      // If trip has ended (current time is after end of end date), mark as completed
      if (now.isAfter(endDateEnd)) {
        await updateTripStatus(trip.id, TripStatus.completed);
        continue;
      }

      // Check departure time for active status
      if (trip.departureTime != null && now.isAfter(trip.departureTime!)) {
        if (trip.status != TripStatus.active) {
          await updateTripStatus(trip.id, TripStatus.active);
        }
        continue;
      }

      // Check gathering time for gathering status
      if (trip.gatheringTime != null && now.isAfter(trip.gatheringTime!)) {
        if (trip.status != TripStatus.gathering) {
          await updateTripStatus(trip.id, TripStatus.gathering);
        }
        continue;
      }

      // Fallback: If no gathering/departure time but trip date has started
      final startDateStart = DateTime(
        trip.startDate.year,
        trip.startDate.month,
        trip.startDate.day,
      );

      if (now.isAfter(startDateStart) ||
          now.isAtSameMomentAs(startDateStart) ||
          (today.year == startDateStart.year &&
              today.month == startDateStart.month &&
              today.day == startDateStart.day)) {
        // If no departure time set, just mark as active on start date
        if (trip.departureTime == null && trip.status != TripStatus.active) {
          await updateTripStatus(trip.id, TripStatus.active);
        }
      }
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _tripsCollection.doc(tripId).delete();
  }

  // ==================== BUDGETS ====================

  /// Stream of all budgets for current user
  Stream<List<BudgetModel>> getBudgetsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _budgetsCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => BudgetModel.fromFirestore(d)).toList(),
        );
  }

  /// Add a new budget
  Future<BudgetModel?> addBudget({
    String tripId = '',
    required String category,
    required double plannedAmount,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _budgetsCollection.doc();
    final budget = BudgetModel(
      id: docRef.id,
      userId: uid,
      tripId: tripId,
      category: category,
      plannedAmount: plannedAmount,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );

    await docRef.set(budget.toFirestore());
    return budget;
  }

  /// Update budget spent amount
  Future<void> updateBudgetSpent(String budgetId, double spentAmount) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _budgetsCollection.doc(budgetId).update({'spentAmount': spentAmount});
  }

  /// Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _budgetsCollection.doc(budgetId).delete();
  }

  // ==================== PAYMENT SPLITS ====================

  /// Stream of all payment splits for current user
  Stream<List<PaymentSplitModel>> getPaymentSplitsStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _paymentSplitsCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => PaymentSplitModel.fromFirestore(d)).toList(),
        );
  }

  /// Add a new payment split
  Future<PaymentSplitModel?> addPaymentSplit({
    required String title,
    required double totalAmount,
    required List<SplitMember> members,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _paymentSplitsCollection.doc();
    final split = PaymentSplitModel(
      id: docRef.id,
      userId: uid,
      title: title,
      totalAmount: totalAmount,
      members: members,
      createdAt: DateTime.now(),
    );

    await docRef.set(split.toFirestore());
    return split;
  }

  /// Update payment split (mark members as paid, etc.)
  Future<void> updatePaymentSplit(PaymentSplitModel split) async {
    final uid = currentUserId;
    if (uid == null || split.userId != uid) return;

    await _paymentSplitsCollection.doc(split.id).update(split.toFirestore());
  }

  /// Delete a payment split
  Future<void> deletePaymentSplit(String splitId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _paymentSplitsCollection.doc(splitId).delete();
  }

  // ==================== SAVED PLACES ====================

  /// Stream of all saved places for current user
  Stream<List<SavedPlaceModel>> getSavedPlacesStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _savedPlacesCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SavedPlaceModel.fromFirestore(d)).toList(),
        );
  }

  /// Add a new saved place
  Future<SavedPlaceModel?> addSavedPlace({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required String category,
    String? notes,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _savedPlacesCollection.doc();
    final place = SavedPlaceModel(
      id: docRef.id,
      userId: uid,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      category: category,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await docRef.set(place.toFirestore());
    return place;
  }

  /// Delete a saved place
  Future<void> deleteSavedPlace(String placeId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _savedPlacesCollection.doc(placeId).delete();
  }

  // ==================== ITINERARIES ====================

  /// Stream of all itineraries for current user
  Stream<List<ItineraryModel>> getItinerariesStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _itinerariesCollection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ItineraryModel.fromFirestore(d)).toList(),
        );
  }

  /// Get itineraries for a specific trip
  Stream<List<ItineraryModel>> getItinerariesForTrip(String tripId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _itinerariesCollection
        .where('userId', isEqualTo: uid)
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ItineraryModel.fromFirestore(d)).toList(),
        );
  }

  /// Add a new itinerary
  Future<ItineraryModel?> addItinerary({
    required String tripId,
    required String title,
    required List<ItineraryItem> items,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _itinerariesCollection.doc();
    final itinerary = ItineraryModel(
      id: docRef.id,
      userId: uid,
      tripId: tripId,
      title: title,
      items: items,
      createdAt: DateTime.now(),
    );

    await docRef.set(itinerary.toFirestore());
    return itinerary;
  }

  /// Update an itinerary
  Future<void> updateItinerary(ItineraryModel itinerary) async {
    final uid = currentUserId;
    if (uid == null || itinerary.userId != uid) return;

    await _itinerariesCollection
        .doc(itinerary.id)
        .update(itinerary.toFirestore());
  }

  /// Delete an itinerary
  Future<void> deleteItinerary(String itineraryId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _itinerariesCollection.doc(itineraryId).delete();
  }

  // ==================== MIGRATION ====================

  /// Migrate notes from SharedPreferences to Firestore
  Future<int> migrateNotesFromLocal(
    List<Map<String, dynamic>> localNotes,
  ) async {
    final uid = currentUserId;
    if (uid == null) return 0;

    int count = 0;
    for (final note in localNotes) {
      try {
        await addNote(
          title: note['title'] ?? '',
          content: note['content'] ?? '',
        );
        count++;
      } catch (_) {}
    }
    return count;
  }

  /// Migrate expenses from SharedPreferences to Firestore
  Future<int> migrateExpensesFromLocal(
    List<Map<String, dynamic>> localExpenses,
  ) async {
    final uid = currentUserId;
    if (uid == null) return 0;

    int count = 0;
    for (final exp in localExpenses) {
      try {
        final date = DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now();
        await addExpense(
          amount: (exp['amount'] as num?)?.toDouble() ?? 0,
          category: exp['category'] ?? 'Other',
          note: exp['note'] ?? '',
          date: date,
        );
        count++;
      } catch (_) {}
    }
    return count;
  }

  // ==================== BOOKINGS ====================

  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('menu_bookings');

  /// Stream of all bookings for current user
  Stream<List<BookingModel>> getBookingsStream({String? type}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _bookingsCollection.where(
      'userId',
      isEqualTo: uid,
    );

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 8),
          onTimeout: (sink) {
            sink.addError(TimeoutException('Business bookings timeout'));
          },
        )
        .map(
          (snap) =>
              snap.docs.map((d) => BookingModel.fromFirestore(d)).toList(),
        )
        .handleError((error) {
          print('Bookings stream error (index may be building): $error');
          return <BookingModel>[];
        });
  }

  /// Stream of all bookings for current business account
  Stream<List<BookingModel>> getBusinessBookingsStream({String? type}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _bookingsCollection.where(
      'businessId',
      isEqualTo: uid,
    );

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .timeout(
          const Duration(seconds: 8),
          onTimeout: (sink) {
            sink.addError(TimeoutException('Business bookings timeout'));
          },
        )
        .map(
          (snap) =>
              snap.docs.map((d) => BookingModel.fromFirestore(d)).toList(),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) {
              debugPrint(
                'Business bookings stream error (index may be building): $error',
              );
              sink.addError(error, stackTrace);
            },
          ),
        );
  }

  /// Get bookings by type
  Future<List<BookingModel>> getBookings({String? type, String? status}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      Query<Map<String, dynamic>> query = _bookingsCollection.where(
        'userId',
        isEqualTo: uid,
      );

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snap = await query.orderBy('createdAt', descending: true).get();
      return snap.docs.map((d) => BookingModel.fromFirestore(d)).toList();
    } catch (e) {
      print('Error fetching bookings (index may be building): $e');
      return [];
    }
  }

  /// Add a new booking
  Future<BookingModel?> addBooking({
    required String type,
    required String serviceName,
    String? serviceId,
    String? businessId,
    required DateTime startDate,
    required DateTime endDate,
    int quantity = 1,
    required double totalPrice,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final docRef = _bookingsCollection.doc();
    final booking = BookingModel(
      id: docRef.id,
      userId: uid,
      businessId: businessId,
      type: type,
      serviceName: serviceName,
      serviceId: serviceId,
      startDate: startDate,
      endDate: endDate,
      quantity: quantity,
      totalPrice: totalPrice,
      status: 'upcoming',
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    await docRef.set(booking.toFirestore());
    return booking;
  }

  /// Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    String status, {
    DateTime? completedAt,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final updateData = <String, dynamic>{'status': status};
    if (completedAt != null) {
      updateData['completedAt'] = Timestamp.fromDate(completedAt);
    }

    await _bookingsCollection.doc(bookingId).update(updateData);
  }

  /// Add review to booking
  Future<void> addBookingReview(
    String bookingId,
    String review,
    int rating,
  ) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _bookingsCollection.doc(bookingId).update({
      'review': review,
      'rating': rating,
    });
  }

  /// Delete a booking
  Future<void> deleteBooking(String bookingId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _bookingsCollection.doc(bookingId).delete();
  }

  // ==================== FAVORITES ====================

  CollectionReference<Map<String, dynamic>> get _favoritesCollection =>
      _firestore.collection('menu_favorites');

  /// Stream of favorites for current user
  Stream<List<FavoriteModel>> getFavoritesStream({String? type}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _favoritesCollection.where(
      'userId',
      isEqualTo: uid,
    );

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FavoriteModel.fromFirestore(d)).toList(),
        );
  }

  /// Check if item is favorited
  Future<bool> isFavorite(String type, String itemId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final snap = await _favoritesCollection
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: type)
        .where('itemId', isEqualTo: itemId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  /// Add to favorites
  Future<FavoriteModel?> addFavorite({
    required String type,
    required String itemId,
    required String itemName,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;

    // Check if already favorited
    if (await isFavorite(type, itemId)) return null;

    final docRef = _favoritesCollection.doc();
    final fav = FavoriteModel(
      id: docRef.id,
      userId: uid,
      type: type,
      itemId: itemId,
      itemName: itemName,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    await docRef.set(fav.toFirestore());
    return fav;
  }

  /// Remove from favorites
  Future<void> removeFavorite(String type, String itemId) async {
    final uid = currentUserId;
    if (uid == null) return;

    final snap = await _favoritesCollection
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: type)
        .where('itemId', isEqualTo: itemId)
        .get();

    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// Toggle favorite
  Future<bool> toggleFavorite({
    required String type,
    required String itemId,
    required String itemName,
    Map<String, dynamic>? metadata,
  }) async {
    if (await isFavorite(type, itemId)) {
      await removeFavorite(type, itemId);
      return false;
    } else {
      await addFavorite(
        type: type,
        itemId: itemId,
        itemName: itemName,
        metadata: metadata,
      );
      return true;
    }
  }

  // ==================== ĐƠN HÀNG CỦA BẠN (YOUR ORDERS) ====================

  /// Lắng nghe danh sách đơn hàng của user, sắp xếp theo thời gian mới nhất
  Stream<List<Map<String, dynamic>>> streamMyOrders({
    String? statusFilter,
    String? typeFilter,
  }) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = _ordersCollection.where(
      'userId',
      isEqualTo: uid,
    );

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    if (typeFilter != null && typeFilter.isNotEmpty) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Lắng nghe danh sách đơn hàng của chủ cửa hàng
  Stream<List<Map<String, dynamic>>> streamBusinessOrders() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _ordersCollection.where('ownerId', isEqualTo: uid).snapshots().map((
      snap,
    ) {
      try {
        final list = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        list.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        return list;
      } catch (e) {
        print('Error mapping orders: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? ticketCode,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final data = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (ticketCode != null) {
      data['ticketCode'] = ticketCode;
    }

    await _ordersCollection.doc(orderId).update(data);
  }

  /// Delete an order
  Future<void> deleteOrder(String orderId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _ordersCollection.doc(orderId).delete();
  }

  /// Tạo đơn hàng
  Future<void> createOrder({
    required String storeName,
    required String itemName,
    required String itemImage,
    required double price,
    required int quantity,
    required String status,
    String? ownerId,
    String? type,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    String finalStatus = status;
    String? ticketCode;

    if (ownerId != null &&
        ownerId.isNotEmpty &&
        (status == 'pending' || status == 'Chờ xác nhận')) {
      try {
        final profileDoc = await _firestore
            .collection('user_profiles')
            .doc(ownerId)
            .get();
        if (profileDoc.exists) {
          final autoApprove = profileDoc.data()?['autoApproveOrders'] == true;
          if (autoApprove) {
            final isTicket =
                storeName.toLowerCase().contains('vé') ||
                storeName.toLowerCase().contains('máy bay') ||
                storeName.toLowerCase().contains('tàu') ||
                storeName.toLowerCase().contains('xe khách');
            if (isTicket) {
              finalStatus = 'delivered';
              ticketCode =
                  'TICKET-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
            } else {
              finalStatus = 'processing';
            }
          }
        }
      } catch (e) {
        print('Lỗi kiểm tra tự động duyệt: $e');
      }
    }

    final data = {
      'userId': uid,
      'ownerId': ownerId ?? '',
      'type': type ?? '',
      'storeName': storeName,
      'items': [
        {
          'name': itemName,
          'image': itemImage,
          'price': price,
          'quantity': quantity,
        },
      ],
      'totalPrice': price * quantity,
      'status': finalStatus,
      'rating': null,
      'review': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (ticketCode != null) {
      data['ticketCode'] = ticketCode;
    }

    await _ordersCollection.add(data);
  }

  /// Gửi đánh giá cho đơn hàng
  Future<void> submitOrderReview(
    String orderId,
    double rating,
    String review,
  ) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _ordersCollection.doc(orderId).update({
      'rating': rating,
      'review': review,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
