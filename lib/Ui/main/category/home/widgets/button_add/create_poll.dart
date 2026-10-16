import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/models/menu_models.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final TextEditingController _questionController = TextEditingController();
  final FirebaseMenuService _menuService = FirebaseMenuService();
  List<TripModel> _trips = [];
  TripModel? _selectedTrip;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    List<TripModel> trips = [];
    try {
      debugPrint('CreatePollPage: Loading trips...');
      trips = await _menuService.getTrips();
      debugPrint('CreatePollPage: Loaded ${trips.length} trips');
      for (final t in trips) {
        debugPrint('  Trip: ${t.name}, status: ${t.status}, id: ${t.id}');
      }
    } catch (e) {
      debugPrint('CreatePollPage: Error loading trips: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tải được danh sách chuyến đi')),
        );
      }
    }

    // Chỉ hiển thị chuyến đi chưa chuyển trạng thái tập trung (pending/gathering)
    final filtered = trips.where((t) {
      return t.status == TripStatus.pending || t.status == TripStatus.gathering;
    }).toList();
    debugPrint('CreatePollPage: Filtered to ${filtered.length} planning trips');
    if (mounted) {
      setState(() {
        _trips = filtered;
      });
    }
  }

  void _createPoll() {
    final q = _questionController.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập câu hỏi')));
      return;
    }
    if (_selectedTrip == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chọn chuyến đi')));
      return;
    }

    final poll = {
      'question': q,
      'tripId': _selectedTrip!.id,
      'options': [_selectedTrip!.name, 'Đi'],
      'createdAt': DateTime.now().toIso8601String(),
    };

    Navigator.pop(context, poll);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt câu hỏi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Câu hỏi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nhập câu hỏi',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn chuyến đi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_trips.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Bạn chưa có chuyến đi nào. Hãy tạo chuyến đi trước.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            DropdownButtonFormField<TripModel>(
              // ignore: deprecated_member_use              initialValue: _selectedTrip,
              items: _trips
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedTrip = v;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Chọn chuyến đi',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: _createPoll,
              child: const Text('Tạo câu hỏi'),
            ),
          ],
        ),
      ),
    );
  }
}
