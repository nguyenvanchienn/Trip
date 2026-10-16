// Trang chỉnh sửa trang cá nhân
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';
import 'package:tourn/models/user_model.dart';
import 'package:tourn/ultils.enums/image_utils.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/accountmanagement/phone_number.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/accountmanagement/email.dart';
import 'package:tourn/Ui/main/category/home/widgets/profile/pinned_details_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // controllers are used for dialog editing
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _pinnedDetailsCtrl = TextEditingController();
  final TextEditingController _socialLinkCtrl = TextEditingController();
  final TextEditingController _workCtrl = TextEditingController();
  final TextEditingController _educationCtrl = TextEditingController();
  final TextEditingController _hobbiesCtrl = TextEditingController();

  // key used by _onSave validation (legacy)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  final FirebaseAccountService _accountService = FirebaseAccountService();

  String? _avatarPath;
  bool _isLoading = false;
  UserModel? _currentUser;

  // Profile data stored in Firestore
  String? _category;
  String? _pinnedDetails;
  String? _socialLink;
  String? _work;
  String? _education;
  String? _hobbies;
  List<String> _interests = []; // music, tv, movies, games
  String? _travelPlace;
  List<String> _pinnedFields =
      []; // Các trường đã ghim để hiển thị trên Giới thiệu

  // helper to show simple edit dialog
  Future<void> _showEditDialog({
    required String title,
    required TextEditingController controller,
    required Future<void> Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Chỉnh sửa $title'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(hintText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                try {
                  await onSave(v);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu thay đổi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // reload local copy from firestore
                  await _loadUserData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi lưu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              Navigator.pop(c);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      // reset any local file path - we'll show network image instead
      _avatarPath = null;
    });
    try {
      final userRepository = context.read<UserRepository>();
      final user = await userRepository.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nameCtrl.text = user.displayName;
          _emailCtrl.text = user.email;
          _phoneCtrl.text = user.phone ?? '';
          _bioCtrl.text = user.bio ?? '';
          _addressCtrl.text = user.address ?? '';
        });
      }

      // Load extended profile data from Firestore
      final profileData = await _accountService.getExtendedProfile();
      if (profileData != null && mounted) {
        setState(() {
          _category = profileData['category'];
          _pinnedDetails = profileData['pinnedDetails'];
          _socialLink = profileData['socialLink'];
          _work = profileData['work'];
          _education = profileData['education'];
          _hobbies = profileData['hobbies'];
          _interests = List<String>.from(profileData['interests'] ?? []);
          _travelPlace = profileData['travelPlace'];
          _pinnedFields = List<String>.from(profileData['pinnedFields'] ?? []);

          _categoryCtrl.text = _category ?? '';
          _pinnedDetailsCtrl.text = _pinnedDetails ?? '';
          _socialLinkCtrl.text = _socialLink ?? '';
          _workCtrl.text = _work ?? '';
          _educationCtrl.text = _education ?? '';
          _hobbiesCtrl.text = _hobbies ?? '';
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Persistence is now handled per-field, so this method may be unused.
  Future<void> _saveProfile() async {
    // kept for backwards compatibility if needed
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    _categoryCtrl.dispose();
    _pinnedDetailsCtrl.dispose();
    _socialLinkCtrl.dispose();
    _workCtrl.dispose();
    _educationCtrl.dispose();
    _hobbiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      print('pickImage: result=$picked');
      if (picked != null) {
        setState(() => _avatarPath = picked.path);

        try {
          final repo = context.read<UserRepository>();
          print('pickImage: uploading ${picked.path}');
          final url = await repo.updateProfilePhoto(File(picked.path));
          print('pickImage: upload returned url=$url');
          if (url != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật ảnh đại diện'),
                backgroundColor: Colors.green,
              ),
            );
            // clear the local path so we show the network version
            setState(() => _avatarPath = null);
            await _loadUserData(); // refresh user data
          } else {
            print('pickImage: upload returned null');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể cập nhật ảnh đại diện'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          print('pickImage error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải ảnh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('pickImage exception: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Bottom sheet for editing/deleting bio
  void _showBioBottomSheet() {
    final ctrl = TextEditingController(text: _currentUser?.bio ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiểu sử',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Viết tiểu sử của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_currentUser?.bio ?? '').isNotEmpty
                        ? () async {
                            final repo = context.read<UserRepository>();
                            await repo.updateBio('');
                            if (mounted) Navigator.pop(c);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa tiểu sử'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await _loadUserData();
                          }
                        : null,
                    child: const Text('Xóa tiểu sử'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newBio = ctrl.text.trim();
                      if (newBio.isNotEmpty) {
                        final repo = context.read<UserRepository>();
                        await repo.updateBio(newBio);
                        if (mounted) Navigator.pop(c);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật tiểu sử'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _loadUserData();
                      }
                    },
                    child: const Text('Lưu'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh (Camera)'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Xóa ảnh hiện tại'),
                onTap: () {
                  Navigator.pop(c);
                  setState(() => _avatarPath = null);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Đóng'),
              onTap: () => Navigator.pop(c),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    // Xử lý lưu thông tin đã chỉnh sửa
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'avatar': _avatarPath,
    };

    Navigator.pop(context, data);
  }

  /// Show category picker dialog
  Future<void> _showCategoryPicker() async {
    final categories = [
      'Người sáng tạo nội dung số',
      'Nghệ sĩ',
      'Nhạc sĩ/Ban nhạc',
      'Blogger',
      'Doanh nhân',
      'Nhiếp ảnh gia',
      'Nhà văn',
      'Vận động viên',
      'Người mẫu',
      'Nhân vật công chúng',
      'Chuyên gia du lịch',
      'Khác',
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Chọn hạng mục'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(categories[i]),
              trailing: _category == categories[i]
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(c, categories[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selected != null) {
      await _accountService.updateExtendedProfile({'category': selected});
      setState(() => _category = selected);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hạng mục'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Toggle interest item
  void _toggleInterest(String interest, bool add) async {
    setState(() {
      if (add) {
        if (!_interests.contains(interest)) {
          _interests.add(interest);
        }
      } else {
        _interests.remove(interest);
      }
    });

    await _accountService.updateExtendedProfile({'interests': _interests});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa trang cá nhân'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _showImageOptions,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          key: ValueKey(_avatarPath ?? _currentUser?.photoUrl),
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _avatarPath != null
                              ? FileImage(File(_avatarPath!)) as ImageProvider
                              : (_currentUser?.photoUrl != null
                                    ? getImageProvider(_currentUser!.photoUrl!)
                                    : null),
                          child:
                              _avatarPath == null &&
                                  _currentUser?.photoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.camera_alt, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Tiểu sử – hiển thị trên header, chỉnh sửa/xóa qua bottom sheet
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Tiểu sử'),
                    subtitle: Text(_currentUser?.bio ?? 'Thêm tiểu sử của bạn'),
                    trailing: const Icon(Icons.edit),
                    onTap: _showBioBottomSheet,
                  ),
                ),
                const SizedBox(height: 12),
                // Chi tiết đã ghim - để hiển thị trên Giới thiệu
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.push_pin),
                    title: const Text('Chi tiết đã ghim'),
                    subtitle: Text(
                      _pinnedFields.isEmpty
                          ? 'Chọn thông tin để hiển thị trên Giới thiệu'
                          : '${_pinnedFields.length} mục đã ghim',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PinnedDetailsPage(),
                        ),
                      ).then((_) => _loadUserData());
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Hạng mục',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(_category ?? 'Chọn hạng mục'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _showCategoryPicker();
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Thông tin cá nhân',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Số điện thoại'),
                      subtitle: Text(
                        _currentUser?.phone ?? 'Thêm số điện thoại',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        // Navigate to phone settings page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhoneListPage(),
                          ),
                        ).then((_) => _loadUserData());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Địa chỉ'),
                      subtitle: Text(_currentUser?.address ?? 'Thêm địa chỉ'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _showEditDialog(
                          title: 'Địa chỉ',
                          controller: _addressCtrl,
                          onSave: (v) async {
                            await context.read<UserRepository>().updateUser(
                              _currentUser!.copyWith(address: v),
                            );
                            setState(
                              () => _currentUser = _currentUser?.copyWith(
                                address: v,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Liên kết',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('Mạng xã hội'),
                      subtitle: Text(
                        _socialLink ?? 'Thêm liên kết mạng xã hội',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _showEditDialog(
                          title: 'Liên kết mạng xã hội',
                          controller: _socialLinkCtrl,
                          onSave: (v) async {
                            await _accountService.updateExtendedProfile({
                              'socialLink': v,
                            });
                            setState(() => _socialLink = v);
                          },
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(_currentUser?.email ?? ''),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        // Navigate to email settings page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmailListPage(),
                          ),
                        ).then((_) => _loadUserData());
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Cộng đồng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.group),
                      title: const Text('Nhóm'),
                      subtitle: const Text('Liên kết nhóm của bạn'),
                      onTap: () async {
                        // Show community link dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Ưu đãi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.local_offer),
                      title: const Text('Khuyến mãi hoặc đường link...'),
                      subtitle: const Text('Thêm ưu đãi của bạn'),
                      onTap: () async {
                        final ctl = TextEditingController();
                        await _showEditDialog(
                          title: 'Ưu đãi / Khuyến mãi',
                          controller: ctl,
                          onSave: (v) async {
                            await _accountService.updateExtendedProfile({
                              'promotion': v,
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Công việc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.work),
                      title: const Text('Kinh nghiệm làm việc'),
                      subtitle: Text(_work ?? 'Thêm kinh nghiệm làm việc'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _showEditDialog(
                          title: 'Kinh nghiệm làm việc',
                          controller: _workCtrl,
                          onSave: (v) async {
                            await _accountService.updateExtendedProfile({
                              'work': v,
                            });
                            setState(() => _work = v);
                          },
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Giáo dục',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.school),
                      title: const Text('Học vấn'),
                      subtitle: Text(_education ?? 'Thêm thông tin học vấn'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _showEditDialog(
                          title: 'Học vấn',
                          controller: _educationCtrl,
                          onSave: (v) async {
                            await _accountService.updateExtendedProfile({
                              'education': v,
                            });
                            setState(() => _education = v);
                          },
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Sở thích',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('Sở thích'),
                      subtitle: Text(_hobbies ?? 'Thêm sở thích của bạn'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        await _showEditDialog(
                          title: 'Sở thích',
                          controller: _hobbiesCtrl,
                          onSave: (v) async {
                            await _accountService.updateExtendedProfile({
                              'hobbies': v,
                            });
                            setState(() => _hobbies = v);
                          },
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Mối quan tâm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.music_note),
                      title: const Text('Nhạc'),
                      subtitle: Text(
                        _interests.contains('music')
                            ? 'Đã thêm'
                            : 'Thêm sở thích âm nhạc',
                      ),
                      trailing: Checkbox(
                        value: _interests.contains('music'),
                        onChanged: (v) => _toggleInterest('music', v ?? false),
                      ),
                      onTap: () => _toggleInterest(
                        'music',
                        !_interests.contains('music'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.tv),
                      title: const Text('Chương trình TV'),
                      subtitle: Text(
                        _interests.contains('tv')
                            ? 'Đã thêm'
                            : 'Thêm chương trình yêu thích',
                      ),
                      trailing: Checkbox(
                        value: _interests.contains('tv'),
                        onChanged: (v) => _toggleInterest('tv', v ?? false),
                      ),
                      onTap: () =>
                          _toggleInterest('tv', !_interests.contains('tv')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.movie),
                      title: const Text('Phim'),
                      subtitle: Text(
                        _interests.contains('movies')
                            ? 'Đã thêm'
                            : 'Thêm phim yêu thích',
                      ),
                      trailing: Checkbox(
                        value: _interests.contains('movies'),
                        onChanged: (v) => _toggleInterest('movies', v ?? false),
                      ),
                      onTap: () => _toggleInterest(
                        'movies',
                        !_interests.contains('movies'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.videogame_asset),
                      title: const Text('Game'),
                      subtitle: Text(
                        _interests.contains('games')
                            ? 'Đã thêm'
                            : 'Thêm game yêu thích',
                      ),
                      trailing: Checkbox(
                        value: _interests.contains('games'),
                        onChanged: (v) => _toggleInterest('games', v ?? false),
                      ),
                      onTap: () => _toggleInterest(
                        'games',
                        !_interests.contains('games'),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Du lịch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.place),
                      title: const Text('Địa điểm yêu thích'),
                      subtitle: Text(_travelPlace ?? 'Thêm địa điểm du lịch'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final ctl = TextEditingController(
                          text: _travelPlace ?? '',
                        );
                        await _showEditDialog(
                          title: 'Địa điểm du lịch yêu thích',
                          controller: ctl,
                          onSave: (v) async {
                            await _accountService.updateExtendedProfile({
                              'travelPlace': v,
                            });
                            setState(() => _travelPlace = v);
                          },
                        );
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  initiallyExpanded: true,
                  title: const Text(
                    'Huy hiệu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Bạn chưa nhận được huy hiệu nào trong tuần này.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
