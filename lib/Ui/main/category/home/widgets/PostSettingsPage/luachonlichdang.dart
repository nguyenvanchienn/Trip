import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Luachonlichdang extends StatefulWidget {
  const Luachonlichdang({super.key});

  @override
  State<Luachonlichdang> createState() => _LuachonlichdangState();
}

class _LuachonlichdangState extends State<Luachonlichdang> {
  String _selectedOption = 'now'; // now, schedule
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lựa chọn lịch đăng',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _canSave() ? _saveSchedule : null,
              child: Text(
                'Xong',
                style: TextStyle(
                  color: _canSave() ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mô tả
            _buildDescription(),

            const Divider(height: 1),

            // Lựa chọn đăng ngay
            _buildOptionTile(
              id: 'now',
              icon: Icons.send,
              title: 'Đăng ngay',
              subtitle: 'Bài viết sẽ được đăng ngay lập tức',
              color: Colors.blue,
            ),

            // Lựa chọn hẹn lịch
            _buildOptionTile(
              id: 'schedule',
              icon: Icons.schedule,
              title: 'Hẹn lịch đăng',
              subtitle: 'Chọn thời gian đăng bài trong tương lai',
              color: Colors.orange,
            ),

            // Phần chọn ngày giờ khi hẹn lịch
            if (_selectedOption == 'schedule') ...[
              const Divider(height: 1),
              _buildSectionHeader('CHỌN THỜI GIAN'),
              _buildDatePicker(),
              _buildTimePicker(),

              // Preview thời gian đã chọn
              if (_scheduledDate != null && _scheduledTime != null)
                _buildSchedulePreview(),
            ],

            const Divider(height: 1),

            // Gợi ý thời gian tốt nhất
            _buildSectionHeader('GỢI Ý THỜI GIAN TỐT NHẤT'),
            _buildSuggestedTimes(),

            const SizedBox(height: 16),

            // Thông tin bổ sung
            _buildInfoSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB620).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFFFFB620),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lên lịch đăng bài',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn thời điểm phù hợp để bài viết của bạn tiếp cận được nhiều người hơn.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedOption == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedOption = id;
          if (id == 'now') {
            _scheduledDate = null;
            _scheduledTime = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFFFB620) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFB620) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.calendar_month,
          color: Colors.green,
          size: 22,
        ),
      ),
      title: const Text(
        'Chọn ngày',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _scheduledDate != null
            ? DateFormat('dd/MM/yyyy').format(_scheduledDate!)
            : 'Chưa chọn ngày',
        style: TextStyle(
          fontSize: 13,
          color: _scheduledDate != null ? Colors.black87 : Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _pickDate,
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.access_time,
          color: Colors.purple,
          size: 22,
        ),
      ),
      title: const Text(
        'Chọn giờ',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _scheduledTime != null
            ? _scheduledTime!.format(context)
            : 'Chưa chọn giờ',
        style: TextStyle(
          fontSize: 13,
          color: _scheduledTime != null ? Colors.black87 : Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _pickTime,
    );
  }

  Widget _buildSchedulePreview() {
    final scheduledDateTime = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );

    final now = DateTime.now();
    final difference = scheduledDateTime.difference(now);
    String timeText;

    if (difference.isNegative) {
      timeText = 'Thời gian đã qua, vui lòng chọn lại';
    } else if (difference.inDays > 0) {
      timeText = 'Còn ${difference.inDays} ngày ${difference.inHours % 24} giờ';
    } else if (difference.inHours > 0) {
      timeText = 'Còn ${difference.inHours} giờ ${difference.inMinutes % 60} phút';
    } else {
      timeText = 'Còn ${difference.inMinutes} phút';
    }

    final isValid = !difference.isNegative;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid
            ? const Color(0xFFFFB620).withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? const Color(0xFFFFB620).withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.event_available : Icons.event_busy,
            color: isValid ? const Color(0xFFFFB620) : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Bài viết sẽ được đăng vào' : 'Thời gian không hợp lệ',
                  style: TextStyle(
                    fontSize: 13,
                    color: isValid ? Colors.grey[700] : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm - dd/MM/yyyy')
                      .format(scheduledDateTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isValid ? Colors.black : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isValid ? Colors.grey[600] : Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTimes() {
    final now = DateTime.now();
    final suggestions = [
      {
        'label': 'Sáng mai (8:00)',
        'time': DateTime(now.year, now.month, now.day + 1, 8, 0),
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
      },
      {
        'label': 'Trưa mai (12:00)',
        'time': DateTime(now.year, now.month, now.day + 1, 12, 0),
        'icon': Icons.wb_sunny_outlined,
        'color': Colors.amber,
      },
      {
        'label': 'Tối nay (20:00)',
        'time': DateTime(now.year, now.month, now.day, 20, 0),
        'icon': Icons.nights_stay,
        'color': Colors.indigo,
      },
      {
        'label': 'Cuối tuần',
        'time': _getNextWeekend(),
        'icon': Icons.weekend,
        'color': Colors.green,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          final time = suggestion['time'] as DateTime;
          final isValid = time.isAfter(now);

          return InkWell(
            onTap: isValid
                ? () {
                    setState(() {
                      _selectedOption = 'schedule';
                      _scheduledDate = time;
                      _scheduledTime = TimeOfDay(hour: time.hour, minute: time.minute);
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isValid
                    ? (suggestion['color'] as Color).withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isValid
                      ? (suggestion['color'] as Color).withOpacity(0.3)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    suggestion['icon'] as IconData,
                    size: 18,
                    color: isValid
                        ? suggestion['color'] as Color
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    suggestion['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isValid ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  DateTime _getNextWeekend() {
    final now = DateTime.now();
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    final nextSaturday = now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
    return DateTime(nextSaturday.year, nextSaturday.month, nextSaturday.day, 10, 0);
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mẹo đăng bài',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bài viết được đăng vào buổi sáng (7-9h) hoặc buổi tối (19-21h) thường nhận được nhiều tương tác hơn.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFB620),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFB620),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  bool _canSave() {
    if (_selectedOption == 'now') return true;
    if (_scheduledDate == null || _scheduledTime == null) return false;

    final scheduledDateTime = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );

    return scheduledDateTime.isAfter(DateTime.now());
  }

  void _saveSchedule() {
    if (_selectedOption == 'now') {
      Navigator.pop(context, {
        'type': 'now',
        'label': 'Đăng ngay',
      });
    } else {
      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );

      Navigator.pop(context, {
        'type': 'schedule',
        'dateTime': scheduledDateTime,
        'label': DateFormat('HH:mm - dd/MM/yyyy').format(scheduledDateTime),
      });
    }
  }
}
