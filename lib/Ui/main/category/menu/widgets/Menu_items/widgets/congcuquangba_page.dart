import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_marketing_service.dart';

class CongCuQuangBaPage extends StatelessWidget {
  const CongCuQuangBaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công cụ quảng bá'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Chiến dịch'),
              Tab(text: 'Voucher'),
              Tab(text: 'Quảng cáo'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PromoOverviewTab(),
            _CampaignTab(),
            _VoucherTab(),
            _AdTab(),
          ],
        ),
      ),
    );
  }
}

class _PromoOverviewTab extends StatelessWidget {
  const _PromoOverviewTab();

  @override
  Widget build(BuildContext context) {
    final service = FirebaseMarketingService();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Tổng quan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: service.streamCampaigns(),
          builder: (context, campaignSnapshot) {
            final campaigns = campaignSnapshot.data ?? [];
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.streamVouchers(),
              builder: (context, voucherSnapshot) {
                final vouchers = voucherSnapshot.data ?? [];
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: service.streamAds(),
                  builder: (context, adSnapshot) {
                    final ads = adSnapshot.data ?? [];
                    final reach = campaigns.fold<int>(
                      0,
                      (sum, c) => sum + ((c['reach'] as num?)?.toInt() ?? 0),
                    );
                    final voucherUsed = vouchers.fold<int>(
                      0,
                      (sum, v) => sum + ((v['used'] as num?)?.toInt() ?? 0),
                    );
                    final totalBudget =
                        campaigns.fold<double>(
                          0,
                          (sum, c) =>
                              sum + ((c['budget'] as num?)?.toDouble() ?? 0),
                        ) +
                        ads.fold<double>(
                          0,
                          (sum, a) =>
                              sum + ((a['budget'] as num?)?.toDouble() ?? 0),
                        );
                    final totalClicks = ads.fold<int>(
                      0,
                      (sum, a) => sum + ((a['clicks'] as num?)?.toInt() ?? 0),
                    );
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetricCard(
                          label: 'Lượt tiếp cận',
                          value: reach.toString(),
                          icon: Icons.remove_red_eye,
                        ),
                        _MetricCard(
                          label: 'Click quảng cáo',
                          value: totalClicks.toString(),
                          icon: Icons.thumb_up_alt_outlined,
                        ),
                        _MetricCard(
                          label: 'Voucher đã dùng',
                          value: voucherUsed.toString(),
                          icon: Icons.shopping_cart_outlined,
                        ),
                        _MetricCard(
                          label: 'Chi phí',
                          value: _formatCurrency(totalBudget),
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Tạo mới', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.campaign_outlined,
          title: 'Tạo chiến dịch mới',
          subtitle: 'Chọn mục tiêu, ngân sách, thời gian',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateCampaignPage())),
        ),
        _ActionTile(
          icon: Icons.confirmation_number_outlined,
          title: 'Tạo voucher',
          subtitle: 'Mã giảm giá, áp dụng theo điều kiện',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateVoucherPage())),
        ),
        _ActionTile(
          icon: Icons.local_fire_department_outlined,
          title: 'Boost bài viết',
          subtitle: 'Tăng độ tiếp cận cho bài viết bán hàng',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateAdPage())),
        ),
      ],
    );
  }
}

class _CampaignTab extends StatelessWidget {
  const _CampaignTab();

