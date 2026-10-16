import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tourn/data/firebase/firebase_business_service.dart';
import 'address_autocomplete_field.dart';

class ServiceFormField {
  final String keyName;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final List<String>? options;
  final String? hintText;
  final bool isMultiSelect;
  final bool isRepeatable;
  final bool isAutocomplete;
  final bool isDatePicker;
  final bool isTimePicker;
  final bool isSchedulePicker;
  final bool isTicketClassPricing;

  const ServiceFormField({
    required this.keyName,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.options,
    this.hintText,
    this.isMultiSelect = false,
    this.isRepeatable = false,
    this.isAutocomplete = false,
    this.isDatePicker = false,
    this.isTimePicker = false,
    this.isSchedulePicker = false,
    this.isTicketClassPricing = false,
  });

  bool get isDropdown =>
      !isMultiSelect &&
      !isRepeatable &&
      !isAutocomplete &&
      !isDatePicker &&
      !isTimePicker &&
      !isSchedulePicker &&
      !isTicketClassPricing &&
      options != null &&
      options!.isNotEmpty;
}

class ServiceCreateForm extends StatefulWidget {
  const ServiceCreateForm({
    super.key,
    required this.title,
    required this.collectionName,
    required this.serviceType,
    this.extraFields = const [],
    this.hideMainPrice = false,
    this.hideServiceName = false,
    this.unitOptions = const [
      'Theo ngày',
      'Theo giờ',
      'Theo chuyến',
      'Theo vé',
      'Theo phòng/đêm',
      'Theo bộ',
    ],
    this.initialUnit,
    this.durationLabel = 'Thuê bao lâu (chọn các gói phù hợp)',
    this.initialData,
    this.existingDocId,
  });

  final String title;
  final String collectionName;
  final String serviceType;
  final List<ServiceFormField> extraFields;
  final bool hideMainPrice;
  final bool hideServiceName;
  final List<String> unitOptions;
  final String? initialUnit;
  final String durationLabel;
  final Map<String, dynamic>? initialData;
  final String? existingDocId;

  @override
  State<ServiceCreateForm> createState() => _ServiceCreateFormState();
}

