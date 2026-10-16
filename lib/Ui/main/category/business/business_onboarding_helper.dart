import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tourn/data/firebase/firebase_account_service.dart';
import 'package:tourn/domain/notification_repository/notification_repository.dart';
import 'package:tourn/domain/storage/storage_service.dart';
import 'package:tourn/models/notification_model.dart';

import 'business_onboarding_step_basic.dart';
import 'business_onboarding_step_license.dart';
import 'business_onboarding_step_location.dart';
import 'business_onboarding_step_media.dart';
import 'business_onboarding_review_screen.dart';

class BusinessOnboardingHelper {
  static Future<void> ensureBusinessSetup(BuildContext context) async {
    final service = FirebaseAccountService();
    final settings = await service.getAccountSettings();
    if (!settings.isBusinessAccount) return;

    final profile = await service.getExtendedProfile() ?? {};
    final completed = profile['businessSetupCompleted'] == true;
    if (completed) return;
    if (!context.mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    // Đợi 600ms để hiệu ứng chuyển trang (transition) hoàn tất hoàn toàn.
    // Việc gọi showDialog ngay khi đang chuyển trang (đặc biệt trên iOS hoặc Hero animation)
    // có thể gây treo app hoặc lỗi layout.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;

    final startBusiness = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mở tài khoản kinh doanh?'),
          content: const Text(
            'Bạn có muốn mở tài khoản kinh doanh để đăng dịch vụ và tiếp cận nhiều khách hơn không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Bắt đầu'),
            ),
          ],
        );
      },
    );

    await service.updateExtendedProfile({
      'businessOnboardingShown': true,
      'businessOnboardingDismissed': startBusiness != true,
      'businessOnboardingUpdatedAt': DateTime.now().toIso8601String(),
    });

    if (startBusiness == true && context.mounted) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => _BusinessSetupScreen(service: service),
        ),
      );
    }
  }
}

class _BusinessSetupScreen extends StatefulWidget {
  const _BusinessSetupScreen({required this.service});

  final FirebaseAccountService service;

  @override
  State<_BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<_BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoryController = TextEditingController();
  final _pageController = PageController();
  final _picker = ImagePicker();
  final List<XFile> _shopImages = [];
  final List<XFile> _locationImages = [];
  XFile? _avatarImage;
  XFile? _licenseImage;
  int _currentStep = 0;
  bool _saving = false;
  bool _basicInfoValidated = false;

