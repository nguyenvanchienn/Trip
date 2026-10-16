import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/data/firebase/firebase_menu_service.dart';
import 'package:tourn/domain/storage/storage_service.dart';
import 'package:tourn/ultils.enums/image_utils.dart';

import 'business_account_settings_screen.dart';
import '../menu/widgets/Menu_items/widgets/cacdondathang_page.dart';
import 'business_reviews_page.dart';
import 'business_service_management_screen.dart';
import 'service_create/business_create_service_screen.dart';
import '../menu/widgets/Menu_items/widgets/congcuquangba_page.dart';
import '../menu/widgets/Menu_items/widgets/doanhthu_page.dart';

class BusinessAccountScreen extends StatefulWidget {
  const BusinessAccountScreen({super.key});

  @override
  State<BusinessAccountScreen> createState() => _BusinessAccountScreenState();
}

class _BusinessAccountScreenState extends State<BusinessAccountScreen> {
  final FirebaseAccountService _service = FirebaseAccountService();
  final ImagePicker _picker = ImagePicker();
  bool? _isOpen;
  bool _isTogglingOpen = false;

  /// Stream lắng nghe thay đổi real-time từ Firestore
  Stream<Map<String, dynamic>?> get _profileStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản doanh nghiệp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _profileStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final businessProfile =
              (data['businessProfile'] as Map<String, dynamic>?) ?? {};
          if (businessProfile.isEmpty) {
            return const Center(child: Text('Chưa có tài khoản doanh nghiệp'));
          }

          final media =
              (businessProfile['media'] as Map<String, dynamic>?) ?? {};
          final avatarPath = media['avatarPath'] as String?;

          final stats =
              (businessProfile['stats'] as Map<String, dynamic>?) ?? {};
          final totalOrders = stats['totalOrders'] ?? 0;
          final revenue = stats['revenue'] ?? '0 đ';
          final rating = stats['rating'] ?? '0.0';

