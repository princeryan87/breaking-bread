# Kue Gelap (Godot 4.3)

Game first-person 3D low poly: dunia di mana gula dilarang. Panggang kue di RV, jual diam-diam, hindari polisi.
Semua objek 3D dan UI dibuat lewat kode, jadi tidak perlu editor Godot untuk membangun game ini.

## Cara upload dan build (tanpa PC kuat)
1. Buat repo baru di GitHub (misalnya `kue-gelap`), lalu unggah SEMUA isi folder ini (termasuk folder `.github`).
2. Buka Settings, lalu Pages, lalu pada Source pilih **GitHub Actions**.
3. Buka tab **Actions**. Workflow "Build Kue Gelap" berjalan otomatis setiap push ke branch `main`. Bisa juga dijalankan manual lewat "Run workflow".
4. Tunggu sampai selesai (sekitar 5 sampai 10 menit).
   - **Web:** link game muncul di job `deploy-web` (biasanya `https://USERNAME.github.io/kue-gelap/`). Buka di browser HP.
   - **APK:** buka run yang sudah selesai, lalu bagian Artifacts, unduh `kue-gelap-apk`, ekstrak zip-nya, dan instal `kue-gelap.apk` di HP (izinkan instal dari sumber tidak dikenal).

## Kontrol
- Layar sentuh: tombol KIRI, KANAN, GAS, REM. Tombol Dapur dan Jual kue di tengah bawah.
- Keyboard: WASD atau panah, E untuk dapur, spasi untuk menjual.

## Cara main
- Beli gula dan tepung di dapur (RV harus berhenti), lalu panggang kue. Kue tetap dipanggang saat kamu menyetir.
- Dekati pelanggan bertanda kerucut merah muda, pelankan RV, lalu tekan Jual kue.
- Tiap penjualan menaikkan Panas. Di atas 50, polisi mengejar. Kabur sampai mereka kehilangan jejak. Kalau tertangkap: denda dan separuh kue disita.
- Upgrade oven (lebih banyak kue, lebih cepat, resep baru) dan mesin RV (lebih kencang).
- Progres tersimpan otomatis.

## Struktur
- `scripts/main.gd`: penghubung semua bagian
- `scripts/game_state.gd`: data game (autoload bernama `Game`)
- `scripts/city.gd`, `rv.gd`, `police.gd`, `customers.gd`: dunia dan karakter
- `scripts/hud.gd`: UI dan kontrol sentuh
- `.github/workflows/build.yml`: build otomatis (web dan APK)

## Keterbatasan saat ini
Hanya satu kota, polisi menembus gedung, belum ada suara, dan visual masih kotak berwarna.
