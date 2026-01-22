# Aturan Pemetaan Transaksi (Transaction Mapping Rules)

Dokumen ini berisi aturan untuk memetakan kode-kode teknis dari log JSON ke dalam deskripsi bisnis yang lebih mudah dipahami.

---

## 1. Pemetaan Berdasarkan PCode (Processing Code)

Digunakan untuk mengidentifikasi jenis transaksi finansial utama.

- **`301000`**: Inquiry Balance (Cek Saldo)
- **`401000`**: Transfer
- **`011000`**: Tarik Tunai (Cash Withdrawal)

---

## 2. Pemetaan Berdasarkan MTI (Message Type Indicator)

Digunakan untuk mengidentifikasi aktivitas jaringan (non-finansial).

- **MTI `0800`**: Sign On
- **MTI `0800`** DAN **`networkMgmtCode == 301`**: Echo Test

---

## 3. Pemetaan Berdasarkan `privateData`

Digunakan untuk mengklasifikasikan jenis jaringan transaksi (On-Us/Off-Us). Logika ini bergantung pada awalan (prefix) dari sebuah field di dalam `privateData`.

- Awalan **`0210`**: `WITHDRAWAL_OFF_US`
- Awalan **`0110`**: `WITHDRAWAL_ON_US`
- Awalan **`02`**: `OFF_US` (Non-Withdrawal)
- Awalan **`01`**: `ON_US` (Non-Withdrawal)

**Aturan Default:** Jika tidak ada awalan yang cocok, transaksi akan diklasifikasikan sebagai `OFF_US`.
