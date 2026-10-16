import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service_create_form.dart';

class CreateFoodServicePage extends StatefulWidget {
  const CreateFoodServicePage({super.key, this.initialData, this.existingDocId});

  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  State<CreateFoodServicePage> createState() => _CreateFoodServicePageState();
}

class _CreateFoodServicePageState extends State<CreateFoodServicePage> {
  List<String> _previousDishes = ['(Không chọn)'];
  bool _loadingDishes = true;

  @override
  void initState() {
    super.initState();
    _fetchPreviousDishes();
  }

  Future<void> _fetchPreviousDishes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('business_food_services')
            .where('ownerId', isEqualTo: uid)
            .get();
        final names = snap.docs
            .map((e) => (e.data()['name'] as String?)?.trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          _previousDishes.addAll(names);
        }
      } catch (e) {
        // Ignore error
      }
    }
    if (mounted) {
      setState(() {
        _loadingDishes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDishes) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ServiceCreateForm(
      initialData: widget.initialData,
      existingDocId: widget.existingDocId,
      title: 'Tạo dịch vụ ẩm thực vùng miền',
      collectionName: 'business_food_services',
      serviceType: 'food',
      unitOptions: const ['Theo suất', 'Theo phần', 'Theo người', 'Theo bàn'],
      initialUnit: 'Theo suất',
      durationLabel: 'Đơn vị bán (chọn đơn vị phù hợp)',
      extraFields: [
        ServiceFormField(
          keyName: 'region',
          label: 'Vùng miền',
          required: true,
          options: const ['Bắc', 'Trung', 'Nam', 'Tây Bắc', 'Tây Nguyên', 'Miền Tây'],
        ),
        ServiceFormField(
          keyName: 'category',
          label: 'Loại món',
          required: true,
          options: const [
            'Đặc sản',
            'Món chính',
            'Ăn vặt',
            'Lẩu',
            'Hải sản',
            'Chay',
            'Khác',
          ],
        ),
        ServiceFormField(
          keyName: 'specialty',
          label: 'Món nổi bật',
          required: false,
          options: _previousDishes,
        ),
        ServiceFormField(
          keyName: 'stockQuantity',
          label: 'Số lượng hàng',
          hintText: 'VD: 50 (để 0 = hết hàng)',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
