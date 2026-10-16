import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:tourn/data/firebase/firebase_account_service.dart';

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final FirebaseAccountService _accountService = FirebaseAccountService();
  final _givenController = TextEditingController(); // Tên
  final _middleController = TextEditingController(); // Tên đệm
  final _familyController = TextEditingController(); // Họ

  final RegExp _nameRegExp = RegExp(r"^[\p{L}\s'-]+$", unicode: true);
  bool _loading = true;
  bool _changed = false;

  String? _givenError;
  String? _familyError;

  @override
  void initState() {
    super.initState();
    _load();

    _givenController.addListener(() {
      setState(() {
        _changed = true;
        _validateFields();
      });
    });
    _middleController.addListener(() => setState(() => _changed = true));
    _familyController.addListener(() {
      setState(() {
        _changed = true;
        _validateFields();
      });
    });
  }

  Future<void> _load() async {
    // Lấy thông tin từ Firebase
    final nameParts = await _accountService.getNameParts();

    if (nameParts.firstName != null || nameParts.lastName != null) {
      _givenController.text = nameParts.firstName ?? '';
      _middleController.text = nameParts.middleName ?? '';
      _familyController.text = nameParts.lastName ?? '';
    } else {
      // Fallback: parse từ displayName
      final user = await _accountService.getCurrentUser();
      final full = user?.displayName ?? '';
      final tokens = full.trim().split(RegExp(r"\s+"));
      String given = '';
      String middle = '';
      String family = '';
      if (tokens.isNotEmpty && tokens.first.isNotEmpty) {
        if (tokens.length == 1) {
          given = tokens[0];
        } else if (tokens.length == 2) {
          family = tokens[0];
          given = tokens[1];
        } else {
          family = tokens.first;
          given = tokens.last;
          middle = tokens.sublist(1, tokens.length - 1).join(' ');
        }
      }
      _givenController.text = given;
      _middleController.text = middle;
      _familyController.text = family;
    }

    _validateFields();

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _givenController.dispose();
    _middleController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  bool _isNameValid(String s) {
    final v = s.trim();
    if (v.isEmpty) return false;
    return _nameRegExp.hasMatch(v);
  }

  void _validateFields() {
    final given = _givenController.text;
    final family = _familyController.text;

    _givenError = (given.trim().isNotEmpty && !_isNameValid(given))
        ? 'Chỉ được chứa chữ cái, khoảng trắng và dấu -'
        : null;
    _familyError = (family.trim().isNotEmpty && !_isNameValid(family))
        ? 'Chỉ được chứa chữ cái, khoảng trắng và dấu -'
        : null;
  }

  void _showPreview() {
    final given = _givenController.text.trim();
    final middle = _middleController.text.trim();
    final family = _familyController.text.trim();

    if (family.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Họ không được để trống')));
      return;
    }

    if (given.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tên không được để trống')));
      return;
    }

    if (!_isNameValid(family)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ chỉ được chứa chữ cái, khoảng trắng và dấu -'),
        ),
      );
      return;
    }

    if (!_isNameValid(given)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên chỉ được chứa chữ cái, khoảng trắng và dấu -'),
        ),
      );
      return;
    }

    // Tạo 2 format hiển thị tên
    final middlePart = middle.isNotEmpty ? ' $middle' : '';
    final option1 = '$given$middlePart $family'; // Tên Tên đệm Họ
    final option2 = '$family$middlePart $given'; // Họ Tên đệm Tên

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NamePreviewPage(
          option1: option1,
          option2: option2,
          firstName: given,
          middleName: middle.isEmpty ? null : middle,
          lastName: family,
          accountService: _accountService,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final given = _givenController.text.trim();
    final middle = _middleController.text.trim();
    final family = _familyController.text.trim();

    if (family.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Họ không được để trống')));
      return;
    }

    if (given.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tên không được để trống')));
      return;
    }

    if (!_isNameValid(family)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ chỉ được chứa chữ cái, khoảng trắng và dấu -'),
        ),
      );
      return;
    }

    if (!_isNameValid(given)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên chỉ được chứa chữ cái, khoảng trắng và dấu -'),
        ),
      );
      return;
    }

    // Lưu vào Firebase
    final result = await _accountService.updateFullName(
      firstName: given,
      middleName: middle.isEmpty ? null : middle,
      lastName: family,
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật tên thành công')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? 'Có lỗi xảy ra')));
    }
  }

  void _openManageOtherNames() {
    // Placeholder: navigate to real manager when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng quản lý tên khác chưa được cài đặt'),
      ),
    );
  }

  void _openLearnMore() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm hiểu thêm'),
        content: const Text(
          'Nếu đổi tên, bạn không thể đổi lại trong 60 ngày. Tránh viết hoa khác thường, thêm dấu câu hoặc ký tự ngẫu nhiên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 12.0,
                            ),
                            child: Text(
                              'Tên',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildNameCard(context),
                          const SizedBox(height: 12),
                          _buildInfoText(context),
                          const SizedBox(height: 18),
                          const Text(
                            'Tên khác',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Những tên khác luôn hiển thị công khai và giúp mọi người tìm thấy bạn trên Trip.',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _openManageOtherNames,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Quản lý tên khác'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            (_changed &&
                                _familyController.text.trim().isNotEmpty &&
                                _givenController.text.trim().isNotEmpty &&
                                _isNameValid(_familyController.text) &&
                                _isNameValid(_givenController.text))
                            ? _showPreview
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text('Xem lại thay đổi'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNameCard(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildField(
            label: 'Tên',
            controller: _givenController,
            error: _givenError,
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor.withOpacity(0.25),
          ),
          _buildField(label: 'Tên đệm', controller: _middleController),
          Divider(
            height: 1,
            thickness: 1,
            color: borderColor.withOpacity(0.25),
          ),
          _buildField(
            label: 'Họ',
            controller: _familyController,
            error: _familyError,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? error,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            cursorColor: Theme.of(context).colorScheme.primary,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: false,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              hintText: label,
              hintStyle: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 14,
              ),
              errorText: error,
              errorStyle: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14);
    return RichText(
      text: TextSpan(
        style: base ?? const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          const TextSpan(
            text:
                'Nếu đổi tên, bạn không thể đổi lại trong 60 ngày. Đừng viết hoa khác thường, thêm bất kỳ dấu câu, ký tự hoặc từ ngẫu nhiên nào. ',
          ),
          TextSpan(
            text: 'Tìm hiểu thêm',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            recognizer: TapGestureRecognizer()..onTap = _openLearnMore,
          ),
        ],
      ),
    );
  }
}

