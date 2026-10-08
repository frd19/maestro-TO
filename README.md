# Maestro Automation - TMS Planner App (Android, environment SIT)

Workspace belajar automation **Maestro** berdasarkan test case
`TO Small scope - Appium - FUNCTIONAL` + AC/TSD `9. AC-TO-01 Create TO Revamp`.

---

## 1. Maestro itu apa, dan kenapa lebih singkat dari Playwright/Appium?

Maestro adalah UI automation framework open-source (mobile + web) yang memakai
**YAML declarative**. Kamu mendeskripsikan *apa yang dilakukan user*, bukan
*bagaimana caranya secara program*.

Perbandingan konsep untuk langkah yang sama ("klik tombol Sign in"):

| Tool | Cara menulis |
| --- | --- |
| **Maestro** | `- tapOn: "Sign in"` |
| **Playwright** | `await page.getByRole('button', { name: 'Sign in' }).click()` |
| **Appium** | setup server + cari elemen via XPath → `driver.findElement(...).click()` |

Kenapa Maestro terlihat simpel:

1. **Tidak ada "test runner code"** - tidak ada `describe/it`, `await`, import, dll.
2. **Auto-wait** - tidak perlu explicit wait; Maestro menunggu elemen muncul sendiri.
3. **Toleran selector** - mencari lewat *accessibility tree* (teks yang terlihat),
   bukan XPath yang rapuh.
4. **Satu sintaks untuk semua platform** - `tapOn`, `inputText`, `assertVisible`
   sama untuk Android, iOS, dan Web.
5. **Skenario jadi YAML biasa** - bisa dibaca QA non-programmer.

Catatan jujur: karena kesederhanaan itu, power Maestro ada di UI-level test.
Untuk data kompleks ada JavaScript (`evalScript`/`runScript`), dan setup data
sering dipadukan dengan API call dari dalam flow.

---

## 2. Environment yang sudah terpasang & terverifikasi

| Komponen | Status | Keterangan |
| --- | --- | --- |
| Maestro CLI | ✅ `2.11.0` | `C:\maestro\maestro\bin\maestro.bat` (sudah masuk `PATH` user) |
| Java | ✅ 24 | prerequisite Maestro (butuh 17+) |
| Android platform-tools (adb) | ✅ | `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe` |
| Device tablet | ✅ | Samsung Galaxy Tab A11+ (`SM_X230`), serial **`RRGL707WSTA`**, landscape 1920x1200 |
| Aplikasi under test | ✅ | **`com.stc.tms.stg.planner`** (STG = environment SIT), hybrid/WebView |
| Chromium (Maestro web) | ⚠️ terunduh | fitur web masih Beta - dipakai hanya bila test web |

### Konfigurasi device yang dilakukan saat setup

```powershell
# 1. Screen timeout 30 menit + layar tetap menyala selama charging
adb shell settings put system screen_off_timeout 1800000
adb shell svc power stayon true

# 2. Bila layar terkunci di tengah test:
adb shell input keyevent KEYCODE_WAKEUP
adb shell input swipe 960 1000 960 300 250   # swipe up unlock
```

> Layar sempat mati saat run pertama - akibatnya assertion gagal dengan elemen
> aneh ("Clock" fullscreen). Ini pelajaran penting: **matikan screen timeout
> sebelum automation**.

---

## 3. Struktur folder

```
TCL\Maestro\
├── config.yaml              # discovery flow, urutan run, output artefak
├── run.ps1                  # helper menjalankan test
├── .gitignore
│
├── flows/                   # >>> TEST CASE (dieksekusi saat suite dijalankan)
│   ├── TC-01-login.yaml                 # Test-01: Login
│   ├── TC-02-create-to.yaml             # Test-02: Create new transport order
│   └── TC-03-convert-sales-order.yaml   # Test-03: Convert SO (OPSIONAL, draft)
│
├── subflows/                # langkah yang dipakai ulang (tidak dieksekusi sendiri)
│   └── login.yaml           # dipakai TC-01/02/03 (prinsip DRY)
│
├── sandbox/                 # eksperimen & probe - bukan test case
│   ├── android-probe.yaml   # bukti Maestro bisa baca app hybrid
│   ├── explore-login.yaml   # reset state untuk memetakan layar login
│   └── smoke-web.yaml       # coba engine web (opsional)
│
├── testcases/               # sumber test case (copy dari folder Downloads)
│   ├── TO Small scope - Appium - FUNCTIONAL.csv
│   └── 9. AC-TO-01 Create TO Revamp.md
│
└── test_output/             # artefak lokal
    └── (run tersimpan juga di %USERPROFILE%\.maestro\tests\<timestamp>)
```