class _ServiceCreateFormState extends State<ServiceCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];

  late final Map<String, TextEditingController> _extraControllers;
  final Map<String, String?> _extraDropdownValues = {};
  final Map<String, Set<String>> _multiSelectValues = {};
  // isRepeatable: danh sách các item + controller nhập tạm
  final Map<String, List<String>> _repeatableValues = {};
  final Map<String, TextEditingController> _repeatableControllers = {};
  final Map<String, TextEditingController> _multiSelectControllers = {};
  final Map<String, TextEditingController> _customControllers = {};
  final Map<String, Set<String>> _ticketClassSelections = {};
  final Map<String, Map<String, TextEditingController>> _ticketClassPriceControllers = {};
  final Map<String, String> _seatClassesConfig = {};
  String? _currentSeatPaintClass;
  final Set<String> _selectedDurations = {};
  final Set<String> _paymentMethods = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _extraControllers = {};
    for (final field in widget.extraFields) {
      if (field.isMultiSelect) {
        _multiSelectValues[field.keyName] = {};
      } else if (field.isRepeatable) {
        _repeatableValues[field.keyName] = [];
        _repeatableControllers[field.keyName] = TextEditingController();
      } else if (field.isDropdown) {
        _extraDropdownValues[field.keyName] = null;
      } else if (field.isTicketClassPricing) {
        _ticketClassSelections[field.keyName] = {};
        _ticketClassPriceControllers[field.keyName] = {};
        for (final opt in field.options ?? <String>[]) {
          _ticketClassPriceControllers[field.keyName]![opt] = TextEditingController();
        }
      } else {
        _extraControllers[field.keyName] = TextEditingController();
      }
      if (field.isMultiSelect) {
        _multiSelectControllers[field.keyName] = TextEditingController();
      }
    }
    final initial = widget.initialUnit;
    if (initial != null && initial.isNotEmpty) {
      _selectedDurations.add(initial);
    }

    // Nếu có initialData (đang sửa), điền dữ liệu cũ vào các trường
    if (widget.initialData != null) {
      final data = widget.initialData!;
      final extra = (data['extra'] as Map<String, dynamic>?) ?? {};
      final savedSeatClasses = extra['seatClassesConfig'] as Map<String, dynamic>? ?? {};
      savedSeatClasses.forEach((k, v) {
        _seatClassesConfig[k] = v.toString();
      });

      _nameController.text = (data['name'] ?? '').toString();
      _priceController.text = (data['price'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();

      _addressController.text = (data['address'] ?? '').toString();
      _phoneController.text = (data['phone'] ?? '').toString();

      if (extra['images'] is List) {
        _imagePaths = (extra['images'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (extra['imageUrl'] != null) {
        _imagePaths = [extra['imageUrl'] as String];
      }

      if (data['durationOptions'] is List) {
        _selectedDurations.addAll(List<String>.from(data['durationOptions']));
      } else if (data['durationOptions'] is String) {
        _selectedDurations.add(data['durationOptions'] as String);
      }

      if (data['paymentMethods'] is List) {
        _paymentMethods.addAll(List<String>.from(data['paymentMethods']));
      }

      for (final field in widget.extraFields) {
        final val = extra[field.keyName];
        if (val == null) continue;

        if (field.isMultiSelect) {
          if (val is List) {
            _multiSelectValues[field.keyName] = Set<String>.from(
              val.map((e) => e.toString()),
            );
          }
        } else if (field.isRepeatable) {
          if (val is List) {
            _repeatableValues[field.keyName] = List<String>.from(
              val.map((e) => e.toString()),
            );
          }
        } else if (field.isDropdown) {
          final valStr = val.toString();
          final opts = field.options ?? [];
          if (opts.contains('Khác') && !opts.contains(valStr)) {
            _extraDropdownValues[field.keyName] = 'Khác';
            _customControllers[field.keyName] = TextEditingController(
              text: valStr,
            );
          } else {
            _extraDropdownValues[field.keyName] = valStr;
          }
        } else if (field.isTicketClassPricing) {
          if (val is Map) {
            final classes = val.keys.map((k) => k.toString()).toSet();
            _ticketClassSelections[field.keyName] = classes;
            for (final k in classes) {
              if (_ticketClassPriceControllers[field.keyName]![k] == null) {
                _ticketClassPriceControllers[field.keyName]![k] = TextEditingController();
              }
              _ticketClassPriceControllers[field.keyName]![k]!.text = _formatWithDotsRaw(val[k].toString());
            }
          }
        } else {
          _extraControllers[field.keyName]?.text = val.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    for (final controller in _extraControllers.values) {
      controller.dispose();
    }
    for (final controller in _repeatableControllers.values) {
      controller.dispose();
    }
    for (final controller in _multiSelectControllers.values) {
      controller.dispose();
    }
    for (final controller in _customControllers.values) {
      controller.dispose();
    }
    for (final map in _ticketClassPriceControllers.values) {
      for (final controller in map.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDocId != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!widget.hideServiceName)
                _buildTextField(
                  label: 'Tên dịch vụ',
                  controller: _nameController,
                  required: true,
                ),
              _buildImagePicker(),
              if (!widget.hideMainPrice)
                _buildTextField(
                  label: 'Giá (VND)',
                  controller: _priceController,
                  required: true,
                  keyboardType: TextInputType.number,
                  validator: _validatePrice,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const _ThousandsSeparatorFormatter(),
                  ],
                ),
              _buildDurationOptions(),
              _buildTextField(
                label: 'Mô tả ngắn',
                controller: _descriptionController,
                required: true,
                maxLines: 3,
              ),
              AddressAutocompleteField(controller: _addressController),
              _buildTextField(
                label: 'Số điện thoại liên hệ',
                controller: _phoneController,
                required: true,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildPaymentMethods(),
              if (widget.extraFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Thông tin bổ sung',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final field in widget.extraFields) ...[
                  field.isMultiSelect
                      ? _buildMultiSelectField(field)
                      : field.isRepeatable
                      ? _buildRepeatableField(field)
                      : field.isDatePicker ||
                            field.isTimePicker ||
                            field.isSchedulePicker
                      ? _buildDateTimePickerField(field)
                      : field.isAutocomplete
                      ? _buildAutocompleteField(field)
                      : field.isTicketClassPricing
                      ? _buildTicketClassPricingField(field)
                      : field.isDropdown
                      ? _buildDropdownField(field)
                      : _buildExtraTextField(field),
                  if (field.keyName == 'airplaneName')
                    _buildInteractiveSeatMapPainter(),
                ]
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFF6B5FB5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Cập nhật dịch vụ' : 'Tạo dịch vụ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (value) {
              if (!required) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập $label';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh sản phẩm (ít nhất 1 ảnh)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildImagePreview(),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _pickImage(fromGallery: true),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Chọn ảnh'),
              ),
            ],
          ),
          if (_imagePaths.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Vui lòng thêm ít nhất 1 ảnh',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imagePaths.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 180,
          color: const Color(0xFFF1F1F1),
          alignment: Alignment.center,
          child: const Icon(Icons.photo, size: 42, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imagePaths.length,
        itemBuilder: (context, index) {
          final path = _imagePaths[index];
          Widget imageWidget;
          if (path.startsWith('http')) {
            imageWidget = Image.network(path, fit: BoxFit.cover);
          } else if (path.startsWith('data:image')) {
            try {
              final base64Str = path.split(',').last;
              imageWidget = Image.memory(
                base64Decode(base64Str),
                fit: BoxFit.cover,
              );
            } catch (e) {
              imageWidget = Container(
                color: Colors.red.shade100,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  size: 42,
                  color: Colors.red,
                ),
              );
            }
          } else {
            imageWidget = Image.file(File(path), fit: BoxFit.cover);
          }

          return Container(
            width: 180,
            margin: EdgeInsets.only(
              right: index == _imagePaths.length - 1 ? 0 : 12,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageWidget,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _imagePaths.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage({bool fromGallery = false}) async {
    if (fromGallery) {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _imagePaths.addAll(picked.map((e) => e.path));
      });
    } else {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (!mounted || picked == null) return;
      setState(() {
        _imagePaths.add(picked.path);
      });
    }
  }

  Widget _buildDurationOptions() {
    if (widget.unitOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '',
          border: OutlineInputBorder(),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(widget.durationLabel),
              ),
            ),
            for (final option in widget.unitOptions)
              CheckboxListTile(
                value: _selectedDurations.contains(option),
                title: Text(option),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedDurations.add(option);
                    } else {
                      _selectedDurations.remove(option);
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final methods = [
      'TripPay',
      'Thanh toán khi nhận hàng',
      'Chuyển khoản ngân hàng',
      'Ví điện tử (Momo, ZaloPay...)',
      'Thẻ tín dụng / Thẻ ghi nợ',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Phương thức thanh toán cho phép',
          border: OutlineInputBorder(),
        ),
        child: Column(
          children: methods.map((method) {
            return CheckboxListTile(
              value: _paymentMethods.contains(method),
              title: Text(method),
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _paymentMethods.add(method);
                  } else {
                    _paymentMethods.remove(method);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExtraTextField(ServiceFormField field) {
    final controller = _extraControllers[field.keyName];
    return _buildTextField(
      label: field.label,
      controller: controller!,
      required: field.required,
      keyboardType: field.keyboardType,
    );
  }

  Widget _buildMultiSelectField(ServiceFormField field) {
    final selected = _multiSelectValues.putIfAbsent(
      field.keyName,
      () => <String>{},
    );
    final presets = field.options ?? [];
    final customItems = selected.where((s) => !presets.contains(s)).toList();
    final addController =
        _multiSelectControllers[field.keyName] ?? TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...presets.map((size) {
                  final isSelected = selected.contains(size);
                  return FilterChip(
                    label: Text(size),
                    selected: isSelected,
                    showCheckmark: true,
                    selectedColor: const Color(0xFFE8E1FF),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF6B5FB5)
                          : const Color(0x3F000000),
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF6B5FB5)
                          : Colors.black87,
                    ),
                    onSelected: (checked) {
                      setState(() {
                        if (checked) {
                          selected.add(size);
                        } else {
                          selected.remove(size);
                        }
                      });
                    },
                  );
                }),
                ...customItems.map((size) {
                  return Chip(
                    label: Text(size),
                    backgroundColor: const Color(0xFFE8E1FF),
                    labelStyle: const TextStyle(
                      color: Color(0xFF6B5FB5),
                      fontWeight: FontWeight.w600,
                    ),
                    deleteIconColor: const Color(0xFF6B5FB5),
                    onDeleted: () {
                      setState(() => selected.remove(size));
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: addController,
                    decoration: const InputDecoration(
                      hintText: 'Thêm khác...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF6B5FB5),
                  ),
                  onPressed: () {
                    final val = addController.text.trim();
                    if (val.isNotEmpty) {
                      setState(() => selected.add(val));
                      addController.clear();
                    }
                  },
                ),
              ],
            ),
            if (selected.isEmpty && field.required)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Vui lòng chọn ít nhất một mục',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatableField(ServiceFormField field) {
    final items = _repeatableValues.putIfAbsent(
      field.keyName,
      () => <String>[],
    );
    final inputCtrl = _repeatableControllers.putIfAbsent(
      field.keyName,
      () => TextEditingController(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Danh sách items đã thêm
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final val = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x3F6B5FB5)),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: Text(
                    '${idx + 1}.',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B5FB5),
                    ),
                  ),
                  title: Text(val),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () {
                      setState(() => items.removeAt(idx));
                    },
                  ),
                ),
              );
            }),
            // Input thêm mới
            field.isTimePicker
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_alarm),
                      label: Text(field.hintText ?? 'Thêm giờ'),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          final timeStr =
                              "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                          if (!items.contains(timeStr)) {
                            setState(() => items.add(timeStr));
                          }
                        }
                      },
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputCtrl,
                          decoration: InputDecoration(
                            hintText: field.hintText ?? 'Nhập và nhấn +',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                items.add(val.trim());
                                inputCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF6B5FB5),
                        ),
                        onPressed: () {
                          final val = inputCtrl.text.trim();
                          if (val.isNotEmpty) {
                            setState(() {
                              items.add(val);
                              inputCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
            if (items.isEmpty && field.required)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Vui lòng thêm ít nhất một mục',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteField(ServiceFormField field) {
    final controller = _extraControllers.putIfAbsent(
      field.keyName,
      () => TextEditingController(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          final options = field.options ?? [];
          return options.where((String option) {
            return option.toLowerCase().contains(
              textEditingValue.text.toLowerCase(),
            );
          });
        },
        onSelected: (String selection) {
          controller.text = selection;
        },
        fieldViewBuilder:
            (
              BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
            ) {
              if (controller.text.isNotEmpty &&
                  fieldTextEditingController.text.isEmpty) {
                fieldTextEditingController.text = controller.text;
              }

              fieldTextEditingController.addListener(() {
                if (controller.text != fieldTextEditingController.text) {
                  setState(() {
                    controller.text = fieldTextEditingController.text;
                  });
                }
              });

              return TextFormField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(
                  labelText: field.label,
                  hintText: field.hintText,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.search),
                ),
                validator: (value) {
                  if (field.required &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập ${field.label}';
                  }
                  return null;
                },
              );
            },
      ),
    );
  }

  Widget _buildDateTimePickerField(ServiceFormField field) {
    final controller = _extraControllers.putIfAbsent(
      field.keyName,
      () => TextEditingController(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          if (field.isSchedulePicker) {
            final result = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Chọn lịch chạy'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.all_inclusive),
                      title: const Text('Hàng ngày'),
                      onTap: () => Navigator.pop(ctx, 'Hàng ngày'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.view_week),
                      title: const Text('Theo thứ trong tuần'),
                      onTap: () => Navigator.pop(ctx, 'weekdays'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Chọn ngày cụ thể'),
                      onTap: () => Navigator.pop(ctx, 'specific_date'),
                    ),
                  ],
                ),
              ),
            );
            if (result == 'Hàng ngày') {
              setState(() {
                controller.text = 'Hàng ngày';
              });
            } else if (result == 'weekdays') {
              if (!mounted) return;
              final selectedDays = await showDialog<List<String>>(
                context: context,
                builder: (ctx) {
                  final days = [
                    'Thứ 2',
                    'Thứ 3',
                    'Thứ 4',
                    'Thứ 5',
                    'Thứ 6',
                    'Thứ 7',
                    'CN',
                  ];
                  final selected = <String>{};
                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return AlertDialog(
                        title: const Text('Chọn ngày hoạt động'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: days.map((day) {
                              return CheckboxListTile(
                                title: Text(day),
                                value: selected.contains(day),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    if (val == true) {
                                      selected.add(day);
                                    } else {
                                      selected.remove(day);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (selected.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng chọn ít nhất 1 ngày',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Sort days
                              final sorted = selected.toList()
                                ..sort(
                                  (a, b) => days
                                      .indexOf(a)
                                      .compareTo(days.indexOf(b)),
                                );
                              Navigator.pop(ctx, sorted);
                            },
                            child: const Text('Xong'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (selectedDays != null && selectedDays.isNotEmpty) {
                setState(() {
                  controller.text = selectedDays.join(', ');
                });
              }
            } else if (result == 'specific_date') {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                setState(() {
                  controller.text =
                      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                });
              }
            }
          } else if (field.isDatePicker) {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                controller.text =
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
              });
            }
          } else if (field.isTimePicker) {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                controller.text =
                    "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
              });
            }
          }
        },
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hintText,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(
            field.isSchedulePicker
                ? Icons.edit_calendar
                : field.isDatePicker
                ? Icons.calendar_today
                : Icons.access_time,
          ),
        ),
        validator: (value) {
          if (field.required && (value == null || value.trim().isEmpty)) {
            return 'Vui lòng chọn ${field.label}';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(ServiceFormField field) {
    final currentValue = _extraDropdownValues[field.keyName];
    final options = _resolveDropdownOptions(field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: currentValue,
            items: options
                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _extraDropdownValues[field.keyName] = value;
                if (field.keyName == 'vehicleType') {
                  final nextOptions = _capacityOptionsForVehicle(value);
                  final currentCapacity = _extraDropdownValues['capacity'];
                  if (currentCapacity != null &&
                      !nextOptions.contains(currentCapacity)) {
                    _extraDropdownValues['capacity'] = null;
                  }
                }
              });
            },
            validator: (value) {
              if (!field.required) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng chọn ${field.label}';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              hintText: field.hintText,
            ),
          ),
          if (currentValue == 'Khác') ...[
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Nhập ${field.label.toLowerCase()}',
              controller: _customControllers.putIfAbsent(
                field.keyName,
                () => TextEditingController(),
              ),
              required: field.required,
            ),
          ],
        ],
      ),
    );
  }

  String _formatWithDotsRaw(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  Widget _buildTicketClassPricingField(ServiceFormField field) {
    final selected = _ticketClassSelections.putIfAbsent(
      field.keyName,
      () => <String>{},
    );
    final options = field.options ?? <String>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((opt) {
                final isSelected = selected.contains(opt);
                return FilterChip(
                  label: Text(opt),
                  selected: isSelected,
                  showCheckmark: true,
                  selectedColor: const Color(0xFFE8E1FF),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6B5FB5)
                        : const Color(0x3F000000),
                  ),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF6B5FB5)
                        : Colors.black87,
                  ),
                  onSelected: (checked) {
                    setState(() {
                      if (checked) {
                        selected.add(opt);
                        if (_ticketClassPriceControllers[field.keyName]![opt] == null) {
                          _ticketClassPriceControllers[field.keyName]![opt] = TextEditingController();
                        }
                      } else {
                        selected.remove(opt);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (selected.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Cài đặt giá cho từng hạng ghế (VND):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...selected.map((opt) {
                final ctrl = _ticketClassPriceControllers[field.keyName]![opt];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(opt)),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            const _ThousandsSeparatorFormatter(),
                          ],
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(),
                            hintText: 'Nhập giá',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            if (selected.isEmpty && field.required)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Vui lòng chọn ít nhất một hạng',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveSeatMapPainter() {
    final airplaneName = _extraControllers['airplaneName']?.text ?? '';
    if (airplaneName.isEmpty) return const SizedBox.shrink();
    
    final isLarge = airplaneName.toLowerCase().contains('boeing 777') ||
                    airplaneName.toLowerCase().contains('boeing 747') ||
                    airplaneName.toLowerCase().contains('airbus a350') ||
                    airplaneName.toLowerCase().contains('airbus a380') ||
                    airplaneName.toLowerCase().contains('boeing 787') ||
                    airplaneName.toLowerCase().contains('airbus a330');
    final rows = isLarge ? 15 : 10;
    final colsConfig = isLarge ? [3, 4, 3] : [3, 3];

    final ticketClassesSel = _ticketClassSelections['ticketClasses'] ?? {};
    if (ticketClassesSel.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Vui lòng tích chọn Hạng ghế ở trên để có thể phân bổ sơ đồ ghế.', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
      );
    }
    
    if (_currentSeatPaintClass == null || !ticketClassesSel.contains(_currentSeatPaintClass)) {
      _currentSeatPaintClass = ticketClassesSel.first;
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sơ đồ máy bay (Bấm để gán hạng ghế)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Chọn một hạng ghế làm cọ vẽ, sau đó bấm vào từng ghế hoặc bấm vào Số Hàng (1, 2, 3...) để đổi màu cả hàng tương ứng.', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ticketClassesSel.map((cls) {
              final isSelected = _currentSeatPaintClass == cls;
              Color clsColor = Colors.blue;
              if (cls == 'Thương gia') clsColor = Colors.orange;
              else if (cls == 'Phổ thông cao cấp') clsColor = Colors.purple;
              return ChoiceChip(
                label: Text(cls),
                selected: isSelected,
                selectedColor: clsColor.withOpacity(0.3),
                onSelected: (val) {
                  if (val) setState(() => _currentSeatPaintClass = cls);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.flight_takeoff, color: Colors.grey, size: 40),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(rows, (rowIndex) {
                  final rowNumber = rowIndex + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_currentSeatPaintClass == null) return;
                            setState(() {
                              int charCode = 65;
                              bool allPainted = true;
                              // Check if all seats in this row already have the current class
                              for (int c in colsConfig) {
                                int tempChar = charCode;
                                for (int i = 0; i < c; i++) {
                                  final seatId = '${rowNumber}${String.fromCharCode(tempChar)}';
                                  if (_seatClassesConfig[seatId] != _currentSeatPaintClass) {
                                    allPainted = false;
                                  }
                                  tempChar++;
                                }
                                charCode += c;
                              }
                              
                              charCode = 65;
                              for (int c in colsConfig) {
                                for (int i = 0; i < c; i++) {
                                  final seatId = '${rowNumber}${String.fromCharCode(charCode)}';
                                  if (allPainted) {
                                    _seatClassesConfig.remove(seatId);
                                  } else {
                                    _seatClassesConfig[seatId] = _currentSeatPaintClass!;
                                  }
                                  charCode++;
                                }
                              }
                            });
                          },
                          child: Container(
                            width: 30,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              rowNumber.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        ..._buildPainterRowSeats(rowNumber, colsConfig),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPainterRowSeats(int rowNumber, List<int> colsConfig) {
    List<Widget> rowChildren = [];
    int charCode = 65; // 'A'

    for (int groupIdx = 0; groupIdx < colsConfig.length; groupIdx++) {
      int colsInGroup = colsConfig[groupIdx];
      List<Widget> groupSeats = [];
      for (int i = 0; i < colsInGroup; i++) {
        final seatId = '${rowNumber}${String.fromCharCode(charCode)}';
        final seatClass = _seatClassesConfig[seatId] ?? 'Phổ thông';
        
        Color classColor = Colors.blue;
        if (seatClass == 'Thương gia') classColor = Colors.orange;
        else if (seatClass == 'Phổ thông cao cấp') classColor = Colors.purple;
        
        groupSeats.add(GestureDetector(
          onTap: () {
            if (_currentSeatPaintClass != null) {
              setState(() {
                if (_seatClassesConfig[seatId] == _currentSeatPaintClass) {
                  _seatClassesConfig.remove(seatId);
                } else {
                  _seatClassesConfig[seatId] = _currentSeatPaintClass!;
                }
              });
            }
          },
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: classColor.withOpacity(0.1),
              border: Border.all(color: classColor.withOpacity(0.5), width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              seatId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: classColor,
                fontSize: 11,
              ),
            ),
          ),
        ));
        charCode++;
      }
      rowChildren.add(Row(mainAxisSize: MainAxisSize.min, children: groupSeats));
      if (groupIdx < colsConfig.length - 1) {
        rowChildren.add(const SizedBox(width: 24));
      }
    }
    return rowChildren;
  }

  List<String> _resolveDropdownOptions(ServiceFormField field) {
    if (field.keyName == 'capacity') {
      final vehicleType = _extraDropdownValues['vehicleType'];
      return _capacityOptionsForVehicle(vehicleType);
    }
    return field.options ?? const [];
  }

  List<String> _capacityOptionsForVehicle(String? vehicleType) {
    switch (vehicleType) {
      case 'Xe máy':
        return ['1', '2'];
      case 'Xe đạp':
        return ['1'];
      case 'Ô tô':
        return ['4', '5', '7', '9', '12', '16'];
      default:
        return ['1', '2', '4', '5', '7', '9', '12', '16', '29', '45'];
    }
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập Giá (VND)';
    }
    final parsed = _parsePrice(value);
    if (parsed == null) {
      return 'Giá không hợp lệ';
    }
    if (parsed <= 0) {
      return 'Giá phải lớn hơn 0';
    }
    return null;
  }

  double? _parsePrice(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() != true) return;
    if (!widget.hideMainPrice && _validatePrice(_priceController.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_validatePrice(_priceController.text)!)),
      );
      return;
    }
    if (!widget.hideServiceName && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên dịch vụ')),
      );
      return;
    }
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 ảnh')),
      );
      return;
    }
    if (widget.unitOptions.isNotEmpty && _selectedDurations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một gói thời gian'),
        ),
      );
      return;
    }
    final price = _parsePrice(_priceController.text) ?? 0;
    final extra = <String, dynamic>{};
    for (final field in widget.extraFields) {
      if (field.isMultiSelect) {
        extra[field.keyName] = (_multiSelectValues[field.keyName] ?? {})
            .toList();
      } else if (field.isRepeatable) {
        extra[field.keyName] = List<String>.from(
          _repeatableValues[field.keyName] ?? [],
        );
      } else if (field.isDropdown) {
        final val = _extraDropdownValues[field.keyName];
        if (val == 'Khác') {
          extra[field.keyName] =
              _customControllers[field.keyName]?.text.trim() ?? '';
        } else {
          extra[field.keyName] = val;
        }
      } else if (field.isTicketClassPricing) {
        final sel = _ticketClassSelections[field.keyName] ?? {};
        final map = <String, dynamic>{};
        for (final s in sel) {
          final priceText = _ticketClassPriceControllers[field.keyName]![s]?.text.replaceAll('.', '') ?? '';
          map[s] = int.tryParse(priceText) ?? 0;
        }
        extra[field.keyName] = map;
      } else {
        extra[field.keyName] =
            _extraControllers[field.keyName]?.text.trim() ?? '';
      }
    }

    extra['seatClassesConfig'] = _seatClassesConfig;

    setState(() => _isSaving = true);
    setState(() => _isSaving = true);

    List<String> imageUrls = [];
    for (final path in _imagePaths) {
      if (path.startsWith('http') || path.startsWith('data:image')) {
        imageUrls.add(path);
      } else {
        try {
          final bytes = await File(path).readAsBytes();
          final base64String = base64Encode(bytes);
          final ext = path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
          imageUrls.add('data:image/$ext;base64,$base64String');
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xử lý ảnh thất bại: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }
    }

    extra['images'] = imageUrls;
    extra['imageUrl'] = imageUrls.isNotEmpty ? imageUrls.first : null;
    final payload = {
      'serviceType': widget.serviceType,
      'name': widget.hideServiceName ? 'Vé phương tiện' : _nameController.text.trim(),
      'price': price,
      'images': imageUrls,
      'image': imageUrls.isNotEmpty ? imageUrls.first : null,
      'durationOptions': _selectedDurations.toList(),
      'paymentMethods': _paymentMethods.toList(),
      'description': _descriptionController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'extra': extra,
      'status': 'active',
    };

    final isEditing = widget.existingDocId != null;
    final service = FirebaseBusinessService();

    bool success;
    String? error;

    if (isEditing) {
      final res = await service.updateService(
        collectionName: widget.collectionName,
        docId: widget.existingDocId!,
        data: payload,
      );
      success = res.success;
      error = res.error;
    } else {
      final res = await service.createService(
        collectionName: widget.collectionName,
        data: payload,
      );
      success = res.success;
      error = res.error;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Cập nhật thành công' : 'Đã đăng dịch vụ'),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Thao tác thất bại')));
    }
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  const _ThousandsSeparatorFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final formatted = _formatWithDots(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}
