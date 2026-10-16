# 🏋️ Grit Fitness Workout Tracker

Aplikasi pelacakan latihan dan progresi beban kebugaran duo atlet (**Hans** & **Cute lil baby**) berbasis **Flutter** dan **Supabase (PostgreSQL + Realtime)**, bertransformasi penuh dari sistem spreadsheet relasional.

---

## 🚀 Fitur Unggulan

### 1. 🏋️ Tandem / Duo Workout Form (Modul 1)
- **Deteksi Hari & Sesi Otomatis**: Secara cerdas memilih sesi latihan sesuai hari kalender (`Tuesday • Heavy Full Body`, `Thursday • Push Day`, `Friday • Pull Day`, `Saturday • Leg Day`).
- **Duo Mode (2 Atlet di 1 Layar)**: Segmented Toggle instan antara **Hans (USR-001)** dan **Cute lil baby (USR-002)**, serta mode Split-View untuk melihat status set kedua atlet berdampingan saat bergantian memakai alat di gym.
- **Smart Progressive Overload (+2.5 kg)**: Otomatis mendeteksi jika atlet mencapai target repetisi di seluruh set pada sesi sebelumnya, lalu memunculkan badge rekomendasi beban naik +2.5 kg dengan tombol "APPLY" sekali sentuh.
- **Tabel Set 1–5 Interaktif**: Input Weight (kg), Reps, kalkulasi live Volume (kg) dan Est. 1RM (rumus Epley), serta checkbox status penyelesaian set.
- **Floating Auto-Rest Timer**: Countdown timer otomatis (default 90 detik, opsi 60s/90s/120s) yang aktif saat set dicentang, dilengkapi getar/haptik saat waktu istirahat habis.
- **One-Tap Save dengan Proteksi Debounce**: Mencegah duplikasi data set seperti pada kasus historis LOG-014–LOG-019 di spreadsheet.

### 2. 📊 4-Week Routine & Weight Progression (Modul 2)
- Kartu ringkasan metrik: `TOTAL SESSIONS`, `TOTAL EXERCISES`, `WORKOUT PROGRESS`, dan `EXERCISE STATUS`.
- Daftar latihan per sesi dengan progres beban otomatis untuk **Week 1 (Kg)**, **Week 2 (Kg)**, **Week 3 (Kg)**, dan **Week 4 (Kg)**.
- Indikator visual tren beban (`Weight Trend`): Panah hijau naik, oranye flat, merah turun.

### 3. 🗓️ Daily Workout Log & History (Modul 3)
- Metrik akurat: `TOTAL SESSIONS` (dihitung dari kombinasi unik tanggal + sesi latihan), `TOTAL VOLUME (kg)`, dan `LAST WORKOUT`.
- Filter komprehensif berdasarkan Atlet, Sesi Hari, dan Tanggal.
- Fitur Edit dan Delete log untuk mengoreksi salah ketik.

### 4. ⚙️ Exercise Manager CRUD (Modul 4)
- Form Modal Bottom Sheet untuk Add New Exercise, Edit Exercise, atau Archive Movement.
- Validasi wajib isi pada Target Session, Exercise Name, Target Muscle, Target Reps, dan Equipment Guide.

---

## 🗄️ Langkah Setup Database di Supabase

1. Buka [Supabase Dashboard](https://supabase.com/dashboard) dan buat project baru.
2. Buka menu **SQL Editor** di dashboard Supabase Anda.
3. Jalankan file schema terlebih dahulu:
   - Salin isi dari [`supabase/migrations/001_init_schema.sql`](supabase/migrations/001_init_schema.sql) dan klik **Run**.
4. Jalankan file seed data yang telah direkonsiliasi:
   - Salin isi dari [`supabase/seed.sql`](supabase/seed.sql) dan klik **Run**.
5. Database Anda sekarang telah berisi:
   - 2 Pengguna tetap (`USR-001`: Hans, `USR-002`: Cute lil baby).
   - 33 Gerakan latihan aktif terstandarisasi (`EXE-001` s.d. `EXE-033`).
   - 113 Baris riwayat log latihan bersih tanpa duplikasi dan bug volume.
   - Realtime aktif pada tabel `workout_logs` dan `exercises_master`.
   - SQL View `v_weekly_progression`.

---

## 📱 Menjalankan & Mem-Build Aplikasi Flutter

### Konfigurasi Kredensial
Salin file `.env.example` menjadi `.env` atau jalankan via `--dart-define`:
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
*(Catatan: Jika kredensial belum diisi, aplikasi tetap dapat dijalankan 100% dalam mode offline dengan 33 gerakan dan 113 data riwayat pre-seeded bawaan).*

### Menjalankan di Chrome (Web)
```bash
flutter run -d chrome
```

### Menjalankan di Perangkat Android
```bash
flutter run -d android
```

### Build APK Android
```bash
flutter build apk --release
```
File APK akan berada di `build/app/outputs/flutter-apk/app-release.apk`.

### Build Web PWA
```bash
flutter build web --release
```
Folder hasil build berada di `build/web/` yang siap di-deploy ke Firebase Hosting, Vercel, Netlify, atau Supabase Storage.

---

## 🧪 Menjalankan Pengujian (Tests & Lint)

```bash
# Analisis statis (0 error, 0 warning)
flutter analyze

# Unit tests & Widget tests (7 passed)
flutter test
```
