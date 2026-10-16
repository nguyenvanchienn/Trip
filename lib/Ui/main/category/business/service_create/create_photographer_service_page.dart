import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreatePhotographerServicePage extends StatelessWidget {
  const CreatePhotographerServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ thợ chụp ảnh',
      collectionName: 'business_photographer_services',
      serviceType: 'photographer',
      unitOptions: ['Theo buổi', 'Theo giờ'],
      extraFields: [
        ServiceFormField(
          keyName: 'style',
          label: 'Phong cách chụp',
          hintText: 'VD: Du lịch, cưới, chân dung',
        ),
        ServiceFormField(
          keyName: 'packages',
          label: 'Gói chụp',
          isRepeatable: true,
          hintText: 'VD: 2 giờ / 50 ảnh / 1 outfit...',
        ),
      ],
    );
  }
}
