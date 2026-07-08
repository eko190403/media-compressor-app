# Media Compressor App

Aplikasi ini saya buat untuk menyelesaikan masalah klasik: ribetnya kirim media (foto/video) yang ukurannya kebesaran, entah itu buat kirim tugas, upload ke sistem kelompok tani, atau sekadar berbagi di medsos. Dengan aplikasi ini, proses kompresi jadi lebih simpel, cepat, dan tetap menjaga kualitas.

### Kenapa Saya Buat Aplikasi Ini?

Jujur, awalnya karena sering banget butuh kompres file tapi males kalau harus buka website atau aplikasi pihak ketiga yang banyak iklannya. Saya pengen solusi yang native di HP, simpel, dan nggak ribet.

### Fitur Utama

- Kompres Foto, Video & PDF: Langsung pilih dari galeri atau penyimpanan, kompres, selesai. Resolusi dan kualitas dioptimalkan otomatis.
- Integrasi Galeri: Hasil kompresi langsung masuk ke galeri HP. Nggak perlu cari-cari lagi.
- Share Langsung: Setelah dikompres, bisa langsung dibagikan ke platform lain.
- Manajemen Kuota (Firebase): Terintegrasi dengan Firebase Firestore untuk membatasi kuota kompresi harian secara aman.
- Monetisasi (AdMob): Tersedia dukungan iklan AdMob untuk versi gratis.
- Bersih: Ada fitur pembersihan otomatis untuk file sementara. Memori HP nggak gampang penuh.

### Preview

<p align="center">
  <img src="assets/screenshots/home.png" width="200" title="Beranda Aplikasi">
  <img src="assets/screenshots/compressing.png" width="200" title="Proses Kompresi">
  <img src="assets/screenshots/result.png" width="200" title="Hasil Kompresi">
  <img src="assets/screenshots/exit_dialog.png" width="200" title="Peringatan Keluar">
</p>

### Teknologi & Arsitektur

Aplikasi ini dikembangkan dengan Flutter dan dirancang menggunakan arsitektur berbasis layanan (Service-Based Architecture) untuk memisahkan logika dari antarmuka pengguna. Beberapa library dan layanan yang saya gunakan:

- flutter_image_compress & video_compress: Mesin utama untuk memproses dan mengompres media secara efisien.
- Firebase Firestore: Digunakan sebagai backend terkelola untuk sistem kuota pengguna.
- Google Mobile Ads: Digunakan untuk integrasi iklan AdMob.
- gal & share_plus: Digunakan agar aplikasi bisa berinteraksi langsung dengan galeri sistem secara native dan membagikan file dengan mudah.
- connectivity_plus & device_info_plus: Mengelola status koneksi dan mengidentifikasi perangkat keras.

### Cara Menjalankan Proyek

Jika Anda ingin mencoba menjalankan kode sumber aplikasi ini di lokal, pastikan Anda sudah menginstal Flutter SDK, lalu jalankan perintah berikut di terminal:

1. Clone repositori ini:
   git clone https://github.com/eko190403/media-compressor-app.git

2. Masuk ke dalam direktori proyek:
   cd media-compressor-app

3. Unduh semua dependensi yang dibutuhkan:
   flutter pub get

4. Jalankan aplikasi di perangkat Android atau emulator:
   flutter run

Catatan: Pastikan Anda menyesuaikan konfigurasi `firebase_options.dart` dan pengaturan AdMob sesuai dengan akun Anda jika ingin membangunnya untuk produksi.

### Tentang Saya

Halo! Saya Eko Saputra, fresh graduate Teknik Informatika dari IIB Darmajaya. Saya fokus di pengembangan aplikasi mobile dan web. Proyek ini saya buat untuk mendalami integrasi native library, backend Firebase, dan arsitektur kode di Flutter.

Kalau Anda tertarik dengan kodenya, atau mau kasih masukan, silakan buka issue atau langsung hubungi saya di LinkedIn. Mari berdiskusi!
