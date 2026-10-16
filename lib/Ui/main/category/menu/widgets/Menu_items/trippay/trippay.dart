import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippayhome.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippaylichsu.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Menu_items/trippay/trippayqr.dart';

class TripPage extends StatefulWidget {
  final int initialTab;

  const TripPage({super.key, this.initialTab = 0});

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  late int _currentPage;

  // Only home and history are part of the main tab stack; QR is
  // launched as a full‑screen route when the user taps the middle
  // icon (similar to mBank behavior).
  final List<Widget> _pages = const [Trippayhome(), Trippaylichsu()];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentPage, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // optionally add a FAB for QR if you want special styling
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.orange,
        currentIndex: _currentPage,
        onTap: (index) {
          if (index == 1) {
            // QR icon pressed: open scanner page instead of switching tabs
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Trippayqr()),
            );
          } else {
            final target = index > 1 ? index - 1 : index;
            setState(() => _currentPage = target);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            label: "QR",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, color: Colors.white),
            label: "Lịch sử",
          ),
        ],
      ),
    );
  }
}
