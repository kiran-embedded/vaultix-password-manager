<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=7C4DFF&height=200&section=header&text=Vaultix&fontSize=70&fontColor=ffffff&animation=twinkling&desc=Offline-First%20Password%20Manager&descSize=20&descAlignY=70" alt="Vaultix Animated Header" />

  <br><br>

  <p>
    <strong>A private, offline-first secure vault built from the ground up to protect your digital life.</strong>
  </p>

  <p>
    <a href="#the-concept">The Concept</a> •
    <a href="#core-features">Features</a> •
    <a href="#how-encryption-works">How Encryption Works</a> •
    <a href="#legal-notice">Legal Notice</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Badge" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart Badge" />
    <img src="https://img.shields.io/badge/Encryption-AES--256--GCM-red?style=for-the-badge" alt="Security Badge" />
  </p>
</div>

---

## 💡 The Concept

I built Vaultix because I didn't trust cloud-based password managers with my raw data. The idea here is simple: **zero trust**. 

Vaultix never sends your plaintext data anywhere. There are no accounts, no subscriptions, and no central servers holding your passwords. Everything you type into Vaultix gets encrypted locally on your phone using military-grade encryption *before* it ever leaves the device. If you decide to back it up, you back it up to *your own* Google Drive—and even then, Google only sees encrypted gibberish.

---

## ⚡ Core Features

- **Total Offline Mode:** Works entirely without an internet connection. The app only connects if you explicitly choose to sync to your personal Google Drive.
- **Biometric Unlock:** Hooked directly into native Fingerprint and Face ID APIs for quick access.
- **Screenshot Blocker:** Forces Android's `FLAG_SECURE` to block anyone (or any background app) from taking screenshots or recording your screen while the vault is open.
- **Custom Password Generator:** Built-in generator to spin up heavy-duty, randomized passwords. You pick the length and character sets.
- **Smart Organization:** Keep your Logins, Credit Cards, and Secure Notes separated and easily accessible.
- **Auto-Sync:** If enabled, the app watches for changes and automatically pushes the newly encrypted database to your Google Drive in the background.

---

## 🔐 How Encryption Works

I didn't cut corners on security. Here's exactly what happens under the hood:

1. **Key Derivation:** When you set your Master Password, Vaultix runs it through PBKDF2 with a secure random salt to stretch it into a strong 256-bit encryption key.
2. **Hardware Storage:** The derived keys are locked inside the device's hardware-backed Keystore (Android) or Secure Enclave (iOS). 
3. **AES-256-GCM:** Every single piece of data you save is encrypted using AES-256 in Galois/Counter Mode. This handles both keeping the data hidden and ensuring nobody tampers with it.
4. **Cloud Blindness:** The payload sent to Google Drive is the ciphertext. Nobody without your Master Password can read your vault.

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=rect&color=36D7FF&height=100&text=Your%20Keys.%20Your%20Data.&fontSize=30&fontColor=000000&animation=fadeIn" alt="Security Banner" />
</div>

---

## 🛑 Legal Notice

### **Copyright (c) 2026 Kiran. All Rights Reserved.**

This repository is strictly a portfolio piece. I made it public so people can read the code and see how I build secure Flutter applications. 

**You do NOT have permission to use, copy, modify, or distribute this code.** 
- You cannot clone this and publish your own version on the Play Store.
- You cannot rip out my custom UI widgets and use them in a commercial app.
- You cannot fork this to bypass the copyright.

Any unauthorized use will result in immediate DMCA takedown notices and legal action. Check the `LICENSE` file for full details.

---

<div align="center">
  <p>Designed and coded by <a href="https://github.com/kiran-embedded">Kiran</a>.</p>
</div>