/// Trang xem trước tên mới
class _NamePreviewPage extends StatefulWidget {
  final String option1; // Tên Họ
  final String option2; // Họ Tên
  final String firstName;
  final String? middleName;
  final String lastName;
  final FirebaseAccountService accountService;

  const _NamePreviewPage({
    required this.option1,
    required this.option2,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.accountService,
  });

  @override
  State<_NamePreviewPage> createState() => _NamePreviewPageState();
}

class _NamePreviewPageState extends State<_NamePreviewPage> {
  int _selectedOption = 0; // 0 = option1, 1 = option2
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);

    // Lưu với displayName format được chọn
    final displayName = _selectedOption == 0 ? widget.option1 : widget.option2;

    final result = await widget.accountService.updateFullName(
      firstName: widget.firstName,
      middleName: widget.middleName,
      lastName: widget.lastName,
      displayNameFormat: _selectedOption == 0 ? 'first_last' : 'last_first',
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật tên thành công')),
      );
      // Pop cả 2 trang (preview và name page)
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? 'Có lỗi xảy ra')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xem trước tên mới',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn cách tên bạn hiển thị trên trang cá nhân.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Options container
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Option 1
                          _buildOptionTile(
                            title: widget.option1,
                            isSelected: _selectedOption == 0,
                            onTap: () => setState(() => _selectedOption = 0),
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.3),
                          ),
                          // Option 2
                          _buildOptionTile(
                            title: widget.option2,
                            isSelected: _selectedOption == 1,
                            onTap: () => setState(() => _selectedOption = 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Warning note
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Lưu ý: Bạn sẽ không thể đổi tên trong vòng 60 ngày tới. ',
                          ),
                          TextSpan(
                            text: 'Tìm hiểu thêm',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Tìm hiểu thêm'),
                                    content: const Text(
                                      'Nếu đổi tên, bạn không thể đổi lại trong 60 ngày. Tránh viết hoa khác thường, thêm dấu câu hoặc ký tự ngẫu nhiên.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Đóng'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Lưu thay đổi'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
