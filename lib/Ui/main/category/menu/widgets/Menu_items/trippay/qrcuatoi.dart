import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Qrcuatoi extends StatelessWidget {
  const Qrcuatoi({super.key});

  @override
  Widget build(BuildContext context) {
    /// dữ liệu QR của bạn (ID user, sdt, tài khoản...)
    const myQrData = "TRIPPAY_USER_0328062539";

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR của tôi"),
        backgroundColor: Colors.orange,
      ),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          const SizedBox(height: 30),

          /// Card QR
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Chiến Nguyễn",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text("0987 654 321"),
                const SizedBox(height: 20),

                /// QR code
                QrImageView(
                  data: myQrData,
                  version: QrVersions.auto,
                  size: 220,
                ),

                const SizedBox(height: 10),
                const Text(
                  "Quét mã để chuyển tiền",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// Nút chức năng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _btn(Icons.share, "Chia sẻ", () {}),
              _btn(Icons.download, "Lưu ảnh", () {}),
              _btn(Icons.copy, "Sao chép ID", () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Đã copy ID")));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String text, VoidCallback onTap) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.orange,
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    );
  }
}
