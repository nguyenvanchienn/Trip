import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class LayoutSelectorDialog extends StatefulWidget {
  final List<XFile> images;
  final int currentLayout;
  final Function(int) onLayoutSelected;

  const LayoutSelectorDialog({
    super.key,
    required this.images,
    required this.currentLayout,
    required this.onLayoutSelected,
  });

  @override
  State<LayoutSelectorDialog> createState() => _LayoutSelectorDialogState();
}

class _LayoutSelectorDialogState extends State<LayoutSelectorDialog> {
  late int _selectedLayout;
  List<Uint8List?> _imageBytes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLayout = widget.currentLayout;
    _loadImages();
  }

  Future<void> _loadImages() async {
    final futures = widget.images
        .take(4)
        .map((img) => img.readAsBytes())
        .toList();
    final results = await Future.wait(futures);
    if (mounted) {
      setState(() {
        _imageBytes = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Chọn bố cục',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onLayoutSelected(_selectedLayout);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Xong',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Layout options
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Layout 1: Grid 2 columns (default Facebook style)
                      _buildLayoutOption(
                        layoutIndex: 0,
                        title: 'Lưới 2 cột',
                        child: _buildLayout2Columns(),
                      ),
                      const SizedBox(height: 16),

                      // Layout 2: Single image full width
                      _buildLayoutOption(
                        layoutIndex: 1,
                        title: 'Ảnh đơn',
                        child: _buildLayoutSingle(),
                      ),
                      const SizedBox(height: 16),

                      // Layout 3: Horizontal scroll
                      _buildLayoutOption(
                        layoutIndex: 2,
                        title: 'Cuộn ngang',
                        child: _buildLayoutHorizontal(),
                      ),
                      const SizedBox(height: 16),

                      // Layout 4: 1 big + 2 small
                      if (widget.images.length >= 3)
                        _buildLayoutOption(
                          layoutIndex: 3,
                          title: '1 lớn + 2 nhỏ',
                          child: _buildLayout1Big2Small(),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutOption({
    required int layoutIndex,
    required String title,
    required Widget child,
  }) {
    final isSelected = _selectedLayout == layoutIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLayout = layoutIndex;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 20,
                    ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
              child: SizedBox(height: 150, child: child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout2Columns() {
    if (_imageBytes.isEmpty) return const SizedBox.shrink();

    // Grid 2x2 với 4 ô bằng nhau
    return Column(
      children: [
        // Hàng 1
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _imageBytes.isNotEmpty
                    ? Image.memory(_imageBytes[0]!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[800]),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _imageBytes.length > 1
                    ? Image.memory(_imageBytes[1]!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[800]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // Hàng 2
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _imageBytes.length > 2
                    ? Image.memory(_imageBytes[2]!, fit: BoxFit.cover)
                    : Container(color: Colors.grey[800]),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _imageBytes.length > 3
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes[3]!, fit: BoxFit.cover),
                          if (widget.images.length > 4)
                            Container(
                              color: Colors.black54,
                              child: Center(
                                child: Text(
                                  '+${widget.images.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutSingle() {
    if (_imageBytes.isEmpty) return const SizedBox.shrink();
    return Image.memory(
      _imageBytes[0]!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 150,
    );
  }

  Widget _buildLayoutHorizontal() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _imageBytes.length,
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: EdgeInsets.only(
            right: index < _imageBytes.length - 1 ? 4 : 0,
          ),
          child: _imageBytes[index] != null
              ? Image.memory(_imageBytes[index]!, fit: BoxFit.cover)
              : Container(color: Colors.grey[800]),
        );
      },
    );
  }

  Widget _buildLayout1Big2Small() {
    if (_imageBytes.length < 3) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Image.memory(
            _imageBytes[0]!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              Expanded(child: Image.memory(_imageBytes[1]!, fit: BoxFit.cover)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes[2]!, fit: BoxFit.cover),
                    if (widget.images.length > 3)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            '+${widget.images.length - 3}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
