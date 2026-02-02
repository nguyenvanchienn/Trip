// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:tourn/Ui/main/category/home/widgets/buttom_add/next.dart';

// class createandeditcontentt extends StatefulWidget {
//   const createandeditcontentt({super.key});

//   @override
//   State<createandeditcontentt> createState() => _createandeditcontenttState();
// }

// class _createandeditcontenttState extends State<createandeditcontentt> {
//   final TextEditingController _contentcontroller =
//       TextEditingController(); // Controller để quản lý nội dung nhập liệu và lưu trữ giá trị

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent, // Đặt nền trong suốt
//         title: Center(
//           child: Text(
//             "Create_content_page".tr(),
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         ),
//         actions: [
//           // Nút next ở góc phải
//           TextButton(
//             onPressed: () {
//               // Xử lý khi nhấn nút next
//               _gotonextpage(context);
//             },
//             child: Text(
//               "Next".tr(),
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: _buildbodypagescreen(),
//     );
//   }

//   Widget _buildbodypagescreen() {
//     return SingleChildScrollView(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment
//             .start, // Căn chỉnh theo trục chính từ trên xuống dưới
//         crossAxisAlignment: CrossAxisAlignment
//             .start, // Căn chỉnh theo trục ngang từ trái sang phải
//         children: [
//           _buildcategoryoption(),
//           _buildcategoryNamefield(),
//           _buildcategorychooseIconfield(),
//           _buildcategorychooseBackgroundcolorfield(),
//         ],
//       ),
//     );
//   }

//   Widget _buildcategoryoption() {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
//       child: Text(
//         "Basic_info".tr(),
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//     );
//   }

//   Widget _buildcategoryNamefield() {
//     return Container(
//       child: Column(
//         children: [
//           TextFormField(
//             controller: _contentcontroller, // Gán controller cho TextFormField
//             keyboardType: TextInputType.multiline,
//             minLines: 12, // Số dòng tối thiểu
//             maxLines: 12, // Số dòng tối đa
//             textAlignVertical:
//                 TextAlignVertical.top, // Căn chỉnh văn bản ở trên cùng
//             decoration: InputDecoration(
//               hintText: "Bạn đang nghĩ gì?",
//               hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(4),
//                 borderSide: BorderSide(color: Colors.grey),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildcategorychooseIconfield() {
//     return Container(
//       child: Column(
//         children: [
//           TextFormField(
//             controller: _contentcontroller, // Gán controller cho TextFormField
//             keyboardType: TextInputType.multiline,
//             textAlignVertical:
//                 TextAlignVertical.top, // Căn chỉnh văn bản ở trên cùng
//             decoration: InputDecoration(
//               hintText: "Bạn đang nghĩ gì?",
//               hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(4),
//                 borderSide: BorderSide(color: Colors.grey),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildcategorychooseBackgroundcolorfield() {
//     return GestureDetector(
//       onTap: () {
//         _buildCategoryBottomSheet(context);
//       },
//       child: Container(
//         margin: const EdgeInsets.all(16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: const [
//             Text("Chọn màu nền", style: TextStyle(fontSize: 16)),
//             Icon(Icons.arrow_forward_ios, size: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   void _buildCategoryBottomSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.4,
//           minChildSize: 0.2,
//           maxChildSize: 0.9,
//           builder: (context, scrollController) {
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[900],
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(20),
//                 ),
//               ),
//               child: ListView(
//                 controller: scrollController,
//                 children: [
//                   Center(
//                     child: Container(
//                       margin: const EdgeInsets.symmetric(vertical: 10),
//                       width: 40,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: Colors.grey,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),

//                   const ListTile(
//                     leading: Icon(Icons.image, color: Colors.green),
//                     title: Text("Ảnh/video"),
//                   ),
//                   const ListTile(
//                     leading: Icon(Icons.person_add),
//                     title: Text("Gắn thẻ người khác"),
//                   ),
//                   const ListTile(
//                     leading: Icon(Icons.emoji_emotions),
//                     title: Text("Cảm xúc/hoạt động"),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   void _gotonextpage(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const next()),
//     );
//   }
// }

