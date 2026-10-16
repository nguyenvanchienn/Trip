import 'package:flutter/material.dart';
import 'service_create_form.dart';

class CreateHotelServicePage extends StatelessWidget {
  const CreateHotelServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  Widget build(BuildContext context) {
    return ServiceCreateForm(
      initialData: initialData,
      existingDocId: existingDocId,
      title: 'Tạo dịch vụ phòng khách sạn',
      collectionName: 'business_hotel_services',
      serviceType: 'hotel',
      unitOptions: ['Theo phòng/đêm', 'Theo phòng/giờ'],
      extraFields: [
        ServiceFormField(
          keyName: 'starRating',
          label: 'Hạng sao',
          required: true,
          options: ['1 sao', '2 sao', '3 sao', '4 sao', '5 sao'],
        ),
        ServiceFormField(
          keyName: 'roomCount',
          label: 'Số phòng sẵn có',
          keyboardType: TextInputType.number,
          required: true,
        ),
        ServiceFormField(
          keyName: 'amenities',
          label: 'Các ưu đãi / tiện ích',
          isMultiSelect: true,
          options: [
            'WiFi', 'Bữa sáng', 'Bể bơi', 'Bãi đỗ xe', 'Gym', 'Spa',
            'Đưa đón sân bay', 'Máy lạnh', 'Tủ lạnh', 'Lễ tân 24h',
            'Thang máy', 'Nhà hàng', 'Bar', 'Thuê xe máy', 'Giặt ủi'
          ],
        ),
      ],
    );
  }
}
