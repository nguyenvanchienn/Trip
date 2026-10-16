class Hospital {
  final String name;
  final String type;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final double rating;
  final String phone;
  final bool isOpen;
  final String openTime;
  final List<String> services;

  Hospital({
    required this.name,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.rating,
    required this.phone,
    required this.isOpen,
    required this.openTime,
    required this.services,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      name: json['name'] as String,
      type: json['type'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      phone: json['phone'] as String,
      isOpen: json['isOpen'] as bool,
      openTime: json['openTime'] as String,
      services: List<String>.from(json['services'] ?? []),
    );
  }

  /// convert to the old map representation used by the static cards
  Map<String, dynamic> toJsonMap() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'rating': rating,
      'phone': phone,
      'isOpen': isOpen,
      'openTime': openTime,
      'services': services,
    };
  }
}

class Atm {
  final String name;
  final String bank;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final bool is24h;
  final bool hasDeposit;
  final List<String> services;

  Atm({
    required this.name,
    required this.bank,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.is24h,
    required this.hasDeposit,
    required this.services,
  });

  factory Atm.fromJson(Map<String, dynamic> json) {
    return Atm(
      name: json['name'] as String,
      bank: json['bank'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      is24h: json['is24h'] as bool,
      hasDeposit: json['hasDeposit'] as bool,
      services: List<String>.from(json['services'] ?? []),
    );
  }
}
