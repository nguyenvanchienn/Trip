import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/domain/storage/storage_service.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippay_pin_page.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

class BusinessPersonalInfoPage extends StatefulWidget {
  const BusinessPersonalInfoPage({super.key, required this.ownerProfile});

  final Map<String, dynamic> ownerProfile;

  @override
  State<BusinessPersonalInfoPage> createState() =>
      _BusinessPersonalInfoPageState();
}

class _BusinessPersonalInfoPageState extends State<BusinessPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  String _phoneDialCode = '84';
  String _phoneFlag = '🇻🇳';
  String _phoneCountryCode = 'VN';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (widget.ownerProfile['name'] ?? '').toString(),
    );
    _phoneController = TextEditingController();
    _emailController = TextEditingController(
      text: (widget.ownerProfile['email'] ?? '').toString(),
    );
    _initPhoneFromProfile(widget.ownerProfile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField(label: 'Tên chủ', controller: _nameController),
              _buildPhoneField(),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Số điện thoại',
          border: const OutlineInputBorder(),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          prefixIcon: InkWell(
            onTap: _pickCountry,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_phoneFlag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '+$_phoneDialCode',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (country) {
        setState(() {
          _phoneDialCode = country.phoneCode;
          _phoneFlag = country.flagEmoji;
          _phoneCountryCode = country.countryCode;
        });
      },
    );
  }

  void _initPhoneFromProfile(Map<String, dynamic> profile) {
    final dial = (profile['phoneDialCode'] ?? '').toString();
    final flag = (profile['phoneFlagEmoji'] ?? '').toString();
    final countryCode = (profile['phoneCountryCode'] ?? '').toString();
    final national = (profile['phoneNationalNumber'] ?? '').toString();

    if (dial.isNotEmpty) _phoneDialCode = dial;
    if (flag.isNotEmpty) _phoneFlag = flag;
    if (countryCode.isNotEmpty) _phoneCountryCode = countryCode;

    if (national.isNotEmpty) {
      _phoneController.text = national;
      return;
    }

    final raw = (profile['phone'] ?? '').toString();
    if (raw.startsWith('+84')) {
      _phoneController.text = raw.replaceFirst('+84', '').trim();
      return;
    }
    _phoneController.text = raw.replaceAll(RegExp(r'\D'), '');
  }

  String _formatPhoneE164() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final national = digits.replaceFirst(RegExp(r'^0+'), '');
    if (national.isEmpty) return '';
    return '+$_phoneDialCode$national';
  }

  String _formatNationalNumber() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    final updated = {
      ...widget.ownerProfile,
      'name': _nameController.text.trim(),
      'phone': _formatPhoneE164(),
      'phoneDialCode': _phoneDialCode,
      'phoneNationalNumber': _formatNationalNumber(),
      'phoneCountryCode': _phoneCountryCode,
      'phoneFlagEmoji': _phoneFlag,
      'email': _emailController.text.trim(),
    };

    final result = await service.updateExtendedProfile({
      'ownerProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin cá nhân')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}

class BusinessInfoPage extends StatefulWidget {
  const BusinessInfoPage({super.key, required this.businessProfile});

  final Map<String, dynamic> businessProfile;

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String? _selectedCategory;
  String _phoneDialCode = '84';
  String _phoneFlag = '🇻🇳';
  String _phoneCountryCode = 'VN';
  Timer? _addressDebounce;
  final List<Map<String, String>> _addressSuggestions = [];
  bool _showAddressSuggestions = false;
  bool _isSaving = false;

