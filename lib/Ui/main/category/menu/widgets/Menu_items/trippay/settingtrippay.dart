import 'package:flutter/material.dart';

class Settingtrippay extends StatelessWidget {
  const Settingtrippay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt TripPay"),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[200],
      body: ListView(
        children: [
          const SizedBox(height: 10),

          _sectionTitle("Tài khoản"),
          _tile(Icons.person, "Thông tin cá nhân", "Sửa tên, số điện thoại"),
          _tile(
            Icons.account_balance,
            "Liên kết ngân hàng",
            "Thêm / xoá tài khoản ngân hàng",
          ),

          const SizedBox(height: 15),

          _sectionTitle("Bảo mật"),
          _tile(Icons.pin_outlined, "Mã PIN ví", "Đổi hoặc bật mã PIN"),
          _tile(Icons.fingerprint, "Face ID / Vân tay", "Mở ví bằng sinh trắc"),
          _tile(Icons.visibility_off, "Ẩn số dư", "Bật tắt hiển thị số dư"),

          const SizedBox(height: 15),

          _sectionTitle("Thông báo"),
          _tile(
            Icons.notifications,
            "Thông báo giao dịch",
            "Nhận thông báo chuyển tiền",
          ),
          _tile(Icons.volume_up, "Âm thanh", "Âm thanh khi nhận tiền"),

          const SizedBox(height: 15),

          _sectionTitle("Khác"),
          _tile(Icons.help_outline, "Trợ giúp", "Câu hỏi thường gặp"),
          _tile(Icons.info_outline, "Về TripPay", "Phiên bản ứng dụng"),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String sub, {Color? color}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withOpacity(0.15),
        child: Icon(icon, color: color ?? Colors.orange),
      ),
      title: Text(title),
      subtitle: sub.isEmpty ? null : Text(sub),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
    );
  }
}
