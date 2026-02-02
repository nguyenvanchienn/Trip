import 'package:flutter/material.dart';

class ThongBao extends StatelessWidget {
  const ThongBao({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 204, 255, 0),
        border: Border(
          top: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
          bottom: BorderSide(color: const Color.fromARGB(255, 0, 255, 132)),
          left: BorderSide(color: const Color.fromARGB(255, 60, 0, 255)),
          right: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
        ),
        
      ),
    );
  }
}
