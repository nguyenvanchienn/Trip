import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BusinessOnboardingReviewScreen extends StatefulWidget {
  const BusinessOnboardingReviewScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.category,
    required this.avatarImage,
    required this.shopImages,
    required this.licenseImage,
    required this.locationImages,
    required this.onConfirm,
  });

  final String name;
  final String phone;
  final String address;
  final String category;
  final XFile? avatarImage;
  final List<XFile> shopImages;
  final XFile? licenseImage;
  final List<XFile> locationImages;
  final Future<void> Function() onConfirm;

  @override
  State<BusinessOnboardingReviewScreen> createState() =>
      _BusinessOnboardingReviewScreenState();
}

class _BusinessOnboardingReviewScreenState
    extends State<BusinessOnboardingReviewScreen> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm tra thông tin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Bước 5/5'),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle('Thông tin cơ bản'),
                    _buildInfoRow('Tên cửa hàng', widget.name),
                    _buildInfoRow('Số điện thoại', widget.phone),
                    _buildInfoRow('Địa chỉ', widget.address),
                    _buildInfoRow('Lĩnh vực', widget.category),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Ảnh đại diện'),
                    const SizedBox(height: 8),
                    widget.avatarImage == null
                        ? _buildEmpty('Chưa có ảnh đại diện')
                        : CircleAvatar(
                            radius: 44,
                            backgroundImage: FileImage(
                              File(widget.avatarImage!.path),
                            ),
                          ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Ảnh quán'),
                    const SizedBox(height: 8),
                    _buildImageGrid(
                      widget.shopImages,
                      emptyText: 'Chưa có ảnh',
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Giấy phép kinh doanh'),
                    const SizedBox(height: 8),
                    widget.licenseImage == null
                        ? _buildEmpty('Chưa có giấy phép')
                        : _buildImageTile(widget.licenseImage!),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Ảnh địa điểm'),
                    const SizedBox(height: 8),
                    _buildImageGrid(
                      widget.locationImages,
                      emptyText: 'Chưa có ảnh địa điểm',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submitting ? null : _handleConfirm,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đăng ký'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Text(text, style: const TextStyle(color: Colors.black54));
  }

  Widget _buildImageTile(XFile file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(file.path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildImageGrid(List<XFile> files, {required String emptyText}) {
    if (files.isEmpty) {
      return _buildEmpty(emptyText);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final file in files)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(file.path),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    setState(() => _submitting = true);
    await widget.onConfirm();
  }
}