  static const int _maxShopImages = 5;
  static const int _maxLocationImages = 3;
  static const int _totalSteps = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản kinh doanh')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bước ${_currentStep + 1}/$_totalSteps'),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    BusinessOnboardingStepBasic(
                      formKey: _formKey,
                      nameController: _nameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      categoryController: _categoryController,
                    ),
                    BusinessOnboardingStepMedia(
                      avatarImage: _avatarImage,
                      shopImages: _shopImages,
                      maxShopImages: _maxShopImages,
                      onPickAvatar: _pickAvatar,
                      onRemoveAvatar: _removeAvatar,
                      onPickShopImages: _pickShopImages,
                      onRemoveShopImage: _removeShopImage,
                    ),
                    BusinessOnboardingStepLicense(
                      licenseImage: _licenseImage,
                      onPickLicense: _pickLicenseImage,
                      onRemoveLicense: _removeLicenseImage,
                    ),
                    BusinessOnboardingStepLocation(
                      locationImages: _locationImages,
                      maxLocationImages: _maxLocationImages,
                      onPickLocationImages: _pickLocationImages,
                      onRemoveLocationImage: _removeLocationImage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _currentStep == 0 ? null : _prevStep,
                    child: const Text('Quay lại'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _saving
                        ? null
                        : (_currentStep == _totalSteps - 1
                              ? _openReview
                              : _nextStep),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == _totalSteps - 1
                                ? 'Hoàn tất'
                                : 'Tiếp tục',
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() != true) {
        return;
      }
      _basicInfoValidated = true;
    }
    setState(() => _currentStep += 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    setState(() => _currentStep -= 1);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickAvatar() async {
    final XFile? picked = await _pickSingleImage();
    if (!mounted || picked == null) return;
    setState(() => _avatarImage = picked);
  }

  void _removeAvatar() {
    setState(() => _avatarImage = null);
  }

  Future<void> _pickShopImages() async {
    final int available = _maxShopImages - _shopImages.length;
    if (available <= 0) {
      _showLimitSnack('Bạn đã đạt tối đa ảnh quán');
      return;
    }
    final _ImagePickResult result = await _pickImages(allowMultiple: true);
    if (!mounted || result.files.isEmpty) return;
    final List<XFile> toAdd = result.files.take(available).toList();
    setState(() => _shopImages.addAll(toAdd));
    if (result.files.length > available) {
      _showLimitSnack('Chỉ lưu tối đa $_maxShopImages ảnh quán');
    }
  }

  void _removeShopImage(int index) {
    setState(() => _shopImages.removeAt(index));
  }

  Future<void> _pickLicenseImage() async {
    final XFile? picked = await _pickSingleImage(maxWidth: 1280);
    if (!mounted || picked == null) return;
    setState(() => _licenseImage = picked);
  }

  void _removeLicenseImage() {
    setState(() => _licenseImage = null);
  }

  Future<void> _pickLocationImages() async {
    final int available = _maxLocationImages - _locationImages.length;
    if (available <= 0) {
      _showLimitSnack('Bạn đã đạt tối đa ảnh địa điểm');
      return;
    }
    final _ImagePickResult result = await _pickImages(allowMultiple: true);
    if (!mounted || result.files.isEmpty) return;
    final List<XFile> toAdd = result.files.take(available).toList();
    setState(() => _locationImages.addAll(toAdd));
    if (result.files.length > available) {
      _showLimitSnack('Chỉ lưu tối đa $_maxLocationImages ảnh địa điểm');
    }
  }

  void _removeLocationImage(int index) {
    setState(() => _locationImages.removeAt(index));
  }

  void _showLimitSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<XFile?> _pickSingleImage({double maxWidth = 1080}) async {
    final ImageSource? source = await _showImageSourceSheet();
    if (source == null) return null;
    return _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: 85,
    );
  }

  Future<_ImagePickResult> _pickImages({required bool allowMultiple}) async {
    final ImageSource? source = await _showImageSourceSheet(
      allowMultiple: allowMultiple,
    );
    if (source == null) {
      return const _ImagePickResult([]);
    }
    if (source == ImageSource.camera) {
      final XFile? captured = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 85,
      );
      return _ImagePickResult(captured == null ? [] : [captured]);
    }
    final List<XFile> picked = allowMultiple
        ? await _picker.pickMultiImage(maxWidth: 1080, imageQuality: 85)
        : [];
    return _ImagePickResult(picked);
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

  Future<void> _submit() async {
    if (_formKey.currentState != null) {
      if (_formKey.currentState?.validate() != true) {
        setState(() => _currentStep = 0);
        _pageController.jumpToPage(0);
        return;
      }
      _basicInfoValidated = true;
    } else if (!_basicInfoValidated) {
      setState(() => _currentStep = 0);
      _pageController.jumpToPage(0);
      return;
    }
    setState(() => _saving = true);

    try {
      // Upload ảnh lên Firebase Storage trước khi lưu
      final storage = context.read<StorageService>();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

      String? avatarUrl;
      if (_avatarImage != null) {
        avatarUrl = await _uploadFile(storage, _avatarImage!.path, 'business_media/$uid/avatar');
      }
      final shopUrls = <String>[];
      for (final img in _shopImages) {
        final url = await _uploadFile(storage, img.path, 'business_media/$uid/shop');
        if (url != null) shopUrls.add(url);
      }
      String? licenseUrl;
      if (_licenseImage != null) {
        licenseUrl = await _uploadFile(storage, _licenseImage!.path, 'business_media/$uid/license');
      }
      final locationUrls = <String>[];
      for (final img in _locationImages) {
        final url = await _uploadFile(storage, img.path, 'business_media/$uid/location');
        if (url != null) locationUrls.add(url);
      }

      final businessProfile = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'category': _categoryController.text.trim(),
        'isOpen': true,
        'media': {
          'avatarPath': avatarUrl ?? _avatarImage?.path,
          'shopImagePaths': shopUrls.isNotEmpty ? shopUrls : _shopImages.map((file) => file.path).toList(),
          'licensePath': licenseUrl ?? _licenseImage?.path,
          'locationImagePaths': locationUrls.isNotEmpty ? locationUrls : _locationImages.map((file) => file.path).toList(),
        },
        'createdAt': DateTime.now().toIso8601String(),
      };

      await widget.service.updateBusinessMode(true);
      await widget.service.updateExtendedProfile({
        'businessProfile': businessProfile,
        'businessSetupCompleted': true,
      });

      final repo = context.read<NotificationRepository>();
      final notifUid = repo.currentUserId;
      if (notifUid != null) {
        await repo.sendSystemNotification(
          recipientId: notifUid,
          senderName: 'Trip',
          message:
              'Tài khoản doanh nghiệp đã được tạo thành công. Nhấn để xem tài khoản.',
          type: NotificationType.businessAccount,
          isBusinessNotification: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _openReview() {
    if (_formKey.currentState != null) {
      if (_formKey.currentState?.validate() != true) {
        setState(() => _currentStep = 0);
        _pageController.jumpToPage(0);
        return;
      }
      _basicInfoValidated = true;
    } else if (!_basicInfoValidated) {
      setState(() => _currentStep = 0);
      _pageController.jumpToPage(0);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BusinessOnboardingReviewScreen(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          category: _categoryController.text.trim(),
          avatarImage: _avatarImage,
          shopImages: List<XFile>.from(_shopImages),
          licenseImage: _licenseImage,
          locationImages: List<XFile>.from(_locationImages),
          onConfirm: _confirmRegistration,
        ),
      ),
    );
  }

  /// Upload một file lên Firebase Storage, trả về download URL hoặc null nếu lỗi
  Future<String?> _uploadFile(StorageService storage, String localPath, String folder) async {
    try {
      final ext = localPath.contains('.') ? localPath.substring(localPath.lastIndexOf('.')) : '.jpg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final destination = '$folder/$ts$ext';
      return await storage.uploadFile(localPath, destination);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tải ảnh thất bại: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ));
      }
      return null;
    }
  }

  Future<void> _confirmRegistration() async {
    await _submit();
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo tài khoản kinh doanh')),
    );
  }
}

class _ImagePickResult {
  const _ImagePickResult(this.files);

  final List<XFile> files;
}
