import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Widget TextField có gợi ý địa chỉ tự động qua Nominatim (OpenStreetMap).
/// Không yêu cầu API key. Ưu tiên kết quả tại Việt Nam.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.validator,
    this.decoration,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _suppressSearch = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_suppressSearch) return;
    final text = widget.controller.text.trim();
    if (text.length < 3) {
      _removeOverlay();
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(text));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'vn',
        'accept-language': 'vi',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'TripApp/1.0'},
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final results = data.map((item) {
          return _PlaceSuggestion(
            displayName: _shortenAddress(item['display_name'] as String),
            fullName: item['display_name'] as String,
          );
        }).toList();
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
        if (results.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _shortenAddress(String full) {
    // Rút gọn: chỉ lấy 4 phần đầu
    final parts = full.split(', ');
    if (parts.length <= 4) return full;
    return parts.take(4).join(', ');
  }

  void _selectSuggestion(_PlaceSuggestion suggestion) {
    _suppressSearch = true;
    widget.controller.text = suggestion.displayName;
    _suppressSearch = false;
    _removeOverlay();
    _focusNode.unfocus();
    setState(() => _suggestions = []);
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, thickness: 0.5),
                    itemBuilder: (ctx, i) {
                      final s = _suggestions[i];
                      return InkWell(
                        onTap: () => _selectSuggestion(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFF6B5FB5),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.displayName,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: widget.decoration ?? InputDecoration(
            labelText: 'Địa chỉ',
            border: const OutlineInputBorder(),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search, color: Color(0xFF6B5FB5)),
          ),
          validator:
              widget.validator ??
              (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
        ),
      ),
    );
  }
}

class _PlaceSuggestion {
  final String displayName;
  final String fullName;

  const _PlaceSuggestion({required this.displayName, required this.fullName});
}