          // Đọc thẳng từ stream, chỉ dùng _isOpen khi đang toggle (optimistic UI)
          final firebaseIsOpen = businessProfile['isOpen'] as bool? ?? true;
          final effectiveIsOpen = _isTogglingOpen ? (_isOpen ?? firebaseIsOpen) : firebaseIsOpen;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeaderCard(
                name: businessProfile['name'] ?? 'Cửa hàng',
                category: businessProfile['category'] ?? 'Chưa cập nhật',
                address: businessProfile['address'] ?? 'Chưa cập nhật',
                avatarPath: avatarPath,
                isOpen: effectiveIsOpen,
              ),
              const SizedBox(height: 16),
              _sectionTitle('Tổng quan hôm nay'),
              const SizedBox(height: 8),
              _buildStatsRow(
                totalOrders: totalOrders.toString(),
                revenue: revenue.toString(),
                rating: rating.toString(),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Hành động nhanh'),
              const SizedBox(height: 8),
              _buildQuickActions(
                isOpen: effectiveIsOpen,
                isLoading: _isTogglingOpen,
                onToggleOpen: _toggleOpen,
                onCreateService: _openCreateService,
              ),
              const SizedBox(height: 16),
              _sectionTitle('Quản lý cửa hàng'),
              const SizedBox(height: 8),
              _buildManagementGrid(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required String name,
    required String category,
    required String address,
    required String? avatarPath,
    required bool isOpen,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF1ECFF), Color(0xFFE8F1FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(avatarPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(category, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                _buildStatusChip(isOpen: isOpen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Lấy ImageProvider phù hợp dựa vào loại path (URL hoặc file local)
  ImageProvider? _getAvatarProvider(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    if (avatarPath.startsWith('data:image')) {
      return getImageProvider(avatarPath);
    }
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return NetworkImage(avatarPath);
    }
    // File local: kiểm tra tồn tại
    if (!kIsWeb && File(avatarPath).existsSync()) {
      return FileImage(File(avatarPath));
    }
    return null;
  }

  Widget _buildAvatar(String? avatarPath) {
    final avatarProvider = _getAvatarProvider(avatarPath);
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: () => _handleAvatarTap(hasAvatar: avatarProvider != null),
        containedInkWell: true,
        radius: 32,
        highlightShape: BoxShape.circle,
        child: SizedBox(
          width: 56,
          height: 56,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF6B5FB5),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAvatarTap({required bool hasAvatar}) async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Tải ảnh lên'),
                onTap: () => Navigator.of(context).pop(_AvatarAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(_AvatarAction.camera),
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Xóa ảnh',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
                ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case _AvatarAction.gallery:
        await _pickAvatar(ImageSource.gallery);
        break;
      case _AvatarAction.camera:
        await _pickAvatar(ImageSource.camera);
        break;
      case _AvatarAction.remove:
        final confirmed = await _confirmRemoveAvatar();
        if (confirmed) {
          await _saveAvatarPath(null);
        }
        break;
      case null:
        break;
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (!mounted || picked == null) return;
    final reviewedPath = await _reviewAvatar(picked);
    if (!mounted || reviewedPath == null) return;

    // Upload ảnh lên Firebase Storage để lưu URL vĩnh viễn
    final uploadedUrl = await _uploadAvatarToStorage(reviewedPath);
    if (!mounted) return;
    await _saveAvatarPath(uploadedUrl ?? reviewedPath);
  }

  /// Upload ảnh avatar lên Firebase Storage, trả về download URL
  Future<String?> _uploadAvatarToStorage(String localPath) async {
    try {
      final storage = context.read<StorageService>();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final ext = localPath.contains('.') ? localPath.substring(localPath.lastIndexOf('.')) : '.png';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final destination = 'business_media/$uid/avatar/$ts$ext';
      final downloadUrl = await storage.uploadFile(localPath, destination);
      return downloadUrl;
    } catch (e) {
      debugPrint('Upload avatar thất bại: $e');
      return null;
    }
  }

  Future<String?> _reviewAvatar(XFile picked) async {
    return Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => _AvatarReviewPage(imageFile: picked)),
    );
  }

  Future<bool> _confirmRemoveAvatar() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa ảnh đại diện?'),
          content: const Text('Ảnh đại diện sẽ bị xóa khỏi hồ sơ cửa hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _saveAvatarPath(String? path) async {
    final profile = await _service.getExtendedProfile() ?? {};
    final businessProfile = Map<String, dynamic>.from(
      (profile['businessProfile'] as Map<String, dynamic>?) ?? {},
    );
    final media = Map<String, dynamic>.from(
      (businessProfile['media'] as Map<String, dynamic>?) ?? {},
    );

    if (path == null || path.isEmpty) {
      media.remove('avatarPath');
    } else {
      media['avatarPath'] = path;
    }
    businessProfile['media'] = media;

    await _service.updateExtendedProfile({'businessProfile': businessProfile});
    // StreamBuilder tự cập nhật UI khi Firestore thay đổi, không cần setState
  }

  Widget _buildStatusChip({required bool isOpen}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFDCF6E6) : const Color(0xFFFCE4E4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Đang mở' : 'Đang đóng',
        style: TextStyle(
          color: isOpen ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required String totalOrders,
    required String revenue,
    required String rating,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseMenuService().streamBusinessOrders(),
      builder: (context, snapshot) {
        int todayOrdersCount = 0;
        double todayRevenue = 0;

        if (snapshot.hasData) {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          for (final order in snapshot.data!) {
            final createdAt = (order['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            if (createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay)) {
              todayOrdersCount++;
              final price = (order['totalPrice'] as num?)?.toDouble() ?? 0;
              todayRevenue += price;
            }
          }
        }

        final formattedRevenue = '${todayRevenue.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} đ';

        return Row(
          children: [
            _buildStatCard('Đơn hôm nay', todayOrdersCount.toString(), onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CacDonDatHangPage()));
            }),
            const SizedBox(width: 8),
            _buildStatCard('Doanh thu', formattedRevenue),
            const SizedBox(width: 8),
            _buildStatCard('Đánh giá', rating),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1F6B5FB5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions({
    required bool isOpen,
    required bool isLoading,
    required VoidCallback onToggleOpen,
    required VoidCallback onCreateService,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onToggleOpen,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isOpen ? Icons.pause_circle : Icons.play_circle),
            label: Text(isOpen ? 'Tạm đóng' : 'Mở cửa'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCreateService,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Tạo dịch vụ'),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementGrid() {
    final items = [
      _ManagementItem('Quản lý dịch vụ', Icons.inventory_2_outlined),
      _ManagementItem('Đơn hàng', Icons.receipt_long_outlined),
      _ManagementItem('Doanh thu', Icons.bar_chart_outlined),
      _ManagementItem('Đánh giá', Icons.star_outline),
      _ManagementItem('Khuyến mãi', Icons.local_offer_outlined),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: [
        for (final item in items)
          InkWell(
            onTap: () => _openManagement(item.title),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x1F6B5FB5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: const Color(0xFF6B5FB5)),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _toggleOpen() async {
    // Đọc giá trị isOpen hiện tại từ Firestore thay vì dùng giá trị mặc định
    final profile = await _service.getExtendedProfile() ?? {};
    final bp = (profile['businessProfile'] as Map<String, dynamic>?) ?? {};
    final current = bp['isOpen'] as bool? ?? true;
    final newValue = !current;

    setState(() {
      _isOpen = newValue;
      _isTogglingOpen = true;
    });

    try {
      final profile = await _service.getExtendedProfile() ?? {};
      final businessProfile = Map<String, dynamic>.from(
        (profile['businessProfile'] as Map<String, dynamic>?) ?? {},
      );
      businessProfile['isOpen'] = newValue;
      final result = await _service.updateExtendedProfile({
        'businessProfile': businessProfile,
      });

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue ? '✅ Đã mở cửa hàng' : '⏸ Đã tạm đóng cửa hàng'),
            backgroundColor: newValue
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
          ),
        );
      } else {
        // Rollback nếu lỗi
        setState(() => _isOpen = current);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${result.error ?? 'Không thể cập nhật'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Rollback nếu lỗi
      setState(() => _isOpen = current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingOpen = false);
      }
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BusinessAccountSettingsScreen()),
    );
  }

  void _openCreateService() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BusinessCreateServiceScreen()),
    );
  }

  void _openManagement(String title) {
    switch (title) {
      case 'Quản lý dịch vụ':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const BusinessServiceManagementScreen(),
          ),
        );
        break;
      case 'Đơn hàng':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CacDonDatHangPage()));
        break;
      case 'Doanh thu':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const DoanhThuPage()));
        break;
      case 'Đánh giá':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BusinessReviewsPage()));
        break;
      case 'Khuyến mãi':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CongCuQuangBaPage()));
        break;
      default:
        _showComingSoon(title);
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title đang phát triển')));
  }
}

