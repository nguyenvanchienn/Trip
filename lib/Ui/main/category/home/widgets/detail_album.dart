import 'package:flutter/material.dart';

class DetailAlbum extends StatelessWidget {
  const DetailAlbum({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Album Page')),
      body: const Center(child: Text('This is the detail album page.')),
    );
  }
}
