import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/binhluan_va_tuongtac_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/hoatdong_ganthe_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/tinnhan_history_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/tin_dadang_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/baiviet_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/bosuutap_valuu_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/chuyendi_datao_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/lichsu_timkiem_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/lichsu_nhacden_page.dart';
import 'package:tourn/Ui/main/category/menu/widgets/Settings/Hoatdongcuaban/lichsu_taikhoan_page.dart';

class Hoatdongcuaban extends StatefulWidget {
  const Hoatdongcuaban({super.key});

  @override
  State<Hoatdongcuaban> createState() => _HoatdongcuabanState();
}

class _HoatdongcuabanState extends State<Hoatdongcuaban> {
  // ===== Icon box giống TikTok =====
  Widget _leadingIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  // ===== Tile =====
  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        ListTile(
          leading: _leadingIcon(icon, color),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        const Divider(height: 1, indent: 72),
      ],
    );
  }

  // ===== Section title =====
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hoạt động của bạn"),
        centerTitle: true,
        elevation: 0,
      ),

      body: ListView(
        children: [
          // ================= INTERACTION =================
          _section("Tương tác"),

          _tile(
            icon: Icons.chat_bubble_outline,
            title: "Bình luận và tương tác",
            subtitle: "Các bình luận, lượt thích của bạn",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BinhluanVaTuongtacPage()),
            ),
          ),

          _tile(
            icon: Icons.alternate_email,
            title: "Hoạt động có gắn thẻ bạn",
            subtitle: "Ai đã nhắc đến hoặc gắn thẻ bạn",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HoatdongGanThePage()),
            ),
          ),

          _tile(
            icon: Icons.message_outlined,
            title: "Tin nhắn",
            subtitle: "Tin nhắn bạn đã gửi và nhận",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TinnhanHistoryPage()),
            ),
          ),

          _tile(
            icon: Icons.auto_stories_outlined,
            title: "Tin",
            subtitle: "Tin bạn đã đăng",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TinDaDangPage()),
            ),
          ),

          // ================= CONTENT =================
          _section("Nội dung"),

          _tile(
            icon: Icons.article_outlined,
            title: "Bài viết",
            subtitle: "Video và bài đăng của bạn",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BaivietPage()),
            ),
          ),

          _tile(
            icon: Icons.bookmark_border,
            title: "Bộ sưu tập và mục đã lưu",
            subtitle: "Video và bài viết bạn đã lưu",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BosuutapVaDaluuPage()),
            ),
          ),

          _tile(
            icon: Icons.map_outlined,
            title: "Chuyến đi đã tạo",
            subtitle: "Các chuyến đi bạn đã đăng",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChuyendidataoPage()),
            ),
          ),

          // ================= HISTORY =================
          _section("Lịch sử"),

          _tile(
            icon: Icons.search_outlined,
            title: "Lịch sử tìm kiếm",
            subtitle: "Các tìm kiếm gần đây",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LichsutimkiemPage()),
            ),
          ),

          _tile(
            icon: Icons.campaign_outlined,
            title: "Lịch sử nhắc đến",
            subtitle: "Những lần bạn được nhắc tới",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LichsunhacdenPage()),
            ),
          ),

          _tile(
            icon: Icons.history,
            title: "Lịch sử tài khoản",
            subtitle: "Hoạt động đăng nhập và thay đổi",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LichsutaikhoanPage()),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
