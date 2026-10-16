import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/data/firebase/firebase_message_service.dart';
import 'package:tourn/data/firebase/trip_notification_helper.dart';
import 'package:tourn/models/menu_models.dart';
import 'package:tourn/models/conversation_model.dart';
import 'goiyngansachthongminh_page.dart';

class TaochuyendiPage extends StatefulWidget {
  const TaochuyendiPage({super.key});

  @override
  State<TaochuyendiPage> createState() => _TaochuyendiPageState();
}

class _TaochuyendiPageState extends State<TaochuyendiPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseMenuService _menuService = FirebaseMenuService();
  final FirebaseMessageService _messageService = FirebaseMessageService();
  final TripNotificationHelper _notificationHelper = TripNotificationHelper();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _maxMembersController = TextEditingController(
    text: '10',
  );

  // New fields controllers
  final TextEditingController _estimatedCostController =
      TextEditingController();
  final TextEditingController _departureTimeController =
      TextEditingController();
  final TextEditingController _startingLocationController =
      TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _gatheringTimeController =
      TextEditingController();

  // Gathering time
  DateTime? _gatheringTime;

  // Selected conversation for trip chat
  ConversationModel? _selectedConversation;
  List<ConversationModel> _groupChats = [];

  // Multiple locations support
  final List<TextEditingController> _locationControllers = [
    TextEditingController(),
  ];

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _departureTime;
  bool _isLoading = false;
  bool _showForm = true;

  // For editing
  TripModel? _editingTrip;

  // Active trips stream
  StreamSubscription<List<TripModel>>? _tripsSubscription;
  List<TripModel> _activeTrips = [];
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveTrips();
    _loadGroupChats();
    _startNotificationChecker();
    _updateTripsStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _maxMembersController.dispose();
    _estimatedCostController.dispose();
    _departureTimeController.dispose();
    _startingLocationController.dispose();
    _passwordController.dispose();
    _gatheringTimeController.dispose();
    for (final c in _locationControllers) {
      c.dispose();
    }
    _tripsSubscription?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _loadActiveTrips() {
    _tripsSubscription = _menuService.getActiveTripsStream().listen(
      (trips) {
        if (mounted) {
          setState(() {
            _activeTrips = trips;
            // Auto-hide form if there are active trips
            if (_activeTrips.isNotEmpty && _showForm) {
              _showForm = false;
            }
            // Show form again if no active trips
            if (_activeTrips.isEmpty) {
              _showForm = true;
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading trips: $error');
        // Keep existing trips on error, don't crash
      },
    );
  }

  void _loadGroupChats() {
    _messageService.getConversations().listen(
      (conversations) {
        if (mounted) {
          setState(() {
            // Only keep group chats
            _groupChats = conversations
                .where((c) => c.type == ConversationType.group)
                .toList();
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading group chats: $error');
      },
    );
  }

  void _startNotificationChecker() {
    // Check every minute for trips that need notification
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndSendNotifications();
    });
    // Also check immediately
    _checkAndSendNotifications();
  }

  Future<void> _updateTripsStatus() async {
    await _menuService.updateTripsStatusByDate();
  }

  Future<void> _checkAndSendNotifications() async {
    final trips = await _menuService.getTripsNeedingNotification();
    for (final trip in trips) {
      await _sendTripStartingNotification(trip);
      await _menuService.markTripNotificationSent(trip.id);
    }
  }

  Future<void> _sendTripStartingNotification(TripModel trip) async {
    await _notificationHelper.sendTripStartingNotifications(trip);
  }

  Future<void> _pickDate(TextEditingController controller, bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    }
  }

  Future<void> _pickDepartureTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      final newDepartureTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      setState(() {
        _departureTime = newDepartureTime;
        _departureTimeController.text = _formatDateTime(_departureTime!);

        // Nếu giờ tập trung muộn hơn giờ xuất phát mới -> xóa giờ tập trung
        if (_gatheringTime != null &&
            _gatheringTime!.isAfter(_departureTime!)) {
          _gatheringTime = null;
          _gatheringTimeController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã xóa giờ tập trung vì muộn hơn giờ xuất phát mới',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _pickGatheringTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      final selectedGatheringTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // Validate: giờ tập trung phải <= giờ xuất phát
      if (_departureTime != null &&
          selectedGatheringTime.isAfter(_departureTime!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Giờ tập trung phải sớm hơn hoặc bằng giờ xuất phát!',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _gatheringTime = selectedGatheringTime;
        _gatheringTimeController.text = _formatDateTime(_gatheringTime!);
      });
    }
  }

  void _addLocationField() {
    setState(() {
      _locationControllers.add(TextEditingController());
    });
  }

  void _removeLocationField(int index) {
    if (_locationControllers.length > 1) {
      setState(() {
        _locationControllers[index].dispose();
        _locationControllers.removeAt(index);
      });
    }
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ngày!")));
      return;
    }

    final locations = _locationControllers
        .map((c) => c.text.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập ít nhất một địa điểm!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final maxMembers = int.tryParse(_maxMembersController.text) ?? 10;
      final estimatedCost = double.tryParse(
        _estimatedCostController.text.replaceAll('.', ''),
      );
      final password = _passwordController.text.trim();

      final trip = await _menuService.addTrip(
        name: _nameController.text.trim(),
        location: locations.first,
        locations: locations,
        description: _descriptionController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        maxMembers: maxMembers,
        estimatedCost: estimatedCost,
        departureTime: _departureTime,
        startingLocation: _startingLocationController.text.trim(),
        gatheringTime: _gatheringTime,
        password: password.isNotEmpty ? password : null,
        conversationId: _selectedConversation?.id,
      );

      // Send notification for trip creation
      if (trip != null) {
        await _notificationHelper.sendTripCreatedNotification(trip);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tạo chuyến đi thành công!"),
          backgroundColor: Colors.orange,
        ),
      );

      // Clear form
      _clearForm();

      // Hide form after creating trip
      setState(() => _showForm = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Edit an existing trip - populate form with trip data
  void _editTrip(TripModel trip) {
    _editingTrip = trip;
    _nameController.text = trip.name;
    _descriptionController.text = trip.description;
    _startDateController.text = _formatDate(trip.startDate);
    _endDateController.text = _formatDate(trip.endDate);
    _maxMembersController.text = trip.maxMembers.toString();
    _startDate = trip.startDate;
    _endDate = trip.endDate;

    // New fields
    _estimatedCostController.text = _formatNumber(trip.estimatedCost);
    _departureTime = trip.departureTime;
    _departureTimeController.text = trip.departureTime != null
        ? _formatDateTime(trip.departureTime!)
        : '';
    _startingLocationController.text = trip.startingLocation;
    _passwordController.text = trip.password ?? '';
    _gatheringTime = trip.gatheringTime;
    _gatheringTimeController.text = trip.gatheringTime != null
        ? _formatDateTime(trip.gatheringTime!)
        : '';

    // Clear and rebuild location controllers
    for (final c in _locationControllers) {
      c.dispose();
    }
    _locationControllers.clear();

    final allLocs = trip.allLocations;
    if (allLocs.isEmpty) {
      _locationControllers.add(TextEditingController());
    } else {
      for (final loc in allLocs) {
        _locationControllers.add(TextEditingController(text: loc));
      }
    }

    setState(() => _showForm = true);
  }

  /// Save trip (create new or update existing)
  Future<void> _saveTrip() async {
    if (_editingTrip != null) {
      await _updateExistingTrip();
    } else {
      await _createTrip();
    }
  }

  /// Update an existing trip
  Future<void> _updateExistingTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn ngày!")));
      return;
    }

    final locations = _locationControllers
        .map((c) => c.text.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập ít nhất một địa điểm!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final maxMembers = int.tryParse(_maxMembersController.text) ?? 10;
      final estimatedCost = double.tryParse(
        _estimatedCostController.text.replaceAll('.', ''),
      );
      final password = _passwordController.text.trim();

      final updatedTrip = _editingTrip!.copyWith(
        name: _nameController.text.trim(),
        location: locations.first,
        locations: locations,
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        maxMembers: maxMembers,
        estimatedCost: estimatedCost,
        departureTime: _departureTime,
        startingLocation: _startingLocationController.text.trim(),
        gatheringTime: _gatheringTime,
        password: password.isNotEmpty ? password : null,
      );

      // Compare changes and update with history
      final changes = _menuService.compareTripChanges(
        _editingTrip!,
        updatedTrip,
      );
      final result = await _menuService.updateTripWithHistory(
        oldTrip: _editingTrip!,
        newTrip: updatedTrip,
        changes: changes,
      );

      // Send notification if trip has other members
      if (result != null && result.members.length > 1) {
        await _notificationHelper.sendTripEditedNotifications(result);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật chuyến đi thành công!"),
          backgroundColor: Colors.orange,
        ),
      );

      // Clear form
      _clearForm();

      // Hide form
      setState(() => _showForm = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _maxMembersController.text = '10';
    _estimatedCostController.clear();
    _departureTimeController.clear();
    _startingLocationController.clear();
    _passwordController.clear();
    _gatheringTimeController.clear();
    for (final c in _locationControllers) {
      c.clear();
    }
    // Reset to single location field
    while (_locationControllers.length > 1) {
      _locationControllers.last.dispose();
      _locationControllers.removeLast();
    }
    _startDate = null;
    _endDate = null;
    _departureTime = null;
    _gatheringTime = null;
    _editingTrip = null;
    _selectedConversation = null;
  }

  Future<void> _cancelTrip(TripModel trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hủy chuyến đi'),
        content: const Text('Bạn có chắc muốn hủy chuyến đi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy chuyến đi'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _menuService.cancelTrip(trip.id);

      // Send cancellation notification to all members
      await _notificationHelper.sendTripCancelledNotifications(trip);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy chuyến đi')));
    }
  }

  Future<void> _confirmCompleteTrip(TripModel trip) async {
    // Check if it's a multi-day trip and not the last day
    if (trip.isMultiDayTrip && !trip.isLastDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ có thể hoàn thành chuyến đi vào ngày cuối cùng'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hoàn thành chuyến đi'),
        content: const Text(
          'Bạn có chắc muốn đánh dấu chuyến đi này đã hoàn thành?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _menuService.completeTrip(trip.id);

      // TODO: Send completion notification to all members if needed

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hoàn thành chuyến đi')));
    }
  }

  Future<void> _addLocationToTrip(TripModel trip) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thêm địa điểm'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Địa điểm mới',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );

    if (ok == true && controller.text.trim().isNotEmpty) {
      await _menuService.addLocationToTrip(trip.id, controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã thêm địa điểm')));
    }
    controller.dispose();
  }

  Future<void> _leaveTrip(TripModel trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rời chuyến đi'),
        content: const Text('Bạn có chắc muốn rời khỏi chuyến đi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rời khỏi'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final uid = _menuService.currentUserId;
      await _menuService.leaveTrip(trip.id);

      if (uid != null) {
        await _notificationHelper.sendMemberLeftNotifications(
          trip: trip,
          leaverId: uid,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã rời khỏi chuyến đi')));
    }
  }

  Future<void> _showMemberDetails(TripModel trip) async {
    // Get member names from Firebase
    final memberNames = await _menuService.getMemberNames(trip.members);
    if (!mounted) return;

    final currentUserId = _menuService.currentUserId;
    final isCurrentUserOwner = currentUserId == trip.userId;

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.group, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Thành viên (${trip.members.length}/${trip.maxMembers})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: trip.members.length,
            itemBuilder: (context, index) {
              final memberId = trip.members[index];
              final isOwner = memberId == trip.userId;
              final name = memberNames[memberId] ?? 'Người dùng';
              final isCurrentUser = memberId == currentUserId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isOwner
                      ? Colors.orange
                      : Colors.grey.shade300,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isOwner ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Chủ trì',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    // Show menu for owner to manage other members
                    if (isCurrentUserOwner && !isCurrentUser)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) async {
                          Navigator.of(c).pop(); // Close dialog first
                          if (value == 'remove') {
                            await _confirmRemoveMember(trip, memberId, name);
                          } else if (value == 'transfer') {
                            await _confirmTransferOwnership(
                              trip,
                              memberId,
                              name,
                            );
                          }
                        },
                        itemBuilder: (context) {
                          // build dynamic menu entries; skip remove when trip is active
                          final items = <PopupMenuEntry<String>>[];
                          items.add(
                            const PopupMenuItem(
                              value: 'transfer',
                              child: Row(
                                children: [
                                  Icon(Icons.swap_horiz, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Chuyển quyền chủ trì'),
                                ],
                              ),
                            ),
                          );
                          if (trip.status != TripStatus.active) {
                            items.add(
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Xóa khỏi chuyến đi'),
                                  ],
                                ),
                              ),
                            );
                          }
                          return items;
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Show edit history dialog
  Future<void> _showEditHistory(TripModel trip) async {
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('Lịch sử chỉnh sửa'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: trip.editHistory.isEmpty
              ? const Center(child: Text('Chưa có chỉnh sửa nào'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: trip.editHistory.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, index) {
                    // Show from newest to oldest
                    final edit =
                        trip.editHistory[trip.editHistory.length - 1 - index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              edit.formattedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (edit.editedByName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Bởi: ${edit.editedByName}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ...edit.changes.map(
                          (change) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(color: Colors.purple),
                                ),
                                Expanded(
                                  child: Text(
                                    change,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    TripModel trip,
    String memberId,
    String memberName,
  ) async {
    // prevent removal if trip is currently active
    if (trip.status == TripStatus.active) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa thành viên khi chuyến đi đang diễn ra'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa $memberName khỏi chuyến đi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _menuService.removeMemberFromTrip(
        trip.id,
        memberId,
      );

      // Also remove from group chat if exists
      if (success &&
          trip.conversationId != null &&
          trip.conversationId!.isNotEmpty) {
        try {
          // Note: We need a method to remove a specific participant
          // For now, the removed user won't be added back but will still be in chat
          // A proper implementation would require removeParticipantFromGroup method
        } catch (e) {
          debugPrint('Error removing member from chat: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã xóa $memberName khỏi chuyến đi'
                : 'Không thể xóa thành viên',
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmTransferOwnership(
    TripModel trip,
    String newOwnerId,
    String newOwnerName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chuyển quyền chủ trì'),
        content: Text(
          'Bạn có chắc muốn chuyển quyền chủ trì cho $newOwnerName?\n\n'
          'Bạn sẽ không còn là chủ trì của chuyến đi này nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _menuService.transferOwnership(trip.id, newOwnerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã chuyển quyền chủ trì cho $newOwnerName'
                : 'Không thể chuyển quyền',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _inviteFriends(TripModel trip) async {
    // Show dialog to share trip info
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Mời bạn bè'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chia sẻ mã chuyến đi cho bạn bè:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    trip.tripCode.isNotEmpty ? trip.tripCode : trip.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: trip.tripCode.isNotEmpty ? 20 : 12,
                      letterSpacing: trip.tripCode.isNotEmpty ? 2 : 0,
                    ),
                  ),
                  if (trip.hasPassword) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock, size: 18, color: Colors.orange),
                  ],
                ],
              ),
            ),
            if (trip.hasPassword) ...[
              const SizedBox(height: 8),
              Text(
                'Mật khẩu: ${trip.password}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Chuyến đi: ${trip.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Địa điểm: ${trip.allLocations.join(" → ")}'),
            Text('Thành viên: ${trip.memberCountDisplay}'),
            const SizedBox(height: 12),
            const Text(
              'Bạn bè có thể nhập mã này để tham gia chuyến đi.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Auto-create group chat when trip has 3+ members and no existing chat
  /// Or add new member to existing chat
  Future<void> _autoCreateTripChat(TripModel trip) async {
    final currentUid = _menuService.currentUserId;
    if (currentUid == null) return;

    try {
      // If trip already has a conversation, add the new member to it
      if (trip.conversationId != null && trip.conversationId!.isNotEmpty) {
        final memberNames = await _menuService.getMemberNames([currentUid]);
        await _messageService.addParticipantsToGroup(
          conversationId: trip.conversationId!,
          participantIds: [currentUid],
          participantNames: memberNames,
        );
        return;
      }

      // Only create new chat if 3+ members and no existing conversation
      if (trip.members.length < 3) return;

      // Get member names for the conversation
      final memberNames = await _menuService.getMemberNames(trip.members);

      // Build participant maps (excluding current user as they're added by createGroupConversation)
      final otherParticipantIds = trip.members
          .where((m) => m != currentUid)
          .toList();

      // Create group conversation
      final conversation = await _messageService.createGroupConversation(
        name: trip.name, // Use trip name as group name
        participantIds: otherParticipantIds,
        participantNames: memberNames,
      );

      if (conversation != null) {
        // Link conversation to trip
        await _menuService.linkConversationToTrip(trip.id, conversation.id);
      }
    } catch (e) {
      // Silent fail - group chat creation is optional
      debugPrint('Error creating trip group chat: $e');
    }
  }

  Future<void> _joinTripById() async {
    final codeController = TextEditingController();
    final passwordController = TextEditingController();

    // First, get the code and check if password is needed
    final tripCode = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tham gia chuyến đi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập mã chuyến đi:'),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Mã chuyến đi',
                hintText: 'VD: 123456',
                prefixIcon: const Icon(Icons.qr_code, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(null),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(codeController.text.trim()),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (tripCode == null || tripCode.isEmpty) {
      codeController.dispose();
      passwordController.dispose();
      return;
    }

    // Check if trip exists and needs password
    final existingTrip = await _menuService.getTripByCode(tripCode);
    if (!mounted) return;

    if (existingTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy chuyến đi với mã này')),
      );
      codeController.dispose();
      passwordController.dispose();
      return;
    }

    String? password;
    if (existingTrip.hasPassword) {
      // Ask for password
      password = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Nhập mật khẩu'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chuyến đi "${existingTrip.name}" yêu cầu mật khẩu'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(null),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(c).pop(passwordController.text.trim()),
              child: const Text('Tham gia'),
            ),
          ],
        ),
      );

      if (password == null) {
        codeController.dispose();
        passwordController.dispose();
        return;
      }
    }

    // Join the trip
    final (success, errorType, trip) = await _menuService.joinTripByCode(
      tripCode,
      password: password,
    );

    if (!mounted) return;

    if (!success) {
      String message;
      switch (errorType) {
        case 'not_found':
          message = 'Không tìm thấy chuyến đi với mã này';
          break;
        case 'full':
          message = 'Chuyến đi đã đủ người';
          break;
        case 'wrong_password':
          message = 'Sai mật khẩu';
          break;
        case 'already_member':
          message = 'Bạn đã là thành viên của chuyến đi này';
          break;
        case 'not_logged_in':
          message = 'Vui lòng đăng nhập để tham gia chuyến đi';
          break;
        case 'already_started':
          message = 'Chuyến đi đã bắt đầu, không thể tham gia';
          break;
        case 'completed':
          message = 'Chuyến đi đã kết thúc';
          break;
        case 'cancelled':
          message = 'Chuyến đi đã bị hủy';
          break;
        default:
          message = 'Không thể tham gia chuyến đi';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else if (trip != null) {
      final uid = _menuService.currentUserId;
      if (uid != null) {
        await _notificationHelper.sendJoinNotifications(
          trip: trip,
          joinerId: uid,
          isFull: trip.isFull,
        );
      }

      // Auto-create group chat if 3+ members and no existing conversation
      await _autoCreateTripChat(trip);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tham gia chuyến đi "${trip.name}"!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    codeController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveTrips = _activeTrips.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text("Tạo chuyến đi"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // Join trip button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Tham gia chuyến đi",
            onPressed: _joinTripById,
          ),
          // Show + button only when form is hidden and there are active trips
          if (!_showForm && hasActiveTrips)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Tạo chuyến đi mới",
              onPressed: () {
                _clearForm();
                setState(() => _showForm = true);
              },
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Lịch sử chuyến đi",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Lichsutaochuyendi()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Show form when _showForm is true
            if (_showForm) _buildTripForm(),

            // Show active trips list
            if (_activeTrips.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildActiveTripsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupChatSelector(),
              const SizedBox(height: 16),
              _buildTextField(
                _nameController,
                "Tên chuyến đi",
                Icons.flag_outlined,
              ),
              const SizedBox(height: 16),

              // Multiple locations section
              const Text(
                "Địa điểm",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildLocationFields(),

              TextButton.icon(
                onPressed: _addLocationField,
                icon: const Icon(Icons.add_location_alt, color: Colors.orange),
                label: const Text(
                  "Thêm địa điểm",
                  style: TextStyle(color: Colors.orange),
                ),
              ),

              const SizedBox(height: 16),
              _buildDateField(_startDateController, "Ngày bắt đầu", true),
              const SizedBox(height: 16),
              _buildDateField(_endDateController, "Ngày kết thúc", false),
              const SizedBox(height: 16),

              // Địa điểm bắt đầu
              _buildTextField(
                _startingLocationController,
                "Địa điểm bắt đầu (tập trung)",
                Icons.my_location,
              ),
              const SizedBox(height: 16),

              // Giờ xuất phát
              TextFormField(
                controller: _departureTimeController,
                readOnly: true,
                onTap: _pickDepartureTime,
                decoration: InputDecoration(
                  labelText: "Giờ xuất phát",
                  prefixIcon: const Icon(
                    Icons.access_time,
                    color: Colors.orange,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Giờ tập trung
              TextFormField(
                controller: _gatheringTimeController,
                readOnly: true,
                onTap: _pickGatheringTime,
                decoration: InputDecoration(
                  labelText: "Giờ tập trung",
                  prefixIcon: const Icon(Icons.schedule, color: Colors.orange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _gatheringTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _gatheringTime = null;
                              _gatheringTimeController.clear();
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _maxMembersController,
                "Số lượng thành viên tối đa",
                Icons.group_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Chi phí ước tính
              _buildEstimatedCostField(),
              const SizedBox(height: 16),

              // Mật khẩu (tùy chọn)
              _buildTextField(
                _passwordController,
                "Mật khẩu bảo vệ (tùy chọn)",
                Icons.lock_outline,
                required: false,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Chọn nhóm chat (tùy chọn)
              _buildTextField(
                _descriptionController,
                "Mô tả",
                Icons.description_outlined,
                maxLines: 3,
                required: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _editingTrip != null
                              ? "CẬP NHẬT CHUYẾN ĐI"
                              : "TẠO CHUYẾN ĐI",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              // Cancel edit button
              if (_editingTrip != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () {
                      _clearForm();
                      setState(() => _showForm = _activeTrips.isEmpty);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Hủy chỉnh sửa"),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLocationFields() {
    return List.generate(_locationControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationControllers[index],
                validator: index == 0
                    ? (v) => v == null || v.isEmpty
                          ? "Vui lòng nhập địa điểm"
                          : null
                    : null,
                decoration: InputDecoration(
                  labelText: "Địa điểm ${index + 1}",
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.orange,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_locationControllers.length > 1)
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                onPressed: () => _removeLocationField(index),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildActiveTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Chuyến đi hiện tại",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 12),
        ...(_activeTrips.map((trip) => _buildTripCard(trip))),
      ],
    );
  }

  Widget _buildTripCard(TripModel trip) {
    final uid = _menuService.currentUserId;
    final isOwner = trip.userId == uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          trip.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Tham gia',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trip.statusDisplayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Trip code row with copy button
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(
                  trip.tripCode.isNotEmpty
                      ? 'Mã: ${trip.tripCode}'
                      : 'Mã: ${trip.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    final codeToCopy = trip.tripCode.isNotEmpty
                        ? trip.tripCode
                        : trip.id;
                    Clipboard.setData(ClipboardData(text: codeToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã chuyến đi'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                ),
                if (trip.hasPassword) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 16, color: Colors.orange),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Member count with full indicator
            Row(
              children: [
                const Icon(Icons.group, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showMemberDetails(trip),
                  child: Text(
                    'Thành viên: ${trip.memberCountDisplay}',
                    style: const TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (trip.isFull) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Đủ người',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),

            // Gathering time if available
            if (trip.gatheringTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Giờ tập trung: ${_formatDateTime(trip.gatheringTime!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],

            // Starting location if available
            if (trip.startingLocation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tập trung: ${trip.startingLocation}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Locations - only owner can add locations
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...trip.allLocations.map(
                        (loc) => Text(
                          '• $loc',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                // Only owner can add locations
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.add_location, color: Colors.orange),
                    onPressed: () => _addLocationToTrip(trip),
                    tooltip: 'Thêm địa điểm',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Dates
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            // Departure time if available
            if (trip.departureTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Xuất phát: ${_formatDateTime(trip.departureTime!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],

            // Estimated cost if available
            if (trip.estimatedCost != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chi phí ước tính: ${_formatCurrency(trip.estimatedCost!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],

            if (trip.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                trip.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],

            // Edit history indicator
            if (trip.editHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showEditHistory(trip),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.purple, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Đã chỉnh sửa ${trip.editHistory.length} lần',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons - different for owner vs member
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Invite friends button - only available when trip can still accept members and not within 1hr of gathering
                if (trip.canJoin && !trip.isWithinOneHourOfGathering)
                  TextButton.icon(
                    onPressed: () => _inviteFriends(trip),
                    icon: const Icon(Icons.person_add, color: Colors.orange),
                    label: const Text(
                      'Mời',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),

                if (isOwner) ...[
                  // Owner can complete trip on the last day
                  if (trip.canManuallyComplete)
                    TextButton.icon(
                      onPressed: () => _confirmCompleteTrip(trip),
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text(
                        'Hoàn thành',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  // Owner can edit (before departure)
                  if (trip.status == TripStatus.pending ||
                      trip.status == TripStatus.gathering)
                    TextButton.icon(
                      onPressed: () => _editTrip(trip),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text(
                        'Sửa',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  // Owner can cancel
                  if (trip.canCancel)
                    TextButton.icon(
                      onPressed: () => _cancelTrip(trip),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ] else ...[
                  // Member can only leave - not within 1hr of gathering
                  if (!trip.isWithinOneHourOfGathering)
                    TextButton.icon(
                      onPressed: () => _leaveTrip(trip),
                      icon: const Icon(Icons.exit_to_app, color: Colors.red),
                      label: const Text(
                        'Rời',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted VNĐ';
  }

  /// Format number with thousand separators (for input field)
  String _formatNumber(double? amount) {
    if (amount == null) return '';
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.blue;
      case TripStatus.gathering:
        return Colors.orange;
      case TripStatus.active:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildTextField(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: c,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: required
          ? (v) => v == null || v.isEmpty ? "Vui lòng nhập $label" : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEstimatedCostField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _estimatedCostController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Chi phí ước tính (VNĐ)',
              prefixIcon: const Icon(Icons.attach_money, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: IconButton(
            onPressed: _showBudgetPresetsDialog,
            icon: const Icon(Icons.savings, color: Colors.orange),
            tooltip: 'Chọn từ ngân sách đã lưu',
          ),
        ),
      ],
    );
  }

  Future<void> _showBudgetPresetsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('budget_presets_v1') ?? [];
    final presets = raw
        .map((s) {
          try {
            final decoded = jsonDecode(s);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
            return <String, dynamic>{};
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((m) => m.isNotEmpty)
        .toList();

    if (presets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Chưa có ngân sách đã lưu. Hãy tạo ngân sách trong "Gợi ý ngân sách thông minh"',
          ),
          action: SnackBarAction(
            label: 'Đi tới',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _BudgetRedirectPage()),
              );
            },
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (c, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Chọn ngân sách đã lưu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(c),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: presets.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (c, i) {
                  final p = presets[i];
                  final total = p['total'] ?? 0;
                  final totalStr = _formatCurrency(
                    total is double ? total : (total as num).toDouble(),
                  );
                  final departure = p['departure'] ?? '';
                  final destination = p['destination'] ?? '';
                  final route = departure.isNotEmpty && destination.isNotEmpty
                      ? '$departure → $destination'
                      : (destination.isNotEmpty
                            ? destination
                            : (departure.isNotEmpty ? departure : ''));

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPresetTypeColor(p['type']),
                        child: const Icon(
                          Icons.savings,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '$totalStr VNĐ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['days'] ?? 1} ngày • ${p['people'] ?? 1} người • ${p['type'] ?? 'Tiêu chuẩn'}',
                          ),
                          if (route.isNotEmpty)
                            Text(
                              route,
                              style: const TextStyle(color: Colors.blue),
                            ),
                        ],
                      ),
                      isThreeLine: route.isNotEmpty,
                      onTap: () => Navigator.pop(c, p),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      final total = selected['total'];
      final totalValue = total is double
          ? total
          : (total as num?)?.toDouble() ?? 0;
      _estimatedCostController.text = _formatNumber(totalValue);

      // Also fill other fields if empty
      if (_startingLocationController.text.isEmpty &&
          selected['departure'] != null) {
        _startingLocationController.text = selected['departure'];
      }
      if (_locationControllers.first.text.isEmpty &&
          selected['destination'] != null) {
        _locationControllers.first.text = selected['destination'];
      }
      // Fill in number of people from preset
      if (selected['people'] != null) {
        _maxMembersController.text = selected['people'].toString();
      }
    }
  }

  Color _getPresetTypeColor(String? type) {
    switch (type) {
      case 'Tiết kiệm':
      case 'Economy':
        return Colors.green;
      case 'Cao cấp':
      case 'Premium':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  Widget _buildGroupChatSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ConversationModel?>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.group, color: Colors.orange),
              const SizedBox(width: 12),
              const Text('Chọn nhóm chat (tùy chọn)'),
            ],
          ),
          value: _selectedConversation,
          items: [
            const DropdownMenuItem<ConversationModel?>(
              value: null,
              child: Text('Nhóm chat tự động'),
            ),
            ..._groupChats.map(
              (conv) => DropdownMenuItem<ConversationModel?>(
                value: conv,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.orange.shade100,
                      backgroundImage: conv.photoUrl != null
                          ? NetworkImage(conv.photoUrl!)
                          : null,
                      child: conv.photoUrl == null
                          ? Text(
                              conv.name?.isNotEmpty == true
                                  ? conv.name![0].toUpperCase()
                                  : 'G',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conv.name ?? 'Nhóm không tên',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${conv.participants.length} TV',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedConversation = value);
          },
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController c, String label, bool isStart) {
    return TextFormField(
      controller: c,
      readOnly: true,
      onTap: () => _pickDate(c, isStart),
      validator: (v) => v == null || v.isEmpty ? "Vui lòng chọn $label" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.orange),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class Lichsutaochuyendi extends StatefulWidget {
  const Lichsutaochuyendi({super.key});

  @override
  State<Lichsutaochuyendi> createState() => _LichsutaochuyendiState();
}

class _LichsutaochuyendiState extends State<Lichsutaochuyendi> {
  final FirebaseMenuService _menuService = FirebaseMenuService();
  List<TripModel> _trips = [];
  StreamSubscription<List<TripModel>>? _subscription;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadTrips() {
    _subscription = _menuService.getTripsStream().listen((trips) {
      _trips = trips;
      if (mounted) setState(() => _loading = false);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted VNĐ';
  }

  Future<void> _showTripDetails(TripModel trip) async {
    final memberNames = await _menuService.getMemberNames(trip.members);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trip.statusDisplayText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Trip code
              _buildDetailRow(Icons.qr_code, 'Mã chuyến đi', trip.tripCode),

              // Date range
              _buildDetailRow(
                Icons.calendar_today,
                'Thời gian',
                '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
              ),

              // Departure time
              if (trip.departureTime != null)
                _buildDetailRow(
                  Icons.access_time,
                  'Giờ xuất phát',
                  _formatDateTime(trip.departureTime!),
                ),

              // Gathering time
              if (trip.gatheringTime != null)
                _buildDetailRow(
                  Icons.schedule,
                  'Giờ tập trung',
                  _formatDateTime(trip.gatheringTime!),
                ),

              // Starting location
              if (trip.startingLocation.isNotEmpty)
                _buildDetailRow(
                  Icons.my_location,
                  'Địa điểm tập trung',
                  trip.startingLocation,
                ),

              // Locations
              _buildDetailRow(
                Icons.location_on,
                'Địa điểm',
                trip.allLocations.join(' → '),
              ),

              // Estimated cost
              if (trip.estimatedCost != null)
                _buildDetailRow(
                  Icons.attach_money,
                  'Chi phí ước tính',
                  _formatCurrency(trip.estimatedCost!),
                ),

              // Description
              if (trip.description.isNotEmpty)
                _buildDetailRow(Icons.description, 'Mô tả', trip.description),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Members
              Text(
                'Thành viên (${trip.members.length}/${trip.maxMembers})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...trip.members.map((memberId) {
                final isOwner = memberId == trip.userId;
                final name = memberNames[memberId] ?? 'Người dùng';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isOwner
                            ? Colors.orange
                            : Colors.grey.shade300,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOwner ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(name)),
                      if (isOwner)
                        const Text(
                          'Chủ trip',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                    ],
                  ),
                );
              }),

              // Edit history
              if (trip.editHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.purple, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Lịch sử chỉnh sửa (${trip.editHistory.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...trip.editHistory.reversed.take(3).map((edit) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edit.formattedTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...edit.changes
                            .take(2)
                            .map(
                              (change) => Text(
                                '• $change',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        if (edit.changes.length > 2)
                          Text(
                            '... và ${edit.changes.length - 2} thay đổi khác',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (trip.editHistory.length > 3)
                  Text(
                    '... và ${trip.editHistory.length - 3} lần chỉnh sửa trước đó',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrip(TripModel trip) async {
    final uid = _menuService.currentUserId;
    final isOwner = trip.userId == uid;

    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ chủ chuyến đi mới có thể xóa')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xóa chuyến đi'),
        content: const Text('Bạn có chắc muốn xóa chuyến đi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _menuService.deleteTrip(trip.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa chuyến đi')));
    }
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.blue;
      case TripStatus.gathering:
        return Colors.orange;
      case TripStatus.active:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _menuService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử chuyến đi"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
          ? const Center(child: Text('Chưa có chuyến đi nào'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final trip = _trips[i];
                final isOwner = trip.userId == uid;

                return Dismissible(
                  key: ValueKey(trip.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: isOwner
                      ? DismissDirection.startToEnd
                      : DismissDirection.none,
                  confirmDismiss: (_) async {
                    if (!isOwner) return false;
                    return await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Xóa chuyến đi'),
                        content: const Text('Bạn có chắc muốn xóa?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(c).pop(true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) => _menuService.deleteTrip(trip.id),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.flight_takeoff,
                        color: Colors.orange,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(trip.name),
                                const SizedBox(width: 6),
                                if (!isOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Tham gia',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(trip.status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              trip.statusDisplayText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.allLocations.join(' → '),
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                          ),
                          Text(
                            'Thành viên: ${trip.memberCountDisplay}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _showTripDetails(trip),
                      onLongPress: isOwner ? () => _deleteTrip(trip) : null,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Widget chuyển hướng đến trang Gợi ý ngân sách thông minh
class _BudgetRedirectPage extends StatelessWidget {
  const _BudgetRedirectPage();

  @override
  Widget build(BuildContext context) {
    return const GoiYNganSachThongMinhPage();
  }
}

/// TextInputFormatter để thêm dấu chấm ngăn cách hàng nghìn
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format with thousand separators
    final String formatted = _formatWithSeparators(digitsOnly);

    // Calculate new cursor position
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset <= newValue.text.length) {
      // Count digits before cursor in new value
      final textBeforeCursor = newValue.text.substring(
        0,
        newValue.selection.baseOffset,
      );
      final digitsBeforeCursor = textBeforeCursor
          .replaceAll(RegExp(r'[^\d]'), '')
          .length;

      // Find position in formatted string
      int digitCount = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (formatted[i] != '.') {
          digitCount++;
          if (digitCount == digitsBeforeCursor) {
            cursorPosition = i + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  String _formatWithSeparators(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
