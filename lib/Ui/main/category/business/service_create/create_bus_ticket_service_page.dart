import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateBusTicketServicePage extends StatelessWidget {
  const CreateBusTicketServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ vé xe khách',
      collectionName: 'business_bus_ticket_services',
      serviceType: 'bus_ticket',
      hideServiceName: true,
      unitOptions: const [],
      extraFields: [
        ServiceFormField(
          keyName: 'busCompany',
          label: 'Hãng xe',
          required: true,
          hintText: 'VD: Phương Trang, Thành Bưởi, ...',
        ),
        ServiceFormField(
          keyName: 'departurePoint',
          label: 'Điểm đi',
          required: true,
          hintText: 'VD: Bến xe Miền Đông, TP.HCM',
        ),
        ServiceFormField(
          keyName: 'arrivalPoint',
          label: 'Điểm đến',
          required: true,
          hintText: 'VD: Đà Lạt, Nha Trang, ...',
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
          keyName: 'busType',
          label: 'Loại xe & Sơ đồ',
          required: true,
          options: [
            'Ghế ngồi 40 chỗ',
            'Ghế ngồi 45 chỗ',
            'Giường nằm 36 chỗ',
            'Giường nằm 45 chỗ',
            'Limousine 9 chỗ',
            'Limousine 34 phòng',
          ],
        ),
      ],
    );
  }
}
