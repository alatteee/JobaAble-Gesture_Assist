import 'package:flutter/material.dart';
import 'package:logbook_app_069/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;

 
  final List<Color> bgColors = [
    const Color(0xFFF0F9FF), 
    const Color(0xFFE0F2FE), 
    const Color(0xFFDEEBFE), 
  ];

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Jadikan Setiap Catatan Berarti",
      "description":
          "Catat, pantau, dan kelola logbook aktivitas harianmu dengan cara yang lebih cerdas dan menyenangkan.",
      "image": "assets/images/onboarding1.png",
      "badge": "Produktivitas",
    },
    {
      "title": "Data Anda, Privasi Anda",
      "description":
          "Semua riwayat dan hitungan tersimpan aman di perangkat Anda. Tidak ada yang bisa mengakses data Anda selain Anda.",
      "image": "assets/images/onboarding2.png",
      "badge": "Keamanan",
    },
    {
      "title": "Raih Target Lebih Cepat",
      "description":
          "Gunakan fitur langkah kustom untuk menyesuaikan progresmu. Setiap pencapaian tersimpan dan bisa dilihat kapan saja!",
      "image": "assets/images/onboarding3.png",
      "badge": "Pencapaian",
    },
  ];

  void nextStep() {
    if (step >= 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    } else {
      setState(() {
        step++;
      });
    }
  }

  void prevStep() {
    if (step > 1) {
      setState(() {
        step--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentData = onboardingData[step - 1];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ═══ BACKGROUND GRADIENT BIRU ═══
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                ],
              ),
            ),
          ),

          // ═══ DECORATIVE FLOATING ICONS ═══
          // Top left small icons
          Positioned(
            top: screenHeight * 0.12,
            left: 30,
            child: _buildFloatingIcon(Icons.edit_rounded, 24, 0.6),
          ),
          Positioned(
            top: screenHeight * 0.18,
            left: 65,
            child: _buildFloatingIcon(Icons.lightbulb_outline_rounded, 20, 0.5),
          ),
          // Top right icons
          Positioned(
            top: screenHeight * 0.1,
            right: 35,
            child: _buildFloatingIcon(Icons.book_outlined, 28, 0.7),
          ),
          Positioned(
            top: screenHeight * 0.18,
            right: 25,
            child: _buildFloatingIcon(Icons.star_border_rounded, 18, 0.4),
          ),
          // Middle left
          Positioned(
            top: screenHeight * 0.35,
            left: 25,
            child: _buildFloatingIcon(Icons.check_circle_outline, 22, 0.5),
          ),
          // Middle right
          Positioned(
            top: screenHeight * 0.38,
            right: 30,
            child: _buildFloatingIcon(Icons.favorite_border_rounded, 20, 0.5),
          ),
          // Bottom decoratives
          Positioned(
            bottom: screenHeight * 0.5,
            left: 45,
            child: _buildFloatingIcon(Icons.emoji_emotions_outlined, 20, 0.4),
          ),

          // ═══ MAIN CONTENT ═══
          SafeArea(
            child: Column(
              children: [
                // Skip button di kanan atas
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (step < 3)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginView()),
                              );
                            },
                            child: const Text(
                              "Lewati",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Badge label (white on blue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    currentData["badge"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ═══ IMAGE SECTION WITH GLOW ═══
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect behind image
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Actual image
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Image.asset(
                          currentData["image"]!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ═══ KONTEN BAWAH - WHITE ROUNDED CARD ═══
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(44),
                      topRight: Radius.circular(44),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF1E3A8A),
                        blurRadius: 40,
                        offset: Offset(0, -10),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ═══ PAGE INDICATORS ═══
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (index) {
                            final isActive = step == index + 1;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              width: isActive ? 36 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                      )
                                    : null,
                                color: isActive ? null : const Color(0xFFE5E7EB),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Color(0xFF3B82F6).withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ═══ TITLE ═══
                      Text(
                        currentData["title"]!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1F2937),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ═══ DESCRIPTION ═══
                      Text(
                        currentData["description"]!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                          height: 1.7,
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ═══ NAVIGATION BUTTONS ═══
                      Row(
                        children: [
                          // Back button (only show if not first page)
                          if (step > 1)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: IconButton(
                                onPressed: prevStep,
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: Color(0xFF374151),
                                ),
                                padding: const EdgeInsets.all(16),
                              ),
                            ),

                          // Next/Start button
                          Expanded(
                            child: SizedBox(
                              height: 60,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: nextStep,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        step == 3 ? "Mulai Sekarang!" : "Selanjutnya",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══ DECORATIVE ELEMENTS ═══
  Widget _buildFloatingIcon(IconData icon, double size, double opacity) {
    return Container(
      padding: EdgeInsets.all(size * 0.3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity * 0.4),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(opacity * 0.2),
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: const Color(0xFF2563EB),
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}
