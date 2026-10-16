import 'package:flutter/material.dart';

class Thongtindangnhapdaluu extends StatefulWidget {
  const Thongtindangnhapdaluu({super.key});

  @override
  State<Thongtindangnhapdaluu> createState() => _ThongtindangnhapdaluuState();
}

class _ThongtindangnhapdaluuState extends State<Thongtindangnhapdaluu> {
  List<Map<String, dynamic>> sessions = [
    {
      "device": "iPhone 13 Pro",
      "location": "Hà Nội, Việt Nam",
      "time": "Đang hoạt động",
      "active": true,
    },
    {
      "device": "Chrome trên Windows",
      "location": "Hồ Chí Minh, Việt Nam",
      "time": "2 giờ trước",
      "active": false,
    },
    {
      "device": "Samsung Galaxy S21",
      "location": "Đà Nẵng, Việt Nam",
      "time": "Hôm qua",
      "active": false,
    },
  ];

  // 🔹 Icon theo thiết bị
  IconData _deviceIcon(String name) {
    name = name.toLowerCase();

    if (name.contains("iphone") ||
        name.contains("samsung") ||
        name.contains("android")) {
      return Icons.smartphone;
    }
    if (name.contains("windows") ||
        name.contains("chrome") ||
        name.contains("mac")) {
      return Icons.laptop_mac;
    }
    return Icons.devices;
  }

  // 🔥 Long press menu
  void _showDeviceMenu(int index) {
    final item = sessions[index];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item["device"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // 🔴 Đăng xuất
              if (!item["active"])
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Đăng xuất thiết bị này"),
                  onTap: () {
                    setState(() => sessions.removeAt(index));
                    Navigator.pop(context);
                  },
                ),

              // 🛡️ Bảo vệ tài khoản
              ListTile(
                leading: const Icon(Icons.security, color: Colors.blue),
                title: const Text("Bảo vệ tài khoản"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã gửi yêu cầu bảo vệ tài khoản"),
                    ),
                  );
                },
              ),

              if (item["active"])
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    "Đây là thiết bị hiện tại",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _deviceTile(int index, Map item) {
    return Column(
      children: [
        ListTile(
          onTap: () => _showDeviceMenu(index),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_deviceIcon(item["device"]), color: Colors.blue),
          ),
          title: Text(item["device"]),
          subtitle: Text("${item["location"]} • ${item["time"]}"),
          trailing: item["active"]
              ? const Text(
                  "Thiết bị này",
                  style: TextStyle(color: Colors.green),
                )
              : null,
        ),
        const Divider(indent: 72),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nơi bạn đã đăng nhập"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) => _deviceTile(index, sessions[index]),
      ),
    );
  }
}
