// login_controller.dart
import 'package:logbook_app_069/services/preferences_service.dart';

class LoginController {
  // Database sederhana menggunakan Map untuk multiple users
  final Map<String, String> _users = {
    'admin': '123',
    'user1': 'pass1',
    'user2': 'pass2',
  };

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  // Juga menyimpan username ke SharedPreferences setelah login berhasil.
  Future<bool> login(String username, String password) async {
    // Cek apakah username ada di database dan passwordnya cocok
    if (_users.containsKey(username) && _users[username] == password) {
      // Simpan last login user ke SharedPreferences
      await PreferencesService.setLastLoginUser(username);
      return true;
    }
    return false;
  }
}
