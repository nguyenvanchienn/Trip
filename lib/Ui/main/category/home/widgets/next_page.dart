// đây là file chứa code của trang next page trong phần home
import 'package:flutter/material.dart';

class next extends StatelessWidget {
  const next({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next Page')),
      body: const Center(child: Text('This is the next page.')),
    );
  }
}
