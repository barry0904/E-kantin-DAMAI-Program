1.Aplikasi eKantin Damai (Kantin Sekolah Damai)

Aplikasi manajemen kantin berbasis Android yang dirancang untuk mempermudah proses pemesanan makanan di lingkungan Sekolah Damai. Aplikasi ini memisahkan hak akses antara **Siswa** (untuk memesan dan membayar) dan **Admin/Pengelola OSIS** (untuk mengelola stok menu, QRIS, dan memproses pesanan).



2.Cara Mengakses dan Menjalankan Program

Pilih salah satu cara di bawah ini untuk mengakses atau mencoba aplikasi:

Cara 1: Mendownload dari link yang saya provide https://drive.google.com/file/d/10f7PZ3jEmRKVECh-wM2RU8GeZ0k1MO-1/view?usp=drive_link

Cara 2: Menjalankan Source Code (Untuk Pengembangan/Pengujian)
Jika Anda ingin melihat atau mengedit kode program di laptop/PC:
1. Klik tombol **Code** (berwarna hijau) di kanan atas halaman GitHub ini, lalu pilih **Download ZIP** (atau lakukan `git clone https://github.com/username/repository-anda.git`).
2. Ekstrak file ZIP tersebut.
3. Buka aplikasi **Android Studio** di laptop Anda.
4. Pilih **Open an Existing Project** dan arahkan ke folder hasil ekstrak tadi.
5. Tunggu proses *Gradle Sync* selesai, lalu hubungkan perangkat Android atau gunakan Emulator, dan klik tombol **Run (Segitiga Hijau)**.



3.Panduan Troubleshooting (Pemasangan APK)

Karena aplikasi ini dikembangkan secara internal (tidak diunduh dari Google Play Store), sistem Android terkadang mendeteksi file sebagai aplikasi berbahaya. Silakan ikuti panduan berikut:

| No | Masalah / Kendala | Kemungkinan Penyebab | Langkah Penyelesaian |
| :--- | :--- | :--- | :--- |
| **1** |Muncul peringatan **"Aplikasi Berbahaya"** (Google Play Protect). | Sistem mendeteksi aplikasi dibuat secara internal dan belum terdaftar di Google Play Store. | 1. Pada layar peringatan, ketuk **"Detail selengkapnya"**.<br>2. Pilih opsi **"Tetap instal"** (*Install anyway*) untuk melanjutkan. |
| **2** |roses instalasi **ditolak/diblokir** sepenuhnya. | Pengaturan keamanan perangkat belum mengizinkan instalasi dari luar Play Store. | 1. Masuk ke **Pengaturan (Settings)** HP.<br>2. Pilih **Keamanan (Security)** / Privasi.<br>3. Aktifkan **"Instal aplikasi dari sumber tidak dikenal"** untuk browser atau File Manager Anda. |

---

4.Panduan Singkat Alur Penggunaan File Aplikasi

Sisi Siswa (Pelanggan)
1. **Registrasi & Login:** Siswa mendaftar menggunakan Nama, NIS (UID Siswa), dan Email Sekolah, lalu masuk melalui halaman Login.
2. **Pilih & Pesan Menu:** Telusuri menu yang tersedia (seperti Pizza, Burger, Lemper), tentukan jumlah porsi menggunakan tombol `+` / `-`, lalu masukkan ke Keranjang.
3. **Checkout & Bayar:** Masuk ke menu Keranjang, periksa pesanan, lalu pilih metode pembayaran **QRIS** (pembayaran digital) atau **Tunai** (bayar langsung di kasir).
4. **Riwayat Pesanan:** Siswa dapat melihat status pesanannya secara *real-time* (*Menunggu Pembayaran / Diproses / Selesai*).

Sisi Admin (Pengelola Kantin / OSIS)
1. **Login Admin:** Masuk menggunakan akun admin khusus yang telah dikonfigurasi oleh sistem sekolah.
2. **Kelola Menu & Stok:** Melalui Dashboard, admin dapat menambah menu baru, memperbarui harga, atau menambah jumlah stok makanan agar sinkron dengan kondisi di kantin fisik.
3. **Update QRIS:** Admin dapat memperbarui gambar kode QRIS kantin kapan saja jika ada perubahan rekening tujuan.
4. **Proses Pesanan & Laporan:** Admin memantau pesanan masuk, memverifikasi pembayaran uang tunai dari siswa, dan memantau total pendapatan melalui halaman Riwayat Penjualan.
