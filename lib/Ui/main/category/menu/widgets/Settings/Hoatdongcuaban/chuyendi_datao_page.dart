import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_activity_service.dart';
import 'package:intl/intl.dart';

/// Trang hiển thị các chuyến đi đã tạo
class ChuyendidataoPage extends StatefulWidget {
  const ChuyendidataoPage({super.key});

  @override
  State<ChuyendidataoPage> createState() => _ChuyendidataoPageState();
}

class _ChuyendidataoPageState extends State<ChuyendidataoPage> {
  final FirebaseActivityService _activityService = FirebaseActivityService();
  List<ActivityItem> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final trips = await _activityService.getMyTrips(limit: 50);

    if (mounted) {
      setState(() {
        _trips = trips;
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildTripCard(ActivityItem trip) {
    final destination = trip.metadata?['destination'] as String?;
    final isPublished = trip.metadata?['isPublished'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                trip.postPhotoUrl != null
                    ? Image.network(
                        trip.postPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.map,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPublished ? 'Đã đăng' : 'Bản nháp',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.postTitle ?? 'Chuyến đi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (destination != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination,
                          style: TextStyle(color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(trip.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến đi đã tạo'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Create new trip
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có chuyến đi nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo chuyến đi đầu tiên của bạn',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Create new trip
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo chuyến đi'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _trips.length,
                itemBuilder: (context, index) => _buildTripCard(_trips[index]),
              ),
            ),
    );
  }
}
