import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateTrainTicketServicePage extends StatelessWidget {
  const CreateTrainTicketServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ vé tàu hỏa',
      collectionName: 'business_train_ticket_services',
      serviceType: 'train_ticket',
      hideServiceName: true,
      unitOptions: const [],
      extraFields: [
        ServiceFormField(
          keyName: 'route',
          label: 'Tuyến đường sắt',
          required: true,
          options: [
            'Hà Nội - Đà Nẵng',
            'Đà Nẵng - Hà Nội',
            'Hà Nội - TP HCM',
            'TP HCM - Hà Nội',
            'Huế - Đà Nẵng',
            'Nha Trang - TP HCM',
            'Khác',
          ],
        ),
        ServiceFormField(
          keyName: 'schedule',
          label: 'Lịch chạy / Chọn ngày',
          required: true,
          isSchedulePicker: true,
        ),
        ServiceFormField(
          keyName: 'time',
          label: 'Giờ khởi hành',
          required: true,
          isRepeatable: true,
          isTimePicker: true,
        ),
        ServiceFormField(
          keyName: 'seatClass',
          label: 'Sơ đồ toa',
          required: true,
          options: ['Toa ghế mềm (64 chỗ)', 'Toa giường nằm (28 chỗ)'],
        ),
        ServiceFormField(
          keyName: 'carriageCount',
          label: 'Số lượng toa',
          required: true,
          options: ['1', '2', '3', '4', '5', 'Khác'],
        ),
      ],
    );
  }
}
