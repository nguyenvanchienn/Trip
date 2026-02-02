import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class HelpContactPage extends StatefulWidget {
  const HelpContactPage({super.key});

  @override
  State<HelpContactPage> createState() => _HelpContactPageState();
}

class _HelpContactPageState extends State<HelpContactPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const supportEmail = 'support@trip.example.com';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_formKey.currentState?.validate() ?? false) {
      // Here you would call your backend or email API
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi yêu cầu hỗ trợ — chúng tôi sẽ phản hồi sớm.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('help_contact_support'.tr()), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'help_contact_support'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('Bạn có thể liên hệ qua email sau để được hỗ trợ:'),
                const SizedBox(height: 8),
                SelectableText(
                  supportEmail,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên của bạn'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v != null && v.contains('@')
                      ? null
                      : 'Vui lòng nhập email hợp lệ',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(labelText: 'Nội dung'),
                    validator: (v) => v != null && v.trim().isNotEmpty
                        ? null
                        : 'Vui lòng mô tả vấn đề',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: supportEmail),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã sao chép email')),
                        );
                      },
                      child: const Text('Sao chép email'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _sendMessage,
                      child: const Text('Gửi yêu cầu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
