// đây là file chứa code của bottom sheet trong trang home hình dấu + ngoài màn hinh chính của home
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/create_and_edit_content.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/create_poll.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/film_reel.dart';
import 'package:tourn/Ui/main/category/home/widgets/button_add/live_stream.dart';
import 'package:tourn/Ui/main/category/messenge/widgets/AIbottonchat.dart';

// project data and domain
import '../../../../../data/post/firestore_post_repository.dart';
import '../../../../../domain/user_repository/user_repository.dart';

// local widgets
import 'check_in.dart';

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
            final double maxChildSize = (maxSheetHeight / constraints.maxHeight)
                .clamp(0.4, 1.0);
            // initialChildSize phải <= maxChildSize
            final double initialChildSize = maxChildSize.clamp(
              0.35,
              maxChildSize,
            );
            return DraggableScrollableSheet(
              initialChildSize: initialChildSize,
              minChildSize:
                  0.35, // Kích thước tối thiểu (20% chiều cao màn hình)
              maxChildSize: maxChildSize,
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
                          Navigator.of(context, rootNavigator: true).push(
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

                      // Check in -> mở trang CheckIn (trả về kết quả khi chọn vị trí)
                      InkWell(
                        onTap: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          final result = await navigator.push(
                            MaterialPageRoute(
                              builder: (context) => const CheckIn(),
                            ),
                          );
                          if (result != null) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Check in: $result')),
                            );
                          }
                        },
                        child: const ListTile(
                          leading: Icon(Icons.location_on, color: Colors.black),
                          title: Text("Check in"),
                        ),
                      ),

                      // Thước phim
                      InkWell(
                        onTap: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          final r = await navigator.push(
                            MaterialPageRoute(
                              builder: (context) => const FilmReelPage(),
                            ),
                          );
                          if (r != null && r is Map) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã tạo thước phim: ${r['title']}',
                                ),
                              ),
                            );
                          }
                        },
                        child: const ListTile(
                          leading: Icon(Icons.movie, color: Colors.black),
                          title: Text("Thước phim"),
                        ),
                      ),

                      // Phát trực tiếp
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LiveStreamPage(),
                            ),
                          );
                        },
                        child: const ListTile(
                          leading: Icon(Icons.videocam, color: Colors.red),
                          title: Text(
                            "Phát trực tiếp",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),

                      // Đặt câu hỏi (Poll)
                      InkWell(
                        onTap: () async {
                          // Save references before popping to avoid deactivated widget error
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);
                          UserRepository? userRepo;
                          try {
                            userRepo = context.read<UserRepository>();
                          } catch (_) {}

                          navigator.pop();
                          final poll = await navigator.push(
                            MaterialPageRoute(
                              builder: (context) => const CreatePollPage(),
                            ),
                          );
                          if (poll != null && poll is Map) {
                            // create a post for this poll/trip selection
                            final question = poll['question'] as String?;
                            final tripId = poll['tripId'] as String?;
                            if (question != null && tripId != null) {
                              final postRepo = FirestorePostRepository();
                              // determine author name and photo
                              String authorName = 'Người dùng';
                              String? authorPhotoUrl;
                              try {
                                if (userRepo != null) {
                                  final currentUser = await userRepo
                                      .getCurrentUser();
                                  if (currentUser?.displayName != null &&
                                      currentUser!.displayName.isNotEmpty) {
                                    authorName = currentUser.displayName;
                                    authorPhotoUrl = currentUser.photoUrl;
                                  }
                                }
                              } catch (_) {}
                              await postRepo.createPost(
                                content: question,
                                authorName: authorName,
                                authorPhotoUrl: authorPhotoUrl,
                                tripId: tripId,
                              );
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã tạo bài viết với chuyến đi',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const ListTile(
                          leading: Icon(
                            Icons.help_outline,
                            color: Colors.black,
                          ),
                          title: Text("Đặt câu hỏi"),
                        ),
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
