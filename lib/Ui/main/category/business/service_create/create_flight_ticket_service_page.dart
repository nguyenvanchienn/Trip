import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateFlightTicketServicePage extends StatelessWidget {
  const CreateFlightTicketServicePage({
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
      title: 'Tạo dịch vụ vé máy bay',
      collectionName: 'business_flight_ticket_services',
      serviceType: 'flight_ticket',
      hideMainPrice: true,
      hideServiceName: true,
      unitOptions: const [],
      extraFields: [
        ServiceFormField(
          keyName: 'airline',
          label: 'Hãng bay',
          required: true,
          options: [
            'Vietnam Airlines',
            'Vietjet Air',
            'Bamboo Airways',
            'Vietravel Airlines',
            'Khác',
          ],
        ),
        ServiceFormField(
          keyName: 'ticketClasses',
          label: 'Hạng ghế (Chọn và nhập giá)',
          required: true,
          isTicketClassPricing: true,
          options: ['Thương gia', 'Phổ thông cao cấp', 'Phổ thông'],
        ),

        ServiceFormField(
          keyName: 'from',
          label: 'Điểm đi (Mã sân bay / Thành phố)',
          required: true,
          isAutocomplete: true,
          options: [
            'HAN (Hà Nội)',
            'SGN (TP. Hồ Chí Minh)',
            'DAD (Đà Nẵng)',
            'CXR (Nha Trang)',
            'PQC (Phú Quốc)',
            'VCA (Cần Thơ)',
            'HPH (Hải Phòng)',
            'VII (Vinh)',
          ],
        ),
        ServiceFormField(
          keyName: 'to',
          label: 'Điểm đến (Mã sân bay / Thành phố)',
          required: true,
          isAutocomplete: true,
          options: [
            'SGN (TP. Hồ Chí Minh)',
            'HAN (Hà Nội)',
            'DAD (Đà Nẵng)',
            'CXR (Nha Trang)',
            'PQC (Phú Quốc)',
            'VCA (Cần Thơ)',
            'HPH (Hải Phòng)',
            'VII (Vinh)',
          ],
        ),
        ServiceFormField(
          keyName: 'date',
          label: 'Ngày khởi hành',
          required: true,
          isDatePicker: true,
        ),
        ServiceFormField(
          keyName: 'time',
          label: 'Giờ khởi hành',
          required: true,
          isTimePicker: true,
        ),
        ServiceFormField(
          keyName: 'airplaneName',
          label: 'Nhập loại/tên máy bay',
          hintText: 'Hệ thống sẽ tự động chọn sơ đồ ghế phù hợp',
          required: true,
          isAutocomplete: true,
          options: [
            'Airbus A220',
            'Airbus A318',
            'Airbus A319',
            'Airbus A320',
            'Airbus A321',
            'Airbus A330',
            'Airbus A340',
            'Airbus A350',
            'Airbus A380',
            'Boeing 717',
            'Boeing 737',
            'Boeing 747',
            'Boeing 757',
            'Boeing 767',
            'Boeing 777',
            'Boeing 787',
            'ATR 42',
            'ATR 72',
            'Embraer E175',
            'Embraer E190',
            'Embraer E195',
            'Bombardier CRJ900',
            'Bombardier Q400',
          ],
        ),
      ],
    );
  }
}
