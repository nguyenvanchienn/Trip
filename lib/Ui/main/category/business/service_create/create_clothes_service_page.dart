import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateClothesServicePage extends StatelessWidget {
  const CreateClothesServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ thuê quần áo & phụ kiện',
      collectionName: 'business_clothes_services',
      serviceType: 'clothes',
      unitOptions: ['Theo bộ', 'Theo ngày'],
      extraFields: [
        ServiceFormField(
          keyName: 'clothingType',
          label: 'Loại trang phục',
          required: true,
          options: ['Áo dài', 'Váy cưới', 'Vest', 'Truyền thống', 'Khác'],
        ),
        ServiceFormField(
          keyName: 'sizeRange',
          label: 'Size có sẵn',
          isMultiSelect: true,
          options: ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL'],
          hintText: 'Chọn các size hiện có',
        ),
        ServiceFormField(
          keyName: 'stockQuantity',
          label: 'Số lượng bộ sẵn có',
          hintText: 'VD: 10',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
