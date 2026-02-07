import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChiaSeThoiGianThucPage extends StatefulWidget {
  const ChiaSeThoiGianThucPage({super.key});

  @override
  State<ChiaSeThoiGianThucPage> createState() => _ChiaSeThoiGianThucPageState();
}

class _ChiaSeThoiGianThucPageState extends State<ChiaSeThoiGianThucPage> {
  bool _isSharing = false;
  Timer? _timer;
  double _lat = 10.762622;
  double _lng = 106.660172;
  DateTime? _lastUpdated;
  final List<String> _viewers = ['An', 'Bình', 'Chi'];
  final String _shareLink = 'https://trip.app/share/abc123';

  void _startSharing() {
    setState(() {
      _isSharing = true;
      _lastUpdated = DateTime.now();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _lat += 0.00012;
        _lng += 0.00008;
        _lastUpdated = DateTime.now();
      });
    });
  }

  void _stopSharing() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isSharing = false;
    });
  }

  void _toggleSharing() => _isSharing ? _stopSharing() : _startSharing();

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareLink));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép link chia sẻ')));
  }

  Future<void> _invite() async {
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ thời gian thực')),
      floatingActionButton: FloatingActionButton.small(
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
                            _isSharing ? 'Đang chia sẻ' : 'Chưa chia sẻ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isSharing ? Colors.green : Colors.black54,
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
                    ElevatedButton(
                      onPressed: _toggleSharing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSharing ? Colors.red : Colors.blue,
                      ),
                      child: Text(_isSharing ? 'Dừng' : 'Bắt đầu'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Map placeholder
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.map, size: 64, color: Colors.grey),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Mock map: ${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
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
                              subtitle: Text('Xem vị trí của bạn'),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
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
