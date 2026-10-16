import 'package:flutter/material.dart';

/// Widget tile tiện ích - luôn hiển thị và có thể bấm bình thường.
class MenuItemTile extends StatefulWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  /// Không còn dùng để check Firestore nữa, giữ lại để tương thích với code cũ.
  final String? collectionName;

  const MenuItemTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.collectionName,
  });

  @override
  State<MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<MenuItemTile> {
  bool _isProcessing = false;

  void _handleTap() async {
    if (_isProcessing || widget.onTap == null) return;

    setState(() => _isProcessing = true);

    widget.onTap!();

    // Mở khóa sau 500ms để tránh push nhiều màn hình cùng lúc, 
    // ngăn tình trạng chồng chéo giao diện và gây treo app.
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildTile(context, isAvailable: true);
  }

  Widget _buildTile(BuildContext context, {required bool isAvailable}) {
    return GestureDetector(
      onTap: isAvailable ? _handleTap : () => _showClosedSnackbar(context),
      child: Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: isAvailable ? 1.0 : 0.38,
            child: ColorFiltered(
              colorFilter: isAvailable
                  ? const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    )
                  : const ColorFilter.matrix([
                      0.33,
                      0.59,
                      0.11,
                      0,
                      0,
                      0.33,
                      0.59,
                      0.11,
                      0,
                      0,
                      0.33,
                      0.59,
                      0.11,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6),
                      ],
                    ),
                    child: Center(child: widget.icon),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          // Badge "Tạm đóng" hiển thị khi không có shop hoạt động
          if (!isAvailable)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tạm đóng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showClosedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(
              Icons.store_mall_directory_outlined,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hiện tại chưa có cửa hàng nào hoạt động trong danh mục này',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