class _ManagementItem {
  const _ManagementItem(this.title, this.icon);

  final String title;
  final IconData icon;
}

enum _AvatarAction { gallery, camera, remove }

class _AvatarReviewPage extends StatefulWidget {
  const _AvatarReviewPage({required this.imageFile});

  final XFile imageFile;

  @override
  State<_AvatarReviewPage> createState() => _AvatarReviewPageState();
}

class _AvatarReviewPageState extends State<_AvatarReviewPage> {
  late XFile _currentFile;
  final TransformationController _controller = TransformationController();
  Size? _imageSize;
  double _lastCropSize = 0;
  bool _isSaving = false;
  bool _transformInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentFile = widget.imageFile;
    _loadImageInfo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xem ảnh đại diện')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cropSize = min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final effectiveCropSize = min(cropSize, 320.0);
                  _lastCropSize = effectiveCropSize;

                  final imageSize = _imageSize;
                  if (imageSize == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final baseScale = _calculateBaseScale(
                    imageSize: imageSize,
                    cropSize: effectiveCropSize,
                  );

                  final baseWidth = imageSize.width * baseScale;
                  final baseHeight = imageSize.height * baseScale;
                  _ensureInitialTransform(
                    cropSize: effectiveCropSize,
                    baseWidth: baseWidth,
                    baseHeight: baseHeight,
                  );

                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRect(
                          child: SizedBox(
                            width: effectiveCropSize,
                            height: effectiveCropSize,
                            child: InteractiveViewer(
                              transformationController: _controller,
                              minScale: 1,
                              maxScale: 4,
                              boundaryMargin: const EdgeInsets.all(120),
                              constrained: false,
                              child: SizedBox(
                                width: baseWidth,
                                height: baseHeight,
                                child: Image.file(
                                  File(_currentFile.path),
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(effectiveCropSize, effectiveCropSize),
                            painter: _CircleCropOverlayPainter(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              final savedPath = await _saveCroppedAvatar(
                                _lastCropSize,
                              );
                              if (!mounted || savedPath == null) return;
                              Navigator.of(context).pop(savedPath);
                            },
                      child: const Text('Dùng ảnh này'),
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

  Future<void> _loadImageInfo() async {
    final bytes = await File(_currentFile.path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (!mounted || decoded == null) return;
    final imageSize = Size(decoded.width.toDouble(), decoded.height.toDouble());
    setState(() {
      _imageSize = imageSize;
      _transformInitialized = false;
    });
  }

  double _calculateBaseScale({
    required Size imageSize,
    required double cropSize,
  }) {
    if (cropSize <= 0) return 1;
    return max(cropSize / imageSize.width, cropSize / imageSize.height);
  }

  void _ensureInitialTransform({
    required double cropSize,
    required double baseWidth,
    required double baseHeight,
  }) {
    if (_transformInitialized) return;
    _transformInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dx = (cropSize - baseWidth) / 2;
      final dy = (cropSize - baseHeight) / 2;
      _controller.value = Matrix4.identity()..translate(dx, dy);
    });
  }

  Future<String?> _saveCroppedAvatar(double cropSize) async {
    if (_isSaving) return null;
    final imageSize = _imageSize;
    if (imageSize == null || cropSize <= 0) return null;
    final baseScale = _calculateBaseScale(
      imageSize: imageSize,
      cropSize: cropSize,
    );

    setState(() => _isSaving = true);
    try {
      final bytes = await File(_currentFile.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final cropRect = _getCropRect(
        cropSize: cropSize,
        baseScale: baseScale,
        imageWidth: decoded.width,
        imageHeight: decoded.height,
      );
      final cropped = img.copyCrop(
        decoded,
        x: cropRect.left.round(),
        y: cropRect.top.round(),
        width: cropRect.width.round(),
        height: cropRect.height.round(),
      );
      final masked = _applyCircleMask(cropped);
      final outputBytes = img.encodePng(masked);

      // Lưu vào thư mục vĩnh viễn (documents), không phải cache
      final docsDir = await getApplicationDocumentsDirectory();
      final avatarsDir = Directory('${docsDir.path}/business_avatars');
      if (!avatarsDir.existsSync()) {
        await avatarsDir.create(recursive: true);
      }
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputFile = File('${avatarsDir.path}/$fileName');
      await outputFile.writeAsBytes(outputBytes, flush: true);
      return outputFile.path;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Rect _getCropRect({
    required double cropSize,
    required double baseScale,
    required int imageWidth,
    required int imageHeight,
  }) {
    final matrix = _controller.value;
    final inverse = Matrix4.inverted(matrix);
    final viewport = Rect.fromLTWH(0, 0, cropSize, cropSize);
    final childRect = MatrixUtils.transformRect(inverse, viewport);

    final left = (childRect.left / baseScale)
        .clamp(0.0, (imageWidth - 1).toDouble())
        .toDouble();
    final top = (childRect.top / baseScale)
        .clamp(0.0, (imageHeight - 1).toDouble())
        .toDouble();
    final right = (childRect.right / baseScale)
        .clamp(1.0, imageWidth.toDouble())
        .toDouble();
    final bottom = (childRect.bottom / baseScale)
        .clamp(1.0, imageHeight.toDouble())
        .toDouble();

    final width = max(1.0, right - left);
    final height = max(1.0, bottom - top);
    final side = min(width, height);

    return Rect.fromLTWH(left, top, side, side);
  }

  img.Image _applyCircleMask(img.Image source) {
    final size = min(source.width, source.height);
    final output = img.Image(width: size, height: size, numChannels: 4);
    final radius = size / 2.0;
    final center = Offset(radius, radius);

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final dx = x - center.dx;
        final dy = y - center.dy;
        if (dx * dx + dy * dy <= radius * radius) {
          final pixel = source.getPixel(x, y);
          output.setPixel(x, y, pixel);
        } else {
          output.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
    return output;
  }
}

class _CircleCropOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.45);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
