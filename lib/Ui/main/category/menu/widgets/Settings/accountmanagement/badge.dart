import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeService {
  static const _idDocFrontKey = 'account_id_doc_front';
  static const _idDocBackKey = 'account_id_doc_back';

  static Future<String?> getFront() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idDocFrontKey);
  }

  static Future<String?> getBack() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idDocBackKey);
  }

  static Future<void> setFront(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_idDocFrontKey);
    } else {
      await prefs.setString(_idDocFrontKey, path);
    }
  }

  static Future<void> setBack(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_idDocBackKey);
    } else {
      await prefs.setString(_idDocBackKey, path);
    }
  }

  // document type
  static const _docTypeKey = 'account_id_doc_type';
  static Future<String?> getDocType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_docTypeKey);
  }

  static Future<void> setDocType(String? type) async {
    final prefs = await SharedPreferences.getInstance();
    if (type == null || type.isEmpty) {
      await prefs.remove(_docTypeKey);
    } else {
      await prefs.setString(_docTypeKey, type);
    }
  }
}

class BadgePage extends StatefulWidget {
  const BadgePage({super.key});

  @override
  State<BadgePage> createState() => _BadgePageState();
}

class _BadgePageState extends State<BadgePage> {
  String? _frontPath;
  String? _backPath;
  String? _docType;
  final List<String> _docOptions = ['CMND/CCCD', 'Hộ chiếu', 'Bằng lái'];
  bool _loading = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final front = await BadgeService.getFront();
    final back = await BadgeService.getBack();
    final docType = await BadgeService.getDocType();
    _frontPath = front;
    _backPath = back;
    _docType = docType;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick({
    required bool front,
    ImageSource source = ImageSource.camera,
  }) async {
    if (_submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yêu cầu đã gửi, không thể chỉnh sửa')),
      );
      return;
    }

    final p = ImagePicker();
    final XFile? f = await p.pickImage(source: source, imageQuality: 80);
    if (f == null) return;
    if (front) {
      await BadgeService.setFront(f.path);
      if (!mounted) return;
      setState(() => _frontPath = f.path);
    } else {
      await BadgeService.setBack(f.path);
      if (!mounted) return;
      setState(() => _backPath = f.path);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã tải giấy tờ lên')));
  }

  Future<void> _remove({required bool front}) async {
    if (_submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yêu cầu đã gửi, không thể chỉnh sửa')),
      );
      return;
    }

    if (front) {
      await BadgeService.setFront(null);
      if (!mounted) return;
      setState(() => _frontPath = null);
    } else {
      await BadgeService.setBack(null);
      if (!mounted) return;
      setState(() => _backPath = null);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xoá giấy tờ')));
  }

  Future<void> _chooseSourceAndPick({required bool front}) async {
    if (_submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yêu cầu đã gửi, không thể chỉnh sửa')),
      );
      return;
    }
    // allow camera or gallery
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.of(c).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.of(c).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Huỷ'),
              onTap: () => Navigator.of(c).pop(null),
            ),
          ],
        ),
      ),
    );
    if (src != null) await _pick(front: front, source: src);
  }

  Future<void> _setDocType(String? type) async {
    await BadgeService.setDocType(type);
    if (!mounted) return;
    setState(() => _docType = type);
  }

  Future<void> _submitForApproval() async {
    // require both front and back
    if (_frontPath == null || _backPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải lên cả hai mặt giấy tờ')),
      );
      return;
    }
    // mark as submitted and simulate submission
    setState(() => _submitted = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yêu cầu phê duyệt đã được gửi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giấy tờ tuỳ thân')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giấy tờ tuỳ thân',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // document type selector (tappable field)
                  GestureDetector(
                    onTap: () async {
                      final selected = await showModalBottomSheet<String?>(
                        context: context,
                        builder: (c) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Chọn loại giấy tờ',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              ..._docOptions.map(
                                (t) => RadioListTile<String>(
                                  title: Text(t),
                                  value: t,
                                  groupValue: _docType,
                                  onChanged: (v) => Navigator.of(c).pop(v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (selected != null) await _setDocType(selected);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Loại giấy tờ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _docType ?? 'Chọn loại giấy tờ',
                            style: _docType == null
                                ? TextStyle(color: Theme.of(context).hintColor)
                                : null,
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // two frames side by side
                  Row(
                    children: [
                      Expanded(child: _buildFrame(front: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFrame(front: false)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // actions
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed:
                  (_frontPath != null && _backPath != null) && !_submitted
                  ? _submitForApproval
                  : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(_submitted ? 'Đã gửi' : 'Gửi yêu cầu phê duyệt'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrame({required bool front}) {
    final path = front ? _frontPath : _backPath;
    return GestureDetector(
      onTap: _submitted ? null : () => _chooseSourceAndPick(front: front),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.35),
          ),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.02),
        ),
        child: Stack(
          children: [
            if (path != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 36,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      front ? 'Mặt trước' : 'Mặt sau',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),

            // overlay lock when submitted
            if (_submitted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            Positioned(
              right: 8,
              top: 8,
              child: path != null
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: _submitted
                              ? null
                              : () => _chooseSourceAndPick(front: front),
                          icon: Icon(
                            Icons.edit,
                            size: 20,
                            color: _submitted
                                ? Theme.of(context).disabledColor
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: _submitted
                              ? null
                              : () => _remove(front: front),
                          icon: Icon(
                            Icons.delete_forever,
                            size: 20,
                            color: _submitted
                                ? Theme.of(context).disabledColor
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
