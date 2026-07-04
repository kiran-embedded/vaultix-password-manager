<div align="center">
  <img src="https://raw.githubusercontent.com/kiran-embedded/vaultix-password-manager/main/assets/icons/app_icon.png" width="120" alt="Vaultix Logo" />

  <h1>Vaultix Password Manager</h1>

  <p>
    <strong>A next-generation, offline-first secure vault for your digital identity.</strong>
  </p>

  <p>
    <a href="#features">Features</a> •
    <a href="#security-architecture">Security</a> •
    <a href="#installation">Installation</a> •
    <a href="#roadmap">Roadmap</a>
  </p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
    <img src="https://img.shields.io/badge/Security-AES--256-red?style=for-the-badge" alt="Security" />
  </p>

  <img src="https://capsule-render.vercel.app/api?type=waving&color=7C4DFF&height=150&section=header&text=Vaultix%20Security&fontSize=40&fontColor=ffffff&animation=fadeIn" alt="Header Animation" />
</div>

---

## 🛡️ The Philosophy

Vaultix was built on a simple premise: **Your data belongs to you, and only you.** 

In a world where data breaches are increasingly common, Vaultix takes a zero-trust, offline-first approach. We don't host servers, we don't hold the keys, and we don't have accounts. Vaultix encrypts everything locally on your device using military-grade standards before a single byte leaves your phone.

---

## ✨ Features

- 🔒 **Zero-Knowledge Architecture:** Everything is encrypted locally. We literally cannot see your data.
- 📱 **Biometric Integration:** Seamlessly unlock your vault using native Fingerprint or Face ID hardware.
- ☁️ **Encrypted Cloud Sync:** Bring your own cloud. Automatically sync your AES-256 encrypted vault to your personal Google Drive. 
- 🛡️ **Screenshot Prevention:** Built-in OS-level flags (`FLAG_SECURE`) to prevent screen recording and screenshotting of sensitive views.
- 🔑 **Smart Password Generator:** Generate high-entropy passwords with customizable character sets, directly integrated into the creation flow.
- 💳 **Organized Vaults:** Neatly organize your digital life: Logins, Credit Cards, Secure Notes, and more.
- 🎨 **Premium UI/UX:** Built with a hyper-polished, fluid, and dynamic interface featuring glassmorphism, neon accents, and bespoke haptics.

---

## 🔐 Security Architecture

Vaultix employs a robust, industry-standard security model to ensure your secrets remain secret.

1. **Master Key Generation:** Your Master Password is run through **PBKDF2** with a unique, securely generated salt to derive a 256-bit encryption key.
2. **Local Encryption:** All entries are encrypted using **AES-256-GCM** (Galois/Counter Mode) ensuring both confidentiality and data authenticity.
3. **Secure Enclave Storage:** The derived keys and cryptographic nonces are stored in the device's hardware-backed Android Keystore / iOS Secure Enclave.
4. **Encrypted Sync:** When syncing to Google Drive, the payload is fully encrypted *before* transmission. The cloud only ever sees ciphertext.

---

## 🚀 Installation & Setup

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/kiran-embedded/vaultix-password-manager.git
   cd vaultix-password-manager
   ```

2. **Fetch Dependencies**
   ```bash
   flutter pub get
   ```

3. **Build the Release APK**
   *(Note: `--no-tree-shake-icons` is required as Vaultix dynamically renders icons based on user category input.)*
   ```bash
   flutter build apk --release --no-tree-shake-icons
   ```

4. **Install on Device**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🛠️ Tech Stack

- **Framework:** Flutter / Dart
- **State Management:** Riverpod
- **Local Storage:** Flutter Secure Storage (Keystore/Keychain)
- **Cloud Sync:** Googleapis / Google Sign-In
- **Animations:** Flutter Animate

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the [issues page](https://github.com/kiran-embedded/vaultix-password-manager/issues).

---

<div align="center">
  <p>Built with ❤️ by <a href="https://github.com/kiran-embedded">Kiran</a>.</p>
  <p><strong>Security first. Privacy always.</strong></p>
</div>
