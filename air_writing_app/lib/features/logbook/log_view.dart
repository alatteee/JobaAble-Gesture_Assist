import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_069/features/logbook/log_controller.dart';
import 'package:logbook_app_069/features/logbook/log_editor_page.dart';
import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_069/helpers/log_helper.dart';
import 'package:logbook_app_069/services/access_control_service.dart';
import 'package:lottie/lottie.dart';

const kPrimary = Color(0xFF3B82F6);
const kPrimaryDark = Color(0xFF2563EB);
const kPrimaryLight = Color(0xFFEFF6FF);
const kTextDark = Color(0xFF1F2937);
const kTextGrey = Color(0xFF6B7280);
// Border radius constants
const _kInputRadius = 12.0;
const _kCardRadius = 16.0;
const _kDialogRadius = 20.0;
const _kButtonRadius = 10.0;

// Category items untuk dropdown
const _categoryItems = [
  {'name': 'Pekerjaan', 'icon': Icons.work_rounded, 'color': Colors.blue},
  {'name': 'Pribadi', 'icon': Icons.person_rounded, 'color': Colors.green},
  {'name': 'Urgent', 'icon': Icons.priority_high_rounded, 'color': Colors.red},
  {'name': 'Mechanical', 'icon': Icons.build_rounded, 'color': Colors.teal},
  {'name': 'Electronic', 'icon': Icons.electrical_services_rounded, 'color': Colors.indigo},
  {'name': 'Software', 'icon': Icons.code_rounded, 'color': Colors.purple},
];

// Helper: Category lookup from _categoryItems
Map<String, dynamic> _catLookup(String name) =>
    _categoryItems.firstWhere((c) => c['name'] == name, orElse: () => _categoryItems[1]);

class CounterView extends StatefulWidget {
  final String username;
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late LogController _controller;
  late Future<List<LogModel>> _logsFuture;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  static const Duration _kMinLoadingDebug = Duration(seconds: 2);

  String _formatIndonesianTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.isNegative) {
      return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
    }

    if (diff.inSeconds < 45) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';

    return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
  }

  String _friendlyCloudError(Object? error) {
    final raw = (error ?? '').toString();
    final lower = raw.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('no address associated') ||
        lower.contains('connection reset')) {
      return 'Koneksi internet terputus atau tidak stabil. Aktifkan internet lalu coba lagi.';
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Koneksi ke server terlalu lama (timeout). Coba lagi atau ganti jaringan.';
    }

    return 'Tidak bisa terhubung ke Cloud saat ini. Coba lagi beberapa saat.';
  }

  Future<void> _refreshLogsAsync() async {
    _refreshLogs();
    try {
      await _logsFuture;
    } catch (_) {
      // Error state ditangani oleh FutureBuilder
    }
  }

