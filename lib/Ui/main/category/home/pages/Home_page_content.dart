import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/pages/Newfeed.dart';
import 'package:tourn/Ui/main/category/home/pages/liststory.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final GlobalKey<NewfeedState> _newfeedKey = GlobalKey<NewfeedState>();

  @override
  Widget build(BuildContext context) {
    // Sử dụng CustomScrollView để kết hợp scroll mượt mà
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Kiểm tra khi scroll gần đến cuối
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          // Trigger load more trong Newfeed
          _newfeedKey.currentState?.loadMoreIfNeeded();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          // Liststory horizontal scroll - độc lập
          SliverToBoxAdapter(child: Liststory()),
          // Newfeed vertical scroll - tích hợp vào CustomScrollView
          Newfeed(key: _newfeedKey),
        ],
      ),
    );
  }
}
