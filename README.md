<div align="center">

<br>

<img src="build/appicon.png" width="88" alt="ArchInit">

<h1>ArchInit</h1>

<p><strong>Arch Linux kurulum sihirbazı.</strong><br>
60 yaşındaki biri için yeterince basit. Geliştirici için yeterince güçlü.</p>

<br>

[![Release](https://img.shields.io/github/v/release/KiruhiHub/SetupWizard?style=flat-square&color=7c6af8&label=release)](https://github.com/KiruhiHub/SetupWizard/releases)
[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat-square&logo=go&logoColor=white)](https://go.dev)
[![Wails](https://img.shields.io/badge/Wails-v2-blueviolet?style=flat-square)](https://wails.io)
[![License](https://img.shields.io/badge/license-MIT-22c55e?style=flat-square)](LICENSE)

<br>

</div>

---

## Ne yapar?

Arch Linux kurulumunu 3 adıma indirir. Teknik bilgi gerekmez.

```
Adım 1 → Kim olduğunu seç   (Günlük / Yazılımcı / Özel)
Adım 2 → Masaüstü stilini seç  (Windows / macOS / KDE)
Adım 3 → Bulut hesabını bağla  (Google / iCloud / OneDrive)
```

Gerisini otomatik halleder.

---

## Özellikler

- **İkon tabanlı arayüz** — Metin yok, herkes anlar
- **QR ile bulut bağlantısı** — rclone OAuth, telefon ile tara
- **Canlı kurulum logu** — Ne yüklendiğini anlık görürsün
- **3 profil** — Günlük kullanım, Yazılımcı, Özel
- **Sidebar navigasyon** — Nerede olduğunu her zaman bilirsin
- **Wails v2** — Native uygulama, Go + Vite

---

## Kurulum

### Gereksinimler

| Araç | Versiyon |
|------|----------|
| [Go](https://go.dev/dl/) | 1.21+ |
| [Node.js](https://nodejs.org/) | 18+ |
| [Wails](https://wails.io/docs/gettingstarted/installation) | v2 |
| [rclone](https://rclone.org/install/) | herhangi |

### Geliştirme

```bash
git clone https://github.com/KiruhiHub/SetupWizard.git
cd SetupWizard
wails dev
```

### Build

```bash
wails build
# → build/bin/SetupWizard
```

---

## Proje Yapısı

```
SetupWizard/
├── main.go              # Wails giriş noktası
├── app.go               # Go backend (rclone, setup runner)
├── scripts/
│   └── setup.sh         # Kurulum betiği
├── frontend/
│   ├── index.html       # Adım 1 — Profil
│   ├── page1.html       # Adım 2 — Masaüstü stili
│   ├── page2.html       # Adım 3 — Bulut bağlantısı
│   └── src/
│       ├── main.js
│       └── css/style.css
└── wails.json
```

---

## Nasıl Çalışır?

1. Kullanıcı **profil** seçer
2. Kullanıcı **masaüstü stili** seçer
3. Kullanıcı **bulut hesabı** bağlar (QR kodu ile rclone OAuth)
4. Backend `scripts/setup.sh` çalıştırır
5. Loglar Wails events ile frontend'e akar

---

## Katkı

PR'lar açık. Büyük değişiklikler için önce issue aç.

---

<div align="center">

MIT © [KiruhiHub](https://github.com/KiruhiHub) · Made with ❤️ for the Linux community

</div>
