# Breaking Bread - Godot 4 Project

Game 3D low-poly first-person tentang bisnis kue gelap di dunia di mana gula & karbohydrat ilegal.

## Struktur Proyek
```
breaking-bread/
├── project.godot           # Konfigurasi proyek Godot
├── export_presets.cfg      # Preset export Web & Android
├── .github/workflows/ci.yml # GitHub Actions build otomatis
├── scenes/
│   └── main.tscn          # Scene utama (RV, kota, polisi, pelanggan)
├── scripts/
│   ├── rv_controller.gd   # Mengemudi RV, memanggang, menjual
│   ├── city_generator.gd  # Generate kota procedural
│   ├── police_controller.gd # AI polisi mengejar
│   └── customer_spawner.gd # Spawn pelanggan
├── autoload/
│   ├── game_manager.gd    # State game (uang, resep, upgrade, panas)
│   ├── ui_manager.gd      # HUD, panel dapur, upgrade, pesan
│   └── audio_manager.gd   # Suara mesin, sirine, efek
└── assets/
    └── icon.png           # Ikon game (placeholder)
```

## Cara Build & Mainkan (Tanpa Install Godot di PC)

### 1. Push ke GitHub
```bash
cd breaking-bread
git init
git add .
git commit -m "Initial Godot project + CI"
git branch -M main
git remote add origin https://github.com/USERNAME/breaking-bread.git
git push -u origin main
```
*Ganti `USERNAME` dengan username GitHub Anda.*

### 2. Aktifkan GitHub Pages
- Buka repo di GitHub → **Settings** → **Pages**
- **Source**: pilih **GitHub Actions**
- Save

### 3. Tunggu Build Selesai
- Buka tab **Actions** di repo GitHub
- Tunggu workflow "Build & Deploy" selesai (biasanya 3-5 menit)
- Build akan menghasilkan:
  - **Web**: deploy otomatis ke GitHub Pages
  - **APK**: download di tab Actions → artifacts → `android-apk`

### 4. Mainkan di HP
- **Web**: Buka `https://USERNAME.github.io/breaking-bread/` di browser HP
- **APK**: Download file `breaking_bread.apk` dari artifacts Actions, install di HP

## Kontrol Game

| Aksi | Keyboard | Layar Sentuh |
|------|----------|--------------|
| Maju | W / ↑ | Tombol ↑ |
| Mundur | S / ↓ | Tombol ↓ |
| Kiri | A / ← | Tombol ← |
| Kanan | D / → | Tombol → |
| Rem | Spasi | Tombol ■ |
| Buka Dapur | E | (saat berhenti dekat RV) |
| Jual Kue | Spasi | (saat dekat pelanggan) |
| Pause | Esc | Tombol ☰ |

## Mekanik Inti
1. **Beli bahan** di panel dapur (Gula $50/5, Tepung $20/10, Madu $80/3 butuh Rep 10+, Cokelat $150/2 butuh Rep 25+)
2. **Panggang kue** di RV (harus berhenti): Brownies, Lapis Karamel, Tart Madu Gelap
3. **Kendarai RV** ke kota, cari pelanggan (tanda kerucut oranye)
4. **Jual kue** → dapat uang & reputasi, tapi **Panas naik 10**
5. **Panas > 50** → Polisi mengejar! Lari hingga jarak > 110m selama 4 detik
6. **Tertangkap** → Denda 50% uang + 50% kue disita
7. **Upgrade Oven** (Lv.2 $300, Lv.3 $800) → buka resep baru, panggang lebih cepat
8. **Upgrade Mesin** (Lv.2 $400, Lv.3 $1000) → RV lebih cepat

## Pengembangan Lanjutan
- Ganti aset placeholder di `assets/models/` dengan model low-poly dari [Kenney](https://kenney.nl/assets) / [Quaternius](https://quaternius.com/)
- Tambah suara di `assets/audio/` (format .ogg/.wav)
- Tambah kota baru di `city_generator.gd`
- Balans ekonomi di `game_manager.gd`

## Lisensi
Proyek pribadi - bebas dimodifikasi.