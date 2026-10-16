import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippay.dart';

class TripPayPinPage extends StatefulWidget {
  /// If true (the default) a successful PIN entry will replace this page
  /// with the main TripPay home screen.
  ///
  /// When used for in‑flow payments we set this to false and the page will
  /// simply pop with a `true` result, allowing the caller to continue.
  final bool redirectToHome;

  const TripPayPinPage({super.key, this.redirectToHome = true});

  @override
  State<TripPayPinPage> createState() => _TripPayPinPageState();
}

class _TripPayPinPageState extends State<TripPayPinPage> {
  String enteredPin = "";
  final String correctPin = "123456";

  void onNumberPress(String number) {
    if (enteredPin.length >= 6) return;

    setState(() {
      enteredPin += number;
    });

    if (enteredPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;

        if (enteredPin == correctPin) {
          if (widget.redirectToHome) {
            // replace PIN page with TripPage but keep menu underneath
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TripPage()),
            );
          } else {
            Navigator.of(context).pop(true);
          }
        } else {
          setState(() {
            enteredPin = "";
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sai mã PIN"),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void deletePin() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  // ✅ SỬA Ở ĐÂY (đổi màu để nhìn rõ)
  Widget buildDot(int index) {
    bool isFilled = index < enteredPin.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled
            ? Colors
                  .white // ⭐ đổi sang trắng
            : Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget numberButton(String n) {
    return GestureDetector(
      onTap: () => onNumberPress(n),
      child: Container(
        width: 75,
        height: 75,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange,
        ),
        alignment: Alignment.center,
        child: Text(
          n,
          style: const TextStyle(
            fontSize: 26,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget deleteButton() {
    return GestureDetector(
      onTap: deletePin,
      child: Container(
        width: 75,
        height: 75,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace, color: Colors.white, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: SafeArea(
        child: Column(
          children: [
            // back button row
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 40),

            const Text(
              "Nhập mã PIN TripPay",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, buildDot),
            ),

            const SizedBox(height: 40),

            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 25,
                  children: [
                    ...List.generate(9, (i) => numberButton("${i + 1}")),
                    const SizedBox(),
                    numberButton("0"),
                    deleteButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
