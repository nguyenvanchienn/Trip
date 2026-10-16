import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateTransportServicePage extends StatelessWidget {
  const CreateTransportServicePage({
    super.key,
    this.initialData,
    this.existingDocId,
  });

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ thuê phương tiện',
      collectionName: 'business_transport_services',
      serviceType: 'transport',
      unitOptions: ['Theo ngày', 'Theo giờ', 'Theo chuyến'],
      extraFields: [
        ServiceFormField(
          keyName: 'vehicleType',
          label: 'Loại phương tiện',
          required: true,
          options: ['Ô tô', 'Xe máy', 'Xe đạp', 'Khác'],
        ),
        ServiceFormField(
          keyName: 'rentalMode',
          label: 'Hình thức thuê',
          required: true,
          options: ['Tự lái', 'Có tài xế', 'Theo giờ', 'Theo ngày'],
        ),
        ServiceFormField(
          keyName: 'capacity',
          label: 'Số chỗ / định mức',
          required: true,
          options: ['1', '2', '4', '5', '7', '9', '12', '16'],
        ),
        ServiceFormField(
          keyName: 'stockQuantity',
          label: 'Số lượng xe sẵn có',
          hintText: 'VD: 3 (số xe đang cho thuê)',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