// làm chuyển đổi ngôn ngữ
// void _showAttachOptions() {
//     showDialog<void>(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           insetPadding: const EdgeInsets.all(24),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.photo, size: 28),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Chức năng tải ảnh chưa được bật'),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 4),
//                     const Text('Tải ảnh lên', style: TextStyle(fontSize: 12)),
//                   ],
//                 ),
//                 const SizedBox(width: 20),
//                 Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.gif, size: 28),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text('Chèn GIF chưa được bật'),
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 4),
//                     const Text('Chèn GIF', style: TextStyle(fontSize: 12)),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// đây là file chứa code của trang search trong phần home
// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';

// class search extends StatefulWidget {
//   const search({super.key});

//   @override
//   State<search> createState() => _searchState();
// }

// class _searchState extends State<search> {
//   final TextEditingController _ctrl = TextEditingController();

//   // Mock data for demonstration. Replace with your real data sources.
//   final List<Map<String, String>> _users = [
//     {'id': 'u1', 'name': 'Nguyễn Hữu Hiển'},
//     {'id': 'u2', 'name': 'Nguyễn Văn Chiến'},
//     {'id': 'u3', 'name': 'Đào Mạnh Vương'},
//   ];

//   final List<Map<String, String>> _posts = [
//     {'id': 'p1', 'title': 'Hành trình Hà Nội', 'snippet': 'Ăn, chơi, ngủ...'},
//     {'id': 'p2', 'title': 'Khám phá Đà Lạt', 'snippet': 'Đồi thông, cà phê...'},
//   ];

//   final List<Map<String, String>> _places = [
//     {'id': 'pl1', 'name': 'Hồ Hoàn Kiếm'},
//     {'id': 'pl2', 'name': 'Bà Nà Hills'},
//   ];

//   List<Map<String, String>> _resUsers = [];
//   List<Map<String, String>> _resPosts = [];
//   List<Map<String, String>> _resPlaces = [];

//   int _tabIndex = 0; // 0: All, 1: Friends, 2: Posts, 3: Places

//   @override
//   void initState() {
//     super.initState();
//     _resUsers = List.from(_users);
//     _resPosts = List.from(_posts);
//     _resPlaces = List.from(_places);
//     _ctrl.addListener(_onSearch);
//   }

//   void _onSearch() {
//     final q = _ctrl.text.trim().toLowerCase();
//     setState(() {
//       if (q.isEmpty) {
//         _resUsers = List.from(_users);
//         _resPosts = List.from(_posts);
//         _resPlaces = List.from(_places);
//       } else {
//         _resUsers = _users
//             .where((u) => u['name']!.toLowerCase().contains(q))
//             .toList();
//         _resPosts = _posts
//             .where(
//               (p) => (p['title']! + p['snippet']!).toLowerCase().contains(q),
//             )
//             .toList();
//         _resPlaces = _places
//             .where((p) => p['name']!.toLowerCase().contains(q))
//             .toList();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _ctrl.removeListener(_onSearch);
//     _ctrl.dispose();
//     super.dispose();
//   }

//   void _deleteUser(String id) {
//     setState(() {
//       _users.removeWhere((u) => u['id'] == id);
//       _resUsers.removeWhere((u) => u['id'] == id);
//     });
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Đã xóa bạn bè')));
//   }

//   void _deletePost(String id) {
//     setState(() {
//       _posts.removeWhere((p) => p['id'] == id);
//       _resPosts.removeWhere((p) => p['id'] == id);
//     });
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Đã xóa bài viết')));
//   }

//   void _deletePlace(String id) {
//     setState(() {
//       _places.removeWhere((p) => p['id'] == id);
//       _resPlaces.removeWhere((p) => p['id'] == id);
//     });
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Đã xóa địa điểm')));
//   }

