import 'package:flutter/material.dart';
import 'package:tourn/data/firebase/firebase_marketing_service.dart';
import 'package:tourn/data/api/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class SharedCheckoutScaffold extends StatefulWidget {
  final String title;
  final Widget content;
  final String ownerId;
  final double basePrice;
  final String itemNameSummary;
  final bool requireAddress;
  final bool allowReceiveAtLocation;
  final String addressLabel;
  final String addressPlaceholder;
  final Future<void> Function(double finalPrice, String extraInfo) onSubmit;

  const SharedCheckoutScaffold({
    super.key,
    required this.title,
    required this.content,
    required this.ownerId,
    required this.basePrice,
    required this.itemNameSummary,
    this.requireAddress = true,
    this.allowReceiveAtLocation = false,
    this.addressLabel = 'Địa chỉ nhận',
    this.addressPlaceholder = 'Chọn hoặc thêm địa chỉ nhận',
    required this.onSubmit,
  });

  @override
  State<SharedCheckoutScaffold> createState() => _SharedCheckoutScaffoldState();
}

class _SharedCheckoutScaffoldState extends State<SharedCheckoutScaffold> {
  String _paymentMethod = 'Thanh toán tiền mặt';
  String _linkedAccountInfo = '';
  bool _isLoading = false;
  Map<String, dynamic>? _selectedFreeshipVoucher;
  Map<String, dynamic>? _selectedDiscountVoucher;

