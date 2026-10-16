import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateShipTicketServicePage extends StatelessWidget {
  const CreateShipTicketServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ vé tàu/phà',
      collectionName: 'business_ship_ticket_services',
      serviceType: 'ship_ticket',
      hideServiceName: true,
      unitOptions: const [],
      extraFields: [
        ServiceFormField(
          keyName: 'departurePoint',
          label: 'Điểm đi',
          required: true,
          hintText: 'VD: Vũng Tàu, Rạch Giá, ...',
        ),
        ServiceFormField(
          keyName: 'arrivalPoint',
          label: 'Điểm đến',
          required: true,
          hintText: 'VD: Côn Đảo, Phú Quốc, ...',
        ),
        ServiceFormField(
          keyName: 'shipType',
          label: 'Loại tàu & Sơ đồ',
          required: true,
          options: ['Tàu cao tốc (100 chỗ)', 'Phà (50 chỗ)'],
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
          keyName: 'seatType',
          label: 'Loại chỗ',
          required: true,
          options: ['Phổ thông', 'VIP'],
        ),
      ],
    );
  }
}
