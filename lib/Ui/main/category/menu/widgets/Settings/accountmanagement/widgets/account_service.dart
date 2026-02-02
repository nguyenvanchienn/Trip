import 'package:shared_preferences/shared_preferences.dart';

// file này quản lý thông tin tài khoản người dùng cục bộ
class AccountService {
  static const _nameKey = 'account_name';
  static const _usernameKey = 'account_username';
  static const _emailKey = 'account_email';
  static const _phoneKey = 'account_phone';
  static const _idDocKey = 'account_id_doc_path';

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<void> setName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || name.isEmpty) {
      await prefs.remove(_nameKey);
    } else {
      await prefs.setString(_nameKey, name);
    }
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> setUsername(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username == null || username.isEmpty) {
      await prefs.remove(_usernameKey);
    } else {
      await prefs.setString(_usernameKey, username);
    }
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<void> setEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.isEmpty) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, email);
    }
  }

  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  static Future<void> setPhone(String? phone) async {
    final prefs = await SharedPreferences.getInstance();
    if (phone == null || phone.isEmpty) {
      await prefs.remove(_phoneKey);
    } else {
      await prefs.setString(_phoneKey, phone);
    }
  }

  static Future<String?> getIdDocumentPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idDocKey);
  }

  static Future<void> setIdDocumentPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_idDocKey);
    } else {
      await prefs.setString(_idDocKey, path);
    }
  }
}
