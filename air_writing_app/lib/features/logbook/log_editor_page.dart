import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/features/logbook/log_controller.dart';

// Constants for styling
const kPrimary = Color(0xFF3B82F6);
const kPrimaryDark = Color(0xFF2563EB);
const kPrimaryLight = Color(0xFFEFF6FF);
const kTextDark = Color(0xFF1F2937);
const kTextGrey = Color(0xFF6B7280);
const kCardRadius = 16.0;
const kInputRadius = 12.0;

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final dynamic currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;
  bool _isSaving = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _selectedCategory = widget.log?.category ?? 'Pribadi';
    _isPublic = widget.log?.isPublic ?? false;

    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul dan isi catatan tidak boleh kosong.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    final bool success;
    if (widget.log == null) {
      success = await widget.controller.addLog(
        title,
        description,
        _selectedCategory,
        _isPublic,
      );
    } else {
      success = await widget.controller.updateLog(
        widget.index!,
        title,
        description,
        _selectedCategory,
        _isPublic,
      );
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (widget.log == null
                    ? 'Catatan berhasil disimpan.'
                    : 'Catatan berhasil diperbarui.')
              : 'Gagal menyimpan catatan. Coba lagi.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: kTextDark,
          surfaceTintColor: Colors.transparent,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.log == null ? Icons.add_rounded : Icons.edit_rounded,
                  size: 18,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.log == null ? "Catatan Baru" : "Edit Catatan",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: kPrimary,
            unselectedLabelColor: kTextGrey,
            indicatorColor: kPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.edit_note_rounded, size: 20),
                text: "Editor",
              ),
              Tab(
                icon: Icon(Icons.visibility_rounded, size: 20),
                text: "Pratinjau",
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _isSaving ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save_rounded, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Simpan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ===== TAB 1: EDITOR =====
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== JUDUL SECTION =====
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.title_rounded,
                                  color: kPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Judul Catatan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: "Masukkan judul catatan...",
                              hintStyle: TextStyle(
                                color: kTextGrey.withOpacity(0.5),
                                fontWeight: FontWeight.normal,
                              ),
                              filled: true,
                              fillColor: kPrimaryLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(kInputRadius),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(kInputRadius),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(kInputRadius),
                                borderSide: const BorderSide(
                                  color: kPrimary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== KATEGORI & VISIBILITY SECTION =====
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.category_rounded,
                                  color: kPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Pengaturan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: kPrimary),
                            decoration: InputDecoration(
                              labelText: "Kategori",
                              labelStyle: const TextStyle(
                                color: kTextGrey,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: kPrimaryLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(kInputRadius),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(kInputRadius),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(kInputRadius),
                                borderSide: const BorderSide(
                                  color: kPrimary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Pribadi',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_rounded, size: 18, color: Colors.green),
                                    SizedBox(width: 10),
                                    Text('Pribadi'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Pekerjaan',
                                child: Row(
                                  children: [
                                    Icon(Icons.work_rounded, size: 18, color: Colors.blue),
                                    SizedBox(width: 10),
                                    Text('Pekerjaan'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Urgent',
                                child: Row(
                                  children: [
                                    Icon(Icons.priority_high_rounded, size: 18, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text('Urgent'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Mechanical',
                                child: Row(
                                  children: [
                                    Icon(Icons.build_rounded, size: 18, color: Colors.teal),
                                    SizedBox(width: 10),
                                    Text('Mechanical'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Electronic',
                                child: Row(
                                  children: [
                                    Icon(Icons.electrical_services_rounded, size: 18, color: Colors.indigo),
                                    SizedBox(width: 10),
                                    Text('Electronic'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Software',
                                child: Row(
                                  children: [
                                    Icon(Icons.code_rounded, size: 18, color: Colors.purple),
                                    SizedBox(width: 10),
                                    Text('Software'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(kInputRadius),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isPublic
                                      ? kPrimary.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _isPublic ? Icons.public_rounded : Icons.lock_rounded,
                                  color: _isPublic ? kPrimary : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Catatan Publik',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kTextDark,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                _isPublic
                                    ? 'Anggota tim & ketua bisa melihat'
                                    : 'Hanya kamu yang bisa melihat',
                                style: TextStyle(
                                  color: kTextGrey,
                                  fontSize: 12,
                                ),
                              ),
                              activeColor: kPrimary,
                              value: _isPublic,
                              onChanged: (value) {
                                setState(() => _isPublic = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== KONTEN/DESKRIPSI SECTION =====
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description_rounded,
                                  color: kPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Isi Catatan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kTextDark,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.code_rounded,
                                      size: 14,
                                      color: kPrimaryDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Markdown',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: kPrimaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(minHeight: 300),
                            decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(kInputRadius),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _descController,
                              maxLines: null,
                              style: const TextStyle(fontSize: 14, height: 1.6),
                              decoration: InputDecoration(
                                hintText: "Tulis laporan dengan format Markdown...\n\n**Bold** _Italic_ `code` [link](url)\n- List item\n1. Numbered list",
                                hintStyle: TextStyle(
                                  color: kTextGrey.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // ===== TAB 2: PRATINJAU =====
            Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kPrimary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pratinjau Markdown',
                              style: TextStyle(
                                color: kPrimaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MarkdownBody(
                      data: _descController.text.isEmpty
                          ? '📝 _Tulis isi catatan untuk melihat pratinjau Markdown._'
                          : _descController.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 14, height: 1.6),
                        h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kTextDark),
                        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark),
                        h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark),
                        code: TextStyle(
                          backgroundColor: kPrimaryLight,
                          color: kPrimaryDark,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
