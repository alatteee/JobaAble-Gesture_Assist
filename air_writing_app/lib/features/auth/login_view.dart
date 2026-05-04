// login_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logbook_app_069/features/auth/login_controller.dart';
import 'package:logbook_app_069/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // State untuk fitur baru
  bool _isPasswordVisible = false;
  int _loginAttempts = 0;
  bool _isLoginDisabled = false;
  Timer? _timer;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleLogin() {
    if (_isLoginDisabled) return;

    String user = _userController.text;
    String pass = _passController.text;

    // Validasi field tidak boleh kosong
    if (user.isEmpty || pass.isEmpty) {
      _showError("Username dan Password tidak boleh kosong!");
      return;
    }

    // login() sekarang async, jadi gunakan Future untuk handle result
    _controller.login(user, pass).then((isSuccess) {
      if (isSuccess) {
        // Reset percobaan jika berhasil
        setState(() {
          _loginAttempts = 0;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Di sini kita kirimkan variabel 'user' ke parameter 'username' di CounterView
            builder: (context) => CounterView(username: user),
          ),
        );
      } else {
        setState(() {
          _loginAttempts++;
        });
        _showError("Login Gagal! Percobaan ke-$_loginAttempts.");

        // Logika untuk menonaktifkan tombol
        if (_loginAttempts >= 3) {
          setState(() {
            _isLoginDisabled = true;
          });
          _timer = Timer(const Duration(seconds: 10), () {
            setState(() {
              _isLoginDisabled = false;
              _loginAttempts = 0; // Reset setelah 10 detik
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    const accent = Color(0xFF3B82F6);
    const accentDark = Color(0xFF1D4ED8);
    const muted = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ══════════════════════════════════════════
                //  TOP BLUE SECTION WITH WAVE
                // ══════════════════════════════════════════
                SizedBox(
                  height: screenH * 0.42,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient background
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2563EB),
                                Color(0xFF3B82F6),
                                Color(0xFF60A5FA),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Decorative floating circles
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        right: 50,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 80,
                        left: -20,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),

                      // Small dots pattern
                      Positioned(
                        top: screenH * 0.08,
                        right: 30,
                        child: _buildDotPattern(),
                      ),

                      // Wave at bottom
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: CustomPaint(
                          size: Size(screenW, 50),
                          painter: _WavePainter(),
                        ),
                      ),

                      // Content on blue area
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // Logo row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Logbook App",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        "Digital Logbook System",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Spacer(),

                              // Big welcome text
                              Text(
                                "Selamat\nDatang!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                  letterSpacing: -1,
                                  shadows: [
                                    Shadow(
                                      color: accentDark.withOpacity(0.3),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Silakan masuk untuk mengelola logbook Anda",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ══════════════════════════════════════════
                //  FORM SECTION
                // ══════════════════════════════════════════
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title with accent bar
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Masuk ke Akun",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Username
                      _buildLabel("Username"),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _userController,
                        hint: "Masukkan username anda",
                        icon: Icons.person_outline_rounded,
                      ),

                      const SizedBox(height: 20),

                      // Password
                      _buildLabel("Password"),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passController,
                        hint: "Masukkan password anda",
                        icon: Icons.lock_outline_rounded,
                        obscure: !_isPasswordVisible,
                        suffix: GestureDetector(
                          onTap: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: muted,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Error
                      if (_loginAttempts > 0 && !_isLoginDisabled) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFEE2E2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 18, color: Color(0xFFEF4444)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Login gagal! Percobaan $_loginAttempts dari 3",
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ══════ LOGIN BUTTON ══════
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoginDisabled ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: muted,
                            elevation: _isLoginDisabled ? 0 : 8,
                            shadowColor: accent.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLoginDisabled
                                    ? "Terkunci (10 detik)"
                                    : "Masuk Sekarang",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (!_isLoginDisabled) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ══════ FOOTER INFO ══════
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  size: 14, color: accent.withOpacity(0.7)),
                              const SizedBox(width: 6),
                              Text(
                                "Koneksi aman & terenkripsi",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: muted.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════ HELPER: FIELD LABEL ══════
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
        letterSpacing: 0.3,
      ),
    );
  }

  // ══════ HELPER: DOT PATTERN ══════
  Widget _buildDotPattern() {
    return SizedBox(
      width: 48,
      height: 48,
      child: GridView.count(
        crossAxisCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          16,
          (_) => Center(
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════ HELPER: INPUT FIELD ══════
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    const accent = Color(0xFF3B82F6);
    const muted = Color(0xFF94A3B8);

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: accent,
      cursorWidth: 1.8,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: muted.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: muted, size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  WAVE PAINTER - curved divider
// ══════════════════════════════════════════
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
          size.width * 0.25, 0, size.width * 0.5, size.height * 0.35)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.7, size.width, size.height * 0.25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