  static const List<String> _categoryOptions = [
    'Ẩm thực',
    'Du lịch',
    'Khách sạn',
    'Giải trí',
    'Mua sắm',
    'Sức khỏe',
    'Giáo dục',
    'Dịch vụ',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: (widget.businessProfile['name'] ?? '').toString(),
    );
    _phoneController = TextEditingController();
    _addressController = TextEditingController(
      text: (widget.businessProfile['address'] ?? '').toString(),
    );
    final category = (widget.businessProfile['category'] ?? '').toString();
    _selectedCategory = category.isEmpty ? null : category;
    _initPhoneFromProfile(widget.businessProfile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _addressDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cửa hàng')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                label: 'Tên cửa hàng',
                controller: _nameController,
              ),
              _buildPhoneField(),
              _buildAddressField(),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final items = {..._categoryOptions};
    if (_selectedCategory != null && _selectedCategory!.trim().isNotEmpty) {
      items.add(_selectedCategory!);
    }
    final sorted = items.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        items: [
          for (final option in sorted)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        decoration: const InputDecoration(
          labelText: 'Lĩnh vực',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => setState(() {
          _selectedCategory = value;
        }),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Số điện thoại',
          border: const OutlineInputBorder(),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          prefixIcon: InkWell(
            onTap: _pickCountry,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_phoneFlag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '+$_phoneDialCode',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextFormField(
            controller: _addressController,
            keyboardType: TextInputType.streetAddress,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ',
              border: OutlineInputBorder(),
            ),
            onChanged: _onAddressChanged,
          ),
        ),
        if (_showAddressSuggestions)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _addressSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _addressSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion['display_name'] ?? ''),
                  onTap: () => _selectAddressSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  void _onAddressChanged(String value) {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchAddressSuggestions(value);
    });
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _addressSuggestions.clear();
        _showAddressSuggestions = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=$query&'
        'format=json&'
        'limit=6&'
        'addressdetails=1&'
        'countrycodes=vn&'
        'accept-language=vi',
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'TournApp/1.0',
          'Accept-Language': 'vi,en;q=0.9',
        },
      );
      if (response.statusCode != 200) return;
      final List results = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        _addressSuggestions
          ..clear()
          ..addAll(
            results
                .map(
                  (result) => {
                    'display_name': result['display_name'] as String,
                  },
                )
                .toList()
                .cast<Map<String, String>>(),
          );
        _showAddressSuggestions = _addressSuggestions.isNotEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressSuggestions.clear();
        _showAddressSuggestions = false;
      });
    }
  }

  void _selectAddressSuggestion(Map<String, String> suggestion) {
    final value = suggestion['display_name'] ?? '';
    setState(() {
      _addressController.text = value;
      _addressSuggestions.clear();
      _showAddressSuggestions = false;
    });
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (country) {
        setState(() {
          _phoneDialCode = country.phoneCode;
          _phoneFlag = country.flagEmoji;
          _phoneCountryCode = country.countryCode;
        });
      },
    );
  }

  void _initPhoneFromProfile(Map<String, dynamic> profile) {
    final dial = (profile['phoneDialCode'] ?? '').toString();
    final flag = (profile['phoneFlagEmoji'] ?? '').toString();
    final countryCode = (profile['phoneCountryCode'] ?? '').toString();
    final national = (profile['phoneNationalNumber'] ?? '').toString();

    if (dial.isNotEmpty) _phoneDialCode = dial;
    if (flag.isNotEmpty) _phoneFlag = flag;
    if (countryCode.isNotEmpty) _phoneCountryCode = countryCode;

    if (national.isNotEmpty) {
      _phoneController.text = national;
      return;
    }

    final raw = (profile['phone'] ?? '').toString();
    if (raw.startsWith('+84')) {
      _phoneController.text = raw.replaceFirst('+84', '').trim();
      return;
    }
    _phoneController.text = raw.replaceAll(RegExp(r'\D'), '');
  }

  String _formatPhoneE164() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final national = digits.replaceFirst(RegExp(r'^0+'), '');
    if (national.isEmpty) return '';
    return '+$_phoneDialCode$national';
  }

  String _formatNationalNumber() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.replaceFirst(RegExp(r'^0+'), '');
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    final updated = {
      ...widget.businessProfile,
      'name': _nameController.text.trim(),
      'phone': _formatPhoneE164(),
      'phoneDialCode': _phoneDialCode,
      'phoneNationalNumber': _formatNationalNumber(),
      'phoneCountryCode': _phoneCountryCode,
      'phoneFlagEmoji': _phoneFlag,
      'address': _addressController.text.trim(),
      'category': (_selectedCategory ?? '').trim(),
    };

    final result = await service.updateExtendedProfile({
      'businessProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin cửa hàng')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}

class OpenHoursPage extends StatefulWidget {
  const OpenHoursPage({super.key, required this.businessProfile});

  final Map<String, dynamic> businessProfile;

  @override
  State<OpenHoursPage> createState() => _OpenHoursPageState();
}

class _OpenHoursPageState extends State<OpenHoursPage> {
  final Set<int> _selectedDays = {};
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOpenHours();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giờ mở cửa')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Ngày hoạt động'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final day in _weekdayOptions)
                  FilterChip(
                    label: Text(day.label),
                    selected: _selectedDays.contains(day.value),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day.value);
                        } else {
                          _selectedDays.remove(day.value);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle('Khung giờ'),
            const SizedBox(height: 8),
            _buildTimeTile(
              label: 'Giờ mở cửa',
              time: _openTime,
              onTap: () => _pickTime(isOpen: true),
            ),
            _buildTimeTile(
              label: 'Giờ đóng cửa',
              time: _closeTime,
              onTap: () => _pickTime(isOpen: false),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Liên kết ngay'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Vui lòng nhập đúng thông tin để liên kết thành công.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _loadOpenHours() {
    final openHours = widget.businessProfile['openHours'];
    if (openHours is Map<String, dynamic>) {
      final days = List<dynamic>.from(openHours['days'] ?? []);
      _selectedDays
        ..clear()
        ..addAll(
          days.map((value) => int.tryParse(value.toString())).whereType<int>(),
        );
      final open = (openHours['open'] ?? '').toString();
      final close = (openHours['close'] ?? '').toString();
      _openTime = _parseTime(open);
      _closeTime = _parseTime(close);
    }
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final display = time == null
        ? 'Chưa chọn'
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(time, alwaysUse24HourFormat: true);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(display),
      trailing: const Icon(Icons.access_time),
      onTap: onTap,
    );
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final initial = isOpen
        ? (_openTime ?? const TimeOfDay(hour: 8, minute: 0))
        : (_closeTime ?? const TimeOfDay(hour: 21, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _openTime = picked;
      } else {
        _closeTime = picked;
      }
    });
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeValue(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_selectedDays.isEmpty || _openTime == null || _closeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày và giờ mở/đóng cửa')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    final openHours = {
      'days': _selectedDays.toList()..sort(),
      'open': _formatTimeValue(_openTime!),
      'close': _formatTimeValue(_closeTime!),
    };
    final updated = {...widget.businessProfile, 'openHours': openHours};

    final result = await service.updateExtendedProfile({
      'businessProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật giờ mở cửa')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}

