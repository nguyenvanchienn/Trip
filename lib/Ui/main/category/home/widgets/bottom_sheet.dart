// đây là file chứa code của bottom sheet trong trang home hình dấu + ngoài màn hinh chính của home
import 'package:flutter/material.dart';
import 'package:tourn/Ui/main/category/home/widgets/create_and_edit_content.dart';
import 'package:tourn/Ui/main/category/mail/widgets/AIbottonchat.dart';

Future<dynamic> bottom(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Cho phép cuộn nội dung
    backgroundColor: Colors.transparent,
    isDismissible: true, // Đảm bảo ấn ra ngoài sẽ đóng
    enableDrag: true, // Cho phép kéo để đóng
    barrierColor: Colors.black.withOpacity(0.3),
    builder: (context) {
      return GestureDetector(
        // Bắt sự kiện chạm ngoài để đóng
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).pop();
        },
        child: LayoutBuilder(
          // Sử dụng LayoutBuilder để lấy kích thước
          builder: (context, constraints) {
            // Tính chiều cao tối đa của nội dung
            final double maxSheetHeight =
                450; // hoặc tự động tính theo nội dung
            return DraggableScrollableSheet(
              initialChildSize:
                  0.53, // Kích thước ban đầu (40% chiều cao màn hình)
              minChildSize:
                  0.35, // Kích thước tối thiểu (20% chiều cao màn hình)
              maxChildSize: (maxSheetHeight / constraints.maxHeight).clamp(
                0.0,
                1.0,
              ),
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    shrinkWrap:
                        true, // Cho phép nội dung co lại theo kích thước
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Tạo bài viết',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop(); // Đóng bottom sheet
                          // Chuyển đến trang tạo và chỉnh sửa nội dung
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const createandeditcontent(),
                            ),
                          );
                        },
                        child: const ListTile(
                          leading: Icon(Icons.edit, color: Colors.black),
                          title: Text("Tạo bài viết"),
                        ),
                      ),
                      const ListTile(
                        leading: Icon(Icons.location_on, color: Colors.black),
                        title: Text("Check in"),
                      ),
                      const ListTile(
                        leading: Icon(Icons.movie, color: Colors.black),
                        title: Text("Thước phim"),
                      ),
                      const ListTile(
                        leading: Icon(Icons.videocam, color: Colors.red),
                        title: Text(
                          "Phát trực tiếp",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      const ListTile(
                        leading: Icon(Icons.help_outline, color: Colors.black),
                        title: Text("Đặt câu hỏi"),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop(); // Đóng bottom sheet
                          // Mở AI Chat Bottom Sheet
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true, // Cho phép cuộn nội dung
                            backgroundColor: Colors.transparent,
                            builder: (context) => const AIChatBottomSheet(),
                          );
                        },
                        child: ListTile(
                          leading: Image.asset(
                            "asset/icon/logo.png",
                            width: 25,
                            height: 25,
                            fit: BoxFit
                                .contain, // Thay đổi kích thước ảnh nếu cần
                          ),
                          title: const Text("TRIP AI"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}
