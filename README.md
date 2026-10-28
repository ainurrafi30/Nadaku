# Nadaku

Aplikasi pemutar preview lagu bergaya Spotify yang dibuat dengan **Flutter** dan **Dart**.
Seluruh data lagu, artis, dan album diambil secara dinamis dari **Deezer Public API**.

Proyek ini dibuat untuk Ujian Tengah Semester (UTS) mata kuliah Pemrograman Mobile.

- Penulis: Ahmad Ainur Rafi (NIM 240605110020)
- Program Studi Teknik Informatika, Universitas Islam Negeri Maulana Malik Ibrahim Malang

## Deskripsi singkat

Nadaku membantu pengguna menemukan dan mendengarkan cuplikan lagu: melihat tangga lagu dunia
per genre, mencari lagu berdasarkan judul atau nama artis, membuka profil artis dan album,
lalu memutar preview 30 detik. Lagu yang disukai dapat disimpan sebagai favorit dan tetap
tersedia setelah aplikasi ditutup.

## Fitur utama

- **Beranda**: chart lagu, artis, dan album populer dunia, dengan filter genre (data genre juga dari API).
- **Pencarian lagu** dengan jeda otomatis (debounce) agar tidak membebani kuota API.
- **Pemutar preview 30 detik**: putar/jeda, geser posisi, lagu sebelumnya/berikutnya, ulangi lagu, dan pemutar mini di setiap halaman.
- **Detail artis** (jumlah penggemar, lagu populer, daftar album) dan **detail album** (daftar lagu).
- **Lagu favorit** yang disimpan lokal di perangkat.
- **Penanganan kondisi asinkron** memakai `FutureBuilder`: *loading*, *success*, dan *error* (dengan tombol "Coba lagi") pada setiap halaman yang mengambil data.
- Pesan kesalahan yang jelas untuk kasus tanpa koneksi, waktu tunggu habis, kesalahan server, batas kuota API, dan data tidak valid.

## Teknologi dan package

| Teknologi / package | Kegunaan |
|---|---|
| Flutter dan Dart 3 | Kerangka kerja dan bahasa pemrograman |
| `http` | Mengirim permintaan HTTP ke Deezer API |
| `just_audio` | Memutar preview audio dari URL |
| `shared_preferences` | Menyimpan daftar lagu favorit di perangkat |
| `cached_network_image` | Menampilkan dan menyimpan cache gambar sampul |
| `flutter_test` | Pengujian unit dan widget |

Sumber data: [Deezer API](https://developers.deezer.com/api) (tidak memerlukan API key untuk endpoint yang dipakai).

## Langkah menjalankan aplikasi

Prasyarat: [Flutter SDK](https://docs.flutter.dev/get-started/install) terpasang, perangkat Android atau emulator aktif, dan koneksi internet.

```bash
git clone <URL-REPOSITORI-INI>
cd nadaku
flutter pub get
flutter run
```

Catatan penting:

1. Jalankan di **Android atau iOS** (emulator atau perangkat). Versi web tidak didukung karena Deezer API tidak mengizinkan permintaan lintas-origin dari browser.
2. Jika membuat ulang project dari awal, izin internet harus ada di `android/app/src/main/AndroidManifest.xml`
   (di atas tag `<application>`):

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

3. Preview lagu hanya berdurasi 30 detik dan sebagian lagu tidak memiliki preview (ditandai "Preview tidak tersedia").

## Struktur folder

```
lib/
├── main.dart                 # titik masuk aplikasi
├── core/                     # konstanta, tema, formatter, util JSON, AppScope
├── models/                   # class model: Track, Artist, Album, Genre, data layar
├── services/
│   ├── deezer_service.dart   # klien API (HTTP, validasi respons, konversi JSON)
│   ├── api_exception.dart    # kesalahan terstruktur untuk antarmuka
│   ├── audio_engine.dart     # abstraksi pemutar audio (just_audio)
│   ├── player_controller.dart# antrean dan status pemutaran
│   └── favorites_controller.dart
├── screens/                  # Beranda, Cari, Favorit, Pemutar, Artis, Album
└── widgets/                  # komponen yang dipakai ulang
test/                         # pengujian unit dan widget
```

## Pengujian

```bash
flutter analyze
flutter test
```

Pengujian otomatis mencakup konversi JSON ke objek Dart, permintaan dan penanganan kesalahan
pada `DeezerService` (menggunakan `MockClient`), logika pemutar, penyimpanan favorit, serta
kondisi loading, success, dan error pada Beranda dan Pencarian.

## Tangkapan layar

Letakkan tangkapan layar di folder `docs/screenshots/` lalu tautkan di sini, misalnya:

```markdown
![Beranda](docs/screenshots/beranda.png)
```
