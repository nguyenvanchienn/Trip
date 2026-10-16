import 'package:flutter/material.dart';

class BusinessOnboardingStepBasic extends StatelessWidget {
  const BusinessOnboardingStepBasic({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.categoryController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController categoryController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Tên cửa hàng'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên cửa hàng';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại liên hệ',
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: addressController,
            decoration: const InputDecoration(labelText: 'Địa chỉ kinh doanh'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: categoryController,
            decoration: const InputDecoration(labelText: 'Lĩnh vực kinh doanh'),
          ),
        ],
      ),
    );
  }
}
