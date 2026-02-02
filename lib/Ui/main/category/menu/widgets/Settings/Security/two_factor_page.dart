import 'package:flutter/material.dart';
import 'two_factor_service.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({super.key});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  bool _enabled = false;
  bool _loading = true;

  String? _method; // 'sms' or 'authenticator'
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _verifyCodeController = TextEditingController();
  String? _secret;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _verifyCodeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _enabled = await TwoFactorService.isEnabled();
    _method = await TwoFactorService.getMethod();
    _phoneController.text = (await TwoFactorService.getPhone()) ?? '';
    _secret = await TwoFactorService.getSecret();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setEnabled(bool v) async {
    await TwoFactorService.setEnabled(v);
    setState(() => _enabled = v);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(v ? 'Đã bật 2 yếu tố' : 'Đã tắt 2 yếu tố')),
      );
  }

  Future<void> _startSmsFlow() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại')),
      );
      return;
    }
    final code = TwoFactorService.generateSmsCode();
    await TwoFactorService.setSmsCode(code);
    // In real app send SMS. Here we show a dialog (simulation).
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mã xác thực (demo)'),
        content: Text('Mã OTP đã gửi: $code'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
    setState(() => _method = 'sms');
  }

  Future<void> _verifySmsCode() async {
    final stored = await TwoFactorService.getSmsCode();
    final entered = _verifyCodeController.text.trim();
    if (entered.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nhập mã xác thực')));
      return;
    }
    if (entered != stored) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mã không đúng')));
      return;
    }
    // success
    await TwoFactorService.setMethod('sms');
    await TwoFactorService.setPhone(_phoneController.text.trim());
    await TwoFactorService.setSmsCode('');
    await _setEnabled(true);
  }

  Future<void> _startAuthenticatorFlow() async {
    var s = await TwoFactorService.getSecret();
    if (s == null) {
      s = TwoFactorService.generateSecret();
      await TwoFactorService.setSecret(s);
    }
    setState(() => _secret = s);
    setState(() => _method = 'authenticator');
    if (!mounted) return;
    // Show secret to user and instructions
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thiết lập ứng dụng Authenticator'),
        content: SelectableText(
          'Mã bí mật: $s\n\nSao chép mã, thêm tài khoản vào app Authenticator (Google Authenticator/OTP) bằng cách nhập mã này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAuthenticator() async {
    // For demo we do not validate TOTP; we just mark configured
    await TwoFactorService.setMethod('authenticator');
    await _setEnabled(true);
  }

  Future<void> _disable() async {
    await TwoFactorService.setEnabled(false);
    await TwoFactorService.setMethod(null);
    await TwoFactorService.setPhone(null);
    await TwoFactorService.setSecret(null);
    setState(() {
      _enabled = false;
      _method = null;
      _phoneController.text = '';
      _secret = null;
    });
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('2FA đã được tắt')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực 2 yếu tố')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_enabled) ...[
                    ListTile(
                      leading: const Icon(Icons.shield),
                      title: const Text('2FA đang bật'),
                      subtitle: Text(
                        'Phương thức: ${_method == 'sms' ? 'SMS' : 'Authenticator'}',
                      ),
                    ),
                    if (_method == 'sms')
                      ListTile(
                        title: Text('Số điện thoại: ${_phoneController.text}'),
                      ),
                    if (_method == 'authenticator')
                      ListTile(
                        title: Text('Ứng dụng Authenticator đã cấu hình'),
                        subtitle: _secret == null
                            ? null
                            : Text('Mã bí mật: $_secret'),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _disable,
                      child: const Text('Tắt 2FA'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Để thay đổi phương thức, hãy tắt 2FA và cấu hình lại.',
                    ),
                  ] else ...[
                    const Text(
                      'Bật xác thực 2 yếu tố (2FA) để tăng bảo mật tài khoản.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại (dùng cho SMS)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startSmsFlow,
                            child: const Text('Thiết lập bằng SMS'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _startAuthenticatorFlow,
                            child: const Text('Thiết lập bằng Authenticator'),
                          ),
                        ),
                      ],
                    ),

                    if (_method == 'sms') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _verifyCodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nhập mã OTP',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _verifySmsCode,
                        child: const Text('Xác nhận mã'),
                      ),
                    ],

                    if (_method == 'authenticator') ...[
                      const SizedBox(height: 12),
                      if (_secret != null) ...[
                        SelectableText('Mã bí mật: $_secret'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _confirmAuthenticator,
                          child: const Text('Đã thêm vào ứng dụng, xác nhận'),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