Kenapa `subflows/` di luar `flows/`? Karena `config.yaml` hanya menganggap
`flows/**` sebagai test case.

---

## 4. Cara menjalankan

```powershell
cd "C:\Users\LENOVO 2023\OneDrive\Desktop\TCL\Maestro"

# 1. Cek device terdeteksi
maestro list-devices

# 2. Jalankan 1 test case
maestro test flows/TC-01-login.yaml

# 3. Jalankan seluruh suite (urutan: TC-01 -> TC-02 -> TC-03)
.\run.ps1

# 4. Lihat isi layar saat ini (untuk menyusun selector)
maestro hierarchy

# 5. Mode visual: inspect elemen + record langkah jadi YAML
maestro studio
```

Variabel dinamis dipakai lewat flag `-e` lalu diakses `${NAMA_VAR}`:

```bash
maestro test flows/TC-01-login.yaml -e LOGIN_EMAIL=om@gmail.com -e LOGIN_PASSWORD=rahasia
```

Kredensial tidak di-hardcode di tengah flow - default ada di blok `env:` header
file, dan bisa ditimpa dari CLI/CI.

---

## 5. Mapping test case -> flow

| CSV | Test case | File flow | Expected |
| --- | --- | --- | --- |
| Test-01 | Login | `flows/TC-01-login.yaml` | "Success to login" |
| Test-02 | Create new transport order (3 step) | `flows/TC-02-create-to.yaml` | "Success to create TO" |
| Test-03 | Convert sales order (**opsional**) | `flows/TC-03-convert-sales-order.yaml` | "Success to create TO" |

Detail Test-02 mengikuti TSD `9. AC-TO-01`:

1. **Basic Detail** - Customer `PT QA`, Order date hari ini, Route `Sidoarjo - Surabaya`
   (Origin Sidoarjo, Destination Surabaya - **koreksi urutan dari user**),
   Transport condition default, Fleet type `BUP Freezer`
2. **Fleet & SLA** - Pick up `tirtamas coldstorindo`, Stand by time = jam sekarang + 1 jam
   (dihitung otomatis JavaScript inline), Drop point `Hokky buah citraland`,
   Product Group `Ayam / 10 Karung / 10 kg / -18`
3. **Route** - pilih `RECOMMENDATION` -> klik `Select Route` -> submit -> assert sukses

---

## 5a. Peta layar aplikasi (hasil `maestro hierarchy`)

**Layar Login** (`com.stc.tms.stg.planner`):

| Elemen | Selector yang dipakai | Catatan |
| --- | --- | --- |
| Judul | `text: "Log in to your account"` | indikator halaman login |
| Field Email | `text: "Enter your email"` | pakai **hint** (field kosong) |
| Field Password | `point: "50%, 61%"` | tanpa teks & tanpa id; posisi tetap setelah `hideKeyboard` |
| Tombol | `text: "Sign in"` | **wajib `hideKeyboard` dulu** - kalau tidak tertutup keyboard |

**Layar Home / Transport Order List** (pascа-login):

| Elemen | Selector | Catatan |
| --- | --- | --- |
| User login | `text: "(?i).*ruslijun@gmail.*"` | indikator sukses login TC-01 |
| Sidebar menu | `text: "Dashboard"` / `"Transport Order"` / `"Route Plan"` / `"Config"` | klik "Transport Order" = langkah *Navigate to transport order* |
| Judul halaman | `text: "Transport Order"` | muncul 3x (judul, sidebar, tombol) -> **ambigu**, pakai `index`/`point`/relasional |
| Tombol kanan atas | `point: "93%, 22%"` (Button, bounds `[1677,237][1896,297]`) | kandidat "transport order button" -> buka opsi Create TO |
| Tab status | `"Dispatching"` / `"In Transit"` / `"Delivered"` | filter list TO |
| Kartu TO | regex `(?i).*TO-\d{8}-\d+.*` | daftar TO (mis. `TO-20261003-0431`) |

