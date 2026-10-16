import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/domain/user_repository/user_repository.dart';

/// Trang chọn các chi tiết để ghim hiển thị trên phần Giới thiệu
class PinnedDetailsPage extends StatefulWidget {
  const PinnedDetailsPage({super.key});

  @override
  State<PinnedDetailsPage> createState() => _PinnedDetailsPageState();
}

class _PinnedDetailsPageState extends State<PinnedDetailsPage> {
  final FirebaseAccountService _accountService = FirebaseAccountService();
  bool _loading = true;

  // Các trường có thể ghim
  Map<String, String?> _availableFields = {};
  List<String> _pinnedFields = [];

  // Tên hiển thị cho các trường (không bao gồm bio)
  static const Map<String, Map<String, dynamic>> _fieldInfo = {
    'category': {'label': 'Hạng mục', 'icon': Icons.category},
    'work': {'label': 'Công việc', 'icon': Icons.work},
    'education': {'label': 'Học vấn', 'icon': Icons.school},
    'address': {'label': 'Địa chỉ', 'icon': Icons.location_on},
    'hobbies': {'label': 'Sở thích', 'icon': Icons.favorite},
    'travelPlace': {'label': 'Địa điểm du lịch yêu thích', 'icon': Icons.place},
    'socialLink': {'label': 'Liên kết mạng xã hội', 'icon': Icons.link},
    'email': {'label': 'Email', 'icon': Icons.email},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Lấy thông tin từ user_profiles
      final profileData = await _accountService.getExtendedProfile();
      final pinnedData = profileData?['pinnedFields'] as List<dynamic>?;

      // Lấy bio và address từ user collection
      final userRepo = context.read<UserRepository>();
      final user = await userRepo.getCurrentUser();

      setState(() {
        _availableFields = {
          'category': profileData?['category'],
          'work': profileData?['work'],
          'education': profileData?['education'],
          'address': user?.address, // Lấy từ user
          'hobbies': profileData?['hobbies'],
          'travelPlace': profileData?['travelPlace'],
          'socialLink': profileData?['socialLink'],
          'email': user?.email, // Lấy từ user
        };

        _pinnedFields = pinnedData?.cast<String>() ?? [];
      });
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePin(String field) async {
    setState(() {
      if (_pinnedFields.contains(field)) {
        _pinnedFields.remove(field);
      } else {
        _pinnedFields.add(field);
      }
    });

    await _accountService.updateExtendedProfile({
      'pinnedFields': _pinnedFields,
    });
  }

  Future<void> _reorderPins(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    setState(() {
      final item = _pinnedFields.removeAt(oldIndex);
      _pinnedFields.insert(newIndex, item);
    });

    await _accountService.updateExtendedProfile({
      'pinnedFields': _pinnedFields,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đã ghim'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn thông tin để hiển thị trên phần Giới thiệu của trang cá nhân',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách các mục đã ghim (có thể kéo thả để sắp xếp)
                  if (_pinnedFields.isNotEmpty) ...[
                    Text(
                      'Đã ghim (kéo để sắp xếp)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pinnedFields.length,
                      onReorder: _reorderPins,
                      itemBuilder: (context, index) {
                        final field = _pinnedFields[index];
                        final info = _fieldInfo[field];
                        final value = _availableFields[field];

                        return Card(
                          key: ValueKey(field),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                info?['icon'] ?? Icons.info,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            title: Text(info?['label'] ?? field),
                            subtitle: Text(
                              value ?? 'Chưa có thông tin',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: value == null
                                    ? Theme.of(context).hintColor
                                    : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.push_pin,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _togglePin(field),
                                  tooltip: 'Bỏ ghim',
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Danh sách các mục chưa ghim
                  Text(
                    'Có thể ghim',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._fieldInfo.entries
                      .where((e) => !_pinnedFields.contains(e.key))
                      .map((entry) {
                        final field = entry.key;
                        final info = entry.value;
                        final value = _availableFields[field];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                info['icon'] ?? Icons.info,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text(info['label'] ?? field),
                            subtitle: Text(
                              value ??
                                  'Chưa có thông tin - Thêm trong Chỉnh sửa trang cá nhân',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: value == null
                                    ? Theme.of(context).hintColor
                                    : null,
                                fontStyle: value == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.push_pin_outlined,
                                color: value != null
                                    ? Colors.grey
                                    : Colors.grey[300],
                              ),
                              onPressed: value != null
                                  ? () => _togglePin(field)
                                  : null,
                              tooltip: value != null
                                  ? 'Ghim'
                                  : 'Cần thêm thông tin trước',
                            ),
                            enabled: value != null,
                          ),
                        );
                      }),

                  const SizedBox(height: 16),
                  Text(
                    'Các mục đã ghim sẽ hiển thị trên phần Giới thiệu của trang cá nhân, giúp mọi người biết thêm về bạn.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