void _setOfflineState(bool offline) {
    if (!mounted || offline == _isOffline) return;
    
    setState(() => _isOffline = offline);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    if (offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text("Anda sedang offline. Data akan disimpan lokal."),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text("Koneksi terhubung! Menyinkronkan data..."),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _initConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    final offline = initial.contains(ConnectivityResult.none) || initial.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _isOffline) {
      _setOfflineState(offline);
    }

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final nowOffline = results.every((r) => r == ConnectivityResult.none);
      if (mounted && nowOffline != _isOffline) {
        _setOfflineState(nowOffline);
        if (!nowOffline) {
          _refreshLogs();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final currentUser = _currentUser();
    _controller = LogController(
      userId: currentUser['uid']!,
      userRole: currentUser['role']!,
      teamId: currentUser['teamId']!,
    );

    // Future-based fetch untuk menangani latensi Cloud
    _logsFuture = _fetchLogs();

    // Pantau konektivitas agar offline warning muncul walau user masih di layar list
    _initConnectivity();
  }

  Future<List<LogModel>> _fetchLogs() async {
    final stopwatch = Stopwatch()..start();

    await LogHelper.writeLog(
      "UI: Memulai fetch data untuk team ${_controller.teamId} dari Cloud...",
      source: "log_view.dart",
      level: 2,
    );

    try {
      final logs = await _controller.loadLogs();

      if (_isOffline) {
          _setOfflineState(false);
        }

        await LogHelper.writeLog(
          "UI: Fetch selesai (${logs.length} data)",
          source: "log_view.dart",
          level: 2,
        );

      return logs;
    } catch (e) {
      if (!_isOffline) {
        _setOfflineState(true);
      }
      await LogHelper.writeLog(
        "UI: Fetch gagal ($e)",
        source: "log_view.dart",
        level: 1,
      );
      rethrow;
    } finally {
      
      if (kDebugMode) {
        final remaining = _kMinLoadingDebug - stopwatch.elapsed;
        if (!remaining.isNegative) {
          await Future<void>.delayed(remaining);
        }
      }
    }
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return "Selamat Pagi ☀️";
    if (hour < 15) return "Selamat Siang 🌤️";
    if (hour < 18) return "Selamat Sore 🌅";
    return "Selamat Malam 🌙";
  }

  // Helper: Centered status popup (auto-dismiss)
  void _showStatusPopup(String message, {IconData icon = Icons.check_circle_rounded, Color? color}) {
    final c = color ?? Colors.green[600]!;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted) Navigator.of(ctx).pop();
        });
        return Dialog(
          backgroundColor: kPrimaryLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kDialogRadius)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: c, size: 36),
                ),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper: Confirmation dialog (returns true if confirmed)
  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Ya',
    Color? confirmColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kPrimaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kDialogRadius)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kTextGrey,
              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
            ),
            child: const Text("Batal", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_kButtonRadius)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Map<String, String> _currentUser() {
    final normalizedUsername = widget.username.toLowerCase();
    final role = normalizedUsername == 'admin' ? 'Ketua' : 'Anggota';
    final teamId = switch (normalizedUsername) {
      'admin' || 'user1' => 'MEKTRA_KLP_01',
      'user2' => 'MEKTRA_KLP_02',
      _ => 'MEKTRA_KLP_01',
    };

    return {
      'uid': widget.username,
      'username': widget.username,
      'role': role,
      'teamId': teamId,
    };
  }

  Future<void> _goToEditor({LogModel? log, int? index}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: _currentUser(),
        ),
      ),
    );

    _refreshLogs();
  }

  void _showDeleteConfirm(int index) async {
    if (await _showConfirmDialog(
      title: "Hapus Catatan?",
      content: "Apakah Anda yakin ingin menghapus catatan ini? Tindakan ini tidak bisa dibatalkan.",
      confirmText: "Ya, Hapus",
      confirmColor: Colors.red[400],
    )) {
      await _controller.removeLog(index);
      _refreshLogs();
      _showStatusPopup("Catatan berhasil dihapus!", icon: Icons.delete_rounded, color: Colors.orange[700]);
    }
  }

  void _showLogoutConfirm() async {
    if (await _showConfirmDialog(
      title: "Konfirmasi Logout",
      content: "Apakah Anda yakin ingin keluar? Sesi Anda akan diakhiri.",
      confirmText: "Ya, Keluar",
      confirmColor: Colors.red[400],
    )) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingView()),
          (route) => false,
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 18, color: kPrimaryDark),
            ),
            const SizedBox(width: 8),
            const Text("Logbook", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: kTextDark,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
              ),
              onPressed: _showLogoutConfirm,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ═══ GRADIENT BACKGROUND WITH DECORATIVE ORBS ═══
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEFF6FF), // Light blue
                    Color(0xFFF0F9FF), // Very light blue
                    Color(0xFFFAFBFC), // Almost white
                    Color(0xFFF9FAFB), // Light gray
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ═══ DECORATIVE ORB 1 - Top Right (Blue) ═══
          Positioned(
            top: -screenHeight * 0.15,
            right: -screenWidth * 0.25,
            child: Container(
              width: screenWidth * 0.7,
              height: screenWidth * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kPrimary.withOpacity(0.15),
                    kPrimary.withOpacity(0.08),
                    kPrimary.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ═══ DECORATIVE ORB 2 - Middle Left (Light Blue) ═══
          Positioned(
            top: screenHeight * 0.3,
            left: -screenWidth * 0.3,
            child: Container(
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF93C5FD).withOpacity(0.2),
                    const Color(0xFF93C5FD).withOpacity(0.1),
                    const Color(0xFF93C5FD).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // ═══ DECORATIVE ORB 3 - Bottom Right (Accent Blue) ═══
          Positioned(
            bottom: -screenHeight * 0.1,
            right: -screenWidth * 0.2,
            child: Container(
              width: screenWidth * 0.5,
              height: screenWidth * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kPrimaryDark.withOpacity(0.12),
                    kPrimaryDark.withOpacity(0.06),
                    kPrimaryDark.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ═══ SMALL ACCENT ORBS ═══
          Positioned(
            top: screenHeight * 0.15,
            left: screenWidth * 0.15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kPrimary.withOpacity(0.1),
                    kPrimary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.5,
            right: screenWidth * 0.1,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF60A5FA).withOpacity(0.15),
                    const Color(0xFF60A5FA).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ═══ MAIN CONTENT ═══
          Padding(
            padding: EdgeInsets.only(top: _isOffline ? 96 : 0),
            child: Column(
              children: [
          // ===== HEADER GOLD PANEL =====
          ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.logsNotifier,
            builder: (context, logs, _) {
              final currentUser = _currentUser();
              final currentUserId = currentUser['uid']!;

              // Filter + deduplikasi berdasarkan fingerprint
              final Map<String, LogModel> visibleMap = {};
              for (final log in logs) {
                if (log.authorId == currentUserId || log.isPublic == true) {
                  final fp =
                      '${log.authorId}-${log.teamId}-${log.title}-${log.description}';
                  final existing = visibleMap[fp];
                  if (existing == null || (!log.isSynced && existing.isSynced)) {
                    visibleMap[fp] = log;
                  }
                }
              }
              final visibleLogs = visibleMap.values.toList();
              return ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.95),
                          const Color(0xFF2563EB).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTimeGreeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${visibleLogs.length} catatan tersimpan",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildNetworkBadge(),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(_kCardRadius),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      _controller.searchLog(value);
                    },
                    decoration: InputDecoration(
                      hintText: "Cari catatan...",
                      hintStyle: TextStyle(color: kTextGrey.withOpacity(0.6), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: kTextGrey, size: 22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            child: _LogListSection(),
          ),
              ],
            ),
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildOfflineBanner(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToEditor,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
        elevation: 4,
      ),
    );
  }

  Widget _buildNetworkBadge() {
    final isOnline = !_isOffline;
    final dotColor = isOnline ? Colors.greenAccent : Colors.redAccent;
    final text = isOnline ? 'Online' : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Offline Mode',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tidak ada koneksi internet. Aktifkan data lalu tarik untuk refresh.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _refreshLogsAsync,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogListSection extends StatelessWidget {
  const _LogListSection();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_CounterViewState>()!;

    return FutureBuilder<List<LogModel>>(
      future: state._logsFuture,
      builder: (context, snapshot) {
        // 1. Loading State (latensi Cloud)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: kPrimary),
                SizedBox(height: 16),
                Text("Mengambil data dari MongoDB Atlas..."),
              ],
            ),
          );
        }

        // 2. Error State
        if (snapshot.hasError) {
          final message = state._friendlyCloudError(snapshot.error);
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: state._refreshLogsAsync,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 120),
                Column(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    const Text(
                      'Offline Mode Warning',
                      style: TextStyle(fontWeight: FontWeight.w700, color: kTextDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextGrey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: state._refreshLogs,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarik ke bawah untuk refresh.',
                      style: TextStyle(color: kTextGrey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // 3. Data kosong — tampilkan Lottie animation sebagai empty state
        final currentStoredLogs = state._controller.logsNotifier.value;
        if (currentStoredLogs.isEmpty) {
          return RefreshIndicator(
            color: kPrimary,
            onRefresh: state._refreshLogsAsync,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== LOTTIE ANIMATION =====
                      Lottie.asset(
                        'assets/animations/empty_state.json',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        repeat: true,
                        errorBuilder: (ctx, err, st) => Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 60,
                            color: kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Logbook Masih Kosong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Belum ada aktivitas hari ini?\nMulai catat kemajuan proyek Anda!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kTextGrey,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: () => state._goToEditor(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Buat Catatan Pertama',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_kButtonRadius),
                          ),
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tarik ke bawah untuk refresh.',
                        style: TextStyle(color: kTextGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 4. Jika data sudah ada, render list seperti biasa
        return ValueListenableBuilder<List<LogModel>>(
          valueListenable: state._controller.filteredLogs,
          builder: (context, currentLogs, child) {
            final currentUserId = state.widget.username;

            // Filter + deduplikasi berdasarkan fingerprint (author+team+date+title)
            final Map<String, LogModel> displayMap = {};
            for (final log in currentLogs) {
              if (log.authorId == currentUserId || log.isPublic == true) {
                final fp =
                    '${log.authorId}-${log.teamId}-${log.title}-${log.description}';
                final existing = displayMap[fp];
                if (existing == null || (!log.isSynced && existing.isSynced)) {
                  displayMap[fp] = log;
                }
              }
            }
            final displayLogs = displayMap.values.toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            // ===== SEARCH EMPTY STATE =====
            // Jika ada data di storage, tapi hasil filter/pencarian kosong
            if (displayLogs.isEmpty) {
              return RefreshIndicator(
                color: kPrimary,
                onRefresh: state._refreshLogsAsync,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/animations/empty_state.json',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            repeat: true,
                            errorBuilder: (ctx, err, st) => Container(
                              padding: const EdgeInsets.all(26),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.search_off_rounded,
                                size: 52,
                                color: kPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tidak Ditemukan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Catatan yang kamu cari tidak ada.\nCoba kata kunci yang berbeda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kTextGrey,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: kPrimary,
              onRefresh: state._refreshLogsAsync,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: displayLogs.length,
                itemBuilder: (context, index) {
                  final log = displayLogs[index];
            final cat = _catLookup(log.category);
            final color = cat['color'] as Color;
            final actualIndex = state._controller.logsNotifier.value.indexWhere(
              (l) => (log.id != null && l.id == log.id) || (l.date == log.date),
            );
            final currentUserId = state.widget.username;
            final currentRole = currentUserId.toLowerCase() == 'admin'
                ? 'Ketua'
                : 'Anggota';
            final isOwner = log.authorId == currentUserId;
            final canEdit = AccessControlService.canPerform(
              currentRole,
              AccessControlService.actionUpdate,
              isOwner: isOwner,
            );
            final canDelete = AccessControlService.canPerform(
              currentRole,
              AccessControlService.actionDelete,
              isOwner: isOwner,
            );
            return Dismissible(
              key: Key(
                log.id?.toHexString() ?? log.date.toIso8601String(),
              ),
              direction: canDelete
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                  ),
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text("Hapus", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              confirmDismiss: (_) => canDelete
                  ? state._showConfirmDialog(
                      title: "Hapus Catatan?",
                      content:
                          "Apakah Anda yakin ingin menghapus catatan ini? Tindakan ini tidak bisa dibatalkan.",
                      confirmText: "Ya, Hapus",
                      confirmColor: Colors.red[400],
                    )
                  : Future.value(false),
              onDismissed: (direction) async {
                if (canDelete && actualIndex != -1) {
                  await state._controller.removeLog(actualIndex);
                  state._refreshLogs();
                  state._showStatusPopup(
                    "Catatan berhasil dihapus!",
                    icon: Icons.delete_rounded,
                    color: Colors.orange[700],
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                  border: Border(
                    left: BorderSide(
                      color: color,
                      width: 4,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_kCardRadius),
                    onTap: canEdit
                        ? () => state._goToEditor(
                              log: log,
                              index: actualIndex != -1 ? actualIndex : index,
                            )
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.18),
                                  color.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(_kInputRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: kTextDark,
                                          letterSpacing: -0.2,
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                // Description
                                Text(
                                  log.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kTextGrey.withOpacity(0.9),
                                    height: 1.5,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                // Footer: Timestamp + Sync + Category
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: kTextGrey.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      state._formatIndonesianTimestamp(log.date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kTextGrey.withOpacity(0.75),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Sync Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: log.isSynced
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            log.isSynced
                                                ? Icons.cloud_done_rounded
                                                : Icons.cloud_off_rounded,
                                            size: 11,
                                            color: log.isSynced
                                                ? Colors.green[700]
                                                : Colors.grey[500],
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            log.isSynced ? 'Sync' : 'Offline',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: log.isSynced
                                                  ? Colors.green[700]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Category Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            color.withOpacity(0.15),
                                            color.withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: color.withOpacity(0.25),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            cat['icon'] as IconData,
                                            size: 10,
                                            color: color,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            log.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: color,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Popup Menu dengan Gatekeeper (RBAC)
                          Builder(
                            builder: (context) {
                              // Jika tidak punya izin apapun, sembunyikan menu
                              if (!canEdit && !canDelete) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: kTextGrey.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.more_vert_rounded,
                                      color: kTextGrey,
                                      size: 18,
                                    ),
                                  ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_kInputRadius),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit' && canEdit) {
                                    state._goToEditor(
                                      log: log,
                                      index: actualIndex != -1
                                          ? actualIndex
                                          : index,
                                    );
                                  } else if (value == 'delete' && canDelete) {
                                    if (actualIndex != -1) {
                                      state._showDeleteConfirm(actualIndex);
                                    }
                                  }
                                },
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<String>>[];

                                  if (canEdit) {
                                    items.add(
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded,
                                                size: 18,
                                                color: Colors.blue[600]),
                                            const SizedBox(width: 12),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (canDelete) {
                                    items.add(
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_rounded,
                                                size: 18,
                                                color: Colors.red[600]),
                                            const SizedBox(width: 12),
                                            const Text('Hapus'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return items;
                                },
                              ),
                            );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

