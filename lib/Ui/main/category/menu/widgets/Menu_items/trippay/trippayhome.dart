import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/settingtrippay.dart';

class Trippayhome extends StatefulWidget {
  const Trippayhome({super.key});

  @override
  State<Trippayhome> createState() => _TrippayhomeState();
}

class _TrippayhomeState extends State<Trippayhome> {
  double balance = 5200000;
  bool showMoney = false;

  String formatMoney(double money) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(money).replaceAll(",", ".")} đ";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        children: [
          // ===== HEADER CAM =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 25),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE + close + settings
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets
                          .zero, // remove default padding for tight alignment
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        // simply pop TripPage to reveal the menu with bottom navigation
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    const Text(
                      "TripPay",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Settingtrippay(),
                          ),
                        );
                      },
                      child: const Icon(Icons.settings, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  "Số dư TripPay",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      showMoney ? formatMoney(balance) : "••••••••",
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        setState(() => showMoney = !showMoney);
                      },
                      icon: Icon(
                        showMoney ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _Quick(Icons.add, "Nạp tiền"),
                    _Quick(Icons.send, "Chuyển tiền"),
                    _Quick(Icons.flight_takeoff, "Thanh toán"),
                    _Quick(Icons.qr_code, "QR Pay"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Quick(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.orange),
        ),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
