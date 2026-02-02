// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:tourn/Ui/main/main_page.dart';
// import 'package:tourn/Ui/sign.up/sign_up_page.dart';

// class a extends StatelessWidget {
//   const a({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF121212),
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           }, // Xử lý khi nhấn nút quay lại
//           icon: const Icon(
//             Icons.arrow_back_ios_new_outlined,
//             size: 20,
//             color: Colors.white,
//           ),
//         ),
//       ),

//       body: SingleChildScrollView(
//         // Cho phép cuộn nếu nội dung vượt quá
//         child: Column(
//           children: [
//             _buildpagetitle(),
//             _buildformlogin(),
//             _buildloginbutton(context),
//             _buildorsplitoivider(),
//             _buildsociallogin(),
//             _buildhavenotaccount(context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildpagetitle() {
//     return Container(
//       alignment: Alignment.center,
//       margin: EdgeInsets.only(top: 90),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Text(
//             "login_title".tr(),
//             style: TextStyle(
//               fontSize: 40,
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               overflow: TextOverflow.visible,
//             ),
//             maxLines: 2,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildformlogin() {
//     return Form(
//       child: Container(
//         margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
//         alignment: Alignment.centerLeft,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildusernamefield(),
//             const SizedBox(height: 20),
//             _buildpasswordfield(),
//           ],
//         ),
//       ),
//     );
//   }

//   Column _buildusernamefield() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "login_username".tr(),
//           style: TextStyle(fontSize: 20, color: Colors.white),
//         ),
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           child: TextFormField(
//             decoration: InputDecoration(
//               hintText: "login_username_desc".tr(), // Văn bản gợi ý
//               hintStyle: TextStyle(color: Colors.white54),
//               border: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.white),
//               ),
//             ),
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }

//   Column _buildpasswordfield() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "login_password".tr(),
//           style: TextStyle(fontSize: 20, color: Colors.white),
//         ),
//         Container(
//           margin: const EdgeInsets.only(top: 10),
//           child: TextFormField(
//             decoration: InputDecoration(
//               hintText: '*********', // Văn bản gợi ý
//               hintStyle: TextStyle(color: Colors.white54),
//               border: OutlineInputBorder(
//                 borderSide: BorderSide(color: Colors.white),
//               ),
//             ),
//             style: TextStyle(color: Colors.white),
//             obscureText: true, // Ẩn văn bản nhập vào
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildloginbutton(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(top: 30, left: 24, right: 24),
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () {
//           _gotomainppage(context);
//         }, // Xử lý khi nhấn nút Login , muốn disable thì để null
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Color.fromARGB(255, 27, 40, 129),
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           disabledBackgroundColor: Color.fromARGB(255, 48, 54, 94),
//         ),
//         child: Text(
//           "login_buttom".tr(),
//           style: TextStyle(fontSize: 20, color: Colors.white),
//         ),
//       ),
//     );
//   }

//   Widget _buildorsplitoivider() {
//     return Container(
//       margin: const EdgeInsets.only(top: 30),
//       child: Row(
//         children: [
//           Expanded(
//             // Mở rộng để chiếm không gian còn lại
//             child: Divider(
//               // Đường chia mở rộng
//               color: Colors.white54,
//               thickness: 1, // Độ dày của đường chia
//               indent: 20, // Khoảng cách từ đầu đến đường chia
//               endIndent: 10, // Khoảng cách từ đường chia đến cuối
//             ),
//           ),
//           Text("login_desc".tr(), style: TextStyle(color: Colors.white54)),
//           Expanded(
//             child: Divider(
//               // Đường chia mở rộng
//               color: Colors.white54,
//               thickness: 1, // Độ dày của đường chia
//               indent: 10, // Khoảng cách từ đầu đến đường chia
//               endIndent: 20, // Khoảng cách từ đường chia đến cuối
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildsociallogin() {
//     return Container(
//       margin: const EdgeInsets.only(top: 30),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Nút đăng nhập với Google
//           _buildbuttomgoogle(),
//           SizedBox(width: 40), // Khoảng cách giữa hai nút
//           // Nút đăng nhập với Facebook
//           _buildbuttomfacebook(),
//         ],
//       ),
//     );
//   }

//   Widget _buildbuttomfacebook() {
//     return Container(
//       width: double.infinity,
//       height: 48,
//       margin: const EdgeInsets.symmetric(vertical: 15),
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: ElevatedButton(
//         onPressed: () {
//           // Xử lý đăng nhập với Facebook
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF4267B2),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Image.asset(
//               'asset/icon/Facebook_Logo_(2019).png',
//               width: 24,
//               height: 24,
//             ),
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 10),
//               child: Text(
//                 "login_continue_facebook".tr(),
//                 style: TextStyle(fontSize: 16, color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildbuttomgoogle() {
//     return Container(
//       width: double.infinity,
//       height: 48,
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: ElevatedButton(
//         onPressed: () {
//           // Xử lý đăng nhập với Google
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color(0xFF4267B2),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Image.asset('asset/icon/google.png', width: 24, height: 24),
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 10),
//               child: Text(
//                 "login_continue_google".tr(),
//                 style: TextStyle(fontSize: 16, color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildhavenotaccount(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(top: 20, bottom: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             "login_desc1".tr(),
//             style: TextStyle(fontSize: 16, color: Colors.white54),
//           ),
//           GestureDetector(
//             // Thêm khả năng nhấn vào văn bản
//             onTap: () {
//               _gotosignuppage(context);
//               // Xử lý khi nhấn vào "Sign Up"
//             },
//             child: Text(
//               "signin_buttom".tr(),
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.blueAccent,
//                 decoration: TextDecoration.underline,
//                 decorationColor: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _gotosignuppage(BuildContext context) {
//     // Hàm chuyển đến trang chính của ứng dụng welcome_page.dart
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const signuppage()),
//     );
//   }

//   void _gotomainppage(BuildContext context) {
//     // Hàm chuyển đến trang chính của ứng dụng mainpage.dart
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const Mainpage()),
//     );
//   }
// }
