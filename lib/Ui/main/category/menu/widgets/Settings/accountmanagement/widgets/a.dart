// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:tourn/Ui/main/category/menu/pages/settings/accountmanagement/account_service.dart';
// import 'package:tourn/Ui/main/category/menu/pages/settings/Security/security_service.dart';

// class AccountPage extends StatefulWidget {
//   const AccountPage({super.key});

//   @override
//   State<AccountPage> createState() => _AccountPageState();
// }

// class _AccountPageState extends State<AccountPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();

//   bool _loading = true;
//   String? _idDocumentPath;
//   bool _securityAcknowledged = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadAccount();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadAccount() async {
//     final name = await AccountService.getName();
//     final email = await AccountService.getEmail();
//     final phone = await AccountService.getPhone();
//     final idDoc = await AccountService.getIdDocumentPath();
//     final ack = await SecurityService.getAcknowledged();
//     _nameController.text = name ?? '';
//     _emailController.text = email ?? '';
//     _phoneController.text = phone ?? '';
//     _idDocumentPath = idDoc;
//     _securityAcknowledged = ack;
//     setState(() => _loading = false);
//   }

//   Future<void> _saveName() async {
//     final name = _nameController.text.trim();
//     if (name.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Tên không được để trống')));
//       return;
//     }
//     await AccountService.setName(name);
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Tên đã được lưu')));
//   }

//   Future<void> _saveEmail() async {
//     final email = _emailController.text.trim();
//     if (email.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Email không được để trống')),
//       );
//       return;
//     }
//     final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
//     if (!regex.hasMatch(email)) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
//       return;
//     }
//     await AccountService.setEmail(email);
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Email đã được lưu')));
//   }

//   Future<void> _savePhone() async {
//     final phone = _phoneController.text.trim();
//     if (phone.isEmpty) {
//       await AccountService.setPhone('');
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Số điện thoại đã bị xoá')));
//       return;
//     }
//     final regex = RegExp(r"^[+0-9\s()-]{6,20}$");
//     if (!regex.hasMatch(phone)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Số điện thoại không hợp lệ')),
//       );
//       return;
//     }
//     await AccountService.setPhone(phone);
//     if (!mounted) return;
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Số điện thoại đã được lưu')));
//   }

//   Future<void> _pickIdDocument() async {
//     final picker = ImagePicker();
//     try {
//       final XFile? file = await picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );
//       if (file == null) return;
//       await AccountService.setIdDocumentPath(file.path);
//       setState(() => _idDocumentPath = file.path);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Đã tải giấy tờ lên')));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi khi tải giấy tờ: ${e.toString()}')),
//       );
//     }
//   }

//   Future<void> _removeIdDocument() async {
//     await AccountService.setIdDocumentPath(null);
//     setState(() => _idDocumentPath = null);
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Đã xoá giấy tờ')));
//   }

//   Future<void> _acknowledgeSecurity() async {
//     await SecurityService.setAcknowledged(true);
//     setState(() => _securityAcknowledged = true);
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Cảm ơn, bạn đã xác nhận cảnh báo bảo mật')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Quản lý tài khoản')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   if (!_securityAcknowledged)
//                     Card(
//                       color: Colors.orange.shade50,
//                       child: Padding(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Row(
//                           children: [
//                             const Icon(
//                               Icons.warning_amber_rounded,
//                               color: Colors.orange,
//                             ),
//                             const SizedBox(width: 8),
//                             const Expanded(
//                               child: Text(
//                                 'Cảnh báo bảo mật: Không chia sẻ mật khẩu hoặc mã OTP với người khác. Thông tin giấy tờ chỉ dùng để xác minh.',
//                                 style: TextStyle(fontSize: 13),
//                               ),
//                             ),
//                             TextButton(
//                               onPressed: _acknowledgeSecurity,
//                               child: const Text('Tôi đã hiểu'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 12),
//                   // Chỉ lưu từng field riêng lẻ với nút lưu tương ứng
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: TextFormField(
//                                 controller: _nameController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Tên hiển thị',
//                                 ),
//                               ),
//                             ),
//                             IconButton(
//                               tooltip: 'Lưu tên',
//                               icon: const Icon(Icons.save),
//                               onPressed: _saveName,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: TextFormField(
//                                 controller: _emailController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Email',
//                                 ),
//                                 keyboardType: TextInputType.emailAddress,
//                               ),
//                             ),
//                             IconButton(
//                               tooltip: 'Lưu email',
//                               icon: const Icon(Icons.save),
//                               onPressed: _saveEmail,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: TextFormField(
//                                 controller: _phoneController,
//                                 decoration: const InputDecoration(
//                                   labelText: 'Số điện thoại',
//                                 ),
//                                 keyboardType: TextInputType.phone,
//                               ),
//                             ),
//                             IconButton(
//                               tooltip: 'Lưu số điện thoại',
//                               icon: const Icon(Icons.save),
//                               onPressed: _savePhone,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         Align(
//                           alignment: Alignment.centerLeft,
//                           child: Text(
//                             'Giấy tờ tuỳ thân',
//                             style: Theme.of(context).textTheme.titleMedium,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         if (_idDocumentPath != null)
//                           Column(
//                             children: [
//                               SizedBox(
//                                 height: 160,
//                                 child: Image.file(
//                                   File(_idDocumentPath!),
//                                   fit: BoxFit.contain,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   ElevatedButton.icon(
//                                     icon: const Icon(
//                                       Icons.change_circle_outlined,
//                                     ),
//                                     label: const Text('Thay giấy tờ'),
//                                     onPressed: _pickIdDocument,
//                                   ),
//                                   const SizedBox(width: 12),
//                                   TextButton(
//                                     onPressed: _removeIdDocument,
//                                     child: const Text('Xoá'),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           )
//                         else
//                           ElevatedButton.icon(
//                             icon: const Icon(Icons.upload_file),
//                             label: const Text('Tải lên giấy tờ tuỳ thân'),
//                             onPressed: _pickIdDocument,
//                           ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
