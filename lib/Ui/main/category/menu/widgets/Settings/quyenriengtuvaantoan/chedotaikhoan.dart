import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';

class Chedotaikhoan extends StatefulWidget {
  const Chedotaikhoan({super.key, this.initialIsBusiness = false});

  final bool initialIsBusiness;

  @override
  State<Chedotaikhoan> createState() => _ChedotaikhoanState();
}

class _ChedotaikhoanState extends State<Chedotaikhoan> {
  final FirebaseAccountService _accountService = FirebaseAccountService();
  late bool _isBusiness;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _isBusiness = widget.initialIsBusiness;
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).hintColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
  }) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Future<void> _confirmSwitch(bool nextValue) async {
    if (_switching) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          nextValue
              ? 'Chuyển sang tài khoản doanh nghiệp?'
              : 'Chuyển về tài khoản cá nhân?',
        ),
        content: Text(
          nextValue
              ? 'Bạn sẽ có công cụ chuyên nghiệp, thống kê và nút liên hệ.'
              : 'Bạn sẽ mất các công cụ doanh nghiệp và thống kê.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _switching = true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await _accountService
            .updateBusinessMode(nextValue)
            .timeout(const Duration(seconds: 20));
        if (!mounted) return;
        setState(() => _isBusiness = nextValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBusiness
                  ? 'Đã chuyển sang tài khoản doanh nghiệp'
                  : 'Đã chuyển về tài khoản cá nhân',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          setState(() => _switching = false);
        }
      }
    }
  }

  Future<void> _startSwitchFlow() async {
    if (_switching) return;
    final nextValue = !_isBusiness;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        bool agreed = false;
        int step = 0;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final steps = [
              {
                'title': nextValue
                    ? 'Chế độ chuyên nghiệp là gì?'
                    : 'Quay về tài khoản cá nhân',
                'subtitle': nextValue
                    ? 'Bật công cụ doanh nghiệp để kinh doanh trong tiện ích này.'
                    : 'Bạn sẽ chuyển về trải nghiệm cá nhân thông thường.',
              },
              {
                'title': 'Lợi ích kinh doanh',
                'subtitle': nextValue
                    ? 'Thống kê, quảng bá, nút liên hệ và danh mục chuyên nghiệp.'
                    : 'Các công cụ kinh doanh sẽ bị tắt.',
              },
              {
                'title': 'Sẵn sàng chuyển đổi',
                'subtitle': nextValue
                    ? 'Xác nhận để bật tài khoản doanh nghiệp.'
                    : 'Xác nhận để quay về tài khoản cá nhân.',
              },
            ];

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[step]['title'] as String,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[step]['subtitle'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (step == 0) ...[
                    _featureTile(
                      icon: Icons.insights_outlined,
                      title: 'Thống kê chuyên nghiệp',
                      subtitle: nextValue
                          ? 'Theo dõi hiệu suất nội dung và tăng trưởng.'
                          : 'Thống kê sẽ bị tắt khi quay về cá nhân.',
                    ),
                    _featureTile(
                      icon: Icons.contact_phone_outlined,
                      title: 'Thông tin liên hệ',
                      subtitle: nextValue
                          ? 'Hiển thị email/số điện thoại để khách liên hệ.'
                          : 'Thông tin liên hệ công khai sẽ bị ẩn.',
                    ),
                  ],
                  if (step == 1) ...[
                    _featureTile(
                      icon: Icons.campaign_outlined,
                      title: 'Công cụ quảng bá',
                      subtitle: nextValue
                          ? 'Tăng độ tiếp cận và gợi ý nội dung.'
                          : 'Chiến dịch quảng bá sẽ bị dừng.',
                    ),
                    _featureTile(
                      icon: Icons.storefront_outlined,
                      title: 'Danh mục doanh nghiệp',
                      subtitle: nextValue
                          ? 'Chọn lĩnh vực kinh doanh phù hợp.'
                          : 'Danh mục doanh nghiệp sẽ bị gỡ.',
                    ),
                  ],
                  if (step == 2) ...[
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      value: agreed,
                      onChanged: (value) => setModalState(() {
                        agreed = value ?? false;
                      }),
                      title: const Text('Tôi đã đọc và hiểu các thay đổi'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      if (step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setModalState(() {
                              step -= 1;
                            }),
                            child: const Text('Quay lại'),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: step == steps.length - 1
                              ? (agreed
                                    ? () => Navigator.of(context).pop(true)
                                    : null)
                              : () => setModalState(() {
                                  step += 1;
                                }),
                          child: Text(
                            step == steps.length - 1 ? 'Xác nhận' : 'Tiếp theo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (accepted == true && mounted) {
      await _confirmSwitch(nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_isBusiness);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text('Chế độ tài khoản'),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            const SizedBox(height: 8),
            _sectionHeader(context, 'Loại tài khoản'),
            ListTile(
              leading: Icon(
                _isBusiness
                    ? Icons.business_center_outlined
                    : Icons.person_outline,
              ),
              title: Text(_isBusiness ? 'Doanh nghiệp' : 'Cá nhân'),
              subtitle: Text(
                _isBusiness
                    ? 'Bạn đang dùng tài khoản doanh nghiệp'
                    : 'Bạn đang dùng tài khoản cá nhân',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const Divider(height: 1),
            _sectionHeader(context, 'Lợi ích doanh nghiệp'),
            _featureTile(
              icon: Icons.insights_outlined,
              title: 'Thống kê & hiệu suất',
              subtitle: 'Xem lượt xem, tương tác và tăng trưởng.',
            ),
            _featureTile(
              icon: Icons.campaign_outlined,
              title: 'Công cụ quảng bá',
              subtitle: 'Tạo chiến dịch và tăng độ tiếp cận.',
            ),
            _featureTile(
              icon: Icons.contact_phone_outlined,
              title: 'Nút liên hệ',
              subtitle: 'Thêm email, số điện thoại, địa chỉ.',
            ),
            _featureTile(
              icon: Icons.storefront_outlined,
              title: 'Hiển thị danh mục',
              subtitle: 'Chọn lĩnh vực kinh doanh phù hợp.',
            ),
            _sectionHeader(context, 'Thông tin trước khi chuyển'),
            ListTile(
              title: const Text(
                'Bạn có thể quay lại tài khoản cá nhân bất kỳ lúc nào.',
              ),
              subtitle: const Text(
                'Một số tính năng cá nhân có thể bị ẩn khi chuyển sang doanh nghiệp.',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: FilledButton(
                onPressed: _switching ? null : _startSwitchFlow,
                child: Text(
                  _isBusiness
                      ? 'Chuyển về tài khoản cá nhân'
                      : 'Chuyển sang tài khoản doanh nghiệp',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
