import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tourn/data/api/emergency_service.dart';
import 'shared/generic_search_page.dart';

class SoskhancapPage extends StatefulWidget {
  const SoskhancapPage({super.key});

  @override
  State<SoskhancapPage> createState() => _SoskhancapPageState();
}

class _SoskhancapPageState extends State<SoskhancapPage> {
  List<EmergencyNumber> _numbers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNumbers();
  }

  Future<void> _loadNumbers() async {
    setState(() {
      _loading = true;
      _error = null;
      _numbers = [];
    });
    try {
      _numbers = await EmergencyService().getNumbers();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
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
            'Số khẩn cấp',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lỗi tải dữ liệu',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadNumbers,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Số khẩn cấp', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenericSearchPage<EmergencyNumber>(
                      searchPrefsKey: 'emergency_search_history',
                      searchHint: 'Tìm số khẩn cấp...',
                      emptyMessage: 'Không tìm thấy số phù hợp',
                      suggestionsMessage: 'Đề xuất cho bạn',
                      brandOrange: Colors.redAccent,
                      brandGreen: Colors.green,
                      pageBg: Colors.white,
                      allItems: _numbers,
                      onSearchMatch: (items, query) {
                        if (query.isEmpty) return items;
                        final q = query.toLowerCase();
                        return items.where((t) {
                          return t.title.toLowerCase().contains(q) ||
                              t.subtitle.toLowerCase().contains(q) ||
                              t.phone.toLowerCase().contains(q);
                        }).toList();
                      },
                      getKeywordName: (t) => t.title,
                      buildItemCard: (num) {
                        return _EmergencyCard(
                          icon: Icons.call,
                          iconColor: Colors.redAccent,
                          title: num.title,
                          subtitle: num.subtitle,
                          phoneNumber: num.phone,
                        );
                      },
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Tìm số khẩn cấp...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildWarningBanner(),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _numbers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final num = _numbers[index];
                return _EmergencyCard(
                  icon: Icons.call,
                  iconColor: Colors.redAccent,
                  title: num.title,
                  subtitle: num.subtitle,
                  phoneNumber: num.phone,
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTips(),
          ],
        ),
      ),
    );
  }
}

Widget _buildWarningBanner() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Trong trường hợp khẩn cấp, vui lòng gọi ngay các số cứu hộ chuyên dụng để được hỗ trợ kịp thời.',
            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTips() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Mẹo xử lý khẩn cấp',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      _TipItem(text: 'Giữ bình tĩnh và xác định vị trí hiện tại của bạn.'),
      _TipItem(
        text: 'Cung cấp thông tin ngắn gọn, rõ ràng cho điều phối viên.',
      ),
      _TipItem(
        text: 'Không di chuyển nạn nhân nếu nghi ngờ chấn thương cột sống.',
      ),
    ],
  );
}

class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String phoneNumber;

  const _EmergencyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
  });

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        trailing: GestureDetector(
          onTap: _makePhoneCall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
