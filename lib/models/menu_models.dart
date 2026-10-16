import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho Ghi chú (Notes)
class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model cho Chi tiêu (Expense)
class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Other',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Trạng thái chuyến đi
enum TripStatus {
  pending, // Chưa bắt đầu
  gathering, // Đang tập trung (từ giờ tập trung đến giờ xuất phát)
  active, // Đang diễn ra (từ giờ xuất phát)
  completed, // Đã hoàn thành
  cancelled, // Đã hủy
}

TripStatus _tripStatusFromString(String? value) {
  if (value == null) return TripStatus.pending;
  return TripStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TripStatus.pending,
  );
}

/// Model lưu lịch sử chỉnh sửa chuyến đi
class TripEditHistory {
  final DateTime editedAt;
  final String editedBy; // User ID người chỉnh sửa
  final String editedByName; // Tên người chỉnh sửa
  final List<String> changes; // Danh sách các thay đổi

  TripEditHistory({
    required this.editedAt,
    required this.editedBy,
    this.editedByName = '',
    required this.changes,
  });

  factory TripEditHistory.fromMap(Map<String, dynamic> map) {
    return TripEditHistory(
      editedAt: (map['editedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedBy: map['editedBy'] ?? '',
      editedByName: map['editedByName'] ?? '',
      changes: List<String>.from(map['changes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'editedAt': Timestamp.fromDate(editedAt),
      'editedBy': editedBy,
      'editedByName': editedByName,
      'changes': changes,
    };
  }

  /// Format thời gian chỉnh sửa
  String get formattedTime {
    return '${editedAt.hour.toString().padLeft(2, '0')}:${editedAt.minute.toString().padLeft(2, '0')} '
        '${editedAt.day.toString().padLeft(2, '0')}/${editedAt.month.toString().padLeft(2, '0')}/${editedAt.year}';
  }
}

/// Model cho Chuyến đi (Trip)
class TripModel {
  final String id;
  final String tripCode; // Mã chuyến đi 6 số
  final String userId;
  final String name;
  final String location; // Backward compatibility
  final List<String> locations; // Multiple locations support
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final List<String> members; // List of user IDs who joined
  final int maxMembers; // Maximum number of members allowed
  final TripStatus status;
  final bool notificationSent; // Track if 10-hour notification was sent
  final double? estimatedCost; // Chi phí ước tính
  final DateTime? departureTime; // Giờ xuất phát
  final DateTime? gatheringTime; // Giờ tập trung
  final String startingLocation; // Địa điểm bắt đầu
  final String? password; // Mật khẩu (tùy chọn)
  final Map<String, double> costBreakdown; // Chi tiết chi phí
  final String? conversationId; // ID của nhóm chat liên kết
  final List<TripEditHistory> editHistory; // Lịch sử chỉnh sửa

  TripModel({
    required this.id,
    this.tripCode = '',
    required this.userId,
    required this.name,
    this.location = '',
    this.locations = const [],
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.members = const [],
    this.maxMembers = 10,
    this.status = TripStatus.pending,
    this.notificationSent = false,
    this.estimatedCost,
    this.departureTime,
    this.gatheringTime,
    this.startingLocation = '',
    this.password,
    this.costBreakdown = const {},
    this.conversationId,
    this.editHistory = const [],
  });

  /// Check if trip requires password
  bool get hasPassword => password != null && password!.isNotEmpty;

  /// Get all locations (combines single location with locations list)
  List<String> get allLocations {
    final List<String> all = [...locations];
    if (location.isNotEmpty && !all.contains(location)) {
      all.insert(0, location);
    }
    return all;
  }

  /// Get member count display string
  String get memberCountDisplay => '${members.length}/$maxMembers';

  /// Check if trip is full
  bool get isFull => members.length >= maxMembers;

  /// Get status display text in Vietnamese
  String get statusDisplayText {
    switch (status) {
      case TripStatus.pending:
        return 'Chưa bắt đầu';
      case TripStatus.gathering:
        return 'Đang tập trung';
      case TripStatus.active:
        return 'Đang diễn ra';
      case TripStatus.completed:
        return 'Đã hoàn thành';
      case TripStatus.cancelled:
        return 'Đã hủy';
    }
  }

  /// Check if today is the last day of the trip
  bool get isLastDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return today.year == endDay.year &&
        today.month == endDay.month &&
        today.day == endDay.day;
  }

  /// Check if today is within the trip dates (can complete)
  bool get isTodayInTripRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return (today.isAfter(startDay) || today.isAtSameMomentAs(startDay)) &&
        (today.isBefore(endDay) || today.isAtSameMomentAs(endDay));
  }

  /// Check if this is a multi-day trip
  bool get isMultiDayTrip {
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return endDay.isAfter(startDay);
  }

  /// Check if the owner can manually complete the trip
  /// - For single-day trips: can complete on that day
  /// - For multi-day trips: can only complete on the last day
  bool get canManuallyComplete {
    if (status != TripStatus.active) return false;
    if (isMultiDayTrip) {
      return isLastDay;
    }
    return isTodayInTripRange;
  }

  /// Check if within 1 hour of gathering time
  bool get isWithinOneHourOfGathering {
    if (gatheringTime == null) return false;
    final now = DateTime.now();
    final diff = gatheringTime!.difference(now);
    // Within 1 hour means gathering time is in the future but less than 1 hour away
    // OR gathering time has already passed
    return diff.inMinutes <= 60;
  }

  /// Check if owner can cancel the trip
  /// Can cancel if trip hasn't departed yet (before departure time)
  bool get canCancel {
    if (status == TripStatus.completed || status == TripStatus.cancelled) {
      return false;
    }
    if (status == TripStatus.active) return false;
    // Can cancel during pending or gathering (before departure)
    return true;
  }

  /// Check if users can join this trip
  /// Can join during pending or gathering status
  bool get canJoin {
    return status == TripStatus.pending || status == TripStatus.gathering;
  }

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel(
      id: doc.id,
      tripCode: data['tripCode'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      locations: List<String>.from(data['locations'] ?? []),
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      members: List<String>.from(data['members'] ?? []),
      maxMembers: data['maxMembers'] ?? 10,
      status: _tripStatusFromString(data['status']),
      notificationSent: data['notificationSent'] ?? false,
      estimatedCost: (data['estimatedCost'] as num?)?.toDouble(),
      departureTime: (data['departureTime'] as Timestamp?)?.toDate(),
      gatheringTime: (data['gatheringTime'] as Timestamp?)?.toDate(),
      startingLocation: data['startingLocation'] ?? '',
      password: data['password'],
      costBreakdown: Map<String, double>.from(
        (data['costBreakdown'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      conversationId: data['conversationId'],
      editHistory:
          (data['editHistory'] as List<dynamic>?)
              ?.map((e) => TripEditHistory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripCode': tripCode,
      'userId': userId,
      'name': name,
      'location': location,
      'locations': locations,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members,
      'maxMembers': maxMembers,
      'status': status.name,
      'notificationSent': notificationSent,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
      if (departureTime != null)
        'departureTime': Timestamp.fromDate(departureTime!),
      if (gatheringTime != null)
        'gatheringTime': Timestamp.fromDate(gatheringTime!),
      'startingLocation': startingLocation,
      if (password != null && password!.isNotEmpty) 'password': password,
      if (costBreakdown.isNotEmpty) 'costBreakdown': costBreakdown,
      if (conversationId != null) 'conversationId': conversationId,
      if (editHistory.isNotEmpty)
        'editHistory': editHistory.map((e) => e.toMap()).toList(),
    };
  }

  TripModel copyWith({
    String? id,
    String? tripCode,
    String? userId,
    String? name,
    String? location,
    List<String>? locations,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    List<String>? members,
    int? maxMembers,
    TripStatus? status,
    bool? notificationSent,
    double? estimatedCost,
    DateTime? departureTime,
    DateTime? gatheringTime,
    String? startingLocation,
    String? password,
    Map<String, double>? costBreakdown,
    String? conversationId,
    List<TripEditHistory>? editHistory,
  }) {
    return TripModel(
      id: id ?? this.id,
      tripCode: tripCode ?? this.tripCode,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      location: location ?? this.location,
      locations: locations ?? this.locations,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      status: status ?? this.status,
      notificationSent: notificationSent ?? this.notificationSent,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      departureTime: departureTime ?? this.departureTime,
      gatheringTime: gatheringTime ?? this.gatheringTime,
      startingLocation: startingLocation ?? this.startingLocation,
      password: password ?? this.password,
      costBreakdown: costBreakdown ?? this.costBreakdown,
      conversationId: conversationId ?? this.conversationId,
      editHistory: editHistory ?? this.editHistory,
    );
  }
}

/// Model cho Ngân sách (Budget)
class BudgetModel {
  final String id;
  final String userId;
  final String tripId; // Optional link to trip
  final String category;
  final double plannedAmount;
  final double spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.userId,
    this.tripId = '',
    required this.category,
    required this.plannedAmount,
    this.spentAmount = 0,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'] ?? '',
      category: data['category'] ?? '',
      plannedAmount: (data['plannedAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (data['spentAmount'] as num?)?.toDouble() ?? 0.0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tripId': tripId,
      'category': category,
      'plannedAmount': plannedAmount,
      'spentAmount': spentAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Model cho Thanh toán chia tiền (Payment Split)
class PaymentSplitModel {
  final String id;
  final String userId;
  final String title;
  final double totalAmount;
  final List<SplitMember> members;
  final DateTime createdAt;
  final bool isSettled;

  PaymentSplitModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalAmount,
    required this.members,
    required this.createdAt,
    this.isSettled = false,
  });

  factory PaymentSplitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final membersList = (data['members'] as List<dynamic>? ?? [])
        .map((m) => SplitMember.fromMap(m as Map<String, dynamic>))
        .toList();
    return PaymentSplitModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      members: membersList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSettled: data['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'totalAmount': totalAmount,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isSettled': isSettled,
    };
  }
}

class SplitMember {
  final String name;
  final double amount;
  final bool hasPaid;

  SplitMember({required this.name, required this.amount, this.hasPaid = false});

  factory SplitMember.fromMap(Map<String, dynamic> map) {
    return SplitMember(
      name: map['name'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      hasPaid: map['hasPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'amount': amount, 'hasPaid': hasPaid};
  }
}

/// Model cho Địa điểm yêu thích (Saved Places)
class SavedPlaceModel {
  final String id;
  final String userId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category; // restaurant, hotel, attraction, etc.
  final String? notes;
  final DateTime createdAt;

  SavedPlaceModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.notes,
    required this.createdAt,
  });

  factory SavedPlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedPlaceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Model cho Hành trình (Itinerary)
class ItineraryModel {
  final String id;
  final String userId;
  final String tripId;
  final String title;
  final List<ItineraryItem> items;
  final DateTime createdAt;

  ItineraryModel({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.title,
    required this.items,
    required this.createdAt,
  });

  factory ItineraryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => ItineraryItem.fromMap(item as Map<String, dynamic>))
        .toList();
    return ItineraryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      tripId: data['tripId'] ?? '',
      title: data['title'] ?? '',
      items: itemsList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tripId': tripId,
      'title': title,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ItineraryItem {
  final String time;
  final String activity;
  final String location;
  final String? notes;

  ItineraryItem({
    required this.time,
    required this.activity,
    required this.location,
    this.notes,
  });

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      time: map['time'] ?? '',
      activity: map['activity'] ?? '',
      location: map['location'] ?? '',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'activity': activity,
      'location': location,
      'notes': notes,
    };
  }
}

/// Model chung cho các loại đặt/thuê dịch vụ (Booking)
class BookingModel {
  final String id;
  final String userId;
  final String? businessId;
  final String type; // hotel, guide, photographer, clothes
  final String serviceName;
  final String? serviceId;
  final DateTime startDate;
  final DateTime endDate;
  final int quantity; // rooms, days, hours
  final double totalPrice;
  final String status; // upcoming, completed, cancelled
  final Map<String, dynamic>? metadata; // extra info like rooms, guests, etc
  final String? review;
  final int? rating;
  final DateTime createdAt;
  final DateTime? completedAt;

  BookingModel({
    required this.id,
    required this.userId,
    this.businessId,
    required this.type,
    required this.serviceName,
    this.serviceId,
    required this.startDate,
    required this.endDate,
    this.quantity = 1,
    required this.totalPrice,
    this.status = 'upcoming',
    this.metadata,
    this.review,
    this.rating,
    required this.createdAt,
    this.completedAt,
  });

  /// Helper to access payment details if they were stored inside [metadata].
  Map<String, dynamic>? get payment =>
      metadata != null ? metadata!['payment'] as Map<String, dynamic>? : null;

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessId: data['businessId'] as String?,
      type: data['type'] ?? '',
      serviceName: data['serviceName'] ?? '',
      serviceId: data['serviceId'],
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: data['quantity'] ?? 1,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'upcoming',
      metadata: data['metadata'] as Map<String, dynamic>?,
      review: data['review'],
      rating: data['rating'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (businessId != null) 'businessId': businessId,
      'type': type,
      'serviceName': serviceName,
      'serviceId': serviceId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status,
      'metadata': metadata,
      'review': review,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? type,
    String? serviceName,
    String? serviceId,
    DateTime? startDate,
    DateTime? endDate,
    int? quantity,
    double? totalPrice,
    String? status,
    Map<String, dynamic>? metadata,
    String? review,
    int? rating,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      serviceName: serviceName ?? this.serviceName,
      serviceId: serviceId ?? this.serviceId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      review: review ?? this.review,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Model cho Yêu thích (Favorites) - lưu các mục yêu thích
class FavoriteModel {
  final String id;
  final String userId;
  final String type; // guide, photographer, clothes, hotel
  final String itemId;
  final String itemName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.itemId,
    required this.itemName,
    this.metadata,
    required this.createdAt,
  });

  factory FavoriteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'itemId': itemId,
      'itemName': itemName,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