//   Future<void> _confirmDeleteUser(String id) async {
//     final ok = await showDialog<bool?>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Xác nhận'),
//         content: const Text('Bạn có chắc muốn xóa bạn bè này?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c, false),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(c, true),
//             child: const Text('Xóa'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true) _deleteUser(id);
//   }

//   Future<void> _confirmDeletePost(String id) async {
//     final ok = await showDialog<bool?>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Xác nhận'),
//         content: const Text('Bạn có chắc muốn xóa bài viết này?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c, false),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(c, true),
//             child: const Text('Xóa'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true) _deletePost(id);
//   }

//   Future<void> _confirmDeletePlace(String id) async {
//     final ok = await showDialog<bool?>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Xác nhận'),
//         content: const Text('Bạn có chắc muốn xóa địa điểm này?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c, false),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(c, true),
//             child: const Text('Xóa'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true) _deletePlace(id);
//   }

//   Future<void> _editUser(Map<String, String> user) async {
//     final ctrl = TextEditingController(text: user['name']);
//     final ok = await showDialog<bool?>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Chỉnh sửa bạn bè'),
//         content: TextField(
//           controller: ctrl,
//           decoration: const InputDecoration(labelText: 'Tên'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c, false),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(c, true),
//             child: const Text('Lưu'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true) {
//       setState(() {
//         final idx = _users.indexWhere((u) => u['id'] == user['id']);
//         if (idx != -1) _users[idx]['name'] = ctrl.text.trim();
//         final rIdx = _resUsers.indexWhere((u) => u['id'] == user['id']);
//         if (rIdx != -1) _resUsers[rIdx]['name'] = ctrl.text.trim();
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Đã cập nhật tên')));
//     }
//   }

//   Future<void> _editPost(Map<String, String> post) async {
//     final titleCtrl = TextEditingController(text: post['title']);
//     final snippetCtrl = TextEditingController(text: post['snippet']);
//     final ok = await showDialog<bool?>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Chỉnh sửa bài viết'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleCtrl,
//               decoration: const InputDecoration(labelText: 'Tiêu đề'),
//             ),
//             TextField(
//               controller: snippetCtrl,
//               decoration: const InputDecoration(labelText: 'Trích dẫn'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c, false),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(c, true),
//             child: const Text('Lưu'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true) {
//       setState(() {
//         final idx = _posts.indexWhere((p) => p['id'] == post['id']);
//         if (idx != -1) {
//           _posts[idx]['title'] = titleCtrl.text.trim();
//           _posts[idx]['snippet'] = snippetCtrl.text.trim();
//         }
//         final rIdx = _resPosts.indexWhere((p) => p['id'] == post['id']);
//         if (rIdx != -1) {
//           _resPosts[rIdx]['title'] = titleCtrl.text.trim();
//           _resPosts[rIdx]['snippet'] = snippetCtrl.text.trim();
//         }
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Đã cập nhật bài viết')));
//     }
//   }

//   Future<void> _editPlace(Map<String, String> place) async {
//     final ctrl = TextEditingController(text: place['name']);
//     final ok = await showDialog<bool?>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Chỉnh sửa địa điểm'),
//         content: TextField(
//           controller: ctrl,
//           decoration: const InputDecoration(labelText: 'Tên địa điểm'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c, false),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(c, true),
//             child: const Text('Lưu'),
//           ),
//         ],
//       ),
//     );
//     if (ok == true) {
//       setState(() {
//         final idx = _places.indexWhere((p) => p['id'] == place['id']);
//         if (idx != -1) _places[idx]['name'] = ctrl.text.trim();
//         final rIdx = _resPlaces.indexWhere((p) => p['id'] == place['id']);
//         if (rIdx != -1) _resPlaces[rIdx]['name'] = ctrl.text.trim();
//       });
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Đã cập nhật địa điểm')));
//     }
//   }