  Map<String, String>? _selectedDeliveryAddress;
  List<Map<String, String>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    if (widget.requireAddress) {
      _loadAddresses();
    }
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('saved_delivery_addresses');
    if (str != null) {
      final List<dynamic> list = jsonDecode(str);
      setState(() {
        _savedAddresses = list.map((e) => Map<String, String>.from(e)).toList();
        if (_savedAddresses.isNotEmpty) {
          _selectedDeliveryAddress = _savedAddresses.first;
        }
      });
    }
  }

  Future<void> _saveAddress(Map<String, String> address) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAddresses.insert(0, address);
      _selectedDeliveryAddress = address;
    });
    await prefs.setString('saved_delivery_addresses', jsonEncode(_savedAddresses));
  }

  Future<void> _updateAddress(int index, Map<String, String> address) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAddresses[index] = address;
      _selectedDeliveryAddress = address;
    });
    await prefs.setString('saved_delivery_addresses', jsonEncode(_savedAddresses));
  }

  double get shippingFee {
    if (!widget.requireAddress) return 0.0;
    if (_selectedDeliveryAddress != null) {
      if (_selectedDeliveryAddress!['isReceiveAtLocation'] == 'true') return 0.0;
      return 30000.0; 
    }
    return 0.0;
  }

  double get freeshipDiscount {
    if (_selectedFreeshipVoucher != null && shippingFee > 0) {
      final discountStr = _selectedFreeshipVoucher!['discount']?.toString() ?? '';
      final match = RegExp(r'(\d+)[kK]').firstMatch(discountStr);
      double maxFreeship = shippingFee;
      if (match != null) {
        maxFreeship = double.parse(match.group(1)!) * 1000;
      }
      return maxFreeship > shippingFee ? shippingFee : maxFreeship;
    }
    return 0.0;
  }

  double get voucherDiscount {
    if (_selectedDiscountVoucher != null) {
      final discountStr = _selectedDiscountVoucher!['discount']?.toString() ?? '';
      double parsedDiscount = 0;
      
      final matchK = RegExp(r'(\d+)[kK]').firstMatch(discountStr);
      if (matchK != null) {
        parsedDiscount = double.parse(matchK.group(1)!) * 1000;
      } else {
        final percentMatch = RegExp(r'(\d+)%').firstMatch(discountStr);
        if (percentMatch != null) {
          parsedDiscount = widget.basePrice * (double.parse(percentMatch.group(1)!) / 100);
        } else {
          final numMatch = RegExp(r'(\d{4,})').firstMatch(discountStr);
          if (numMatch != null) {
             parsedDiscount = double.parse(numMatch.group(1)!);
          }
        }
      }
      return parsedDiscount > widget.basePrice ? widget.basePrice : parsedDiscount;
    }
    return 0.0;
  }

  double get finalPrice {
    double total = widget.basePrice + shippingFee - freeshipDiscount - voucherDiscount;
    return total > 0 ? total : 0;
  }

  void _confirmSubmitBooking() {
    if (widget.requireAddress && _selectedDeliveryAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ${widget.addressLabel.toLowerCase()}')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.title),
        content: Text('Bạn có chắc chắn muốn tiến hành với tổng thanh toán là ${finalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} đ không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitBooking();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    
    final address = (widget.requireAddress && _selectedDeliveryAddress != null)
        ? '${_selectedDeliveryAddress!['name']} - ${_selectedDeliveryAddress!['phone']} - ${_selectedDeliveryAddress!['address']}'
        : '';
    final freeshipCode = _selectedFreeshipVoucher != null ? _selectedFreeshipVoucher!['code'] : '';
    final discountCode = _selectedDiscountVoucher != null ? _selectedDiscountVoucher!['code'] : '';

    String extraInfo = '';
    if (address.isNotEmpty) extraInfo += ' - ${widget.addressLabel}: $address';
    if (freeshipCode!.isNotEmpty) extraInfo += ' - Mã Freeship: $freeshipCode';
    if (discountCode!.isNotEmpty) extraInfo += ' - Mã giảm giá: $discountCode';
    String paymentDisplay = _paymentMethod;
    if (_linkedAccountInfo.isNotEmpty) {
      paymentDisplay += ' (Liên kết: $_linkedAccountInfo)';
    }
    extraInfo += ' - Thanh toán: $paymentDisplay';

    try {
      await widget.onSubmit(finalPrice, extraInfo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddAddressDialog({Map<String, String>? editAddress, int? editIndex}) {
    final nameCtrl = TextEditingController(text: editAddress?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: editAddress?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: editAddress?['address'] ?? '');
    bool isLocating = false;
    List<String> suggestions = [];
    Timer? debounce;

    void updateSuggestions(String query, Function setModalState) {
      if (debounce?.isActive ?? false) debounce!.cancel();
      if (query.trim().length < 3) {
        setModalState(() => suggestions = []);
        return;
      }
      debounce = Timer(const Duration(milliseconds: 500), () async {
        try {
          final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
            'q': query,
            'format': 'json',
            'limit': '5',
            'countrycodes': 'vn',
            'accept-language': 'vi',
          });
          final response = await http.get(uri, headers: {'User-Agent': 'TripApp/1.0'});
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final results = data.map((item) {
                final full = item['display_name'] as String;
                final parts = full.split(', ');
                return parts.length <= 4 ? full : parts.take(4).join(', ');
            }).toList();
            setModalState(() {
              suggestions = results;
            });
          }
        } catch (_) {}
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16, right: 16, top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thêm ${widget.addressLabel.toLowerCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên người nhận', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    onChanged: (val) => updateSuggestions(val, setModalState),
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ cụ thể (Nhập để hiện gợi ý)', 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: isLocating 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location, color: Colors.blue),
                        onPressed: isLocating ? null : () async {
                          setModalState(() { isLocating = true; addressCtrl.text = 'Đang lấy vị trí...'; });
                          try {
                            final pos = await LocationService().getCurrentPosition().timeout(const Duration(seconds: 10));
                            if (pos != null) {
                              setModalState(() { 
                                addressCtrl.text = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'; 
                                suggestions = []; 
                              });
                            } else {
                              setModalState(() { addressCtrl.text = ''; });
                            }
                          } catch (e) {
                            setModalState(() { addressCtrl.text = ''; });
                          } finally {
                            setModalState(() { isLocating = false; });
                          }
                        },
                      ),
                    ),
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: suggestions.map((s) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined, color: Colors.deepPurple, size: 20),
                          title: Text(s),
                          onTap: () {
                            setModalState(() {
                              addressCtrl.text = s;
                              addressCtrl.selection = TextSelection.fromPosition(TextPosition(offset: s.length));
                              suggestions = [];
                            });
                          },
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty && addressCtrl.text.trim().isNotEmpty) {
                          final newAddr = {
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'address': addressCtrl.text.trim(),
                          };
                          if (editIndex != null) {
                            _updateAddress(editIndex, newAddr);
                          } else {
                            _saveAddress(newAddr);
                          }
                          Navigator.pop(ctx); 
                          Navigator.pop(context); 
                        }
                      },
                      child: const Text('Lưu địa chỉ'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showAddressListBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chọn ${widget.addressLabel.toLowerCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (widget.allowReceiveAtLocation)
                ListTile(
                  leading: const Icon(Icons.storefront, color: Colors.blue),
                  title: const Text('Nhận tại chỗ người cho thuê', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Không tốn phí giao nhận'),
                  trailing: _selectedDeliveryAddress?['isReceiveAtLocation'] == 'true'
                      ? const Icon(Icons.check_circle, color: Colors.deepPurple)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedDeliveryAddress = {
                        'name': 'Nhận tại chỗ',
                        'phone': '',
                        'address': 'Nhận tại cửa hàng/địa chỉ người cho thuê',
                        'isReceiveAtLocation': 'true',
                      };
                    });
                    Navigator.pop(ctx);
                  },
                ),
              if (widget.allowReceiveAtLocation) const Divider(),
              if (_savedAddresses.isNotEmpty)
                ..._savedAddresses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final addr = entry.value;
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.deepPurple),
                    title: Text('${addr['name']} | ${addr['phone']}'),
                    subtitle: Text(addr['address'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddAddressDialog(editAddress: addr, editIndex: index);
                          },
                          child: const Text('Sửa', style: TextStyle(color: Colors.blue)),
                        ),
                        if (_selectedDeliveryAddress == addr)
                          const Icon(Icons.check_circle, color: Colors.deepPurple)
                        else
                          const SizedBox(width: 24),
                      ],
                    ),
                    onTap: () {
                      setState(() { _selectedDeliveryAddress = addr; });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.deepOrange),
                title: const Text('Thêm địa chỉ mới', style: TextStyle(color: Colors.deepOrange)),
                onTap: () {
                  _showAddAddressDialog();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showVoucherBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn mã giảm giá',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: FirebaseMarketingService().getVouchersByOwner(widget.ownerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final sellerVouchers = snapshot.data ?? [];
                    final sellerFreeshipVouchers = sellerVouchers.where((v) {
                      final title = (v['discount'] ?? '').toString().toLowerCase();
                      return title.contains('freeship') || title.contains('miễn phí') || title.contains('vận chuyển');
                    }).toList();
                    final sellerDiscountVouchers = sellerVouchers.where((v) {
                      final title = (v['discount'] ?? '').toString().toLowerCase();
                      return !title.contains('freeship') && !title.contains('miễn phí') && !title.contains('vận chuyển');
                    }).toList();

                    final allFreeship = [...sellerFreeshipVouchers];
                    final allDiscount = [...sellerDiscountVouchers];

                    if (allFreeship.isEmpty && allDiscount.isEmpty) {
                      return const Center(child: Text('Chưa có mã giảm giá nào'));
                    }

                    return ListView(
                      children: [
                        if (allFreeship.isNotEmpty) ...[
                          Container(
                            color: Colors.green.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: const Row(
                              children: [
                                Icon(Icons.local_shipping, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text('Mã Miễn Phí Vận Chuyển', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                          ),
                          ...allFreeship.map((v) => _buildVoucherItem(v, isFreeship: true)),
                          const Divider(),
                        ],
                        if (allDiscount.isNotEmpty) ...[
                          Container(
                            color: Colors.orange.shade50,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: const Row(
                              children: [
                                Icon(Icons.confirmation_number, color: Colors.deepOrange, size: 20),
                                SizedBox(width: 8),
                                Text('Mã Giảm Giá / Hoàn Xu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              ],
                            ),
                          ),
                          ...allDiscount.map((v) => _buildVoucherItem(v, isFreeship: false)),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherItem(Map<String, dynamic> voucher, {required bool isFreeship}) {
    final isSelected = isFreeship 
        ? (_selectedFreeshipVoucher != null && _selectedFreeshipVoucher!['code'] == voucher['code'])
        : (_selectedDiscountVoucher != null && _selectedDiscountVoucher!['code'] == voucher['code']);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFreeship ? Colors.green : Colors.deepOrange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(isFreeship ? Icons.local_shipping : Icons.local_offer, color: Colors.white, size: 20),
      ),
      title: Row(
        children: [
          Text(voucher['code']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              voucher['source'] ?? 'Chủ shop', 
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
        ],
      ),
      subtitle: Text(voucher['discount']?.toString() ?? ''),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.deepPurple)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() {
          if (isFreeship) {
            _selectedFreeshipVoucher = isSelected ? null : voucher;
          } else {
            _selectedDiscountVoucher = isSelected ? null : voucher;
          }
        });
      },
    );
  }

  void _showLinkAccountDialog(String method) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Liên kết $method'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập số tài khoản / số thẻ...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _paymentMethod = method;
                  _linkedAccountInfo = controller.text.trim();
                });
                Navigator.pop(ctx); 
                Navigator.pop(context); 
              }
            },
            child: const Text('Liên kết'),
          ),
        ],
      ),
    );
  }

  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text('Thanh toán tiền mặt'),
                trailing: _paymentMethod == 'Thanh toán tiền mặt' ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() {
                    _paymentMethod = 'Thanh toán tiền mặt';
                    _linkedAccountInfo = '';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.blue),
                title: const Text('Chuyển khoản ngân hàng'),
                subtitle: _paymentMethod == 'Chuyển khoản ngân hàng' && _linkedAccountInfo.isNotEmpty 
                    ? const Text('Đã liên kết', style: TextStyle(color: Colors.green)) 
                    : const Text('Chưa liên kết'),
                trailing: _paymentMethod == 'Chuyển khoản ngân hàng' ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
                onTap: () {
                  _showLinkAccountDialog('Chuyển khoản ngân hàng');
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.pink),
                title: const Text('Ví điện tử (Momo, ZaloPay...)'),
                subtitle: _paymentMethod == 'Ví điện tử (Momo, ZaloPay...)' && _linkedAccountInfo.isNotEmpty 
                    ? const Text('Đã liên kết', style: TextStyle(color: Colors.green)) 
                    : const Text('Chưa liên kết'),
                trailing: _paymentMethod == 'Ví điện tử (Momo, ZaloPay...)' ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
                onTap: () {
                  _showLinkAccountDialog('Ví điện tử (Momo, ZaloPay...)');
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.deepPurple),
                title: const Text('TripPay'),
                subtitle: const Text('Thanh toán tự động qua ví TripPay'),
                trailing: _paymentMethod == 'TripPay' ? const Icon(Icons.check_circle, color: Colors.deepPurple) : null,
                onTap: () {
                  setState(() {
                    _paymentMethod = 'TripPay';
                    _linkedAccountInfo = ''; 
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? Colors.black : Colors.black54,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${isDiscount ? '-' : ''}${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} đ',
            style: TextStyle(
              color: isTotal ? Colors.deepPurple : (isDiscount ? Colors.green : Colors.black87),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF6F2FA),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.content,
                  const SizedBox(height: 16),

                  // Delivery Address, Promo Code, Payment Method
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.requireAddress) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.deepPurple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.addressLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _showAddressListBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_selectedDeliveryAddress != null) ...[
                                          Text('${_selectedDeliveryAddress!['name']} | ${_selectedDeliveryAddress!['phone']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(_selectedDeliveryAddress!['address'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                        ] else ...[
                                          Text(widget.addressPlaceholder, style: const TextStyle(color: Colors.black54)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],

                        // Promo code
                        const Row(
                          children: [
                            Icon(Icons.local_offer, color: Colors.deepOrange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Mã giảm giá',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showVoucherBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_selectedFreeshipVoucher != null)
                                        Text(
                                          '🚗 ${_selectedFreeshipVoucher!['code']}',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      if (_selectedDiscountVoucher != null)
                                        Text(
                                          '🏷️ ${_selectedDiscountVoucher!['code']}',
                                          style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                                        ),
                                      if (_selectedFreeshipVoucher == null && _selectedDiscountVoucher == null)
                                        const Text(
                                          'Chọn hoặc nhập mã giảm giá',
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Payment method
                        const Row(
                          children: [
                            Icon(Icons.payment, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Phương thức thanh toán',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showPaymentBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _paymentMethod,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      if (_linkedAccountInfo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Đã liên kết: *${_linkedAccountInfo.length > 4 ? _linkedAccountInfo.substring(_linkedAccountInfo.length - 4) : _linkedAccountInfo}',
                                          style: const TextStyle(color: Colors.green, fontSize: 13),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                              ],
                            ),
                          ),
                        ),
                        
                        // Chi tiết thanh toán
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Chi tiết thanh toán',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow('Tổng tiền hàng ${widget.itemNameSummary}', widget.basePrice),
                        if (shippingFee > 0)
                          _buildPriceRow('Tổng tiền phí vận chuyển', shippingFee),
                        if (freeshipDiscount > 0)
                          _buildPriceRow('Mã miễn phí vận chuyển', freeshipDiscount, isDiscount: true),
                        if (voucherDiscount > 0)
                          _buildPriceRow('Mã giảm giá/Hoàn xu', voucherDiscount, isDiscount: true),
                        const SizedBox(height: 8),
                        const Divider(),
                        _buildPriceRow('Tổng thanh toán', finalPrice, isTotal: true),
                        const SizedBox(height: 24),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tổng thanh toán', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        Text(
                          '${finalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ".")} đ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmSubmitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Đặt ngay',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
