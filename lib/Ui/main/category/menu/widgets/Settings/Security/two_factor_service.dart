import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class TwoFactorService {
  static const _enabledKey = 'two_factor_enabled';
  static const _methodKey = 'two_factor_method'; // 'sms' or 'authenticator'
  static const _phoneKey = 'two_factor_phone';
  static const _secretKey = 'two_factor_secret';
  static const _smsCodeKey = 'two_factor_sms_code';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, v);
  }

  static Future<String?> getMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_methodKey);
  }

  static Future<void> setMethod(String? method) async {
    final prefs = await SharedPreferences.getInstance();
    if (method == null) {
      await prefs.remove(_methodKey);
    } else {
      await prefs.setString(_methodKey, method);
    }
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  static Future<void> setPhone(String? phone) async {
    final prefs = await SharedPreferences.getInstance();
    if (phone == null) {
      await prefs.remove(_phoneKey);
    } else {
      await prefs.setString(_phoneKey, phone);
    }
  }

  static Future<String?> getSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secretKey);
  }

  static Future<void> setSecret(String? secret) async {
    final prefs = await SharedPreferences.getInstance();
    if (secret == null) {
      await prefs.remove(_secretKey);
    } else {
      await prefs.setString(_secretKey, secret);
    }
  }

  static Future<void> setSmsCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_smsCodeKey, code);
    // set a short-lived code (for demo; in production you should expire it)
  }

  static Future<String?> getSmsCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_smsCodeKey);
  }

  // Helper: generate random 6-digit code
  static String generateSmsCode() {
    final rnd = Random.secure();
    final code = rnd.nextInt(900000) + 100000; // 100000 - 999999
    return code.toString();
  }

  // Helper: generate a simple secret (base32-like) for authenticator apps
  static String generateSecret([int length = 16]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }
}