**Form Create Transport Order** (wizard, dibuka dari tombol kanan atas):

| Elemen | Selector | Catatan |
| --- | --- | --- |
| Tombol kanan atas | `point: "93%, 22%"` | membuka dropdown menu |
| Menu create | `text: "Create new transport order"` | langkah 3 TC-02 |
| Menu convert | `text: "Convert sales order"` | langkah 2 TC-03 |
| Judul form | `text: "Create Transport Order"` | indikator form terbuka |
| Wizard kiri | `"Basic Detail"` / `"Fleet and SLA"` / `"Route"` | 3 langkah wizard |
| Field Customer | `text: "Select Customer"` → modal | dropdown + search box |
| Field Origin | `text: "Origin City"` → modal `Search by city` | dropdown + search box |
| Field Destination | `text: "Destination City"` → modal | sama |
| Tombol navigasi | `text: "Next"` / `text: "Cancel"` | android.widget.Button |

**Pola dropdown di app ini** (konsisten): klik field → modal muncul dengan
**search box EditText** (`Search by customer name` / `Search by city`) + **list
item** (`text: "PT QA.*"`, `text: ".*Surabaya,.*"`).

> Trik selector: item list memakai format `"Kota, Provinsi"` - tambahkan koma di
> regex (`.*Surabaya,.*`) supaya TIDAK ambigu dengan isi search box (`Surabaya`
> tanpa koma). Bila list butuh pencarian, ketik dulu lewat search box-nya.

---

## 6. Konvensi selector (Android)

Prioritas selector yang dipakai:

1. **Teks yang terlihat / accessibilityText** (paling stabil):
   ```yaml
   - tapOn: "Sign in"
   - tapOn: "(?i).*create new transport order.*"    # regex
   ```
2. **Hint text** - Android mengekspos `android:hint` sebagai teks, jadi field
   kosong bisa diklik pakai hint-nya:
   ```yaml
   - tapOn: "Enter your email"
   ```
3. **Selector relatif** bila elemen tidak punya teks sama sekali:
   ```yaml
   - tapOn:
       below:
         text: "Password"
   ```
4. `id` (resource-id) - **tidak tersedia** di app ini (semua elemen kosong id-nya),
   jadi jangan andalkan `data-testid` / css - itu hanya berlaku untuk web.

### Pelajaran nyata dari run pertama (baca ini!)

1. **`label` tidak boleh jadi key sibling** - harus di dalam map command:
   ```yaml
   - launchApp          # ❌ label di baris berikutnya -> "Invalid Command"
   - tapOn:             # ✅
       text: "Sign in"
       label: 'Klik sign in'
   ```
2. **Tutup keyboard sebelum pakai selector relatif** - teks "Password" juga ada
   di suggestion strip keyboard, sehingga anchor bisa salah sasaran dan field
   password tidak keisi (email jadi ikut tertimpa).
3. **Matikan screen timeout** - kalau tidak, assertion gagal dengan elemen "Clock".
4. **Assertion penengah membantu debugging** - mis. assert email masih benar
   setelah pindah field, jadi kegagalan langsung ketahuan di langkah mana.
5. Artefak gagal ada di `%USERPROFILE%\.maestro\tests\<timestamp>\`:
   screenshot, hierarchy JSON, logcat, commands.json.

---

## 7. Checklist belajar

- [ ] Baca `flows/TC-01-login.yaml` + `subflows/login.yaml` (pahami `runFlow`, `clearState`)
- [x] Jalankan TC-01, pastikan PASS (✅ PASSED 07-Okt-2026, assertion positif: Dashboard + user Rusli Junaidi)
- [ ] `maestro studio` untuk inspect layar & rekam langkah jadi YAML
- [ ] Selesaikan TC-02 (petakan layar create TO step 1-3, ganti selector TODO)
- [ ] (Opsional) TC-03
- [ ] Pelajari lanjutan: tags, `executionOrder`, `optional`, `evalScript`, loops, conditions

### Referensi resmi

- Docs: https://docs.maestro.dev
- Commands: https://docs.maestro.dev/reference/commands-available
- Selectors (text/id/relational): https://docs.maestro.dev/reference/selectors/core-selectors
- Android: https://docs.maestro.dev/get-started/supported-platform/android
- Web (Beta): https://docs.maestro.dev/get-started/supported-platform/web-browser