  @override
  Widget build(BuildContext context) {
    final service = FirebaseMarketingService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.streamCampaigns(),
      builder: (context, snapshot) {
        final campaigns = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chiến dịch',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateCampaignPage(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo mới'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (campaigns.isEmpty) const Text('Chưa có chiến dịch'),
            ...campaigns.map(
              (c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text((c['name'] ?? '').toString()),
                  subtitle: Text(
                    'Ngân sách: ${_formatCurrency((c['budget'] as num?)?.toDouble() ?? 0)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text((c['status'] ?? '').toString()),
                      const SizedBox(height: 4),
                      Text('Reach ${(c['reach'] ?? 0).toString()}'),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CampaignDetailPage(campaign: c),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoucherTab extends StatelessWidget {
  const _VoucherTab();

  @override
  Widget build(BuildContext context) {
    final service = FirebaseMarketingService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.streamVouchers(),
      builder: (context, snapshot) {
        final vouchers = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Voucher', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateVoucherPage(),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo mới'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (vouchers.isEmpty) const Text('Chưa có voucher'),
            ...vouchers.map(
              (v) => Card(
                child: ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: Text((v['code'] ?? '').toString()),
                  subtitle: Text(
                    'Giảm: ${(v['discount'] ?? '').toString()} - Sử dụng ${(v['used'] ?? 0)}/${(v['quantity'] ?? 0)}',
                  ),
                  trailing: Text((v['status'] ?? '').toString()),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VoucherDetailPage(voucher: v),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdTab extends StatelessWidget {
  const _AdTab();

  @override
  Widget build(BuildContext context) {
    final service = FirebaseMarketingService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.streamAds(),
      builder: (context, snapshot) {
        final ads = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quảng cáo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateAdPage()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo mới'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ads.isEmpty) const Text('Chưa có quảng cáo'),
            ...ads.map(
              (a) => Card(
                child: ListTile(
                  leading: const Icon(Icons.local_fire_department_outlined),
                  title: Text((a['name'] ?? '').toString()),
                  subtitle: Text(
                    'Ngân sách: ${_formatCurrency((a['budget'] as num?)?.toDouble() ?? 0)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text((a['status'] ?? '').toString()),
                      const SizedBox(height: 4),
                      Text('Click ${(a['clicks'] ?? 0).toString()}'),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AdDetailPage(ad: a)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.pink),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}

class CampaignDetailPage extends StatelessWidget {
  const CampaignDetailPage({super.key, required this.campaign});

  final Map<String, dynamic> campaign;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text((campaign['name'] ?? '').toString())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Trạng thái', (campaign['status'] ?? '').toString()),
            _detailRow(
              'Ngân sách',
              _formatCurrency((campaign['budget'] as num?)?.toDouble() ?? 0),
            ),
            _detailRow('Lượng tiếp cận', '${campaign['reach'] ?? 0}'),
            _detailRow('Thời gian', (campaign['duration'] ?? '').toString()),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Theo dõi hiệu quả chiến dịch theo từng ngày.'),
          ],
        ),
      ),
    );
  }
}

class VoucherDetailPage extends StatelessWidget {
  const VoucherDetailPage({super.key, required this.voucher});

  final Map<String, dynamic> voucher;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text((voucher['code'] ?? '').toString())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Giảm giá', (voucher['discount'] ?? '').toString()),
            _detailRow(
              'Đã dùng',
              '${voucher['used'] ?? 0}/${voucher['quantity'] ?? 0}',
            ),
            _detailRow('Trạng thái', (voucher['status'] ?? '').toString()),
            const SizedBox(height: 16),
            const Text(
              'Điều kiện',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Áp dụng cho đơn hàng từ 300.000 VND.'),
          ],
        ),
      ),
    );
  }
}

class AdDetailPage extends StatelessWidget {
  const AdDetailPage({super.key, required this.ad});

  final Map<String, dynamic> ad;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text((ad['name'] ?? '').toString())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Trạng thái', (ad['status'] ?? '').toString()),
            _detailRow(
              'Ngân sách',
              _formatCurrency((ad['budget'] as num?)?.toDouble() ?? 0),
            ),
            _detailRow('Số click', '${ad['clicks'] ?? 0}'),
            _detailRow('Thời gian', (ad['duration'] ?? '').toString()),
            const SizedBox(height: 16),
            const Text(
              'Đề xuất',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Thử thêm nội dung video để tăng tương tác.'),
          ],
        ),
      ),
    );
  }
}

class CreateCampaignPage extends StatelessWidget {
  const CreateCampaignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleCreatePage(
      title: 'Tạo chiến dịch',
      fields: const ['Tên chiến dịch', 'Ngân sách (VND)', 'Thời gian'],
      onSave: (values) async {
        final name = values[0].trim();
        final budget = double.tryParse(values[1].trim());
        final duration = values[2].trim();
        if (name.isEmpty || budget == null || duration.isEmpty) {
          throw Exception('Vui lòng nhập đầy đủ thông tin');
        }
        await FirebaseMarketingService().createCampaign(
          name: name,
          budget: budget,
          duration: duration,
        );
      },
    );
  }
}

class CreateVoucherPage extends StatelessWidget {
  const CreateVoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleCreatePage(
      title: 'Tạo voucher',
      fields: const ['Mã voucher', 'Giá trị giảm', 'Số lượng'],
      onSave: (values) async {
        final code = values[0].trim();
        final discount = values[1].trim();
        final quantity = int.tryParse(values[2].trim());
        if (code.isEmpty || discount.isEmpty || quantity == null) {
          throw Exception('Vui lòng nhập đầy đủ thông tin');
        }
        await FirebaseMarketingService().createVoucher(
          code: code,
          discount: discount,
          quantity: quantity,
        );
      },
    );
  }
}

class CreateAdPage extends StatelessWidget {
  const CreateAdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SimpleCreatePage(
      title: 'Tạo quảng cáo',
      fields: const ['Nội dung quảng cáo', 'Ngân sách (VND)', 'Thời gian'],
      onSave: (values) async {
        final content = values[0].trim();
        final budget = double.tryParse(values[1].trim());
        final duration = values[2].trim();
        if (content.isEmpty || budget == null || duration.isEmpty) {
          throw Exception('Vui lòng nhập đầy đủ thông tin');
        }
        await FirebaseMarketingService().createAd(
          content: content,
          budget: budget,
          duration: duration,
        );
      },
    );
  }
}

class _SimpleCreatePage extends StatefulWidget {
  const _SimpleCreatePage({
    required this.title,
    required this.fields,
    required this.onSave,
  });

  final String title;
  final List<String> fields;
  final Future<void> Function(List<String> values) onSave;

  @override
  State<_SimpleCreatePage> createState() => _SimpleCreatePageState();
}

class _SimpleCreatePageState extends State<_SimpleCreatePage> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _controllers.addAll(
      widget.fields.map((_) => TextEditingController()).toList(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(widget.fields.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[index],
                decoration: InputDecoration(labelText: widget.fields[index]),
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                final values = _controllers
                    .map((controller) => controller.text)
                    .toList();
                await widget.onSave(values);
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Đã lưu')));
                Navigator.of(context).pop();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final s = value.toStringAsFixed(0);
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return '${s.replaceAll(reg, '.')} đ';
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
