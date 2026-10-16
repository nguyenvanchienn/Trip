import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateGuideServicePage extends StatelessWidget {
  const CreateGuideServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ hướng dẫn viên',
      collectionName: 'business_guide_services',
      serviceType: 'guide',
      unitOptions: ['Theo ngày', 'Theo giờ'],
      extraFields: [
        ServiceFormField(
          keyName: 'languages',
          label: 'Ngôn ngữ',
          required: true,
          isMultiSelect: true,
          options: [
            'Tiếng Việt',
            'Tiếng Anh',
            'Tiếng Trung',
            'Tiếng Nhật',
            'Tiếng Hàn',
            'Tiếng Pháp',
            'Tiếng Nga',
          ],
        ),
        ServiceFormField(
          keyName: 'experienceYears',
          label: 'Kinh nghiệm (năm)',
          keyboardType: TextInputType.number,
        ),
        ServiceFormField(
          keyName: 'specialty',
          label: 'Thế mạnh',
          hintText: 'VD: Tour ẩm thực, trekking',
        ),
      ],
    );
  }
}
