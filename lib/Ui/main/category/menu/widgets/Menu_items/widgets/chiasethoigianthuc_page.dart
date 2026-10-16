import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChiaSeThoiGianThucPage extends StatefulWidget {
  /// When [sessionId] is provided the page acts as a viewer; otherwise
  /// the page is a host that can start/stop sharing and will create a
  /// session in Firestore.
  const ChiaSeThoiGianThucPage({super.key, this.sessionId});

  final String? sessionId;

  @override
  State<ChiaSeThoiGianThucPage> createState() => _ChiaSeThoiGianThucPageState();
}

class _ChiaSeThoiGianThucPageState extends State<ChiaSeThoiGianThucPage> {
  bool _isSharing = false;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  StreamSubscription<QuerySnapshot>? _viewersSubscription;

  double _lat = 10.762622; // will be replaced by real location on init
  double _lng = 106.660172;
  DateTime? _lastUpdated;

  /// request permission and try to read the current location once
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        _lastUpdated = DateTime.now();
      });
      _mapController.move(LatLng(_lat, _lng), 13.0);
    } catch (_) {}
  }

  final List<String> _viewers = [];

  String? _sessionId;
  String _shareLink = '';

  static const _prefsKey = 'realtime_share_session';

  // map controller for displaying current position
  final MapController _mapController = MapController();

  bool get _isViewer => widget.sessionId != null;

  Future<void> _startSharing() async {
    // ensure location permission
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập vị trí')),
        );
      }
      return;
    }

    setState(() {
      _isSharing = true;
      _lastUpdated = DateTime.now();
    });

    // try to grab immediate current location so session starts with accurate coords
    try {
      final p = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = p.latitude;
          _lng = p.longitude;
          _lastUpdated = DateTime.now();
        });
        _mapController.move(LatLng(_lat, _lng), 13.0);
      }
    } catch (_) {}

    // create a Firestore session document and remember its id
    final doc = await FirebaseFirestore.instance
        .collection('location_shares')
        .add({
          'lat': _lat,
          'lng': _lng,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
    _sessionId = doc.id;
    _shareLink = 'https://trip.app/share/$_sessionId';
    // persist so leaving the page doesn't drop the session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _sessionId!);

    // start listening for viewers joining
    _viewersSubscription = FirebaseFirestore.instance
        .collection('location_shares')
        .doc(_sessionId)
        .collection('viewers')
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() {
              _viewers.clear();
              _viewers.addAll(
                snap.docs.map((d) => d.data()['name'] as String? ?? d.id),
              );
            });
          }
        });

    // start receiving position updates
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            distanceFilter: 5,
            // You can adjust accuracy or other options here if needed
          ),
        ).listen(
          (Position pos) {
            if (!mounted) return;
            setState(() {
              _lat = pos.latitude;
              _lng = pos.longitude;
              _lastUpdated = DateTime.now();
            });
            // move map so host sees current position immediately
            _mapController.move(LatLng(_lat, _lng), 13.0);
            // push update to Firestore
            if (_sessionId != null) {
              FirebaseFirestore.instance
                  .collection('location_shares')
                  .doc(_sessionId)
                  .set({
                    'lat': _lat,
                    'lng': _lng,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
            }
          },
          onError: (error) {
            // Handle location permission errors gracefully
            debugPrint('Position stream error: $error');
          },
        );

    // also grab one immediate position
    try {
      final p = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = p.latitude;
          _lng = p.longitude;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (_) {}
  }

  Future<void> _stopSharing() async {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _viewersSubscription?.cancel();
    _viewersSubscription = null;
    // forget persisted session id
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (mounted) {
      setState(() {
        _isSharing = false;
      });
    }
  }

  void _toggleSharing() {
    if (_isSharing) {
      _stopSharing();
    } else {
      _startSharing();
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép link chia sẻ')));
  }

  Future<void> _invite() async {
    // don't need to persist anything; invites only make sense when
    // sharing is active, so nothing extra to do here.
    final nameController = TextEditingController();
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mời người dùng'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Tên hoặc email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(nameController.text.trim()),
            child: const Text('Mời'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      setState(() => _viewers.add(res));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã mời $res')));
    }
  }

  @override
  void initState() {
    super.initState();
    // if we previously started sharing and haven't stopped, restore
    _restoreSession();

    if (!_isViewer) {
      // get a one‑time fix so initial UI shows correct coords
      _initLocation();
    }

    if (_isViewer) {
      _attachAsViewer();
    }
  }

  /// restore a previously persisted session if available
  Future<void> _restoreSession() async {
    if (_isViewer) return;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefsKey);
    if (id != null) {
      // we were sharing previously, so resume
      _sessionId = id;
      _shareLink = 'https://trip.app/share/$_sessionId';
      setState(() {
        _isSharing = true;
      });
      // start the viewers listener and position stream like in _startSharing
      _viewersSubscription = FirebaseFirestore.instance
          .collection('location_shares')
          .doc(_sessionId)
          .collection('viewers')
          .snapshots()
          .listen((snap) {
            if (mounted) {
              setState(() {
                _viewers.clear();
                _viewers.addAll(
                  snap.docs.map((d) => d.data()['name'] as String? ?? d.id),
                );
              });
            }
          });
      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(distanceFilter: 5),
          ).listen(
            (Position pos) {
              if (!mounted) return;
              setState(() {
                _lat = pos.latitude;
                _lng = pos.longitude;
                _lastUpdated = DateTime.now();
              });
              _mapController.move(LatLng(_lat, _lng), 13.0);
              if (_sessionId != null) {
                FirebaseFirestore.instance
                    .collection('location_shares')
                    .doc(_sessionId)
                    .set({
                      'lat': _lat,
                      'lng': _lng,
                      'lastUpdated': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
              }
            },
            onError: (error) {
              // Handle location permission errors gracefully
              debugPrint('Position stream error: $error');
            },
          );
    }
  }

  void _attachAsViewer() {
    // add ourselves to viewer list
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    final name = auth.currentUser?.displayName ?? 'Người xem';
    if (widget.sessionId != null && uid != null) {
      FirebaseFirestore.instance
          .collection('location_shares')
          .doc(widget.sessionId)
          .collection('viewers')
          .doc(uid)
          .set({'name': name, 'joined': FieldValue.serverTimestamp()});
    }

    // listen to the shared session document
    _sessionSubscription = FirebaseFirestore.instance
        .collection('location_shares')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists) return;
          final data = snap.data();
          if (data == null) return;
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          final ts = data['lastUpdated'] as Timestamp?;
          if (lat != null && lng != null) {
            if (mounted) {
              setState(() {
                _lat = lat;
                _lng = lng;
                _lastUpdated = ts?.toDate();
              });
            }
            _mapController.move(LatLng(lat, lng), 13.0);
          }
        });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();

    _sessionSubscription?.cancel();
    _viewersSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ thời gian thực')),
      floatingActionButton: _isViewer
          ? null
          : FloatingActionButton.small(
              onPressed: _invite,
              tooltip: 'Mời',
              child: const Icon(Icons.person_add),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isViewer
                                ? 'Đang xem'
                                : (_isSharing
                                      ? 'Đang chia sẻ'
                                      : 'Chưa chia sẻ'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isViewer
                                  ? Colors.orange
                                  : (_isSharing
                                        ? Colors.green
                                        : Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vị trí: ${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lastUpdated != null
                                ? 'Cập nhật: ${_lastUpdated!.toLocal()}'
                                : 'Chưa có cập nhật',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isViewer)
                      ElevatedButton(
                        onPressed: _toggleSharing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSharing
                              ? Colors.red
                              : Colors.blue,
                        ),
                        child: Text(_isSharing ? 'Dừng' : 'Bắt đầu'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Map showing current position
            SizedBox(
              height: 180,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_lat, _lng),
                  initialZoom: 13.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.tourn',
                    tileProvider: NetworkTileProvider(),
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_lat, _lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          size: 32,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Viewers + share link
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Người đang xem',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _viewers.isEmpty
                        ? const Center(child: Text('Chưa có người xem'))
                        : ListView.separated(
                            itemCount: _viewers.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) => ListTile(
                              leading: CircleAvatar(
                                child: Text(_viewers[i][0].toUpperCase()),
                              ),
                              title: Text(_viewers[i]),
                              subtitle: Text(
                                _isViewer
                                    ? 'Đang theo dõi'
                                    : 'Xem vị trí của bạn',
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isViewer)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _shareLink,
                            style: const TextStyle(color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _copyLink,
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