//   Widget _buildSectionHeader(String title) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8.0),
//     child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 4,
//       initialIndex: _tabIndex,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(
//             'search'.tr(),
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           bottom: TabBar(
//             onTap: (i) => setState(() => _tabIndex = i),
//             tabs: const [
//               Tab(text: 'Tất cả'),
//               Tab(text: 'Bạn bè'),
//               Tab(text: 'Bài viết'),
//               Tab(text: 'Địa điểm'),
//             ],
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             children: [
//               TextField(
//                 controller: _ctrl,
//                 decoration: InputDecoration(
//                   hintText: 'Tìm kiếm tên, bài viết, địa điểm, bạn bè...',
//                   prefixIcon: const Icon(Icons.search),
//                   suffixIcon: _ctrl.text.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.clear),
//                           onPressed: () => _ctrl.clear(),
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Expanded(
//                 child: TabBarView(
//                   physics: const NeverScrollableScrollPhysics(),
//                   children: [
//                     // All: grouped sections
//                     _buildAllView(),
//                     // Friends
//                     _buildUserList(),
//                     // Posts
//                     _buildPostList(),
//                     // Places
//                     _buildPlaceList(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAllView() {
//     final children = <Widget>[];
//     if (_resUsers.isNotEmpty) {
//       children.add(_buildSectionHeader('Bạn bè'));
//       children.addAll(
//         _resUsers.map(
//           (u) => ListTile(
//             leading: const Icon(Icons.person),
//             title: Text(u['name']!),
//             onTap: () {},
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => _editUser(u),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => _confirmDeleteUser(u['id']!),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//     if (_resPosts.isNotEmpty) {
//       children.add(_buildSectionHeader('Bài viết'));
//       children.addAll(
//         _resPosts.map(
//           (p) => ListTile(
//             leading: const Icon(Icons.article),
//             title: Text(p['title']!),
//             subtitle: Text(p['snippet']!),
//             onTap: () {},
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => _editPost(p),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => _confirmDeletePost(p['id']!),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//     if (_resPlaces.isNotEmpty) {
//       children.add(_buildSectionHeader('Địa điểm'));
//       children.addAll(
//         _resPlaces.map(
//           (pl) => ListTile(
//             leading: const Icon(Icons.place),
//             title: Text(pl['name']!),
//             onTap: () {},
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () => _editPlace(pl), // Chỉnh sửa địa điểm
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () =>
//                       _confirmDeletePlace(pl['id']!), // Xóa địa điểm
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//     if (children.isEmpty) return const Center(child: Text('Không có kết quả'));
//     return ListView.separated(
//       itemCount: children.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (c, i) => children[i],
//     );
//   }

//   Widget _buildUserList() {
//     if (_resUsers.isEmpty)
//       return const Center(child: Text('Không tìm thấy bạn bè'));
//     return ListView.separated(
//       itemCount: _resUsers.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (c, i) {
//         final u = _resUsers[i];
//         return ListTile(
//           leading: const CircleAvatar(child: Icon(Icons.person)),
//           title: Text(u['name']!),
//           onTap: () {},
//         );
//       },
//     );
//   }

//   Widget _buildPostList() {
//     if (_resPosts.isEmpty)
//       return const Center(child: Text('Không tìm thấy bài viết'));
//     return ListView.separated(
//       itemCount: _resPosts.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (c, i) {
//         final p = _resPosts[i];
//         return ListTile(
//           leading: const Icon(Icons.article),
//           title: Text(p['title']!),
//           subtitle: Text(p['snippet']!),
//           onTap: () {},
//         );
//       },
//     );
//   }

//   Widget _buildPlaceList() {
//     if (_resPlaces.isEmpty)
//       return const Center(child: Text('Không tìm thấy địa điểm'));
//     return ListView.separated(
//       itemCount: _resPlaces.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (c, i) {
//         final pl = _resPlaces[i];
//         return ListTile(
//           leading: const Icon(Icons.place),
//           title: Text(pl['name']!),
//           onTap: () {},
//         );
//       },
//     );
//   }
// }
