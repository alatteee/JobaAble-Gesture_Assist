# 📱 LogBook App: Multi-Step Counter & History Logger

[![Framework](https://img.shields.io/badge/Framework-Flutter-blue.svg)](https://flutter.dev/)
[![Language](https://img.shields.io/badge/Language-Dart-blue.svg)](https://dart.dev/)
[![Principles](https://img.shields.io/badge/Principles-SRP-green.svg)](https://en.wikipedia.org/wiki/Single_responsibility_principle)

[cite_start]Aplikasi mobile sederhana yang dibangun dengan **Flutter** untuk mendemonstrasikan penerapan **Single Responsibility Principle (SRP)** dan manajemen state dasar. [cite: 34, 35] [cite_start]Proyek ini merupakan bagian dari tugas **Modul 1 Praktikum Proyek 4**. [cite: 1]

---

## 🌟 Fitur Utama

* [cite_start]**Multi-Step Counter**: Menambah atau mengurangi nilai angka berdasarkan input "Step" yang dinamis. [cite: 202, 204]
* [cite_start]**History Logger**: Mencatat setiap aktivitas (Tambah, Kurang, Reset) lengkap dengan waktu kejadian. [cite: 213, 215]
* [cite_start]**Smart History Limit**: Mengelola memori dengan hanya menampilkan **5 aktivitas terakhir** saja. [cite: 221]
* **Professional UI/UX**:
    * [cite_start]Tampilan modern menggunakan **Gradient Card**. [cite: 227]
    * [cite_start]Indikator warna pada riwayat (Hijau untuk Tambah, Merah untuk Kurang). [cite: 227]
    * [cite_start]Dialog konfirmasi dan **SnackBar** untuk aksi Reset agar data tidak hilang tidak sengaja. [cite: 228]

---

## 🧠 Self-Reflection: Implementasi Prinsip SRP

[cite_start]**"Bagaimana prinsip SRP membantu saat harus menambah fitur History Logger tadi?"** 

Penerapan prinsip **Single Responsibility Principle (SRP)** sangat mempermudah proses pengembangan, terutama saat menambahkan fitur *History Logger*. [cite_start]Karena kode telah dipisahkan, saya hanya perlu memodifikasi file `counter_controller.dart` untuk menangani struktur data `List<String>` dan logika manipulasi riwayat tanpa perlu mengkhawatirkan kode antarmuka.  [cite_start]Pemisahan antara mana yang bertugas "berpikir" (*Controller*) dan mana yang bertugas "tampil estetis" (*View*) membuat aplikasi lebih mudah dikembangkan. [cite: 46]

---

## 🛠️ Struktur Proyek

[cite_start]Sesuai dengan panduan modul, struktur kode dibagi menjadi: [cite: 149, 150]

```text
lib/
├── main.dart                <-- Entry point: Menjalankan MyApp & CounterView [cite: 149]
├── counter_controller.dart  <-- Logika: Angka, Step, List Riwayat [cite: 149]
└── counter_view.dart        <-- Antarmuka: Tombol, Teks, Dialog, SnackBar [cite: 149]