class _WeekdayOption {
  const _WeekdayOption(this.value, this.label);

  final int value;
  final String label;
}

const List<_WeekdayOption> _weekdayOptions = [
  _WeekdayOption(1, 'T2'),
  _WeekdayOption(2, 'T3'),
  _WeekdayOption(3, 'T4'),
  _WeekdayOption(4, 'T5'),
  _WeekdayOption(5, 'T6'),
  _WeekdayOption(6, 'T7'),
  _WeekdayOption(7, 'CN'),
];

class BusinessMediaPage extends StatefulWidget {
  const BusinessMediaPage({super.key, required this.businessProfile});

  final Map<String, dynamic> businessProfile;

  @override
  State<BusinessMediaPage> createState() => _BusinessMediaPageState();
}

class _BusinessMediaPageState extends State<BusinessMediaPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  late Map<String, dynamic> _media;
  String? _avatarPath;
  String? _licensePath;
  late List<String> _shopImagePaths;
  late List<String> _locationImagePaths;

  @override
  void initState() {
    super.initState();
    _media = Map<String, dynamic>.from(
      (widget.businessProfile['media'] as Map<String, dynamic>?) ?? {},
    );
    _avatarPath = _media['avatarPath'] as String?;
    _licensePath = _media['licensePath'] as String?;
    _shopImagePaths = List<String>.from(_media['shopImagePaths'] ?? []);
    _locationImagePaths = List<String>.from(_media['locationImagePaths'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ảnh/Media')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Ảnh đại diện'),
            const SizedBox(height: 8),
            _buildSingleImage(_avatarPath, emptyText: 'Chưa có ảnh'),
            _buildActionRow(
              onPick: () => _pickSingle((path) => _avatarPath = path),
              onRemove: _avatarPath == null
                  ? null
                  : () => setState(() => _avatarPath = null),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Ảnh quán'),
            const SizedBox(height: 8),
            _buildImageGrid(
              _shopImagePaths,
              emptyText: 'Chưa có ảnh quán',
              onRemove: (index) => setState(() {
                _shopImagePaths.removeAt(index);
              }),
            ),
            _buildMultiActionRow(onAdd: () => _pickMulti(_shopImagePaths)),
            const SizedBox(height: 16),
            _sectionTitle('Giấy phép kinh doanh'),
            const SizedBox(height: 8),
            _buildSingleImage(_licensePath, emptyText: 'Chưa có giấy phép'),
            _buildActionRow(
              onPick: () => _pickSingle((path) => _licensePath = path),
              onRemove: _licensePath == null
                  ? null
                  : () => setState(() => _licensePath = null),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Ảnh địa điểm'),
            const SizedBox(height: 8),
            _buildImageGrid(
              _locationImagePaths,
              emptyText: 'Chưa có ảnh địa điểm',
              onRemove: (index) => setState(() {
                _locationImagePaths.removeAt(index);
              }),
            ),
            _buildMultiActionRow(onAdd: () => _pickMulti(_locationImagePaths)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Liên kết ngay'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Vui lòng nhập đúng thông tin để liên kết thành công.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActionRow({
    required VoidCallback onPick,
    required VoidCallback? onRemove,
  }) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Chọn ảnh'),
        ),
        const SizedBox(width: 12),
        TextButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xóa'),
        ),
      ],
    );
  }

  Widget _buildMultiActionRow({required VoidCallback onAdd}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Thêm ảnh'),
      ),
    );
  }

  Widget _buildSingleImage(String? path, {required String emptyText}) {
    if (path == null || path.isEmpty) {
      return Text(emptyText, style: const TextStyle(color: Colors.black54));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildImageWidget(path, height: 180, width: double.infinity),
    );
  }

  Widget _buildImageGrid(
    List<String> paths, {
    required String emptyText,
    required void Function(int index) onRemove,
  }) {
    if (paths.isEmpty) {
      return Text(emptyText, style: const TextStyle(color: Colors.black54));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < paths.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImageWidget(paths[i], width: 96, height: 96),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => onRemove(i),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageWidget(String url, {double? width, double? height}) {
    return SmartImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
    );
  }

  Future<void> _pickSingle(void Function(String path) onPicked) async {
    final picked = await _pickSingleImage();
    if (!mounted || picked == null) return;
    setState(() => onPicked(picked.path));
  }

  Future<void> _pickMulti(List<String> target) async {
    final picks = await _pickImages(allowMultiple: true);
    if (!mounted || picks.isEmpty) return;
    setState(() {
      target.addAll(picks.map((file) => file.path));
    });
  }

  Future<XFile?> _pickSingleImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) return null;
    return _picker.pickImage(source: source, maxWidth: 1080, imageQuality: 85);
  }

  Future<List<XFile>> _pickImages({required bool allowMultiple}) async {
    final source = await _showImageSourceSheet(allowMultiple: allowMultiple);
    if (source == null) return [];
    if (source == ImageSource.camera) {
      final captured = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 85,
      );
      return captured == null ? [] : [captured];
    }
    return _picker.pickMultiImage(maxWidth: 1080, imageQuality: 85);
  }

  Future<ImageSource?> _showImageSourceSheet({bool allowMultiple = false}) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  allowMultiple ? 'Chọn nhiều ảnh' : 'Chọn từ thư viện',
                ),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isRemotePath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _buildDestination(String section, String localPath) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final extIndex = localPath.lastIndexOf('.');
    final ext = extIndex == -1 ? '' : localPath.substring(extIndex);
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'business_media/$uid/$section/$ts$ext';
  }

  Future<String?> _uploadIfNeeded(
    StorageService storage,
    String? path,
    String section,
  ) async {
    if (path == null || path.isEmpty) return null;
    if (_isRemotePath(path)) return path;
    final file = File(path);
    if (!await file.exists()) return null;
    final dest = _buildDestination(section, path);
    return storage.uploadFile(path, dest);
  }

  Future<List<String>> _uploadListIfNeeded(
    StorageService storage,
    List<String> paths,
    String section,
  ) async {
    final results = <String>[];
    for (final path in paths) {
      final uploaded = await _uploadIfNeeded(storage, path, section);
      if (uploaded != null && uploaded.isNotEmpty) {
        results.add(uploaded);
      }
    }
    return results;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    final storage = context.read<StorageService>();

    final avatarUrl = await _uploadIfNeeded(storage, _avatarPath, 'avatar');
    final licenseUrl = await _uploadIfNeeded(storage, _licensePath, 'license');
    final shopUrls = await _uploadListIfNeeded(
      storage,
      _shopImagePaths,
      'shop',
    );
    final locationUrls = await _uploadListIfNeeded(
      storage,
      _locationImagePaths,
      'location',
    );

    final media = {
      ..._media,
      'avatarPath': avatarUrl,
      'licensePath': licenseUrl,
      'shopImagePaths': shopUrls,
      'locationImagePaths': locationUrls,
    };
    final updated = {...widget.businessProfile, 'media': media};

    final result = await service.updateExtendedProfile({
      'businessProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh/media')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}

enum _PaymentReceiveMethod { bank, wallet }

class _SelectOption {
  final String label;
  final String shortLabel;
  final String subtitle;
  final Color color;

  const _SelectOption({
    String? label,
    String? shortLabel,
    String? subtitle,
    required this.color,
  }) : label = label ?? '',
       shortLabel = shortLabel ?? '',
       subtitle = subtitle ?? '';
}

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key, required this.businessProfile});

  final Map<String, dynamic> businessProfile;

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountOwnerController;
  late final TextEditingController _walletController;
  late final TextEditingController _walletAccountNumberController;
  late _PaymentReceiveMethod _receiveMethod;
  bool _isSaving = false;
  bool _showLinked = false;
  final List<Map<String, dynamic>> _linkedMethods = [];
  int? _editingIndex;

  final List<_SelectOption> _banks = const [
    _SelectOption(
      label: 'Vietcombank',
      shortLabel: 'VCB',
      subtitle: 'Ngân hàng TMCP Ngoại thương Việt Nam',
      color: Color(0xFF0A7B3F),
    ),
    _SelectOption(
      label: 'BIDV',
      shortLabel: 'BIDV',
      subtitle: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam',
      color: Color(0xFF0B4DA1),
    ),
    _SelectOption(
      label: 'VietinBank',
      shortLabel: 'CTG',
      subtitle: 'Ngân hàng TMCP Công thương Việt Nam',
      color: Color(0xFFE4002B),
    ),
    _SelectOption(
      label: 'Agribank',
      shortLabel: 'AGB',
      subtitle: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn VN',
      color: Color(0xFFB20C1B),
    ),
    _SelectOption(
      label: 'Techcombank',
      shortLabel: 'TCB',
      subtitle: 'Ngân hàng TMCP Kỹ thương Việt Nam',
      color: Color(0xFFEB1E2D),
    ),
    _SelectOption(
      label: 'MB Bank',
      shortLabel: 'MB',
      subtitle: 'Ngân hàng TMCP Quân đội',
      color: Color(0xFF1A3E8E),
    ),
    _SelectOption(
      label: 'ACB',
      shortLabel: 'ACB',
      subtitle: 'Ngân hàng TMCP Á Châu',
      color: Color(0xFF00A3E0),
    ),
    _SelectOption(
      label: 'Sacombank',
      shortLabel: 'STB',
      subtitle: 'Ngân hàng TMCP Sài Gòn Thương Tín',
      color: Color(0xFF1C78C0),
    ),
    _SelectOption(
      label: 'VPBank',
      shortLabel: 'VPB',
      subtitle: 'Ngân hàng TMCP Việt Nam Thịnh Vượng',
      color: Color(0xFF4AAE4A),
    ),
    _SelectOption(
      label: 'TPBank',
      shortLabel: 'TPB',
      subtitle: 'Ngân hàng TMCP Tiên Phong',
      color: Color(0xFF7B2C91),
    ),
    _SelectOption(
      label: 'HDBank',
      shortLabel: 'HDB',
      subtitle: 'Ngân hàng TMCP Phát triển TP.HCM',
      color: Color(0xFFD71F27),
    ),
    _SelectOption(
      label: 'OCB',
      shortLabel: 'OCB',
      subtitle: 'Ngân hàng TMCP Phương Đông',
      color: Color(0xFF0E78C8),
    ),
    _SelectOption(
      label: 'SHB',
      shortLabel: 'SHB',
      subtitle: 'Ngân hàng TMCP Sài Gòn - Hà Nội',
      color: Color(0xFFED1C24),
    ),
    _SelectOption(
      label: 'VIB',
      shortLabel: 'VIB',
      subtitle: 'Ngân hàng TMCP Quốc tế Việt Nam',
      color: Color(0xFF0B5AA6),
    ),
    _SelectOption(
      label: 'SeABank',
      shortLabel: 'SEAB',
      subtitle: 'Ngân hàng TMCP Đông Nam Á',
      color: Color(0xFF0057A8),
    ),
    _SelectOption(
      label: 'LienVietPostBank',
      shortLabel: 'LPB',
      subtitle: 'Ngân hàng TMCP Bưu điện Liên Việt',
      color: Color(0xFF1F7A3E),
    ),
    _SelectOption(
      label: 'SCB',
      shortLabel: 'SCB',
      subtitle: 'Ngân hàng TMCP Sài Gòn',
      color: Color(0xFF1E4E9D),
    ),
    _SelectOption(
      label: 'Eximbank',
      shortLabel: 'EIB',
      subtitle: 'Ngân hàng TMCP Xuất Nhập khẩu Việt Nam',
      color: Color(0xFF007AC2),
    ),
    _SelectOption(
      label: 'KienlongBank',
      shortLabel: 'KLB',
      subtitle: 'Ngân hàng TMCP Kiên Long',
      color: Color(0xFF007A5E),
    ),
  ];

  final List<_SelectOption> _wallets = const [
    _SelectOption(
      label: 'TripPay',
      shortLabel: 'TP',
      subtitle: 'Ví điện tử TripPay',
      color: Color.fromARGB(255, 243, 132, 48),
    ),
    _SelectOption(
      label: 'MoMo',
      shortLabel: 'MoMo',
      subtitle: 'Ví điện tử MoMo',
      color: Color(0xFFD82D8B),
    ),
    _SelectOption(
      label: 'ZaloPay',
      shortLabel: 'ZP',
      subtitle: 'Ví điện tử ZaloPay',
      color: Color(0xFF0080FF),
    ),
    _SelectOption(
      label: 'ShopeePay',
      shortLabel: 'SP',
      subtitle: 'Ví điện tử ShopeePay',
      color: Color(0xFFEE4D2D),
    ),
    _SelectOption(
      label: 'Viettel Money',
      shortLabel: 'VT',
      subtitle: 'Ví điện tử Viettel Money',
      color: Color(0xFFEE0033),
    ),
    _SelectOption(
      label: 'VNPay',
      shortLabel: 'VNP',
      subtitle: 'Ví điện tử VNPay',
      color: Color(0xFF0057A6),
    ),
    _SelectOption(
      label: 'Payoo',
      shortLabel: 'PY',
      subtitle: 'Ví điện tử Payoo',
      color: Color(0xFF00A4B4),
    ),
    _SelectOption(
      label: 'AirPay',
      shortLabel: 'AP',
      subtitle: 'Ví điện tử AirPay',
      color: Color(0xFF00C2B3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final payment =
        (widget.businessProfile['payment'] as Map<String, dynamic>?) ?? {};
    final paymentMethodsRaw =
        (widget.businessProfile['paymentMethods'] as List<dynamic>?) ?? [];
    if (paymentMethodsRaw.isNotEmpty) {
      _linkedMethods
        ..clear()
        ..addAll(
          paymentMethodsRaw.whereType<Map<String, dynamic>>().map(
            (m) => Map<String, dynamic>.from(m),
          ),
        );
    } else {
      final hasLinked =
          (payment['bankName'] ?? '').toString().trim().isNotEmpty ||
          (payment['wallet'] ?? '').toString().trim().isNotEmpty;
      if (hasLinked) {
        _linkedMethods.add(Map<String, dynamic>.from(payment));
      }
    }
    _bankNameController = TextEditingController(
      text: (payment['bankName'] ?? '').toString(),
    );
    _accountNumberController = TextEditingController(
      text: (payment['accountNumber'] ?? '').toString(),
    );
    _accountOwnerController = TextEditingController(
      text: (payment['accountOwner'] ?? '').toString(),
    );
    _walletController = TextEditingController(
      text: (payment['wallet'] ?? '').toString(),
    );
    _walletAccountNumberController = TextEditingController(
      text: (payment['walletAccountNumber'] ?? '').toString(),
    );
    final methodRaw = (payment['method'] ?? '').toString();
    final hasBank =
        _bankNameController.text.trim().isNotEmpty ||
        _accountNumberController.text.trim().isNotEmpty ||
        _accountOwnerController.text.trim().isNotEmpty;
    final hasWallet = _walletController.text.trim().isNotEmpty;
    if (methodRaw == 'wallet') {
      _receiveMethod = _PaymentReceiveMethod.wallet;
    } else if (methodRaw == 'bank') {
      _receiveMethod = _PaymentReceiveMethod.bank;
    } else if (hasBank && !hasWallet) {
      _receiveMethod = _PaymentReceiveMethod.bank;
    } else {
      _receiveMethod = _PaymentReceiveMethod.wallet;
    }

    _showLinked = _linkedMethods.isNotEmpty;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountOwnerController.dispose();
    _walletController.dispose();
    _walletAccountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTripPay =
        _walletController.text.trim().toLowerCase() == 'trippay'.toLowerCase();
    final bankName = _bankNameController.text.trim();
    final bankAccount = _accountNumberController.text.trim();
    final bankOwner = _accountOwnerController.text.trim();
    final walletName = _walletController.text.trim();
    final walletAccount = _walletAccountNumberController.text.trim();
    final isBankValid =
        bankName.isNotEmpty && bankAccount.isNotEmpty && bankOwner.isNotEmpty;
    final isWalletValid =
        walletName.isNotEmpty && (isTripPay || walletAccount.isNotEmpty);
    final canSubmit = _receiveMethod == _PaymentReceiveMethod.bank
        ? isBankValid
        : isWalletValid;
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_showLinked && _linkedMethods.isNotEmpty) ...[
              const Text(
                'Phương thức đã liên kết',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _linkedMethods.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildLinkedMethodCard(_linkedMethods[i], i),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => setState(() {
                        _showLinked = false;
                        _bankNameController.clear();
                        _accountNumberController.clear();
                        _accountOwnerController.clear();
                        _walletController.clear();
                        _walletAccountNumberController.clear();
                        _receiveMethod = _PaymentReceiveMethod.bank;
                        _editingIndex = null;
                      }),
                icon: const Icon(Icons.add),
                label: const Text('Thêm phương thức'),
              ),
            ] else ...[
              _buildMethodToggle(),
              const SizedBox(height: 12),
              if (_receiveMethod == _PaymentReceiveMethod.bank) ...[
                _buildTextField(
                  label: 'Ngân hàng',
                  controller: _bankNameController,
                  readOnly: true,
                  onTap: () => _selectFromList(
                    title: 'Chọn ngân hàng',
                    options: _banks,
                    controller: _bankNameController,
                  ),
                ),
                _buildTextField(
                  label: 'Số tài khoản',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  label: 'Chủ tài khoản',
                  controller: _accountOwnerController,
                ),
              ] else ...[
                _buildTextField(
                  label: 'Ví điện tử',
                  controller: _walletController,
                  readOnly: true,
                  onTap: () => _selectFromList(
                    title: 'Chọn ví điện tử',
                    options: _wallets,
                    controller: _walletController,
                  ),
                ),
                if (!isTripPay)
                  _buildTextField(
                    label: 'Số tài khoản ví',
                    controller: _walletAccountNumberController,
                    keyboardType: TextInputType.number,
                  ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving || !canSubmit ? null : _save,
                child: const Text('Liên kết ngay'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lưu ý: Vui lòng nhập đúng thông tin để liên kết thành công.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedMethodCard(Map<String, dynamic> payment, int index) {
    final method = (payment['method'] ?? '').toString();
    final bankName = (payment['bankName'] ?? '').toString();
    final bankAccount = (payment['accountNumber'] ?? '').toString();
    final bankOwner = (payment['accountOwner'] ?? '').toString();
    final walletName = (payment['wallet'] ?? '').toString();
    final walletAccount = (payment['walletAccountNumber'] ?? '').toString();
    final isWallet = method == 'wallet';
    final isTripPay =
        walletName.trim().toLowerCase() == 'trippay'.toLowerCase();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWallet ? 'Ví điện tử' : 'Ngân hàng',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isWallet) ...[
              Text(walletName.isEmpty ? 'Không xác định' : walletName),
              const SizedBox(height: 4),
              Text(
                isTripPay
                    ? 'Ví tích hợp trong ứng dụng'
                    : (walletAccount.isEmpty
                          ? 'Chưa có số tài khoản'
                          : 'Số tài khoản: $walletAccount'),
              ),
            ] else ...[
              Text(bankName.isEmpty ? 'Không xác định' : bankName),
              const SizedBox(height: 4),
              Text(
                bankAccount.isEmpty
                    ? 'Chưa có số tài khoản'
                    : 'Số tài khoản: $bankAccount',
              ),
              const SizedBox(height: 4),
              Text(
                bankOwner.isEmpty
                    ? 'Chưa có chủ tài khoản'
                    : 'Chủ tài khoản: $bankOwner',
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => _startEditMethod(index),
                  child: const Text('Chỉnh sửa'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSaving ? null : () => _unlinkMethod(index),
                  child: const Text('Huỷ liên kết'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startEditMethod(int index) {
    final payment = _linkedMethods[index];
    final method = (payment['method'] ?? '').toString();
    final isWallet = method == 'wallet';

    setState(() {
      _editingIndex = index;
      _showLinked = false;
      _receiveMethod = isWallet
          ? _PaymentReceiveMethod.wallet
          : _PaymentReceiveMethod.bank;
      _bankNameController.text = (payment['bankName'] ?? '').toString();
      _accountNumberController.text = (payment['accountNumber'] ?? '')
          .toString();
      _accountOwnerController.text = (payment['accountOwner'] ?? '').toString();
      _walletController.text = (payment['wallet'] ?? '').toString();
      _walletAccountNumberController.text =
          (payment['walletAccountNumber'] ?? '').toString();
    });
  }

  Future<void> _unlinkMethod(int index) async {
    if (_isSaving) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc muốn huỷ liên kết phương thức này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Huỷ liên kết'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    setState(() => _isSaving = true);

    final updatedMethods = List<Map<String, dynamic>>.from(_linkedMethods)
      ..removeAt(index);
    final updatedProfile = {
      ...widget.businessProfile,
      'paymentMethods': updatedMethods,
      'payment': updatedMethods.isNotEmpty ? updatedMethods.last : {},
    };

    final service = FirebaseAccountService();
    final result = await service.updateExtendedProfile({
      'businessProfile': updatedProfile,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      setState(() {
        _linkedMethods
          ..clear()
          ..addAll(updatedMethods);
        _showLinked = _linkedMethods.isNotEmpty;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã huỷ liên kết')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Huỷ liên kết thất bại')),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: readOnly ? const Icon(Icons.keyboard_arrow_down) : null,
        ),
      ),
    );
  }

  Future<void> _selectFromList({
    required String title,
    required List<_SelectOption>? options,
    required TextEditingController controller,
  }) async {
    final safeOptions = options ?? const <_SelectOption>[];
    String keyword = '';
    List<_SelectOption> filtered = List<_SelectOption>.from(safeOptions);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (sheetCtx, setSheetState) {
              void updateFilter(String value) {
                keyword = value;
                final q = keyword.trim().toLowerCase();
                if (q.isEmpty) {
                  filtered = List<_SelectOption>.from(safeOptions);
                } else {
                  filtered = safeOptions
                      .where(
                        (o) =>
                            o.label.toLowerCase().contains(q) ||
                            o.shortLabel.toLowerCase().contains(q),
                      )
                      .toList();
                }
              }

              return DraggableScrollableSheet(
                initialChildSize: 0.75,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 12,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Tìm theo tên',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setSheetState(() => updateFilter(value)),
                        ),
                        const SizedBox(height: 12),
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Không tìm thấy kết quả'),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              controller: scrollController,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (itemCtx, index) {
                                final option = filtered[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: option.color,
                                    child: Text(
                                      option.shortLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    option.label.isEmpty
                                        ? 'Không xác định'
                                        : option.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  subtitle: Text(option.subtitle),
                                  onTap: () =>
                                      Navigator.pop(itemCtx, option.label),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        controller.text = selected;
        if (controller == _walletController &&
            selected.trim().toLowerCase() == 'trippay'.toLowerCase()) {
          _walletAccountNumberController.clear();
        }
      });
    }
  }

  Widget _buildMethodToggle() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Ngân hàng'),
            selected: _receiveMethod == _PaymentReceiveMethod.bank,
            onSelected: (_) =>
                setState(() => _receiveMethod = _PaymentReceiveMethod.bank),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Ví điện tử'),
            selected: _receiveMethod == _PaymentReceiveMethod.wallet,
            onSelected: (_) =>
                setState(() => _receiveMethod = _PaymentReceiveMethod.wallet),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final bankName = _bankNameController.text.trim();
    final bankAccount = _accountNumberController.text.trim();
    final bankOwner = _accountOwnerController.text.trim();
    final walletName = _walletController.text.trim();
    final walletAccount = _walletAccountNumberController.text.trim();
    final isTripPay = walletName.toLowerCase() == 'trippay'.toLowerCase();

    if (_receiveMethod == _PaymentReceiveMethod.bank) {
      if (bankName.isEmpty || bankAccount.isEmpty || bankOwner.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập đủ thông tin ngân hàng')),
        );
        return;
      }
    } else {
      if (walletName.isEmpty || (!isTripPay && walletAccount.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập đủ thông tin ví điện tử'),
          ),
        );
        return;
      }
    }

    if (_receiveMethod == _PaymentReceiveMethod.wallet && isTripPay) {
      final verified =
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const TripPayPinPage(redirectToHome: false),
            ),
          ) ??
          false;
      if (!verified) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xác thực TripPay thất bại')),
        );
        return;
      }
    }
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    final payment = {
      'method': _receiveMethod == _PaymentReceiveMethod.bank
          ? 'bank'
          : 'wallet',
      'bankName': bankName,
      'accountNumber': bankAccount,
      'accountOwner': bankOwner,
      'wallet': walletName,
      'walletAccountNumber': isTripPay ? '' : walletAccount,
    };

    final updatedMethods = List<Map<String, dynamic>>.from(_linkedMethods);
    if (_editingIndex != null && _editingIndex! < updatedMethods.length) {
      updatedMethods[_editingIndex!] = payment;
    } else {
      updatedMethods.add(payment);
    }

    final updated = {
      ...widget.businessProfile,
      'payment': payment,
      'paymentMethods': updatedMethods,
    };

    final result = await service.updateExtendedProfile({
      'businessProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật thanh toán')));
      setState(() {
        _linkedMethods
          ..clear()
          ..addAll(updatedMethods);
        _showLinked = true;
        _editingIndex = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key, required this.businessProfile});

  final Map<String, dynamic> businessProfile;

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _orderNotifications = true;
  bool _promoNotifications = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final notifications =
        (widget.businessProfile['notifications'] as Map<String, dynamic>?) ??
        {};
    _orderNotifications = notifications['order'] ?? true;
    _promoNotifications = notifications['promo'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Thông báo đơn hàng'),
              value: _orderNotifications,
              onChanged: (value) => setState(() {
                _orderNotifications = value;
                _save();
              }),
            ),
            SwitchListTile(
              title: const Text('Thông báo khuyến mãi'),
              value: _promoNotifications,
              onChanged: (value) => setState(() {
                _promoNotifications = value;
                _save();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    final notifications = {
      'order': _orderNotifications,
      'promo': _promoNotifications,
    };

    final updated = {...widget.businessProfile, 'notifications': notifications};

    final result = await service.updateExtendedProfile({
      'businessProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông báo')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỗ trợ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Chủ đề',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _submit,
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSending) return;
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin')),
      );
      return;
    }

    setState(() => _isSending = true);
    final service = FirebaseAccountService();
    final result = await service.submitSupportRequest(
      subject: subject,
      message: message,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    if (result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu hỗ trợ')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.error ?? 'Gửi thất bại')));
    }
  }
}

class AutoReplySettingsPage extends StatefulWidget {
  const AutoReplySettingsPage({super.key, required this.businessProfile});

  final Map<String, dynamic> businessProfile;

  @override
  State<AutoReplySettingsPage> createState() => _AutoReplySettingsPageState();
}

class _AutoReplySettingsPageState extends State<AutoReplySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late bool _enabled;
  late final TextEditingController _messageController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final autoReply = widget.businessProfile['autoReply'];
    if (autoReply is Map<String, dynamic>) {
      _enabled = autoReply['enabled'] == true;
      _messageController = TextEditingController(text: (autoReply['message'] ?? '').toString());
    } else {
      _enabled = false;
      _messageController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn tự động')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Bật tin nhắn tự động'),
                subtitle: const Text('Hệ thống sẽ tự động phản hồi khách hàng khi họ gửi tin nhắn đầu tiên.'),
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              if (_enabled)
                TextFormField(
                  controller: _messageController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung phản hồi',
                    border: OutlineInputBorder(),
                    hintText: 'Xin chào, chúng tôi có thể giúp gì cho bạn?',
                  ),
                  validator: (value) {
                    if (_enabled && (value == null || value.trim().isEmpty)) {
                      return 'Vui lòng nhập nội dung phản hồi';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final service = FirebaseAccountService();
    
    final autoReply = {
      'enabled': _enabled,
      'message': _messageController.text.trim(),
    };
    
    final updated = {
      ...widget.businessProfile,
      'autoReply': autoReply,
    };

    final result = await service.updateExtendedProfile({
      'businessProfile': updated,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật tin nhắn tự động')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Cập nhật thất bại')),
      );
    }
  }
}
